# Oppgave: N-Tier Network Segmentation i Microsoft Azure

## Case: InfraIT.sec sin Cloud Migration

InfraIT.sec planlegger å migrere deler av sin infrastruktur til Microsoft Azure. Som del av migrasjonsprosjektet har du blitt tildelt oppgaven med å designe og implementere nettverksinfrastrukturen i Azure som skal være grunnlaget for fremtidige deployments.

Organisasjonen har strenge sikkerhetskrav basert på **Zero Trust**-prinsipper og **Defense in Depth**. Spesielt viktig er det at frontend-webservere IKKE skal kunne kommunisere direkte med database-tier - all kommunikasjon må gå via application-tier (backend) som fungerer som et kontrollert mellomledd.

---

## Din Rolle

Du er **Cloud Infrastructure Engineer** hos InfraIT.sec og rapporterer til **Infrastructure Manager**. Din oppgave er å sette opp det initiale nettverket i Azure med riktig segmentering og sikkerhetskontroller.

---

## Tekniske Krav

### 1. Virtual Network

Opprett et Virtual Network (VNet) i Azure med følgende spesifikasjoner:

**VNet-konfigurasjon:**
- **Navn:** `<prefix>-vnet-infraitsec`
- **Adresseområde:** `10.0.0.0/16`
- **Region:** North Europe
- **Resource Group:** `<prefix>-rg-infraitsec-network`

### 2. Subnets (N-Tier Design)

Implementer en 3-tier nettverksarkitektur med følgende subnets:

| Tier | Subnet Name | Address Range | Formål |
|------|-------------|---------------|---------|
| Frontend | `subnet-frontend` | `10.0.1.0/24` | Web servers, load balancers |
| Backend | `subnet-backend` | `10.0.2.0/24` | Application servers, business logic |
| Data | `subnet-data` | `10.0.3.0/24` | Database servers, data storage |

### 3. Network Security Groups (NSG)

Opprett separate NSGs for hvert subnet og implementer følgende sikkerhetspolicy:

**NSG-navngiving:**
- Frontend NSG: `<prefix>-nsg-frontend`
- Backend NSG: `<prefix>-nsg-backend`
- Data NSG: `<prefix>-nsg-data`

**Kommunikasjonsregler (KRITISK):**
```
✅ TILLATT:
   Frontend  →  Backend  (HTTPS, port 443)
   Backend   →  Data     (Database, port 3306 eller 5432)

❌ BLOKKERT:
   Frontend  →  Data     (direkte tilgang IKKE tillatt)
   Data      →  Frontend (ingen back-channel)
```

**Krav til regler:**
- Eksplisitte Allow-regler for tillatt kommunikasjon
- Eksplisitte Deny-regler for blokkert kommunikasjon
- Logiske prioriteringer (lavere nummer = høyere prioritet)
- Beskrivende navn og descriptions på alle custom rules

### 4. Test-VMs

For å verifisere nettverkskonfigurasjonen, skal du deploye test-VMs:

**Minimum krav:**
- 1 VM i frontend subnet
- 1 VM i backend subnet  
- 1 VM i data subnet

**VM-spesifikasjoner:**
- **OS:** Ubuntu Server 24.04 LTS eller lignende
- **Størrelse:** Standard_B1s (tilstrekkelig for testing)
- **Resource Group:** `<prefix>-rg-infraitsec-compute`
- **Navngiving:** `<prefix>-vm-frontend`, `<prefix>-vm-backend`, `<prefix>-vm-data`

---

## Testing og Verifisering

### Obligatoriske Tester

Du skal dokumentere følgende tester ved hjelp av **Azure Network Watcher** verktøy:

#### Test 1: IP Flow Verify

Utfør IP flow verify for å bekrefte at:

**Test A: Frontend → Backend (Skal Tillates)**
- Source: Frontend VM
- Destination: Backend VM private IP
- Port: 443 (HTTPS)
- **Forventet:** Access = Allowed

**Test B: Frontend → Data (Skal Blokkeres)**
- Source: Frontend VM
- Destination: Data VM private IP
- Port: 3306 eller 5432
- **Forventet:** Access = Denied

**Test C: Backend → Data (Skal Tillates)**
- Source: Backend VM
- Destination: Data VM private IP
- Port: 3306 eller 5432
- **Forventet:** Access = Allowed

#### Test 2: NSG Diagnostics

Kjør NSG diagnostics for Test B (Frontend → Data) og dokumenter:
- Hvilke NSG-regler som evalueres
- Hvilken regel som blokkerer trafikken
- Full evaluation path

#### Test 3: Praktisk Connectivity Test (Valgfritt, men anbefalt)

Utfør praktisk testing med `ping` eller `nc` (netcat) mellom VMs for å verifisere at blokkering faktisk fungerer i praksis.

---

## Leveranse

Du skal vise frem til læringsassistent at trafikk tillates og blokkeres som forventet.

## Etter presentert for læringsassistent:

Slå av og slett alle virtuelle maskiner (om en har alle VM-ene i en egen Resource Group, kan en slette hele denne Resource Group-en) som ble opprettet i forbindelse med testing av VNET og subnet. Dere trenger IKKE å slette VNET, subnet og NSG-er.
