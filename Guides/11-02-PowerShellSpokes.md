# Azure PowerShell – Tilkobling og Deployment av Spoke-nettverk

## Oversikt

Så langt har du opprettet Azure-ressurser manuelt via portalen. Det fungerer godt for å lære seg hva de ulike ressursene er og hvordan de henger sammen, men i praksis er manuell klikking i portalen lite egnet for gjentakende oppgaver. Hvis du skal rive ned og bygge opp et miljø flere ganger — for eksempel for å øve til eksamen, eller fordi noe gikk galt — er det både tidkrevende og feilutsatt å gjøre det for hånd.

**PowerShell med Az-modulen** gir deg muligheten til å beskrive infrastruktur som kode. Du definerer ressursene én gang i et script, og kan deretter kjøre det så mange ganger du vil med garantert samme resultat. Denne øvelsen introduserer deg til det grunnleggende: hvordan du installerer nødvendige moduler, kobler deg til din Azure-tenant, og kjører et script som oppretter spoke 2 og spoke 3 fra forrige øvelse.

**Læringsmål:**
- Installere og verifisere Az PowerShell-modulen
- Koble til Azure med `Connect-AzAccount` mot riktig tenant og subscription
- Forstå og bruke variabler i et PowerShell-script
- Kjøre et script som oppretter virtuelle nettverk med subnets i Azure

**Estimert tid:** 30 minutter

---

## Forutsetninger

- [ ] PowerShell 7 installert på din maskin (kontroller med `$PSVersionTable.PSVersion` i et PowerShell-vindu)
- [ ] Tenant ID og Subscription ID for ditt Azure-miljø (Finnes i portal.azure.com)
- [ ] Ditt tildelte prefix (f.eks. `eg06`, `tim84`)
- [ ] Fullført forrige øvelse — `<prefix>-rg-infraitsec-networking` eksisterer allerede

---

## Del 1: Installer Az-modulen

### Hva er Az-modulen?

Az er den offisielle PowerShell-modulen fra Microsoft for å administrere Azure-ressurser. En **modul** er en samling av kommandoer (kalt *cmdlets*) som utvider hva PowerShell kan gjøre. Uten Az-modulen kjenner ikke PowerShell til kommandoer som `New-AzVirtualNetwork` eller `Connect-AzAccount`.

### Steg 1.1: Åpne PowerShell 7

Åpne **PowerShell 7** — ikke Windows PowerShell 5.1. Du kan skille dem ved at PowerShell 7 viser `PS 7.x.x` i tittelen, eller ved å kjøre:

```powershell
$PSVersionTable.PSVersion
```

Outputen skal vise `Major` lik `7` eller høyere.

### Steg 1.2: Sjekk om Az-modulen allerede er installert

```powershell
Get-Module -Name Az -ListAvailable
```

Hvis du ser en liste med versjonsnummer, er modulen allerede installert — hopp til Del 2. Hvis du får blank output eller en feilmelding, fortsett til neste steg.

### Steg 1.3: Installer Az-modulen

```powershell
Install-Module -Name Az -Repository PSGallery -Force
```

Dette kan ta noen minutter. PowerShell laster ned og installerer modulen fra det offisielle PowerShell Gallery-repositoriet. Flagget `-Force` sørger for at installasjonen kjøres uten bekreftelsesprompts.

> **Merk:** Hvis du får spørsmål om å stole på repositoriet (`Do you want PowerShellGet to install and import the NuGet provider?`), svar **Y** og trykk Enter.

### Steg 1.4: Verifiser installasjonen

```powershell
Get-Module -Name Az -ListAvailable
```

Du skal nå se en liste der `Az` er oppført med et versjonsnummer. Modulen er klar til bruk.

---

## Del 2: Koble til Azure

### Hva skjer når du kobler til?

`Connect-AzAccount` starter en autentiseringsprosess der du logger inn med din NTNU-bruker mot Microsofts identitetstjeneste (Entra ID). Ved å oppgi både `-Tenant` og `-SubscriptionId` sørger du for at du lander i riktig tenant og riktig subscription umiddelbart — uten å måtte navigere manuelt etterpå.

### Steg 2.1: Koble til din Azure-tenant

Erstatt verdiene i enkeltfnutter med dine faktiske IDs (oppgitt av lærer):

```powershell
Connect-AzAccount -Tenant 'xxxx-xxxx-xxxx-xxxx' -SubscriptionId 'yyyy-yyyy-yyyy-yyyy'
```

Et nettleservindu åpner seg automatisk. Logg inn med din NTNU-bruker. Når innloggingen er fullført, lukkes nettleservinduet og PowerShell-vinduet viser en bekreftelse med kontoinformasjon.

### Steg 2.2: Verifiser tilkoblingen

Sjekk at du er koblet til riktig subscription:

```powershell
Get-AzContext
```

Outputen viser hvilken konto, tenant og subscription du er aktiv på. Bekreft at `SubscriptionId` og `TenantId` matcher det du forventet.

---

## Del 3: Opprett spoke 2 og spoke 3 med script

### Hva gjør scriptet?

Scriptet under oppretter de to spoke-nettverkene fra forrige øvelse — `<prefix>-vnet-spoke2` og `<prefix>-vnet-spoke3` — med korrekte adresserom og subnets. Alle verdier som er spesifikke for ditt miljø er samlet som variabler øverst i scriptet. Du trenger bare å endre disse variablene; resten av scriptet er generelt og gjenbrukbart.

### Steg 3.1: Tilpass variablene

Åpne et nytt script i VS Code eller lim inn direkte i PowerShell. Endre variablene øverst til dine egne verdier:

```powershell
#########################################################
# Variabler — endre disse til dine egne verdier
#########################################################

$prefix            = 'tim84'       # Ditt tildelte prefix
$resourceGroupName = "$prefix-rg-infraitsec-network"
$location          = 'northeurope'  # Husk å endre til samme region/location som du har brukt tidligere

# Spoke 2
$spoke2VnetName    = "$prefix-vnet-spoke2"
$spoke2AddressSpace = '10.1.0.0/16'
$spoke2SubnetName  = 'subnet-workload'
$spoke2SubnetPrefix = '10.1.0.0/24'

# Spoke 3
$spoke3VnetName    = "$prefix-vnet-spoke3"
$spoke3AddressSpace = '10.2.0.0/16'
$spoke3SubnetName  = 'subnet-workload'
$spoke3SubnetPrefix = '10.2.0.0/24'

#########################################################
# Opprett spoke 2
#########################################################

Write-Host "Oppretter $spoke2VnetName..." -ForegroundColor Cyan

$spoke2Subnet = New-AzVirtualNetworkSubnetConfig `
    -Name $spoke2SubnetName `
    -AddressPrefix $spoke2SubnetPrefix

New-AzVirtualNetwork `
    -Name $spoke2VnetName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -AddressPrefix $spoke2AddressSpace `
    -Subnet $spoke2Subnet `
    -Tag @{ Owner = $prefix; Environment = 'Lab'; Course = 'InfraIT.sec' }

Write-Host "$spoke2VnetName opprettet." -ForegroundColor Green

#########################################################
# Opprett spoke 3
#########################################################

Write-Host "Oppretter $spoke3VnetName..." -ForegroundColor Cyan

$spoke3Subnet = New-AzVirtualNetworkSubnetConfig `
    -Name $spoke3SubnetName `
    -AddressPrefix $spoke3SubnetPrefix

New-AzVirtualNetwork `
    -Name $spoke3VnetName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -AddressPrefix $spoke3AddressSpace `
    -Subnet $spoke3Subnet `
    -Tag @{ Owner = $prefix; Environment = 'Lab'; Course = 'InfraIT.sec' }

Write-Host "$spoke3VnetName opprettet." -ForegroundColor Green

Write-Host "`nFerdig! Begge spoke-nettverk er opprettet." -ForegroundColor Green
```

### Steg 3.2: Forstå scriptet

Før du kjører, les gjennom de viktigste delene:

**Variabler** (`$prefix`, `$location` osv.) gjør scriptet gjenbrukbart. Ved å samle alle konfigurasjonsverdier øverst slipper du å lete gjennom koden for å gjøre endringer.

**`New-AzVirtualNetworkSubnetConfig`** oppretter en subnet-konfigurasjon i minnet — det vil si at subnettet ikke eksisterer i Azure ennå, men er klart til å sendes med i neste kommando.

**`New-AzVirtualNetwork`** oppretter selve det virtuelle nettverket i Azure og inkluderer subnet-konfigurasjonen fra forrige steg via `-Subnet`-parameteren. Legg merke til backtick-tegnet `` ` `` på slutten av linjene — dette er PowerShells linjeskifttegn og lar deg skrive én lang kommando over flere linjer for lesbarhetens skyld.

**`Write-Host`** med `-ForegroundColor` gir farget output i terminalen, slik at du enkelt kan se fremdriften i scriptet.

### Steg 3.3: Kjør scriptet

Lim inn hele scriptet i PowerShell og trykk Enter. Du vil se cyan-farget tekst mens ressursene opprettes, etterfulgt av grønn tekst når hvert nettverk er klart. Hele kjøringen tar typisk 15–30 sekunder.

### Steg 3.4: Verifiser resultatet

Bekreft at begge nettverkene ble opprettet som forventet:

```powershell
Get-AzVirtualNetwork -ResourceGroupName "$prefix-rg-infraitsec-network" |
    Select-Object Name, Location, @{N='AddressSpace';E={$_.AddressSpace.AddressPrefixes}}
```

Du skal se alle dine virtuelle nettverk i resource gruppen listet opp med navn og adresserom — inkludert de to nye spoke-nettverkene.

For å inspisere subnets i ett spesifikt nettverk:

```powershell
Get-AzVirtualNetwork -Name "$prefix-vnet-spoke2" -ResourceGroupName "$prefix-rg-infraitsec-network" |
    Select-Object -ExpandProperty Subnets |
    Select-Object Name, AddressPrefix
```

---

## Feilsøking

### Problem: `Connect-AzAccount` åpner ikke nettleservindu
**Årsak:** Nettleseren kan være blokkert av popup-blokkering, eller du kjører PowerShell uten grafisk grensesnitt.
**Løsning:** Prøv å kjøre med `-UseDeviceAuthentication`-flagget i stedet:
```powershell
Connect-AzAccount -Tenant 'xxxx-xxxx-xxxx-xxxx' -SubscriptionId 'yyyy-yyyy-yyyy-yyyy' -UseDeviceAuthentication
```
Du får da en kode og en URL du kan åpne manuelt i hvilken som helst nettleser.

### Problem: `Install-Module` feiler med tilgangsfeil
**Årsak:** PowerShell kjøres uten administratorrettigheter.
**Løsning:** Legg til `-Scope CurrentUser` for å installere bare for din bruker, uten å trenge admin:
```powershell
Install-Module -Name Az -Repository PSGallery -Force -Scope CurrentUser
```

### Problem: `New-AzVirtualNetwork` feiler med "Resource group not found"
**Årsak:** Variabelen `$resourceGroupName` inneholder feil navn, eller resource gruppen eksisterer ikke.
**Løsning:** Verifiser at resource gruppen eksisterer:
```powershell
Get-AzResourceGroup -Name "$prefix-rg-infraitsec-networking"
```
Sjekk også at `$prefix` er satt til ditt faktiske prefix og ikke inneholder skrivefeil.

### Problem: `Get-AzContext` viser feil subscription etter innlogging
**Årsak:** Kontoen din har tilgang til flere subscriptions og Azure valgte feil.
**Løsning:** Bytt aktivt subscription manuelt:
```powershell
Set-AzContext -SubscriptionId 'yyyy-yyyy-yyyy-yyyy'
```

---

## Refleksjonsspørsmål

1. **Scripting vs. portal:**
   - Hvilke situasjoner egner seg best for manuell oppretting via portalen, og hvilke egner seg best for scripting?
   - Hva er fordelene med å samle alle konfigurasjonsverdier som variabler øverst i et script?

2. **Autentisering:**
   - Hvorfor er det nødvendig å oppgi både `-Tenant` og `-SubscriptionId` til `Connect-AzAccount`?
   - Hva er forskjellen på en Tenant ID og en Subscription ID?

3. **Idempotens:**
   - Hva tror du skjer hvis du kjører scriptet to ganger uten å slette ressursene i mellom?
   - Hva må til for at et script skal være *idempotent* — det vil si at det gir samme resultat uansett hvor mange ganger det kjøres?

---

## Neste steg

Nå som VNET er på på plass, er neste steg:

- **VNET Peering** — Sette opp peering mellom hub og spokes nettverkene

---

## Ressurser

- [Az PowerShell Module Documentation](https://learn.microsoft.com/en-us/powershell/azure/)
- [Connect-AzAccount](https://learn.microsoft.com/en-us/powershell/module/az.accounts/connect-azaccount)
- [New-AzVirtualNetwork](https://learn.microsoft.com/en-us/powershell/module/az.network/new-azvirtualnetwork)
- [PowerShell 7 Installation](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell)