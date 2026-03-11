# Azure Linux Virtual Machine - Opprettelse med Sikker SSH-tilgang

## Oversikt

I denne øvelsen skal du opprette en Linux virtual machine (Ubuntu Server) i Azure og konfigurere sikker SSH-tilgang. Du lærer å begrense nettverkstilgang til kun din egen IP-adresse - en viktig sikkerhetspraksis.

**Hva er forskjellen på Linux VM vs. Windows VM?**

Linux-VMs er ofte foretrukket for web servers og cloud workloads fordi de:
- Koster mindre (ingen Windows-lisens)
- Bruker mindre ressurser (kan kjøre på mindre VM sizes)
- Er lettere å automatisere (SSH, scripting)
- Er standard i mange cloud-native environments

**Læringsmål:**
- Opprette og konfigurere en Linux (Ubuntu) VM
- Finne din egen offentlige IP-adresse
- Konfigurere sikre NSG-regler med IP-begrensning
- Koble til VM via SSH
- Installere og konfigurere web server (Nginx)
- Forstå SSH key-based authentication vs. password

**Estimert tid:** 30-40 minutter

---

## Forutsetninger

- [ ] Ferdigstilt forrige øvelser (VNet, subnets, NSG)
- [ ] VNet: `<prefix>-vnet-infraitsec`
- [ ] Subnet: `subnet-frontend`
- [ ] NSG: `<prefix>-nsg-frontend` (knyttet til subnet)
- [ ] SSH-klient installert (Windows Terminal, PuTTY, eller Linux/Mac terminal)

---

## Del 1: Forstå Linux VM og SSH

### Hvorfor Linux for Web Servers?

**Fordeler:**
- **Lavere kostnad:** Ingen Windows Server-lisens (~30% billigere)
- **Mindre ressurskrav:** Kan kjøre på B1s (1 vCPU, 1GB RAM) uten problemer
- **Lettere automatisering:** SSH + bash scripts
- **Industri-standard:** Mest brukt for web servers og cloud workloads
- **Container-ready:** Docker, Kubernetes kjører naturlig på Linux

**Ubuntu Server LTS (Long Term Support):**
- 5 års support og oppdateringer
- Stabil og veldokumentert
- Stort community
- Gratis og open source

### SSH vs. RDP

**SSH (Secure Shell):**
- Kryptert remote terminal-tilgang
- Primært kommandolinje (terminal)
- Kan også forwarde GUI (X11) hvis nødvendig
- Port 22 (standard)

**Autentisering:**
- **Password:** Brukernavn + passord (enklere, mindre sikkert)
- **SSH Keys:** Private/public key pair (anbefalt, mer sikkert)

Vi bruker password for lab-formål, men produksjon bør bruke SSH keys.

---

## Del 2: Finn Din Offentlige IP-adresse

Dette er **kritisk** for sikker NSG-konfigurasjon!

### Steg 2.1: Hva er Min Offentlige IP?

**Metode 1 - Via Nettside (Enklest):**

1. Åpne browser

2. Gå til: [https://whatismyipaddress.com/](https://whatismyipaddress.com/)
   - Eller: [https://icanhazip.com/](https://icanhazip.com/)
   - Eller: [https://ifconfig.me/](https://ifconfig.me/)

3. **Kopier IP-adressen** som vises
   - Eksempel: `158.39.75.123`

**Metode 2 - Via PowerShell:**
```powershell
(Invoke-WebRequest -Uri "https://api.ipify.org").Content
```

**Metode 3 - Via Linux/Mac Terminal:**
```bash
curl ifconfig.me
```

### Steg 2.2: Noter IP-adressen

**VIKTIG:** 
- Kopier IP-adressen et sted du lett finner den
- Du trenger den når du konfigurerer NSG-regel
- Eksempel: `158.39.75.123`

**Er du på NTNU-nettverk?**

Hvis du er på campus eller VPN, vil IP-adressen være NTNU sin offentlige IP. Dette er OK - NSG-regelen vil tillate tilgang fra NTNU-nettverket.

**Hva hvis IP endres?**

Hvis du får ny IP (f.eks. bytter nettverk hjemme ↔ NTNU), må du oppdatere NSG-regelen. Vi viser hvordan senere.

---

## Del 3: Opprett Linux Virtual Machine

### Steg 3.1: Start VM Creation

1. Azure Portal → Søk **"Virtual machines"**

2. Klikk **"Virtual machines"**

3. Klikk **"+ Create"** → **"Azure virtual machine"**

### Steg 3.2: Basics Tab

**Project details:**
- **Subscription:** Velg din subscription
- **Resource group:** Opprett ny RG `<prefix>-rg-infraitsec-compute` (lettere å slette alle compute resources(VM))

**Instance details:**
- **Virtual machine name:** `<prefix>-vm-linux01`
  - Eksempel: `eg06-vm-linux01`
- **Region:** `North Europe`
- **Availability options:** `No infrastructure redundancy required`
- **Security type:** `Standard`
- **Image:** Klikk dropdown → Søk **"Ubuntu"**
  - Velg: **"Ubuntu Server 24.04 LTS - x64 Gen2"**
  - Eller: **"Ubuntu Server 22.04 LTS"** (også bra)
  - **LTS = Long Term Support** (5 års oppdateringer)
- **VM architecture:** `x64`
- **Size:** Klikk **"See all sizes"**

### Steg 3.3: Velg VM Size

**For Linux kan du gå mindre enn Windows:**

1. Filtrer på **B-series**

2. Velg **Standard_B1s** (anbefalt for lab):
   - 1 vCPU, 1 GiB memory
   - ~€7.50/måned (hvis alltid on)
   - Helt tilstrekkelig for Linux web server!

**Eller B2s hvis du vil ha mer kraft:**
- 2 vCPU, 4 GiB memory
- ~€30/måned

3. Klikk **"Select"**

### Steg 3.4: Administrator Account

**Authentication type:**
- Velg **"Password"**
  - SSH public key er bedre for produksjon
  - Password er enklere for lab

**Username:**
- **Username:** `azureuser`
  - Standard convention for Azure Linux VMs
  - Kan også bruke ditt eget brukernavn.
  - **IKKE bruk:** "admin", "root", "administrator" (blokkert)

**Password:**
- **Password:** Lag et sterkt passord
  - Minimum 12 tegn
  - Store/små bokstaver, tall, spesialtegn
  - Eksempel: `L1nux@Azure2026__`
- **Confirm password:** Gjenta passord

**NOTER:** Brukernavn og passord - trenger det for SSH!

### Steg 3.5: Inbound Port Rules

**VIKTIG - Her setter vi IKKE opp SSH ennå!**

**Public inbound ports:**
- Velg **"None"**

**Hvorfor None?**

Vi skal lage en mer sikker NSG-regel MANUELT som kun tillater SSH fra din IP-adresse. Ikke fra "Any" (hele internett)!

**Licensing:**
- Ikke relevant for Linux (gratis OS)

Klikk **"Next: Disks >"**

---

## Del 4: Disks Configuration

**OS disk type:**
- Velg **"Standard SSD (locally-redundant storage)"**

**OS disk size:**
- **30 GiB** (default for Ubuntu)
- Mindre enn Windows (Ubuntu bruker ~10GB etter installasjon)

**Delete with VM:**
- ☑ **"Delete with VM"**

**Data disks:**
- Ikke legg til (ikke nødvendig for lab)

Klikk **"Next: Networking >"**

---

## Del 5: Networking Configuration

**Virtual network:**
- Velg `<prefix>-vnet-infraitsec`

**Subnet:**
- Velg `subnet-frontend (10.0.1.0/24)`

**Public IP:**
- **Create new**
- **Name:** `<prefix>-vm-linux01-pip`
- **SKU:** `Standard`
- **Assignment:** `Static`
  - Static anbefales - IP endres ikke
- Klikk **"OK"**

**NIC network security group:**
- Velg **"None"**
- Vi bruker subnet-NSG i stedet

**Delete NIC when VM is deleted:**
- ☑ Enable (rydder opp automatisk)

**Load balancing:**
- **None**

Klikk **"Next: Management >"**

---

## Del 6: Management Configuration

**Enable system assigned managed identity:**
- ☑ **Enable**
- **Auto-shutdown:**
  - ☑ **Enable auto-shutdown**
  - **Time:** `19:00`
  - **Time zone:** `(UTC+01:00) Oslo`
  - ☑ **Send notification**
  - **Email:** `<din-email@ntnu.no>`

## Del 7: Monitoring
**Boot diagnostics:**
- ☑ **Enable with managed storage account**

**Enable OS guest diagnostics:**
- ☐ Disable (ikke nødvendig for lab)

Klikk **"Next: Advanced >"**

---

## Del 7: Advanced (Valgfritt)

**Custom data / Cloud-init:**

Hvis du vil automatisere installasjon av software under VM provisioning:
```yaml
#cloud-config
package_upgrade: true
packages:
  - nginx
  - curl
  - git
```

Dette installerer Nginx automatisk under VM oppstart. **Valgfritt - vi installerer manuelt senere.**

Klikk **"Next: Tags >"**

---

## Del 8: Tags

| Name | Value |
|------|-------|
| `Owner` | `<dittbrukernavn>` |
| `Environment` | `Lab` |
| `Course` | `InfraIT-Cyber` |
| `Purpose` | `Linux-Web-Server` |
| `OS` | `Ubuntu` |

Klikk **"Review + create"**

---

## Del 9: Create VM

**Estimated cost:** ~€10-12/måned (B1s, static IP, 30GB disk)

**Mye billigere enn Windows!** (~€30/måned for sammenlignbar Windows VM)

1. Klikk **"Create"**

2. Deployment tar **3-5 minutter** (raskere enn Windows!)

3. **"Go to resource"** når ferdig

---

## Del 10: Opprett Sikker SSH NSG-regel

Nå skal vi lage en NSG-regel som KUN tillater SSH fra din IP-adresse.

### Steg 10.1: Naviger til NSG

1. Azure Portal → Søk **"Network security groups"**

2. Klikk på `<prefix>-nsg-frontend`

3. Venstre meny → **"Inbound security rules"**

### Steg 10.2: Legg til SSH Rule (Sikker!)

1. Klikk **"+ Add"**

2. **Konfigurer:**

**Source:**
- **Source:** `IP Addresses` ← IKKE "Any"!
- **Source IP addresses/CIDR ranges:** `<din-IP>/32`
  - Eksempel: `158.39.75.123/32`
  - `/32` betyr "kun denne eksakte IP-adressen"

**Source port ranges:**
- `*` (alle source ports)

**Destination:**
- **Destination:** `Any`
- **Service:** `SSH`
- **Destination port ranges:** `22` (auto-fylles)

**Protocol:**
- `TCP` (auto-fylles)

**Action:**
- `Allow`

**Priority:**
- `130` (høyere enn HTTP/HTTPS regler hvis du har dem)

**Name:**
- `Allow-SSH-From-MyIP`

**Description:**
- `Allow SSH only from my public IP address for secure remote access`

3. Klikk **"Add"**

**Hva har vi oppnådd?**

✅ SSH er KUN tilgjengelig fra din IP-adresse  
✅ Resten av internett kan IKKE nå SSH  
✅ Defense in depth - selv om passord lekkes, kan ikke random IP koble til  
✅ Best practice security!

---

## Del 11: Koble til VM via SSH

### Steg 11.1: Hent VM Public IP

1. Gå til VM: `<prefix>-vm-linux01`

2. **Overview** → kopier **Public IP address**
   - Eksempel: `20.54.78.90`

### Steg 11.2: SSH fra Windows

**Windows 10/11 (Windows Terminal eller PowerShell):**
```powershell
ssh azureuser@20.54.78.90
```

Erstatt `20.54.78.90` med din VM sin public IP.

**Første gang:**
```
The authenticity of host '20.54.78.90' can't be established.
ECDSA key fingerprint is SHA256:abc123...
Are you sure you want to continue connecting (yes/no)?
```

Skriv **`yes`** og trykk Enter.

**Password:**
- Skriv inn passordet du satte under VM creation
- Du vil IKKE se tegn når du skriver (normalt for SSH)
- Trykk Enter

**Success!**
```
Welcome to Ubuntu 24.04 LTS (GNU/Linux ...)

azureuser@eg06-vm-linux01:~$
```

Du er nå inne i VM! 🎉

### Steg 11.3: SSH fra Mac/Linux/Windows
```bash
ssh azureuser@20.54.78.90
```

---

## Del 12: Verifiser VM og Utforsk Linux

### Steg 12.1: Grunnleggende Linux Commands

**I SSH-sesjon:**
```bash
# Se hvem du er logget inn som
whoami
# Output: azureuser

# Se hostname
hostname
# Output: eg06-vm-linux01

# Se operativsystem
cat /etc/os-release
# Output: Ubuntu 24.04 LTS...

# Se privat IP-adresse
ip addr show eth0 | grep inet
# Output: inet 10.0.1.x/24 ...

# Se tilgjengelig disk
df -h
# Output: /dev/sda1    30G  10G  19G  35% /

# Se minne
free -h
# Output: total  1.0Gi ...

# Se CPU info
lscpu | grep "Model name"
```

### Steg 12.2: Test Internettilgang
```bash
# Ping Google (test utgående connectivity)
ping -c 4 google.com
# Skal fungere

# Test DNS oppløsning
nslookup google.com
# Skal vise IP-adresser

# Hent en nettside
curl -I https://www.google.com
# Skal vise HTTP 200 OK
```

**Alt fungerer!** Utgående internettilgang er tillatt som default.

### Steg 12.3: Oppdater System

**Best practice:** Alltid oppdater etter installasjon.
```bash
# Oppdater package lists
sudo apt update

# Oppgrader installerte pakker
sudo apt upgrade -y
```

Dette kan ta 2-5 minutter første gang.

---

## Del 13: Installer Nginx Web Server

### Steg 13.1: Installer Nginx
```bash
# Installer Nginx
sudo apt install nginx -y

# Sjekk at Nginx kjører
sudo systemctl status nginx
```

**Output:**
```
● nginx.service - A high performance web server
   Active: active (running)
```

Trykk `q` for å avslutte status-visning.

### Steg 13.2: Test Nginx Lokalt
```bash
# Test fra VM selv
curl http://localhost
```

**Du skal se HTML-output:**
```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

Nginx fungerer! 🌐

### Steg 13.3: Åpne HTTP i NSG

**Problem:** Nginx kjører, men er ikke tilgjengelig fra internett fordi NSG blokkerer port 80.

**Løsning:**

1. Azure Portal → `<prefix>-nsg-frontend`

2. **Inbound security rules** → **"+ Add"**

3. **Konfigurer:**
   - **Source:** `Any` (web servers må være tilgjengelige for alle)
   - **Destination:** `Any`
   - **Service:** `HTTP`
   - **Port:** `80` (auto)
   - **Action:** `Allow`
   - **Priority:** `100`
   - **Name:** `Allow-HTTP-Inbound`

4. **Add**

### Steg 13.4: Test Nginx fra Internett

**Fra din PC (browser):**

1. Åpne browser

2. Gå til: `http://<vm-public-IP>`
   - Eksempel: `http://20.54.78.90`

3. Du skal se: **"Welcome to nginx!"**

**Gratulerer!** Din Linux VM er nå en fungerende web server! 🎉

---

## Del 14: Lag Custom Web Page

### Steg 14.1: Rediger Index Page

**I SSH-sesjon:**
```bash
# Naviger til web root
cd /var/www/html

# Backup original fil
sudo cp index.nginx-debian.html index.nginx-debian.html.bak

# Opprett ny index.html
sudo nano index.html
```

**Lim inn følgende HTML:**
```html
<!DOCTYPE html>
<html>
<head>
    <title>Azure Linux Lab</title>
    <style>
        body {
            font-family: 'Segoe UI', Arial, sans-serif;
            text-align: center;
            padding: 50px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        h1 { font-size: 3em; margin-bottom: 20px; }
        .info { font-size: 1.2em; margin: 10px; }
        .box {
            background: rgba(255,255,255,0.1);
            padding: 20px;
            border-radius: 10px;
            margin: 20px auto;
            max-width: 600px;
        }
    </style>
</head>
<body>
    <h1>🐧 Azure Linux VM</h1>
    <div class="box">
        <div class="info">Student: <strong>[DIN PREFIX]</strong></div>
        <div class="info">VM: Ubuntu Server 24.04 LTS</div>
        <div class="info">Web Server: Nginx</div>
        <div class="info">Course: DCST1005 - InfraIT Cyber</div>
    </div>
    <p>Deployed in Azure North Europe Region</p>
</body>
</html>
```

**Lagre:**
- Trykk `Ctrl+O` (WriteOut)
- Trykk `Enter` (bekreft filnavn)
- Trykk `Ctrl+X` (Exit)

### Steg 14.2: Test Custom Page

**Refresh browser:** `http://<vm-public-IP>`

Du skal nå se din custom side med gradient bakgrunn! 🌈

---

## Del 15: Verifiser Monitoring Integration

### Steg 15.1: Sjekk Azure Monitor Agent (i VM)
```bash
# Sjekk om agent kjører
systemctl status azuremonitoragent

# Eller
ps aux | grep azuremonitor
```

Skal vise at agenten kjører.

### Steg 15.2: Query i Log Analytics

**Azure Portal → Log Analytics Workspace:**
```kusto
Heartbeat
| where TimeGenerated > ago(1h)
| where Computer contains "linux01"
| project TimeGenerated, Computer, OSType, OSName, OSMajorVersion
```

**Forventet (etter 10-15 min):**
```
TimeGenerated         Computer              OSType  OSName  OSMajorVersion
2024-03-10 14:23:12   eg06-vm-linux01      Linux   Ubuntu  24
```

**Hybrid Monitoring i praksis:**
- On-prem Windows (DC1, SRV1) via Arc
- Azure Windows VM (hvis du lagde den)
- Azure Linux VM (linux01)

**Alt i samme workspace!** 🎯

---

## Del 16: Sikkerhet - Hva Hvis IP Endres?

### Scenario: Du Bytter Nettverk

Du var på NTNU campus (IP: `158.39.75.123`), nå er du hjemme (IP: `81.166.x.x`).

**Problem:** SSH blokkeres fordi NSG tillater kun gammel IP.

### Løsning: Oppdater NSG Rule

1. **Finn ny IP:** `curl ifconfig.me` eller [whatismyipaddress.com](https://whatismyipaddress.com)

2. **Oppdater NSG:**
   - Portal → `<prefix>-nsg-frontend`
   - **Inbound rules** → Klikk på `Allow-SSH-From-MyIP`
   - **Source IP addresses:** Endre til ny IP + `/32`
   - **Save**

3. **Test SSH:** Skal fungere igjen

### Alternativ: Tillat IP Range

Hvis du switcher ofte mellom nettverk:
```
Source IP: 158.39.75.0/24,81.166.0.0/16
```

Dette tillater hele IP-ranges (mer permissivt, men fortsatt bedre enn "Any").

---

## Del 17: Stoppe og Starte VM

### Steg 17.1: Stop VM

**Husk å stoppe VM når du ikke bruker den!**

**Azure Portal:**

1. VM-siden → **"Stop"**

2. Status: Running → Stopped (deallocated)

**Når stopped (deallocated):**
- ✅ Betaler kun storage (~€1-2/måned)
- ✅ Compute charges stopper
- ✅ Public IP frigjøres (static IP beholdes)

### Steg 17.2: Start VM

1. VM-siden → **"Start"**

2. ~1-2 minutter oppstart (raskere enn Windows!)

3. SSH inn på nytt

---

## Del 18: Feilsøking

### Problem: "SSH Connection Refused"

**Symptom:** `ssh: connect to host X.X.X.X port 22: Connection refused`

**Sjekk:**

1. **VM kjører?** Status må være "Running"

2. **NSG tillater SSH fra din IP?**
   - VM → Networking → Effective security rules
   - Se etter regel som tillater port 22 fra din IP

3. **Riktig IP i NSG?**
   - Din IP kan ha endret seg
   - Sjekk: `curl ifconfig.me`
   - Oppdater NSG hvis nødvendig

4. **SSH service kjører i VM?**
   - Kan ikke sjekke uten tilgang, men burde kjøre automatisk

**Løsning:**
- Oppdater NSG source IP til din nåværende IP
- Eller midlertidig: Endre source til "Any" for testing (IKKE la stå!)

---

### Problem: "Nginx ikke tilgjengelig fra internett"

**Symptom:** `http://<ip>` fungerer ikke

**Sjekk:**

1. **Nginx kjører?** (i SSH):
```bash
   sudo systemctl status nginx
```

2. **NSG tillater port 80?**
   - VM → Networking → Inbound port rules → HTTP (80)

3. **Firewall i Linux?** (Ubuntu har ikke firewall enabled som default)
```bash
   sudo ufw status
   # Skal vise: inactive
```

**Løsning:**
- Legg til NSG inbound rule for HTTP (port 80) fra "Any"

---

### Problem: "Can't update packages - apt errors"

**Symptom:** `sudo apt update` feiler

**Sjekk:**
```bash
# Test DNS
nslookup archive.ubuntu.com

# Test connectivity
curl http://archive.ubuntu.com
```

**Løsning:**
- VM må ha utgående internettilgang (default tillatt)
- Sjekk at subnet-NSG ikke blokkerer outbound

---

## Refleksjonsspørsmål

1. **Sikkerhet:**
   - Hvorfor er det viktig å begrense SSH til kun din IP?
   - Hva er risikoen ved å åpne SSH til "Any" (hele internett)?

2. **Linux vs. Windows:**
   - Hvilke fordeler har Linux for web servers?
   - Når ville du valgt Windows Server i stedet?

3. **Kostnader:**
   - Hvorfor er Linux VM billigere enn Windows VM?
   - Hvor mye kan du spare ved å bruke B1s (1 vCPU) for Linux vs. B2s for Windows?

4. **SSH:**
   - Hva er forskjellen på password og SSH key authentication?
   - Hvorfor er SSH keys sikrere?

5. **NSG Best Practices:**
   - Hva er "Principle of Least Privilege" i context av NSG rules?
   - Hvordan balanserer du tilgjengelighet (f.eks. HTTP til "Any") vs. sikkerhet (SSH til spesifikk IP)?

---

## Neste Steg

Nå som du har både Windows og Linux VMs, kan du:

1. **Sammenligne monitoring** - KQL queries på tvers av OS-typer
2. **Deploy applikasjoner** - Node.js, Python, Docker på Linux
3. **Last balancing** - Distribuere trafikk mellom flere VMs
4. **Cleanup** - Slette ressurser for å spare kostnader

**Gratulerer!** Du har nå deployert en sikker Linux web server i Azure! 🐧🎉

---

## Ressurser

- [Azure Linux VMs Documentation](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/)
- [Ubuntu Server Documentation](https://ubuntu.com/server/docs)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [SSH Best Practices](https://www.ssh.com/academy/ssh/best-practices)
- [Azure Network Security Best Practices](https://learn.microsoft.com/en-us/azure/security/fundamentals/network-best-practices)