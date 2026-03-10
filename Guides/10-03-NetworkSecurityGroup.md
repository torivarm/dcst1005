# Network Security Groups - Nettverkssikkerhet i Azure

## Oversikt

I denne øvelsen skal du opprette en Network Security Group (NSG) og knytte den til et subnet. NSG fungerer som en virtuell firewall som kontrollerer inn- og utgående nettverkstrafikk basert på regler du definerer.

**Hva er en Network Security Group?**

En NSG er en samling av sikkerhetsregler som tillater eller blokkerer nettverkstrafikk til og fra Azure-ressurser. Tenk på det som en stateful firewall som inspiserer hver nettverkspakke og avgjør om den skal slippes gjennom eller droppes basert på dine regler.

**Læringsmål:**
- Forstå NSG-konseptet og hvordan det implementeres
- Opprette NSG med sikkerhetsregler
- Knytte NSG til subnet
- Forstå default security rules og prioritering
- Konfigurere inbound og outbound rules

**Estimert tid:** 25 minutter

---

## Forutsetninger

- [ ] Ferdigstilt forrige øvelser (VNet og subnets opprettet)
- [ ] VNet: `<prefix>-vnet-infraitsec` med subnets
- [ ] Grunnleggende forståelse av TCP/IP og porter

---

## Del 1: Forstå Network Security Groups

### NSG vs. Tradisjonelle Firewalls

**Tradisjonell on-premises firewall:**
- Fysisk eller virtuell appliance
- Plassert på nettverksgrensen
- Må konfigureres og vedlikeholdes av deg
- Kostbar hardware/lisenser

**Azure NSG:**
- Software-defined security
- Distribuert på hver nettverksressurs
- Managed av Azure (ingen hardware)
- Gratis (ingen ekstra kostnad)
- Stateful (husker etablerte connections)

### Hvor Kan NSG Knyttes?

NSG kan knyttes på to nivåer:

**1. Subnet-nivå:**
- Påvirker ALLE ressurser i subnet
- Enklere å administrere (én regel gjelder for mange VMs)
- Anbefalt for generell nettverkssegmentering

**2. Network Interface (NIC) nivå:**
- Påvirker kun én spesifikk VM
- Finere kontroll per VM
- Nyttig for VMs med spesielle sikkerhetskrav

**Kan kombineres:** 
En VM kan ha både subnet-NSG og NIC-NSG. Begge sett med regler evalueres (mest restriktive vinner).

### Default Security Rules

Hver NSG kommer med innebygde default-regler som **ikke kan slettes** (men kan overstyres):

**Inbound default rules:**
1. **AllowVNetInBound** - Tillat all trafikk fra andre ressurser i samme VNet
2. **AllowAzureLoadBalancerInBound** - Tillat Azure Load Balancer health probes
3. **DenyAllInBound** - Blokker ALL annen inngående trafikk (fra internett)

**Outbound default rules:**
1. **AllowVNetOutBound** - Tillat til andre ressurser i VNet
2. **AllowInternetOutBound** - Tillat utgående trafikk til internett
3. **DenyAllOutBound** - Blokker alt annet

**Hva betyr dette?**

Som standard:
- ✅ Ressurser i VNet kan snakke sammen
- ✅ Ressurser kan nå ut til internett
- ❌ Internett kan IKKE nå inn til ressurser (blokkert)

### Rule Prioritering

NSG-regler evalueres basert på **prioritet** (lavere nummer = høyere prioritet):

- Prioritet: **100-4096** (du kan sette)
- Default rules har prioritet: **65000+** (lav prioritet)

**Eksempel:**
```
Priority 100: Allow HTTP (port 80) from Internet
Priority 200: Deny all from Internet
Priority 65000: (Default) Deny all inbound

Resultat: HTTP tillates (regel 100 vinner)
```

Første regel som matcher stopper evalueringen (no fall-through).

---

## Del 2: Opprett Network Security Group

### Steg 2.1: Naviger til NSG-opprettelse

1. Azure Portal → Søk **"Network security groups"**

2. Klikk **"Network security groups"** i resultatene

3. Klikk **"+ Create"**

### Steg 2.2: Basics Tab

**Project details:**
- **Subscription:** Velg din subscription
- **Resource group:** Velg `<prefix>-rg-infraitsec-network` (samme som VNet)

**Instance details:**
- **Name:** `<prefix>-nsg-frontend`
  - Eksempel: `eg06-nsg-frontend`
  - Navnekonvensjon: `<prefix>-nsg-<subnet-name>`
- **Region:** `North Europe` (VIKTIG: må matche VNet sin region!)

**Hvorfor samme region som VNet?**

NSG må være i samme region som ressursene den skal beskytte. Azure tillater ikke å knytte NSG fra en region til ressurser i en annen region.

Klikk **"Next: Tags >"**

### Steg 2.3: Tags

Legg til samme tags som tidligere:

| Name | Value |
|------|-------|
| `Owner` | `<dittbrukernavn>` |
| `Environment` | `Lab` |
| `Course` | `InfraIT-Cyber` |
| `Purpose` | `Network-Security` |

Klikk **"Review + create"**

### Steg 2.4: Create

1. Verifiser innstillinger

2. Klikk **"Create"**

3. Deployment tar ~10-15 sekunder

4. Klikk **"Go to resource"**

---

## Del 3: Utforsk Default Security Rules

### Steg 3.1: Se Inbound Rules

Du er nå på NSG-siden.

1. Venstre meny → **"Inbound security rules"**

**Du skal se 3 default rules:**

| Priority | Name | Port | Protocol | Source | Destination | Action |
|----------|------|------|----------|--------|-------------|--------|
| 65000 | AllowVNetInBound | Any | Any | VirtualNetwork | VirtualNetwork | Allow |
| 65001 | AllowAzureLoadBalancerInBound | Any | Any | AzureLoadBalancer | Any | Allow |
| 65500 | DenyAllInBound | Any | Any | Any | Any | Deny |

**Hva betyr kolonnene?**

- **Priority:** Lavere nummer = høyere prioritet
- **Name:** Beskrivende navn på regelen
- **Port:** Hvilken port (eller "Any" for alle)
- **Protocol:** TCP, UDP, ICMP, eller Any
- **Source:** Hvor trafikken kommer fra
- **Destination:** Hvor trafikken går til
- **Action:** Allow (tillat) eller Deny (blokker)

### Steg 3.2: Se Outbound Rules

1. Venstre meny → **"Outbound security rules"**

**Du skal se 3 default rules:**

| Priority | Name | Port | Protocol | Source | Destination | Action |
|----------|------|------|----------|--------|-------------|--------|
| 65000 | AllowVNetOutBound | Any | Any | VirtualNetwork | VirtualNetwork | Allow |
| 65001 | AllowInternetOutBound | Any | Any | Any | Internet | Allow |
| 65500 | DenyAllOutBound | Any | Any | Any | Any | Deny |

**Merk:** Outbound default-reglene er mye mer permissive. Som standard kan ressurser nå ut til internett fritt.

---

## Del 4: Opprett Custom Inbound Rule (Allow HTTP)

La oss legge til en regel som tillater HTTP-trafikk (port 80) fra internett.

### Steg 4.1: Legg til Inbound Rule

1. Fortsatt på NSG-siden → **"Inbound security rules"**

2. Klikk **"+ Add"** øverst

### Steg 4.2: Konfigurer Rule

**Source:**
- **Source:** `Any` (tillat fra alle IP-adresser)
  - Alternativt: "IP Addresses" hvis du vil begrense til spesifikke IPs
- **Source port ranges:** `*` (alle porter fra source)

**Destination:**
- **Destination:** `Any` (til alle ressurser i subnet)
- **Service:** `HTTP` (velg fra dropdown - setter automatisk port 80)
  - Alternativt: "Custom" og skriv port manuelt
- **Destination port ranges:** `80` (fylles automatisk når du velger HTTP)

**Action:**
- Velg **"Allow"**

**Priority:**
- **Priority:** `100`
- Lavt nummer = høy prioritet (evalueres først)

**Name:**
- **Name:** `Allow-HTTP-Inbound`
- Beskrivende navn som forklarer hva regelen gjør

**Description:**
- **Description:** `Allow HTTP traffic from internet to web servers`

**Klikk "Add"**

### Steg 4.3: Verifiser Rule

Gå tilbake til **"Inbound security rules"**

Du skal nå se:

| Priority | Name | Port | Protocol | Source | Destination | Action |
|----------|------|------|----------|--------|-------------|--------|
| 100 | Allow-HTTP-Inbound | 80 | TCP | Any | Any | Allow |
| 65000 | AllowVNetInBound | Any | Any | VirtualNetwork | VirtualNetwork | Allow |
| ... | ... | ... | ... | ... | ... | ... |

**Merk:** Din custom rule vises øverst (lavest priority-nummer).

---

## Del 5: Opprett Custom Inbound Rule (Allow HTTPS)

La oss legge til HTTPS (port 443) også.

### Steg 5.1: Legg til Rule

1. **"Inbound security rules"** → **"+ Add"**

2. **Konfigurer:**
   - **Source:** `Any`
   - **Source port ranges:** `*`
   - **Destination:** `Any`
   - **Service:** `HTTPS`
   - **Destination port ranges:** `443` (auto-fylt)
   - **Protocol:** `TCP` (auto-fylt)
   - **Action:** `Allow`
   - **Priority:** `110`
   - **Name:** `Allow-HTTPS-Inbound`
   - **Description:** `Allow HTTPS traffic from internet`

3. Klikk **"Add"**

---

## Del 6: Opprett Custom Inbound Rule (Allow RDP)

For å kunne remote desktop til Windows VMs, trenger vi å tillate RDP (port 3389).

### Steg 6.1: Legg til RDP Rule

1. **"Inbound security rules"** → **"+ Add"**

2. **Konfigurer:**
   - **Source:** `Any` 
     - **ADVARSEL:** I produksjon bør du ALDRI bruke "Any" for RDP!
     - Bedre: Begrens til din IP-adresse eller VPN-nettverk
   - **Source port ranges:** `*`
   - **Destination:** `Any`
   - **Service:** `RDP`
   - **Destination port ranges:** `3389` (auto-fylt)
   - **Protocol:** `TCP`
   - **Action:** `Allow`
   - **Priority:** `120`
   - **Name:** `Allow-RDP-Inbound`
   - **Description:** `Allow RDP for management (LAB ONLY - not production safe)`

3. Klikk **"Add"**

**Sikkerhetsnote:**

Å åpne RDP fra "Any" (internett) er en sikkerhetsrisiko i produksjon. Bedre alternativer:
- Bruk Azure Bastion (ingen public RDP exposure)
- Begrens til ditt offentlige IP: "My IP address"
- Bruk VPN og kun tillat RDP fra VPN-nettverk
- Bruk Just-In-Time (JIT) access

For lab-formål er dette akseptabelt, men **aldri i produksjon!**

---

## Del 7: (Valgfritt) Opprett Outbound Rule

Som standard er utgående trafikk til internett tillatt. Hvis du vil blokkere eller begrense dette:

### Eksempel: Blokker Utgående til Port 25 (SMTP)

Mange organisasjoner blokkerer utgående SMTP (port 25) for å forhindre spam fra kompromitterte servere.

1. **"Outbound security rules"** → **"+ Add"**

2. **Konfigurer:**
   - **Source:** `Any`
   - **Source port ranges:** `*`
   - **Destination:** `Internet`
   - **Service:** `Custom`
   - **Destination port ranges:** `25`
   - **Protocol:** `TCP`
   - **Action:** `Deny`
   - **Priority:** `100`
   - **Name:** `Deny-SMTP-Outbound`
   - **Description:** `Block outbound SMTP to prevent spam`

3. Klikk **"Add"**

**Dette er valgfritt for labben** - du trenger ikke denne regelen med mindre du vil eksperimentere.

---

## Del 8: Knytt NSG til Subnet

NSG er nå opprettet med regler, men påvirker ingenting før den knyttes til et subnet eller network interface.

### Steg 8.1: Naviger til Subnets

1. Fortsatt på NSG-siden → Venstre meny → **"Subnets"**

2. Du skal se: "This network security group is not associated to any subnets"

3. Klikk **"+ Associate"**

### Steg 8.2: Velg Subnet

1. **Virtual network:** Velg `<prefix>-vnet-infraitsec`

2. **Subnet:** Velg `subnet-frontend`

3. Klikk **"OK"**

**Hva skjer nå?**

NSG knyttes til frontend-subnet. Alle ressurser som deployes i dette subnet (VMs, osv.) vil automatisk få disse sikkerhetsreglene applisert.

### Steg 8.3: Verifiser Association

Etter noen sekunder skal du se:

- **Subnets**-listen viser: `<prefix>-vnet-infraitsec/subnet-frontend`
- Status: Associated

---

## Del 9: Opprett NSG for Backend (Valgfritt)

Du kan også opprette separate NSGs for andre subnets med forskjellige regler.

### Steg 9.1: Opprett Backend NSG

1. Portal → **"Network security groups"** → **"+ Create"**

2. **Konfigurer:**
   - **Resource group:** `<prefix>-rg-infraitsec-network`
   - **Name:** `<prefix>-nsg-backend`
   - **Region:** `North Europe`

3. **Tags:** Samme som før

4. **Create**

### Steg 9.2: Konfigurer Backend Rules

Backend-servere bør IKKE være tilgjengelige direkte fra internett. Kun fra frontend-subnet.

**Inbound rule eksempel:**

1. Gå til `<prefix>-nsg-backend` → **"Inbound security rules"** → **"+ Add"**

2. **Konfigurer:**
   - **Source:** `IP Addresses`
   - **Source IP addresses/CIDR ranges:** `10.0.1.0/24` (frontend subnet)
   - **Destination:** `Any`
   - **Service:** `Custom`
   - **Destination port ranges:** `443,8080` (API ports, eksempel)
   - **Protocol:** `TCP`
   - **Action:** `Allow`
   - **Priority:** `100`
   - **Name:** `Allow-From-Frontend`

3. **Add**

**Merk:** Med denne regelen kan kun ressurser i frontend-subnet nå backend. Internett kan ikke.

### Steg 9.3: Knytt til Backend Subnet

1. `<prefix>-nsg-backend` → **"Subnets"** → **"+ Associate"**

2. Velg `<prefix>-vnet-infraitsec` / `subnet-backend`

3. **OK**

---

## Del 10: Verifiser NSG-konfigurasjonen

### Steg 10.1: Oversikt over NSGs

1. Portal → **"Network security groups"**

2. Du skal se:
   - `<prefix>-nsg-frontend` - Associated to 1 subnet
   - `<prefix>-nsg-backend` - Associated to 1 subnet (hvis opprettet)

### Steg 10.2: Effective Security Rules (Etter VM Deployment)

Når du har deployet en VM, kan du se "effective security rules" - kombinasjonen av subnet-NSG og NIC-NSG.

**For nå:**
- Gå til VNet → **Subnets** → `subnet-frontend`
- Under "Network security group" skal du se: `<prefix>-nsg-frontend`

---

## Del 11: Testing av NSG Rules (Konseptuelt)

Når du senere deployer en VM i subnet-frontend, vil NSG-reglene tre i kraft.

### Forventet Oppførsel:

**VM med public IP i subnet-frontend:**

**Inngående trafikk:**
- ✅ HTTP (port 80) - TILLATT (din regel 100)
- ✅ HTTPS (port 443) - TILLATT (din regel 110)
- ✅ RDP (port 3389) - TILLATT (din regel 120)
- ❌ SSH (port 22) - BLOKKERT (ingen rule, default deny vinner)
- ❌ Port 8080 - BLOKKERT (ingen rule)

**Utgående trafikk:**
- ✅ Internett (alle porter) - TILLATT (default rule)
- ✅ Andre VMs i VNet - TILLATT (default rule)

### Testing når VM er deployed:
```powershell
# Fra din PC:
Test-NetConnection -ComputerName <VM-public-IP> -Port 80
# Skal lykkes

Test-NetConnection -ComputerName <VM-public-IP> -Port 22
# Skal feile (connection timed out)
```

---

## Del 12: NSG Best Practices

### Naming Conventions

**God praksis:**
- `<prefix>-nsg-<subnet>` - f.eks. `eg06-nsg-frontend`
- `<prefix>-nsg-<vm>` - hvis NSG på VM-nivå

**Dårlig praksis:**
- Generiske navn som "nsg1", "testnsg"

### Rule Organization

**Prioritering:**
- **100-199:** Allow-regler for spesifikke tjenester
- **200-299:** Deny-regler for kjente trusler
- **300-399:** Logging/monitoring regler
- **65000+:** Default rules (ikke rør disse)

### Security by Default

**Principle of Least Privilege:**
- Start med å blokkere alt
- Åpne kun porter som eksplisitt trengs
- Begrens source IPs når mulig
- Bruk service tags (f.eks. "Internet", "VirtualNetwork") i stedet for "*"

### Dokumentasjon

**Description-feltet:**
- Bruk alltid description på custom rules
- Forklar HVORFOR regelen eksisterer
- Legg til ticket-nummer hvis relevant (i produksjon)

**Eksempel:**
```
Name: Allow-HTTP-Inbound
Description: Allow HTTP for web servers (Ticket: INC-12345)
```

---

## Del 13: Feilsøking

### Problem: "Cannot associate NSG - wrong region"

**Symptom:** Får feilmelding når du prøver å knytte NSG til subnet.

**Årsak:** NSG og VNet er i forskjellige Azure-regioner.

**Løsning:**
1. Verifiser region på NSG: NSG → Overview → Location
2. Verifiser region på VNet: VNet → Overview → Location
3. Hvis forskjellige: Opprett ny NSG i riktig region

---

### Problem: "RDP blocked even though I created allow rule"

**Symptom:** Kan ikke RDP til VM selv med NSG-regel.

**Årsak:** Flere mulige årsaker.

**Løsning - sjekkliste:**
1. **NSG knyttet til riktig subnet/NIC?** Verifiser association
2. **Regel har riktig prioritet?** Lavere nummer = høyere prioritet
3. **VM har public IP?** Uten public IP kan du ikke nå fra internett
4. **Windows Firewall på VM blokkerer?** NSG er ikke det samme som OS-firewall
5. **Effective security rules:** Sjekk VM → Networking → se hvilke regler faktisk gjelder

---

### Problem: "Too many NSG rules - hitting limit"

**Symptom:** Kan ikke legge til flere regler.

**Årsak:** Azure har limits på antall NSG-regler (default ~1000 per NSG).

**Løsning:**
1. Konsolider regler (bruk port ranges: "80,443,8080" i én regel)
2. Bruk Application Security Groups (ASG) for å gruppere ressurser
3. Split i flere NSGs hvis nødvendig

---

## Refleksjonsspørsmål

1. **Default Security:**
   - Hvorfor er default oppførsel å blokkere inngående trafikk fra internett?
   - Hva er fordelene og ulempene med å tillate utgående trafikk som standard?

2. **Rule Prioritering:**
   - Hva skjer hvis du har to motstridende regler (én Allow, én Deny) for samme port?
   - Hvordan bestemmes hvilken regel som "vinner"?

3. **Subnet vs. NIC NSG:**
   - Når ville du brukt NSG på subnet-nivå vs. NIC-nivå?
   - Hva skjer hvis både subnet og NIC har NSG med motstridende regler?

4. **Sikkerhet:**
   - Hvorfor er det farlig å åpne RDP (port 3389) til "Any" i produksjon?
   - Hvilke alternativer finnes for sikker remote management?

5. **Comparison:**
   - Hvordan skiller Azure NSG seg fra en tradisjonell on-premises firewall?
   - Hva er fordelene med software-defined security?

---

## Neste Steg

Nå som du har opprettet og konfigurert NSGs, skal du:

1. **Deploye en Virtual Machine** - Plassere VM i beskyttet subnet
2. **Test NSG-regler** - Verifisere at trafikk blokkeres/tillates som forventet
3. **Opprett flere VMs** - Bygge ut infrastrukturen
4. **Integrer med monitoring** - Se NSG flow logs i Log Analytics

**Gratulerer!** Du har nå implementert nettverkssikkerhet for din Azure-infrastruktur! 🎉

---

## Ressurser

- [Azure NSG Documentation](https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)
- [NSG Best Practices](https://learn.microsoft.com/en-us/azure/security/fundamentals/network-best-practices)
- [Service Tags Reference](https://learn.microsoft.com/en-us/azure/virtual-network/service-tags-overview)
- [NSG Flow Logs](https://learn.microsoft.com/en-us/azure/network-watcher/network-watcher-nsg-flow-logging-overview)