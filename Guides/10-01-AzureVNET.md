# Azure Virtual Network - Opprettelse i Portal

## Oversikt

I denne øvelsen skal du opprette et Azure Virtual Network (VNet) som danner grunnlaget for din Azure-baserte infrastruktur. VNet fungerer som et isolert nettverksområde i Azure hvor du kan plassere virtuelle maskiner, storage accounts, og andre Azure-ressurser.

**Hva er et Virtual Network?**

Et Azure Virtual Network er en logisk isolasjon av Azure-nettverket dedikert til din subscription. Tenk på det som ditt eget private nettverk i skyen, tilsvarende et on-premises nettverk du administrerer selv, men med fordelene av Azures skalerbare infrastruktur.

**Læringsmål:**
- Forstå hensikten med Azure Virtual Networks
- Opprette et VNet med riktig adresseområde
- Forstå naming conventions for delte Azure-miljøer

**Estimert tid:** 15 minutter

---

## Forutsetninger

- [ ] Tilgang til Azure Portal med din NTNU-bruker
- [ ] Tilgang til subscription
- [ ] Kjennskap til grunnleggende IP-adressering og subnetting
- [ ] Ditt tildelte prefix (f.eks. `eg06`, `tim84`)

---

## Del 1: Planlegging av IP-adresseområde

Før du oppretter VNet, må du bestemme hvilket IP-adresseområde nettverket skal bruke.

### Hva er et Adresseområde?

Et VNet må ha et definert IP-adresseområde (address space) som brukes til å tildele IP-adresser til ressurser i nettverket. Dette adresseområdet må være:
- Et privat IP-område (ikke offentlig internett-adresser)
- Stort nok til å romme alle ressurser du planlegger
- Unikt hvis du senere skal koble VNet til on-premises nettverk via VPN

### Anbefalte Adresseområder

For lab-miljøet anbefales følgende:

**RFC 1918 private adresseområder:**
- `10.0.0.0/8` - Stort område, mye plass
- `172.16.0.0/12` - Middels område
- `192.168.0.0/16` - Mindre område

**For denne labben bruker vi:**
- `10.100.0.0/16` - Gir 65,536 adresser
- Unikt område som ikke kolliderer med lab-nettverket ditt i OpenStack

**Hvorfor /16?**

En `/16` subnet mask gir deg 65,536 IP-adresser, som er mer enn nok for lab-formål. Du kan deretter dele dette opp i mindre subnets (f.eks. `/24` subnets med 256 adresser hver) for forskjellige formål.

---

## Del 2: Opprett Virtual Network

### Steg 2.1: Naviger til Virtual Networks

1. Logg inn på [Azure Portal](https://portal.azure.com) med din NTNU-bruker

2. I søkefeltet øverst, søk etter **"Virtual networks"**

3. Klikk **"Virtual networks"** i resultatene

4. Klikk **"+ Create"**

### Steg 2.2: Basics Tab

**Fyll ut følgende:**

**Project details:**
- **Subscription:** Velg riktig subscription
- **Resource group:** Velg **"Create new"**
  - **Navn:** `<prefix>-rg-infraitsec-network`
  - Eksempel: `eg06-rg-infraitsec-network`

**Instance details:**
- **Virtual network name:** `<prefix>-vnet-infraitsec`
  - Eksempel: `eg06-vnet-infraitsec`
  - **VIKTIG:** Bruk din egen prefix for å sikre unikt navn
- **Region:** Velg en region som har brukt tidligere

**Hvorfor egen Resource Group?**

Å opprette en separat resource group for networking-ressurser gjør det enkelt å:
- Organisere ressurser etter kategori
- Administrere tilganger (RBAC) på nettverksnivå
- Rydde opp senere (kan slette hele RG)
- Få oversikt over kostnader per ressursgruppe

Klikk **Next**

### Steg 2.3: Security Tab

På **Security**-flaket **kan** du enable flere sikkerhetsfunksjoner. For vårt lab-formål, skal vi **ikke** enable noen av disse i denne sammenhengen.

- **Virtual network encryption:** Ikke enable (koster penger)
  - Aktiver kryptering av virtuelle nettverk for å kryptere trafikk som beveger seg innenfor det virtuelle nettverket

- **Azure Bastion:** Ikke enable (koster penger)
  - Bastion gir sikker RDP/SSH-tilgang uten public IP
  - Bra for produksjon, men ikke nødvendig for lab
  
- **Azure Firewall:** Ikke enable (koster **mye** penger)
  - Managed firewall service
  - Dyrt for lab-bruk
  
- **Azure DDoS Network Protection:** Ikke enable (koster **mye** penger)
  - Beskyttelse mot DDoS-angrep
  - Ikke nødvendig for lab

**La alle stå på "Disable"** for å unngå kostnader.

Klikk **"Next: IP Addresses >"**

### Steg 2.4: IP Addresses Tab

Her defineres nettverkets adresseområde.

**IPv4 address space:**

1. Du skal se et forhåndsutfylt adresseområde (f.eks. `10.0.0.0/16`)

2. Vi kan bare la dette området stå, siden det ikke er farlig om flere studenter har samme adresserom som ikke skal kommunisere sammen.

3. Her ser vi også et default subnet med navnet default. Trykk på søppelbøtten ved dette subnetet, siden vi skal opprette egen, og benytte en bedre navnestandard enn default.
   
4.  Klikk **"Next"** for komme til Tags. Legg til tags som tidligere.

5.  Review and Create

**Hva betyr dette?**

- `10.100.0.0/16` betyr at VNet kan bruke IP-adresser fra `10.100.0.0` til `10.100.255.255`
- Totalt 65,536 mulige IP-adresser
- Dette er mer enn nok for alle subnets du kommer til å opprette

**Subnets:**

Du ser at Azure automatisk har opprettet et default subnet. Vi skal **IKKE** bruke dette - vi oppretter egne subnets i neste øvelse.

1. Hvis det finnes et "default" subnet → **slett det** (søppelbøtte-ikon)

**Hvorfor ikke default subnet?**

Vi vil ha kontroll over subnet-strukturen og opprette subnets med beskrivende navn som reflekterer deres formål (frontend, backend, management, etc.)

Klikk **"Next: Tags >"**

### Steg 2.5: Tags Tab

Tags brukes til å organisere og kategorisere Azure-ressurser.

**Legg til følgende tags:**

| Name | Value |
|------|-------|
| `Owner` | `<dittbrukernavn>` |
| `Environment` | `Lab` |
| `Course` | `InfraIT-Cyber` |
| `Purpose` | `Hybrid-Infrastructure` |

**Hvorfor tags?**

- Enkel filtrering og søk etter ressurser
- Kostnadssporing per prosjekt/miljø
- Automatisering basert på tags
- Dokumentasjon av ressurs-eierskap

Klikk **"Next: Review + create >"**

### Steg 2.6: Review and Create

1. Azure validerer konfigurasjonen din

2. **Gjennomgå innstillingene:**
   - Resource group: `<prefix>-rg-infraitsec-network`
   - VNet name: `<prefix>-vnet-infraitsec`
   - Region: North Europe
   - Address space: `10.100.0.0/16`
   - Subnets: Ingen (skal være tomt)

3. Hvis validering passerer, klikk **"Create"**

4. Deployment starter - dette tar typisk 30-60 sekunder

5. Når du ser "Your deployment is complete", klikk **"Go to resource"**

---

## Del 3: Verifiser Virtual Network

### Steg 3.1: Oversikt

Du er nå på VNet-siden. Sjekk følgende:

**Overview-fanen:**
- **Resource group:** Skal vise din nye RG
- **Location:** North Europe
- **Subscription:** Din subscription
- **Address space:** `10.100.0.0/16`
- **Subnets:** 0 (vi oppretter disse i neste øvelse)

### Steg 3.2: Utforsk Settings

**Venstre meny → Settings:**

**Address space:**
- Klikk på **"Address space"** (venstre meny)
- Bekreft at `10.100.0.0/16` er listet
- Dette kan endres senere hvis nødvendig

**Subnets:**
- Klikk på **"Subnets"**
- Skal være tom (vi oppretter subnets i neste øvelse)

**Connected devices:**
- Klikk på **"Connected devices"**
- Skal være tom (ingen VM-er eller andre ressurser ennå)

**DNS servers:**
- Klikk på **"DNS servers"**
- Skal vise **"Default (Azure-provided)"**
- Dette betyr at Azure sin DNS-server brukes automatisk

**Hva er Azure-provided DNS?**

Azure gir automatisk DNS-oppløsning for ressurser i VNet:
- Ressurser kan finne hverandre via hostname
- Automatisk registrering av VM-navn
- Ingen egen DNS-server nødvendig for enkel lab

---

## Del 4: Visualiser Network Topology (Valgfritt)

Azure Portal har et verktøy for å visualisere nettverkstopologi.

### Steg 4.1: Network Topology Viewer

1. I Azure Portal, søk etter **"Network Watcher"**

2. Venstre meny → **Topology**

3. **Subscription:** Velg din subscription

4. **Resource group:** Velg `<prefix>-rg-infraitsec-network`

5. Klikk **"View topology"** eller vent på automatisk oppdatering

**Du skal se:**
- En grafisk fremstilling av ditt VNet
- Foreløpig bare VNet-ikonet (ingen subnets eller VMs ennå)

Dette verktøyet blir mer nyttig etter hvert som du legger til flere ressurser.

---

## Del 5: Forberedelse til Hybrid Connectivity (Konseptuelt)

Selv om du ikke setter opp VPN i denne øvelsen, er det viktig å forstå hvordan VNet passer inn i hybrid cloud-arkitekturen.

### On-Premises til Azure Connectivity

**Ditt VNet (`10.100.0.0/16`)** i Azure kan kobles til **ditt lab-nettverk** i OpenStack via:

**Point-to-Site VPN (P2S):**
- Din PC kobler til Azure VNet via VPN-klient
- Nyttig for administrativ tilgang
- Krever VPN Gateway (koster ~€30/mnd)

**Site-to-Site VPN (S2S):**
- Permanent VPN-tunnel mellom on-premises og Azure
- Alle servere i begge nettverk kan kommunisere
- Krever VPN Gateway på begge sider

**Azure ExpressRoute:**
- Dedikert privat forbindelse til Azure (ikke over internett)
- Høy ytelse, lav latency
- Dyrt - for enterprise-bruk

**For denne labben:**

Vi setter IKKE opp VPN (for dyrt), men VNet-strukturen vi bygger nå er forberedt for fremtidig VPN-integrasjon hvis nødvendig.

**Viktig designprinsipp:**

VNet-adresseområdet (`10.100.0.0/16`) må **ikke** overlappe med on-premises nettverk (`192.168.111.0/24` i OpenStack). Dette sikrer at IP-ruting fungerer korrekt hvis du senere kobler nettverkene sammen.

---

## Feilsøking

### Problem: "Virtual network name is already in use"

**Symptom:** Får feilmelding under validering at VNet-navnet allerede eksisterer.

**Årsak:** En annen student (eller du tidligere) har opprettet VNet med samme navn.

**Løsning:**

1. Bruk ditt unike prefix: `<prefix>-vnet-infraitsec`
2. Hvis fortsatt konflikt, legg til dato: `<prefix>-vnet-infraitsec-0603` (dag+måned)

---

### Problem: "Address space overlaps with existing VNet"

**Symptom:** Validering feiler med melding om overlappende adresseområder.

**Årsak:** Hvis du har andre VNets i samme subscription/region med overlappende IP-områder.

**Løsning:**

1. Sjekk eksisterende VNets: Portal → Virtual Networks → se address spaces
2. Velg et unikt område, f.eks.:
   - `10.101.0.0/16`
   - `10.110.0.0/16`
   - `10.200.0.0/16`

---

### Problem: "Subscription has reached VNet limit"

**Symptom:** Kan ikke opprette VNet - quota exceeded.

**Årsak:** Standard quota er typisk 50-100 VNets per subscription.

**Løsning:**

1. Sjekk eksisterende VNets: `Virtual Networks` → list alle
2. Slett gamle/ubrukte VNets
3. Kontakt lærer hvis quota må økes

---

## Refleksjonsspørsmål

1. **IP-adressering:**
   - Hvorfor bruker vi private IP-adresser (`10.x.x.x`) i VNet?
   - Hva er forskjellen på private og public IP-adresser i Azure?

2. **Network Design:**
   - Hvorfor valgte vi `/16` for VNet i stedet for `/24`?
   - Hva er fordelen med å ha et stort adresseområde selv om vi ikke bruker alle adressene?

3. **Hybrid Cloud:**
   - Hvordan skiller Azure VNet seg fra et tradisjonelt on-premises VLAN?
   - Hvilke fordeler gir et cloud-basert VNet sammenlignet med fysisk nettverksutstyr?

4. **Resource Organization:**
   - Hvorfor opprettet vi en separat Resource Group for network-ressurser?
   - Hva er fordelen med tags på Azure-ressurser?

5. **Sikkerhet:**
   - Er ressurser i et VNet automatisk isolert fra internett?
   - Hva må til for at en VM i dette VNet skal kunne nås fra internett?

---

## Neste Steg

Nå som du har opprettet et Virtual Network, er neste steg å:

1. **Opprette Subnets** - Dele VNet inn i logiske segmenter
2. **Konfigurere Network Security Groups** - Definere firewallregler
3. **Deploye en Virtual Machine** - Plassere VM i VNet
4. **Test connectivity** - Verifisere nettverkskommunikasjon

**Gratulerer!** Du har nå et Azure Virtual Network som danner grunnlaget for din Azure-infrastruktur! 🎉

---

## Ressurser

- [Azure Virtual Network Documentation](https://learn.microsoft.com/en-us/azure/virtual-network/)
- [Plan Virtual Networks](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-vnet-plan-design-arm)
- [IP Addressing in Azure](https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/public-ip-addresses)