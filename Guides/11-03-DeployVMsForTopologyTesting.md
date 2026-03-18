# Azure Hub-Spoke Topologi med Azure Firewall

## Last ned scriptet til lokal maskin og kjør det etter at du har koblet deg til din Tenant i VS Code (eller ønsket editor)

[PowerShell - Deploy VM's with Web Server and Create Firewall Rules](11-03-PowerShellScriptForDeployment.ps1)


# Deploy-HubSpokeVMs.ps1 – Hva gjør scriptet?

## Oversikt

I forrige øvelse bygde du hub-spoke-topologien manuelt i Azure Portal. I denne øvelsen kjører du et PowerShell-script som automatisk deployer tre Linux VM-er — én i hvert spoke — og konfigurerer Azure Firewall til å rute innkommende trafikk til korrekt VM via **DNAT-regler**. Etter at scriptet er ferdig kan du åpne en nettleser, skrive inn adressen til firewallen med et portnummer, og få servert en nettside fra riktig spoke.

Dette er et realistisk enterprise-scenario: VM-ene har ingen offentlig IP-adresse og er ikke direkte synlige fra internett. Det eneste inngangspunktet er Azure Firewall, som bestemmer nøyaktig hvilken trafikk som slippes inn, og til hvem.

**Læringsmål:**
- Forstå hva DNAT er og hvordan det brukes i Azure Firewall
- Forstå hvorfor VM-er uten public IP er tryggere enn VM-er med
- Kjøre et parameterisert PowerShell-script og tilpasse det til eget miljø
- Verifisere at trafikkruting via firewall fungerer som forventet

**Estimert tid:** 20–30 minutter (ekskludert VM-deploytid på ~5 minutter)

---

## Forutsetninger

- [ ] Du er innlogget med `Connect-AzAccount` mot riktig tenant og subscription
- [ ] Hub-spoke-topologien fra forrige øvelse er på plass: hub VNET, spoke-VNETs, VNET peering, rutetabeller og Azure Firewall
- [ ] `Deploy-HubSpokeVMs.ps1` er lastet ned og åpnet i VS Code eller en teksteditor

---

## Trafikkflyt — fra nettleser til webserver

Før du kjører scriptet er det nyttig å forstå nøyaktig hva som skjer når du besøker `http://<firewall-public-ip>:8081` i nettleseren.

Se figuren ovenfor. Trafikkflyten er:

**Steg 1 — Pakken treffer firewallen.**
Nettleseren din sender en HTTP-forespørsel til firewall public IP på port 8081. Firewallen mottar pakken og slår opp hvilken DNAT-regel som matcher destinasjonsport 8081.

**Steg 2 — DNAT-oversettelse.**
Firewallen finner regelen `dnat-http-spoke1`, som sier at trafikk til `:8081` skal oversettes og videresentsendes til `10.0.1.10:80`. Firewallen endrer destinasjonsadressen i pakken fra sin egen public IP til VM-ens private IP — dette kalles Destination Network Address Translation (DNAT).

**Steg 3 — Pakken sendes inn i spoke 1.**
Firewallen sender den oversatte pakken inn i `vnet-hub` via peering-forbindelsen til `vnet-infraitsec`, der den treffer `vm-web-spoke1` på port 80.

**Steg 4 — nginx svarer.**
nginx på VM-en mottar forespørselen og returnerer HTML-siden. Returtrafikken går tilbake via firewallen, som er stateful og husker den opprinnelige forbindelsen — den oversetter returadressen automatisk.

**Viktig detalj — SNAT på inngående trafikk:**
VM-en ser ikke din opprinnelige IP-adresse som kilde. Den ser firewall private IP (`10.100.1.4`). Dette er derfor NSG-reglene på spoke-subnetene tillater inngående HTTP og SSH fra `10.100.1.0/26` (AzureFirewallSubnet) — ikke fra internett direkte. Det er scriptet som legger til disse NSG-reglene automatisk.

---

## Hva scriptet gjør, steg for steg

Scriptet er delt inn i fem logiske steg som kjøres sekvensielt.

### Steg 1 — Opprett compute resource group

Scriptet sjekker om `<prefix>-rg-infraitsec-compute` allerede eksisterer. Finnes den ikke, opprettes den med de angitte tags. VM-ene plasseres i denne resource group, adskilt fra networks-ressursene i `<prefix>-rg-infraitsec-network`. Dette er i tråd med separasjon av ressurstyper som vi har praktisert gjennom hele kurset.

### Steg 2 — Deploy tre Linux VM-er

For hvert spoke kaller scriptet funksjonen `Deploy-SpokeVM`, som gjør følgende:

Funksjonen henter VNET-objektet og det angitte subnet fra Azure, og bygger deretter en NIC-konfigurasjon uten public IP. VM-en tildeles en **statisk privat IP-adresse** som du definerer i variablene øverst — dette er nødvendig fordi DNAT-reglene i neste steg hardkoder disse adressene som videresendingsmål.

VM-en konfigureres med Ubuntu 24.04 LTS og et **cloud-init-script** som kjøres automatisk ved første oppstart. Cloud-init installerer nginx og erstatter standard-forsiden med en tilpasset HTML-side som viser hvilken spoke VM-en tilhører og dens private IP. Dette skjer uten at du trenger å SSH inn.

Alle tre VM-er deployes sekvensielt med fremdriftsmeldinger i terminalen.

### Steg 3 — Legg til NSG-regler

Scriptet oppdaterer NSGene som er tilknyttet subnet-ene der VM-ene er deployet. Det legges til to inbound-regler i hver NSG:

- `allow-http-from-firewall` — tillater TCP port 80 fra `10.100.1.0/26`
- `allow-ssh-from-firewall` — tillater TCP port 22 fra `10.100.1.0/26`

Kildekretsen er bevisst begrenset til AzureFirewallSubnet. En VM i spoke 1 skal ikke kunne nås på port 80 fra spoke 2 eller internett direkte — bare via firewallen. Scriptet sjekker om reglene allerede finnes før det forsøker å legge dem til, slik at det er trygt å kjøre scriptet flere ganger.

### Steg 4 — Konfigurer DNAT-regler i Firewall Policy

Scriptet henter firewall-objektet og leser ut public IP-adressen automatisk — du trenger ikke å slå opp denne manuelt. Det opprettes deretter seks DNAT-regler, to per spoke (HTTP og SSH), som samles i én rule collection `dnat-spoke-vms` med prioritet 100.

Portmappingen er som følger:

| Ekstern port | Protokoll | Videresender til |
|---|---|---|
| `:8081` | TCP | `10.0.1.10:80` (spoke 1 HTTP) |
| `:8082` | TCP | `10.1.0.10:80` (spoke 2 HTTP) |
| `:8083` | TCP | `10.2.0.10:80` (spoke 3 HTTP) |
| `:2221` | TCP | `10.0.1.10:22` (spoke 1 SSH) |
| `:2222` | TCP | `10.1.0.10:22` (spoke 2 SSH) |
| `:2223` | TCP | `10.2.0.10:22` (spoke 3 SSH) |

SSH bruker ikke-standard porter eksternt (2221–2223) i stedet for standard port 22. Dette er en enkel men effektiv teknikk for å redusere automatisert skanning — de fleste portscannere og botnet-er scanner port 22, ikke 2221.

### Steg 5 — Oppsummering i terminalen

Etter fullført deployment skriver scriptet ut en ferdig formatert oversikt med alle URL-er og SSH-kommandoer, klar til å kopieres direkte.

---

## Tilpass variablene

Åpne scriptet og endre variablene øverst til dine egne verdier. De viktigste er:

```powershell
$prefix        = 'eg06'          # Ditt tildelte prefix
$adminPassword = 'InfraIT2025!'  # Velg et passord (min. 12 tegn)
```

De øvrige variablene — subnet-navn, VM-navn, IP-adresser og porter — er forhåndssatt til verdiene fra gjennomgangen og kan stå uendret med mindre du har avveket fra navnestandarden.

> **Merk om passord i klartekst:** Scriptet lagrer VM-passordet som en vanlig tekststreng i variabelen `$adminPassword`. Dette er praktisk for lab-formål, men er ikke anbefalt i produksjonsmiljøer. I en reell deployment ville passordet vært håndtert via `Read-Host -AsSecureString` eller hentet fra Azure Key Vault.

---

## Kjør scriptet og verifiser

### Kjøring

Lim inn hele scriptet i PowerShell-vinduet og trykk Enter, eller kjør filen direkte:

```powershell
.\Deploy-HubSpokeVMs.ps1
```

Scriptet skriver ut fremdrift underveis. Total kjøretid er typisk 5–8 minutter, avhengig av VM-deploytid.

### Verifisering av HTTP

Når scriptet er ferdig venter du ytterligere 2–3 minutter mens cloud-init installerer nginx. Åpne deretter nettleseren og naviger til:

```
http://<firewall-public-ip>:8081
http://<firewall-public-ip>:8082
http://<firewall-public-ip>:8083
```

Hver adresse skal vise en enkel nettside som bekrefter hvilken spoke trafikken ble sendt til.

### Verifisering av SSH

Test SSH-tilgang via firewallen til én av VM-ene (erstatt IP og port med faktisk verdi fra scriptet):

```bash
ssh azureuser@<firewall-public-ip> -p 2221
```

Kobler du til, har DNAT-regelen for SSH fungert korrekt.

### Verifisering i Azure Portal

Du kan bekrefte DNAT-konfigurasjonen i portalen:

1. Naviger til `<prefix>-fwpolicy-hub`
2. Velg **Rule collections** i venstremenyen
3. Du skal se en rule collection ved navn `dnat-spoke-vms` under `DnatRuleCollectionGroup`
4. Åpne den og bekreft at alle seks DNAT-regler er listet

---

## Opprydding

Når du er ferdig med å teste, stopp VM-ene for å spare kostnader:

```powershell
Stop-AzVM -ResourceGroupName "$prefix-rg-infraitsec-compute" -Name "$prefix-vm-web-spoke1" -Force
Stop-AzVM -ResourceGroupName "$prefix-rg-infraitsec-compute" -Name "$prefix-vm-web-spoke2" -Force
Stop-AzVM -ResourceGroupName "$prefix-rg-infraitsec-compute" -Name "$prefix-vm-web-spoke3" -Force
```

For å slette VM-ene og hele compute resource group:

```powershell
Remove-AzResourceGroup -Name "$prefix-rg-infraitsec-compute" -Force
```

Husk at Azure Firewall fortsatt faktureres så lenge den kjører. Se oppryddingsguiden i [hub-spoke-walkthroughen](11-01-HubSpokeNetwork.md) for riktig sletterekkefølge for alle ressurser.

---

## Feilsøking

### Problem: Nettleseren får ikke svar på port 8081–8083
**Mulig årsak 1:** Cloud-init er ikke ferdig ennå. Vent 3–4 minutter og prøv igjen.
**Mulig årsak 2:** DNAT-regelen er ikke propagert til firewallen. Sjekk at `dnat-spoke-vms` vises i Firewall Policy og at firewallen viser **Provisioning state: Succeeded**.
**Mulig årsak 3:** NSG-regelen mangler eller er feil konfigurert. Naviger til NSGen for spoke-subnettet og bekreft at `allow-http-from-firewall` er til stede med source `10.100.1.0/26`.

### Problem: SSH gir "Connection refused"
**Årsak:** Cloud-init kjører fremdeles, eller SSH-tjenesten er ikke oppe ennå.
**Løsning:** Vent et par minutter og prøv igjen. Du kan også sjekke VM-status i portalen.

### Problem: `Deploy-SpokeVM` feiler med "Subnet not found"
**Årsak:** Variabelen `$spoke1SubnetName` matcher ikke det faktiske subnet-navnet i VNET-et.
**Løsning:** Verifiser subnet-navnene i portalen: naviger til `<prefix>-vnet-infraitsec` → Subnets og sjekk eksakt stavemåte.

### Problem: DNAT rule collection group eksisterer allerede
**Årsak:** Scriptet er kjørt tidligere og `DnatRuleCollectionGroup` ble allerede opprettet.
**Løsning:** Slett den eksisterende rule collection group i portalen under `<prefix>-fwpolicy-hub` og kjør scriptet på nytt, eller legg til reglene manuelt i portalen.

---

## Refleksjonsspørsmål

1. **DNAT og sikkerhet:**
   - Hva er sikkerhetsfordelen med å rute all innkommende trafikk via firewallen fremfor å gi VM-ene egne public IP-adresser?
   - Hva er konsekvensen for angripere av at VM-ene ikke er direkte synlige fra internett?

2. **SNAT-effekten:**
   - VM-ene ser `10.100.1.4` (firewall private IP) som kildaadresse i innkommende HTTP-forespørsler, ikke din faktiske IP. Hva betyr dette for logging og feilsøking på VM-nivå?
   - Hvis du skulle logge faktisk klient-IP, hvor ville du gjort det?

3. **Port-valg:**
   - Hvorfor bruker SSH-tilgang porter 2221–2223 eksternt i stedet for standard port 22?
   - Er dette en tilstrekkelig sikkerhetstiltak alene, eller er det noe annet du burde gjøre i tillegg?

4. **Cloud-init:**
   - Hva er fordelen med å bruke cloud-init til å installere og konfigurere nginx kontra å SSH inn og gjøre det manuelt etter deployment?
   - Hva ville skje hvis cloud-init-scriptet inneholder en feil — ville VM-en starte opp likevel?

---

## Ressurser

- [Azure Firewall DNAT](https://learn.microsoft.com/en-us/azure/firewall/tutorial-firewall-dnat)
- [Azure Firewall Policy Rule Collections](https://learn.microsoft.com/en-us/azure/firewall/policy-rule-sets)
- [Cloud-init on Azure](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/using-cloud-init)
- [New-AzFirewallPolicyNatRule](https://learn.microsoft.com/en-us/powershell/module/az.network/new-azfirewallpolicynatrule)