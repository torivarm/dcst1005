# Lab 12-01: Deployment script for hub-spoke infrastruktur

I denne labben skal du kjøre et PowerShell-script som setter opp nettverksinfrastrukturen du trenger for de kommende labbene om VPN Gateway og Azure Kubernetes Service. Istedenfor å klikke deg gjennom Azure Portal steg for steg, uttrykker du hele infrastrukturen som kode — ett script som oppretter alt i riktig rekkefølge.

Dette er ikke bare en tidsbesparelse. Infrastruktur som kode er en grunnleggende arbeidsmetode i moderne drift. Når infrastrukturen er beskrevet i kode, kan den versjonskontrolleres, deles med kolleger, auditeres og reproduseres nøyaktig — noe som er umulig med manuelle portaloperasjoner. Du vil kjenne igjen prinsippet fra tidligere i kurset der dere brukte Heat templates i OpenStack for å provisjonere Windows Server-miljøet automatisk.

Scriptet er idempotent, noe som betyr at det kan kjøres flere ganger uten å feile eller opprette duplikater. Hvis kjøringen avbrytes, kan du starte på nytt og scriptet vil hoppe over det som allerede er opprettet og fortsette der det slapp.

> **Start scriptet tidlig.** Opprettelse av nettverksressurser i Azure tar noen minutter, og du vil at infrastrukturen er klar før du starter på Lab 12-02 der VPN Gateway og AKS deployes.

---

## Forutsetninger

Følgende må være på plass før du kjører scriptet:

Du trenger PowerShell 7 og Az-modulen installert på lokal maskin. Az-modulen ble installert i en tidligere lab. Verifiser at den er tilgjengelig ved å åpne VS Code på lokal maskin og kjøre følgende i et PowerShell-terminalvindu:

```powershell
Get-Module -Name Az -ListAvailable | Select-Object Name, Version
```

Du trenger din **Tenant ID**, som du finner i Azure Portal under **Microsoft Entra ID → Overview**. Kopier verdien fra feltet **Tenant ID**.

Du trenger ditt **prefiks** — initialer pluss to sifre fra fødselsåret (f.eks. `on03`). Dette er det samme prefikset du har brukt i alle tidligere Azure-laber.

---

## Del 1 — Gjennomgang av scriptets struktur

Før du kjører scriptet er det nyttig å forstå hva det gjør og hvorfor det er bygget opp slik det er. Åpne `12-01-DeployInfrastructure.ps1` i VS Code og les gjennom de ulike seksjonene mens du leser forklaringene under.

[PowerShell - Deploy infrastructure](12-01-DeployInfrastructure.ps1)

### Konfigurasjonsseksjonen

Øverst i scriptet finner du to variabler du selv må fylle inn:

```powershell
$prefix   = "prefix"               # <-- ENDRE TIL DITT EGET PREFIKS
$tenantId = "your-tenant-id-here"  # <-- ENDRE TIL DIN TENANT ID
```

Resten av variablene — ressursnavn, adresseplan og tags — bygges automatisk fra prefikset ditt. Dette sikrer at alle studenter følger samme navnekonvensjon uten å måtte huske alle reglene manuelt.

### Adresseplanen

Scriptet setter opp to separate VNET-er med følgende adresserom:

| Ressurs | Adresserom | Formål |
|---------|-----------|--------|
| Hub VNET | 10.0.0.0/16 | Sentralt nettverk for delte tjenester |
| GatewaySubnet | 10.0.0.0/27 | Reservert for VPN Gateway |
| ManagementSubnet | 10.0.1.0/24 | Administrasjonsressurser |
| Spoke VNET | 10.1.0.0/16 | Applikasjonsnettverk |
| AKS-subnett | 10.1.0.0/24 | Azure Kubernetes Service |

GatewaySubnet bruker et `/27`-prefix (32 adresser), som er anbefalt minimum for VPN Gateway. Azure reserverer alltid fem adresser per subnett til intern bruk, så et `/27` gir 27 tilgjengelige adresser — tilstrekkelig for gateway-en.

VPN-klienter som kobler til via P2S tildeles adresser fra et eget adresserom (`172.16.0.0/24`) som konfigureres i Lab 12-02. Dette adresserommet er adskilt fra alle VNET-adressene og må ikke overlappe.

### Idempotente sjekker

For hver ressurs sjekker scriptet om den allerede eksisterer før det forsøker å opprette den:

```powershell
$existingRg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if ($existingRg) {
    Write-Status -Message $rgName -Status "Exists"
} else {
    New-AzResourceGroup ...
    Write-Status -Message $rgName -Status "Created"
}
```

`-ErrorAction SilentlyContinue` er nøkkelen her: istedenfor å kaste en feilmelding når ressursen ikke finnes, returnerer kommandoen `$null`, og `if`-blokken håndterer begge tilfeller. Output bruker fargekoder — grønn for ny ressurs, gul for eksisterende.

### NSG-logikken

Scriptet oppretter en Network Security Group kun på ManagementSubnet. Dette er et bevisst valg:

**GatewaySubnet** skal ikke ha NSG — Azure tillater det ikke, fordi gatewayen trenger fri tilgang til å administrere VPN-tilkoblinger internt.

**AKS-subnettet** skal ikke ha en custom NSG fra oss — AKS oppretter og administrerer sine egne nettverksregler internt ved deployment. En custom NSG på subnettnivå kan blokkere kritisk intern Kubernetes-kommunikasjon mellom API server, nodes og pods.

### Peering-konfigurasjonen

Peering opprettes i begge retninger, noe som er et Azure-krav. De to peeringene har ulike innstillinger som gjenspeiler rollen hub og spoke har:

```powershell
# Hub -> Spoke: AllowGatewayTransit er et switch-parameter
Add-AzVirtualNetworkPeering `
    -Name $peeringHubToSpoke `
    -VirtualNetwork $hubVnet `
    -RemoteVirtualNetworkId $spokeVnet.Id `
    -AllowGatewayTransit

# Spoke -> Hub: ingen switch-parametere = begge false
Add-AzVirtualNetworkPeering `
    -Name $peeringSpokeToHub `
    -VirtualNetwork $spokeVnet `
    -RemoteVirtualNetworkId $hubVnet.Id
```

`AllowGatewayTransit` på hub-siden betyr at hub-en tillater at spoke-ene *bruker* gateway-en sin. `UseRemoteGateways` på spoke-siden betyr at spoke-en *ønsker* å bruke hub-ens gateway. Disse to innstillingene må matche — begge må være aktive for at trafikk fra VPN-klienter skal nå spoke-en.

Scriptet setter `UseRemoteGateways` til false (ved å utelate switch-parameteret) fordi VPN Gateway ikke eksisterer ennå. Hvis du forsøker å aktivere `UseRemoteGateways` mot en hub som ikke har en gateway, vil Azure returnere en feilmelding. Du aktiverer denne innstillingen i Lab 12-02 etter at gateway-en er provisjonert.

---

## Del 2 — Konfigurer og kjør scriptet

### Steg 2.1 — Åpne scriptet i VS Code

Åpne `12-01-DeployInfrastructure.ps1` i VS Code på lokal maskin. Finn de to variablene øverst i scriptet og erstatt plassholderverdiene:

```powershell
$prefix   = "on03"                                  # Ditt eget prefiks
$tenantId = "ec25d615-a67b-411a-9073-de7880b3b8a3"  # Din Tenant ID
```

Lagre filen.

### Steg 2.2 — Kjør scriptet

Åpne et PowerShell-terminalvindu i VS Code (**Terminal → New Terminal**) og kjør:

```powershell
.\12-01-DeployInfrastructure.ps1
```

### Steg 2.3 — Autentiser mot Azure

Scriptet åpner en nettleserside der du logger inn med din `@stud.ntnu.no`-konto. Etter vellykket innlogging returnerer scriptet til terminalen og fortsetter.

Hvis nettleservinduet ikke åpner seg automatisk, kan du bruke device authentication som alternativ. Erstatt `Connect-AzAccount`-linjen i scriptet med:

```powershell
Connect-AzAccount -Tenant $tenantId -UseDeviceAuthentication
```

### Steg 2.4 — Følg med på output

Scriptet skriver statusmeldinger underveis. Fargeforklaringen er som følger:

| Farge | Betydning |
|-------|-----------|
| Grønn `[NY]` | Ressursen ble opprettet nå |
| Gul `[EKSISTERER]` | Ressursen fantes allerede, hoppet over |
| Cyan `[OPPDATERT]` | Ressursen ble endret |
| Rød `[FEIL]` | Noe gikk galt |

Et vellykket kjøring uten eksisterende ressurser vil se omtrent slik ut:

```
[2/8] Oppretter Resource Groups...
  [NY]          on03-rg-infraitsec-network
  [NY]          on03-rg-infraitsec-compute

[3/8] Oppretter NSG for ManagementSubnet...
  [NY]          on03-nsg-management

[4/8] Oppretter Hub VNET med subnett...
  [NY]          on03-vnet-hub (10.0.0.0/16)
    Subnett: GatewaySubnet (10.0.0.0/27) - ingen NSG (Azure-krav)
    Subnett: on03-snet-management (10.0.1.0/24) - med NSG

[5/8] Oppretter Spoke VNET med AKS-subnett...
  [NY]          on03-vnet-spoke (10.1.0.0/16)
    Subnett: on03-snet-aks (10.1.0.0/24) - ingen NSG (AKS-krav)

[6/8] Konfigurerer VNET Peering (hub <-> spoke)...
  [NY]          on03-peer-hub-to-spoke (AllowGatewayTransit = true)
  [NY]          on03-peer-spoke-to-hub (UseRemoteGateways = false, oppdateres i neste lab)
```

---

## Del 3 — Verifiser infrastrukturen i Azure Portal

Når scriptet er ferdig, navigerer du til Azure Portal og verifiserer at ressursene er opprettet korrekt.

### Steg 3.1 — Sjekk Resource Groups

Naviger til **Resource groups** i Azure Portal. Du skal se to nye resource groups:

- `<prefix>-rg-infraitsec-network`
- `<prefix>-rg-infraitsec-compute`

Compute-gruppen er tom foreløpig — AKS deployes her i Lab 12-02.

### Steg 3.2 — Sjekk Hub VNET og subnett

Åpne `<prefix>-rg-infraitsec-network` og klikk på `<prefix>-vnet-hub`. Under **Subnets** skal du se:

- `GatewaySubnet` med adresserom `10.0.0.0/27` og ingen NSG
- `<prefix>-snet-management` med adresserom `10.0.1.0/24` og NSG tilknyttet

### Steg 3.3 — Sjekk peering-status

Klikk på `<prefix>-vnet-hub` og velg **Peerings** under Settings. Du skal se `<prefix>-peer-hub-to-spoke` med status **Connected**.

Gjør det samme for `<prefix>-vnet-spoke` — peeringen `<prefix>-peer-spoke-to-hub` skal også vise **Connected**.

Hvis en peering viser **Initiated** istedenfor **Connected**, betyr det at kun én side ble opprettet. Kjør scriptet på nytt — det vil oppdage den inkonsistente tilstanden, slette begge sider og opprette dem på nytt.

---

## Del 4 — Hvis scriptet avbrytes

Siden scriptet er idempotent, er fremgangsmåten enkel hvis noe går galt:

Les feilmeldingen i terminalen for å forstå hva som feilet. De vanligste årsakene er nettverksproblemer under autentisering, timeout mot Azure API, eller at en ressurs er i en midlertidig tilstand (f.eks. "Updating").

Kjør scriptet på nytt. Ressurser som allerede er opprettet vises med gul `[EKSISTERER]`-melding og hoppes over. Scriptet fortsetter fra der det slapp og forsøker å opprette det som mangler.

Hvis du ser en rød `[FEIL]`-melding, ta kontakt med faglærer og vis frem feilmeldingen fra terminalen.

---

## Oppsummering

Etter fullført lab skal du ha følgende på plass i Azure:

To resource groups — én for nettverk og én for compute-ressurser som kommer i neste lab.

Et hub-spoke nettverksoppsett med VNET peering der hub-en er konfigurert til å dele en fremtidig VPN Gateway med spoke-en.

Et GatewaySubnet i hub-en dimensjonert og navngitt korrekt for VPN Gateway.

Et AKS-subnett i spoke-en dimensjonert for kubenet-basert Kubernetes-deployment.

Du er nå klar for Lab 12-02, der VPN Gateway og AKS deployes inn i denne infrastrukturen.