# Network Segmentation og Testing med Network Watcher

## Oversikt

I denne øvelsen skal du implementere et n-tier nettverk med kontrollert kommunikasjon mellom subnets. Du lærer å bruke Network Security Groups (NSG) for å implementere mikrosegmentering, og Network Watcher for å diagnostisere nettverkstrafikk.

**Hva er Mikrosegmentering?**

Mikrosegmentering handler om å dele nettverket i små isolerte segmenter hvor kommunikasjon mellom segmenter kontrolleres strengt. Dette reduserer "blast radius" ved sikkerhetsbrudd - hvis en frontend-server kompromitteres, kan angriperen ikke automatisk hoppe til database-tier.

**Kommunikasjonsmodell vi Implementerer:**
```
┌─────────────────┐
│  Frontend       │
│  (10.0.1.0/24)  │
└────────┬────────┘
         │ ✅ Tillatt
         ▼
┌─────────────────┐
│  Backend        │
│  (10.0.2.0/24)  │
└────────┬────────┘
         │ ✅ Tillatt
         ▼
┌─────────────────┐
│  Data           │
│  (10.0.3.0/24)  │
└─────────────────┘

Frontend → Data: ❌ BLOKKERT
```

**Læringsmål:**
- Implementere n-tier network segmentation med NSG
- Bruke Network Watcher diagnostic tools
- Teste og verifisere nettverkskommunikasjon
- Forstå IP flow verify, NSG diagnostics, og Next hop
- Troubleshoot nettverksproblemer systematisk

**Estimert tid:** 45-60 minutter

---

## Forutsetninger

- [ ] Ferdigstilt VNet og subnets (tre subnets: frontend, backend, data)
- [ ] Grunnleggende kjennskap til Linux VM deployment
- [ ] SSH-klient installert
- [ ] Forståelse av NSG-konsepter

---

## Del 1: Forberedelse - Deploy Test VMs

### Steg 1.1: Oversikt over Nødvendige VMs

For denne øvelsen trenger du **3 Linux VMs** (Ubuntu Server):

| VM Name | Subnet | Private IP | Formål |
|---------|--------|------------|--------|
| `<prefix>-vm-frontend` | subnet-frontend | 10.0.1.x | Simulerer web server |
| `<prefix>-vm-backend` | subnet-backend | 10.0.2.x | Simulerer app server |
| `<prefix>-vm-data` | subnet-data | 10.0.3.x | Simulerer database |

**Hvorfor Linux?**
- Lettere å teste med (curl, ping, nc)
- Billigere enn Windows (B1s tilstrekkelig)
- Mindre ressurskrav

### Steg 1.2: Deploy VMs (Hurtigguide)

**Du har allerede lært å deploye Linux VMs, så her er en rask oppsummering:**

**Opprett 3 VM-er i hvert sitt subnet:**

1. **Virtual machines** → **Create**

2. **Basics:**
   - **Name:** `<prefix>-vm-frontend`, `<prefix>-vm-backend`, `<prefix>-vm-data`
   - **Image:** Ubuntu Server 24.04 LTS
   - **Size:** Standard_B1s (1 vCPU, 1GB RAM)
   - **Authentication:** Password
   - **Username:** `azureuser`
   - **Password:** Velg sterkt passord (samme for alle 3 for enkelhet)
   - **Inbound ports:** None (vi konfigurerer NSG senere)

3. **Disks:**
   - **OS disk:** Standard SSD, 30 GiB
   - ☑ Delete with VM

4. **Networking:**
   - **VNet:** `<prefix>-vnet-infraitsec`
   - **Subnet:** 
     - VM 1: `subnet-frontend`
     - VM 2: `subnet-backend`
     - VM 3: `subnet-data`
   - **Public IP:** 
     - Frontend: Ja (for SSH management)
     - Backend: Ja (for SSH management)
     - Data: Ja (for SSH management)
   - **NIC NSG:** None
   - ☑ Delete NIC when VM is deleted

5. **Management:**
   - ☑ System assigned managed identity
   - ☑ Boot diagnostics
   - ☑ Auto-shutdown: 19:00

6. **Tags:**
   - Tier: Frontend/Backend/Data (tilpass per VM)

7. **Create**

**Deployment tid:** ~5 min per VM

### Steg 1.3: Verifiser VMs

**Når alle 3 VMs er deployed:**

1. **Virtual machines** → Se alle 3 VMs med status "Running"

2. **Noter private IP-adresser:**
```
Frontend VM: 10.0.1.4 (eksempel)
Backend VM:  10.0.2.4 (eksempel)
Data VM:     10.0.3.4 (eksempel)
```

**VIKTIG:** Noter faktiske IP-adresser - de kan være forskjellige!

### Steg 1.4: Test SSH til Alle VMs

**SSH til frontend VM:**
```bash
ssh azureuser@<frontend-public-ip>
```

**I frontend VM - test at VM fungerer:**
```bash
# Sjekk hostname
hostname
# Output: <prefix>-vm-frontend

# Sjekk IP
ip addr show eth0 | grep "inet "
# Output: inet 10.0.1.4/24 ...

# Test internett
ping -c 3 google.com
# Skal fungere

# Exit
exit
```

**Gjenta for backend og data VMs** for å bekrefte at alle er oppe.

---

## Del 2: Forstå Default Kommunikasjon

### Steg 2.1: Test Default Behavior (Før NSG-endringer)

**Som default kan alle subnets kommunisere fritt i VNet.**

**SSH til frontend VM:**
```bash
ssh azureuser@<frontend-public-ip>
```

**Test ping til backend:**
```bash
ping -c 4 10.0.2.4  # Erstatt med faktisk backend private IP
```

**Output:**
```
64 bytes from 10.0.2.4: icmp_seq=1 ttl=64 time=0.8 ms
64 bytes from 10.0.2.4: icmp_seq=2 ttl=64 time=0.9 ms
...
--- 10.0.2.4 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss
```

**Test ping til data tier:**
```bash
ping -c 4 10.0.3.4  # Erstatt med faktisk data private IP
```

**Skal også fungere!**

**Hvorfor?**

Default NSG-regel **AllowVNetInBound** (prioritet 65000) tillater all trafikk innenfor VNet.

**Vårt mål:** Endre dette slik at frontend IKKE kan nå data tier direkte.

---

## Del 3: Implementer Network Segmentation med NSG

### Steg 3.1: Planlegg NSG-strategi

**Vi skal opprette 3 NSGs (én per subnet):**

| NSG Name | Attached to | Formål |
|----------|-------------|--------|
| `<prefix>-nsg-frontend` | subnet-frontend | Kontrollerer trafikk til/fra frontend |
| `<prefix>-nsg-backend` | subnet-backend | Kontrollerer trafikk til/fra backend |
| `<prefix>-nsg-data` | subnet-data | Kontrollerer trafikk til/fra data |

**Kommunikasjonsregler:**

**Frontend NSG (Inbound):**
- Tillat SSH fra internett (for management)
- Tillat HTTP/HTTPS fra internett (web traffic)

**Frontend NSG (Outbound):**
- Tillat til Backend subnet
- **Blokker til Data subnet**

**Backend NSG (Inbound):**
- Tillat fra Frontend subnet
- Tillat SSH fra internett (for management)

**Backend NSG (Outbound):**
- Tillat til Data subnet

**Data NSG (Inbound):**
- Tillat kun fra Backend subnet
- Tillat SSH fra internett (for management)

**Data NSG (Outbound):**
- Default (tillat utgående)

### Steg 3.2: Opprett NSG for Data Tier

**Vi starter med Data tier (mest restriktiv):**

1. **Network security groups** → **Create**

2. **Konfigurer:**
   - **Name:** `<prefix>-nsg-data`
   - **Resource group:** `<prefix>-rg-infraitsec-network`
   - **Region:** North Europe

3. **Create**

**Legg til Inbound Rules:**

**Rule 1: Allow SSH for Management**

- **Source:** IP Addresses
- **Source IP:** `<din-IP>/32`
- **Destination:** Any
- **Service:** SSH (port 22)
- **Action:** Allow
- **Priority:** 100
- **Name:** `Allow-SSH-Management`

**Rule 2: Allow from Backend Subnet**

- **Source:** IP Addresses
- **Source IP addresses:** `10.0.2.0/24` (backend subnet)
- **Destination:** Any
- **Service:** Custom
- **Destination ports:** `3306,5432` (MySQL, PostgreSQL - eksempel)
- **Protocol:** TCP
- **Action:** Allow
- **Priority:** 110
- **Name:** `Allow-From-Backend`
- **Description:** `Allow database access from backend tier only`

**Rule 3: Deny from Frontend (Explicit)**

- **Source:** IP Addresses
- **Source IP addresses:** `10.0.1.0/24` (frontend subnet)
- **Destination:** Any
- **Service:** Custom
- **Destination ports:** `*`
- **Protocol:** Any
- **Action:** Deny
- **Priority:** 120
- **Name:** `Deny-From-Frontend`
- **Description:** `Explicitly deny direct access from frontend tier`

**Knytt til Subnet:**

1. NSG → **Subnets** → **Associate**
2. **VNet:** `<prefix>-vnet-infraitsec`
3. **Subnet:** `subnet-data`
4. **OK**

### Steg 3.3: Opprett NSG for Backend Tier

1. **Create** ny NSG: `<prefix>-nsg-backend`

**Inbound Rules:**

**Rule 1: Allow SSH**
- **Source:** IP Addresses
- **Source IP:** `<din-IP>/32`
- **Service:** SSH
- **Priority:** 100
- **Name:** `Allow-SSH-Management`

**Rule 2: Allow from Frontend**
- **Source:** IP Addresses
- **Source IP:** `10.0.1.0/24`
- **Destination:** Any
- **Service:** Custom
- **Ports:** `443,8080` (HTTPS, API - eksempel)
- **Protocol:** TCP
- **Action:** Allow
- **Priority:** 110
- **Name:** `Allow-From-Frontend`

**Outbound Rules:**

**Rule 1: Allow to Data Tier**
- **Source:** Any
- **Destination:** IP Addresses
- **Destination IP:** `10.0.3.0/24`
- **Service:** Custom
- **Ports:** `3306,5432`
- **Action:** Allow
- **Priority:** 100
- **Name:** `Allow-To-Data`

**Knytt til Subnet:** `subnet-backend`

### Steg 3.4: Opprett NSG for Frontend Tier

1. **Create** ny NSG: `<prefix>-nsg-frontend`

**Inbound Rules:**

**Rule 1: Allow SSH**
- **Source:** IP Addresses
- **Source IP:** `<din-IP>/32`
- **Service:** SSH
- **Priority:** 100
- **Name:** `Allow-SSH-Management`

**Rule 2: Allow HTTP/HTTPS from Internet**
- **Source:** Any
- **Service:** HTTP
- **Priority:** 110
- **Name:** `Allow-HTTP-Internet`

**Rule 3: Allow HTTPS**
- **Source:** Any
- **Service:** HTTPS
- **Priority:** 120
- **Name:** `Allow-HTTPS-Internet`

**Outbound Rules:**

**Rule 1: Allow to Backend**
- **Source:** Any
- **Destination:** IP Addresses
- **Destination IP:** `10.0.2.0/24`
- **Service:** HTTPS
- **Action:** Allow
- **Priority:** 100
- **Name:** `Allow-To-Backend`

**Rule 2: Deny to Data (Explicit)**
- **Source:** Any
- **Destination:** IP Addresses
- **Destination IP:** `10.0.3.0/24`
- **Service:** Any
- **Action:** Deny
- **Priority:** 110
- **Name:** `Deny-To-Data`
- **Description:** `Frontend must not directly access data tier`

**Knytt til Subnet:** `subnet-frontend`

---

## Del 4: Introduksjon til Network Watcher

### Steg 4.1: Hva er Network Watcher?

Network Watcher er et sett med network monitoring og diagnostic tools i Azure. Tenk på det som "network troubleshooting toolkit" i skyen.

**Hovedfunksjoner:**

**Monitoring:**
- Topology visualization
- Connection monitor
- Network performance monitor

**Diagnostic Tools:**
- IP flow verify (tester om pakke vil tillates/blokkeres)
- NSG diagnostics (analyserer NSG-regler)
- Next hop (viser routing path)
- VPN troubleshoot
- Packet capture

**Logging:**
- NSG flow logs
- Traffic analytics

**For denne øvelsen:** Vi fokuserer på de 3 diagnostic tools.

### Steg 4.2: Enable Network Watcher

Network Watcher må være enabled for din region.

1. Azure Portal → Søk **"Network Watcher"**

2. Venstre meny → **"Overview"**

3. **Sjekk at Network Watcher er enabled for North Europe:**
   - Skal vise: "North Europe - Enabled"

**Hvis ikke enabled:**

1. Expand **"North Europe"** region

2. Klikk **"Enable Network Watcher"**

**Network Watcher er nå klar!** ✅

---

## Del 5: IP Flow Verify - Test Trafikk-flow

### Steg 5.1: Hva er IP Flow Verify?

IP flow verify tester om en spesifikk nettverkspakke vil tillates eller blokkeres basert på NSG-regler. Du spesifiserer:
- Source VM
- Destination IP
- Port og protokoll
- Direction (inbound/outbound)

Azure sjekker alle relevante NSG-regler og forteller deg resultatet.

### Steg 5.2: Test Frontend → Backend (Skal Fungere)

1. **Network Watcher** → **IP flow verify** (under Network diagnostic tools)

2. **Konfigurer test:**
   - **Subscription:** Din subscription
   - **Resource group:** `<prefix>-rg-infraitsec-compute`
   - **Virtual machine:** `<prefix>-vm-frontend`
   - **Network interface:** Auto-selected
   - **Protocol:** TCP
   - **Direction:** Outbound
   - **Local IP address:** (auto-fylles - frontend VM IP)
   - **Local port:** 50000 (source port - tilfeldig høy port)
   - **Remote IP address:** `10.0.2.4` (backend VM private IP)
   - **Remote port:** 443 (HTTPS til backend)

3. Klikk **"Check"**

**Forventet resultat:**
```
Access: Allowed
Rule name: Allow-To-Backend
NSG name: <prefix>-nsg-frontend
Direction: Outbound
```

**Tolkning:** Trafikk fra frontend til backend på port 443 er TILLATT av vår NSG-regel! ✅

### Steg 5.3: Test Frontend → Data (Skal Blokkeres)

1. **Samme oppsett, men endre:**
   - **Remote IP address:** `10.0.3.4` (data VM private IP)
   - **Remote port:** 3306 (MySQL port)

2. **Check**

**Forventet resultat:**
```
Access: Denied
Rule name: Deny-To-Data
NSG name: <prefix>-nsg-frontend
Direction: Outbound
```

**Tolkning:** Frontend kan IKKE nå data tier direkte! Segmenteringen fungerer! ✅

### Steg 5.4: Test Backend → Data (Skal Fungere)

1. **Konfigurer:**
   - **VM:** `<prefix>-vm-backend`
   - **Direction:** Outbound
   - **Remote IP:** `10.0.3.4` (data VM)
   - **Remote port:** 3306

2. **Check**

**Forventet resultat:**
```
Access: Allowed
Rule name: Allow-To-Data
NSG name: <prefix>-nsg-backend
```

**Backend kan nå data tier!** ✅

### Steg 5.5: Test Inbound til Data fra Frontend (Double Check)

1. **Konfigurer:**
   - **VM:** `<prefix>-vm-data`
   - **Direction:** Inbound
   - **Protocol:** TCP
   - **Local port:** 3306
   - **Remote IP:** `10.0.1.4` (frontend VM)
   - **Remote port:** 50000

2. **Check**

**Forventet resultat:**
```
Access: Denied
Rule name: Deny-From-Frontend
NSG name: <prefix>-nsg-data
Direction: Inbound
```

**Data tier blokkerer frontend! Segmentering bekreftet fra begge retninger!** ✅

---

## Del 6: NSG Diagnostics - Analysere NSG Rules

### Steg 6.1: Hva er NSG Diagnostics?

NSG diagnostics gir en omfattende analyse av alle NSG-regler som påvirker kommunikasjon mellom to endpoints. Det viser:
- Alle gjeldende NSG-regler
- Hvilke regler som matcher
- Hvorfor trafikk tillates/blokkeres
- Full evaluering path

**Forskjell fra IP flow verify:**
- IP flow verify: Rask "vil denne pakken slippes gjennom?"
- NSG diagnostics: Detaljert "hvorfor/hvorfor ikke, og hvilke regler evalueres?"

### Steg 6.2: Diagnostiser Frontend → Data

1. **Network Watcher** → **NSG diagnostics**

2. **Konfigurer:**
   - **Source type:** Virtual machine
   - **Virtual machine:** `<prefix>-vm-frontend`
   - **Destination type:** IP address
   - **Destination IP address:** `10.0.3.4` (data VM)
   - **Traffic direction:** Outbound
   - **Protocol:** TCP
   - **Destination port:** 3306

3. **Check**

**Resultat viser detaljert analyse:**
```
Traffic status: Blocked

NSG rules evaluated:
┌─────────────────────────────────────────────────┐
│ Outbound Rules - nsg-frontend (on subnet)       │
├─────────────────────────────────────────────────┤
│ Priority 100: Allow-To-Backend                  │
│   Source: Any                                   │
│   Destination: 10.0.2.0/24                      │
│   Result: No match (destination is 10.0.3.4)    │
├─────────────────────────────────────────────────┤
│ Priority 110: Deny-To-Data                      │
│   Source: Any                                   │
│   Destination: 10.0.3.0/24                      │
│   Result: MATCH - DENY                          │
│   ⚠️ Traffic blocked by this rule               │
└─────────────────────────────────────────────────┘

Effective rule: Deny-To-Data (Priority 110)
Action: Deny
```

**Tolkning:**
- Regel med prioritet 100 matches ikke (feil destination subnet)
- Regel med prioritet 110 matcher og blokkerer trafikk
- Clear explanation av hvorfor trafikk blokkeres

### Steg 6.3: Diagnostiser Backend → Data

1. **NSG diagnostics** med:
   - **Source VM:** `<prefix>-vm-backend`
   - **Destination IP:** `10.0.3.4`
   - **Port:** 3306

**Resultat:**
```
Traffic status: Allowed

NSG rules evaluated:

Outbound (Backend NSG):
  Priority 100: Allow-To-Data → MATCH - ALLOW ✅

Inbound (Data NSG):
  Priority 110: Allow-From-Backend → MATCH - ALLOW ✅

Effective action: Allow
```

**Tolkning:** Trafikk tillates av BÅDE source (backend) outbound NSG OG destination (data) inbound NSG!

---

## Del 7: Next Hop - Forstå Routing

### Steg 7.1: Hva er Next Hop?

Next hop viser hvor en pakke sendes videre i nettverket. I Azure betyr dette:
- VirtualNetwork: Pakke rutes internt i VNet
- Internet: Pakke sendes ut til internett
- VirtualAppliance: Pakke sendes via firewall/NVA
- None: Pakke droppes (ingen route)

**Nyttig for:**
- Forstå routing paths
- Troubleshoot connectivity issues
- Verifisere custom routes

### Steg 7.2: Test Next Hop - Intra-VNet

1. **Network Watcher** → **Next hop**

2. **Konfigurer:**
   - **Resource group:** `<prefix>-rg-infraitsec-compute`
   - **Virtual machine:** `<prefix>-vm-frontend`
   - **Network interface:** Auto
   - **Source IP address:** (auto - frontend VM IP)
   - **Destination IP address:** `10.0.2.4` (backend VM)

3. **Next hop**

**Resultat:**
```
Next hop type: VirtualNetwork
Next hop IP address: 10.0.2.4
Route table ID: System Route
```

**Tolkning:**
- Pakke rutes direkte innenfor VNet (ingen gateway/router i mellom)
- "System Route" betyr Azure sin automatiske routing
- Lav latency, høy throughput (intern Azure backbone)

### Steg 7.3: Test Next Hop - Til Internett

1. **Samme oppsett, men:**
   - **Destination IP:** `8.8.8.8` (Google DNS)

**Resultat:**
```
Next hop type: Internet
Route table ID: System Route
```

**Tolkning:**
- Pakke sendes ut til internett via Azure edge router
- Default route: 0.0.0.0/0 → Internet

### Steg 7.4: Forstå Route Tables

**Azure har automatiske system routes:**

| Destination | Next Hop | Beskrivelse |
|-------------|----------|-------------|
| 10.0.0.0/16 | VirtualNetwork | Alle VNet-interne adresser |
| 0.0.0.0/0 | Internet | Default route til internett |
| 168.63.129.16/32 | VirtualNetwork | Azure metadata service |

**Custom route tables** kan legges til for:
- Force tunneling (all internett-trafikk via on-prem)
- Network Virtual Appliances (firewall)
- VPN/ExpressRoute routing

**For vår lab:** System routes er tilstrekkelige.

---

## Del 8: Praktisk Testing med Ping og Netcat

### Steg 8.1: Tillat ICMP (Ping) i NSG

**Default:** ICMP er blokkert i NSG.

**Legg til ICMP-regler i hver NSG:**

**Eksempel - Frontend NSG Inbound:**

1. `<prefix>-nsg-frontend` → **Inbound rules** → **Add**

2. **Konfigurer:**
   - **Source:** IP Addresses
   - **Source IP:** `10.0.2.0/24,10.0.3.0/24` (backend og data subnets)
   - **Protocol:** ICMP
   - **Action:** Allow
   - **Priority:** 200
   - **Name:** `Allow-ICMP-From-VNet`

**Gjenta for alle 3 NSGs** (både inbound og outbound).

**Eller enklere:** Opprett regel med source/destination = **VirtualNetwork** (service tag).

### Steg 8.2: Test Ping - Frontend til Backend

**SSH til frontend VM:**
```bash
ssh azureuser@<frontend-public-ip>
```

**Ping backend:**
```bash
ping -c 4 10.0.2.4
```

**Forventet resultat:**
```
PING 10.0.2.4 (10.0.2.4) 56(84) bytes of data.
64 bytes from 10.0.2.4: icmp_seq=1 ttl=64 time=1.2 ms
64 bytes from 10.0.2.4: icmp_seq=2 ttl=64 time=0.8 ms
...
--- 10.0.2.4 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss
```

**Frontend → Backend: FUNGERER!** ✅

### Steg 8.3: Test Ping - Frontend til Data
```bash
ping -c 4 10.0.3.4
```

**Forventet resultat:**
```
PING 10.0.3.4 (10.0.3.4) 56(84) bytes of data.

--- 10.0.3.4 ping statistics ---
4 packets transmitted, 0 received, 100% packet loss, time 3056ms
```

**Ingen svar! Frontend → Data: BLOKKERT!** ❌ (Som forventet!)

**Dette bekrefter at NSG-reglene fungerer!**

### Steg 8.4: Test Port Connectivity med Netcat

**Netcat (nc)** kan teste om spesifikke TCP-porter er åpne.

**SSH til backend VM:**
```bash
ssh azureuser@<backend-public-ip>
```

**Start en enkel lytter på port 8080:**
```bash
nc -l 8080
```

**I en ANNEN terminal - SSH til frontend VM:**
```bash
ssh azureuser@<frontend-public-ip>
```

**Test connection til backend port 8080:**
```bash
nc -zv 10.0.2.4 8080
```

**Hvis NSG tillater (som vår regel for port 8080):**
```
Connection to 10.0.2.4 8080 port [tcp/*] succeeded!
```

**Test til data tier (skal feile):**
```bash
nc -zv 10.0.3.4 3306
```

**Output:**
```
nc: connect to 10.0.3.4 port 3306 (tcp) failed: Connection timed out
```

**Blokkert som forventet!** ✅

### Steg 8.5: Test Faktisk Dataflyt (Valgfritt)

**Advanced test - send data gjennom tiers:**

**På data VM - start listener:**
```bash
echo "DATABASE RESPONSE" | nc -l 3306
```

**På backend VM - koble til og les:**
```bash
nc 10.0.3.4 3306
# Output: DATABASE RESPONSE
```

**På frontend VM - prøv samme:**
```bash
nc 10.0.3.4 3306
# Henger (timeout) - connection blokkert
```

**Dette demonstrerer praktisk segmentering!**

---

## Del 9: Topology Visualization

### Steg 9.1: Se Nettverkstopologi

1. **Network Watcher** → **Topology**

2. **Select:**
   - **Resource group:** `<prefix>-rg-infraitsec-network`

3. **Topology viser:**
```
                    Internet
                       │
          ┌────────────┼────────────┐
          │            │            │
    ┌─────▼─────┐ ┌────▼────┐ ┌────▼────┐
    │ Frontend  │ │ Backend │ │  Data   │
    │   NSG     │ │   NSG   │ │   NSG   │
    └─────┬─────┘ └────┬────┘ └────┬────┘
          │            │            │
    ┌─────▼─────┐ ┌────▼────┐ ┌────▼────┐
    │  subnet-  │ │ subnet- │ │ subnet- │
    │  frontend │ │ backend │ │  data   │
    └─────┬─────┘ └────┬────┘ └────┬────┘
          │            │            │
       ┌──▼──┐      ┌──▼──┐      ┌──▼──┐
       │ VM  │      │ VM  │      │ VM  │
       └─────┘      └─────┘      └─────┘
```

**Klikk på NSG-ikoner** for å se tilknyttede regler direkt i topology view!

---

## Del 10: Feilsøking

### Problem: "Ping fungerer ikke selv med ICMP-regel"

**Sjekk:**

1. **NSG har ICMP Allow-regel?**
   - Både inbound OG outbound NSG må tillate

2. **Linux VM firewall?**
```bash
   sudo ufw status
   # Skal vise: inactive (Ubuntu default)
```

3. **ICMP i effective security rules?**
   - VM → Networking → Effective rules

**Løsning:**
- Legg til ICMP-regel med source = VirtualNetwork, destination = VirtualNetwork

---

### Problem: "IP flow verify sier Allow, men ping feiler fortsatt"

**Mulige årsaker:**

1. **OS-level firewall:**
   - NSG er network-layer, men OS kan også blokkere
   - Sjekk `ufw` (Ubuntu) eller `iptables`

2. **Application ikke lytter:**
   - NSG kan tillate port 8080, men ingen app lytter der
   - Sjekk: `sudo netstat -tulpn | grep 8080`

3. **Wrong protocol:**
   - IP flow verify testet TCP, men du pinger (ICMP)
   - Test med riktig protokoll

---

### Problem: "NSG diagnostics viser 'Allowed' men connection feiler"

**Sjekk:**

1. **Routing:**
   - Next hop tool - er pakken rutet riktig?

2. **Application-level block:**
   - VM kan nås, men applikasjon kan ha egen ACL
   - Database kan kreve authentication

3. **Timeout:**
   - Connection kan være tillatt, men VM svarer ikke (crash, high load)

---

## Refleksjonsspørsmål

1. **Mikrosegmentering:**
   - Hvorfor er det viktig at frontend ikke kan nå data tier direkte?
   - Hvilke angrepsscenarier forhindrer denne segmenteringen?

2. **Defense in Depth:**
   - Vi har NSG både på subnet og kunne ha på NIC - hva er fordelen?
   - Hvordan kompletterer NSG andre sikkerhetstiltak (firewalls, WAF, osv.)?

3. **Troubleshooting Strategy:**
   - Hvis ping feiler - hvilken rekkefølge sjekker du ting?
   - Hvordan bruker du IP flow verify vs. NSG diagnostics vs. Next hop?

4. **Network Design:**
   - Kunne vi implementert samme segmentering uten separate subnets?
   - Hva er forskjellen på network segmentation og application-level access control?

5. **Real-world Application:**
   - Hvordan ville denne n-tier design se ut i produksjon?
   - Hvilke andre tiers/subnets ville du lagt til? (DMZ, management, osv.)

---

## Oppsummering

**Du har nå lært:**

✅ **Network Segmentation:**
- Implementere n-tier nettverk med NSG
- Kontrollere trafikk mellom subnets
- Implementere least-privilege network access

✅ **Network Watcher Tools:**
- IP flow verify - rask testing av NSG-regler
- NSG diagnostics - detaljert regel-analyse
- Next hop - routing troubleshooting

✅ **Practical Testing:**
- Ping testing mellom subnets
- Port connectivity testing med netcat
- Topology visualization

✅ **Troubleshooting:**
- Systematisk feilsøking av network issues
- Forstå forskjell på NSG, OS firewall, og application ACL

**Network Security Posture:**
```
Before: Flat network - any VM can reach any VM
After:  Segmented network - controlled communication paths
        Frontend → Backend ✅
        Backend → Data ✅
        Frontend → Data ❌ (blocked!)
```

**Dette er produksjonsklare sikkerhetsprinsipper!** 🔒

---

## Neste Steg

Behold denne infrastrukturen - den vil brukes i fremtidige øvelser:

1. **NSG Rule Management** - Modifisere og optimalisere regler
2. **Resource Cleanup** - Sikker sletting
3. **Azure Blob Storage** - Backup integration
4. **Advanced Scenarios** - Application Gateway, Load Balancer

**VIKTIG:** Ikke slett VMs/NSGs ennå - vi bruker dem videre!

**Husk å stoppe (deallocate) VMs når du ikke jobber** for å spare kostnader!

---

## Ressurser

- [Network Watcher Documentation](https://learn.microsoft.com/en-us/azure/network-watcher/)
- [IP Flow Verify](https://learn.microsoft.com/en-us/azure/network-watcher/network-watcher-ip-flow-verify-overview)
- [NSG Diagnostics](https://learn.microsoft.com/en-us/azure/network-watcher/network-watcher-network-configuration-diagnostics-overview)
- [Next Hop](https://learn.microsoft.com/en-us/azure/network-watcher/network-watcher-next-hop-overview)
- [Network Security Best Practices](https://learn.microsoft.com/en-us/azure/security/fundamentals/network-best-practices)
- [Microsegmentation in Azure](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/dmz/secure-vnet-dmz)