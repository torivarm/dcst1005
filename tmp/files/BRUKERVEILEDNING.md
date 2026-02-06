# InfraIT.sec Automated Deployment - Brukerveiledning

## Oversikt

Denne Heat-templaten deployer et komplett Active Directory-miljø for InfraIT.sec med:
- **DC1**: Domenekontroller med fullstendig OU-struktur, grupper og brukere
- **SRV1**: Filserver med DFS Namespace-rollen installert
- **CL1**: Testklient meldt inn i domenet
- **MGR**: IT-administrator arbeidsstasjon med utviklerverktøy og RSAT

**Deployment-tid**: Ca. 30-45 minutter (avhengig av nettverkshastighet)

## Før deployment

### Forberedelser

1. Logg inn på OpenStack via skyhigh.iik.ntnu.no
2. Sørg for at du har tilgjengelig kvote for:
   - 4 instanser
   - 28 vCPUs (4+4+2+4 cores)
   - 40 GB RAM (16+8+8+16 GB)
   - 4 floating IPs

### Parameters som må bestemmes

Du må bestemme følgende før deployment:

| Parameter | Beskrivelse | Standard | Anbefaling |
|-----------|-------------|----------|------------|
| `key_name` | SSH nøkkel (må finnes i OpenStack) | - | Bruk din eksisterende nøkkel |
| `admin_username` | Ditt brukernavn for `adm_<navn>` | student | Bruk ditt eget navn/brukernavn |
| `domain_admin_password` | Passord for domain admin | P@ssw0rd2025! | **ENDRE** for produksjon |
| `local_admin_password` | Lokalt admin-passord | LocalP@ss2025! | Kan være samme som domain |
| `user_default_password` | Standardpassord for brukere | UserP@ss2025! | **ENDRE** for produksjon |

## Deployment-prosess

### Steg 1: Upload template

```bash
# Via OpenStack CLI
openstack stack create -t infraitsec-automated.yaml \
  --parameter key_name=<din-nøkkel> \
  --parameter admin_username=<ditt-navn> \
  --parameter domain_admin_password='<sterkt-passord>' \
  infraitsec-lab

# Eller bruk Horizon web UI:
# Project → Orchestration → Stacks → Launch Stack
```

### Steg 2: Overvåk deployment

```bash
# Se stack status
openstack stack show infraitsec-lab

# Følg event log
openstack stack event list infraitsec-lab --follow

# Se detaljert output når ferdig
openstack stack output show infraitsec-lab --all
```

### Steg 3: Vent på ferdigstillelse

**Forventet tidsforløp:**
- **0-5 min**: VMs provisioneres og starter
- **5-15 min**: DC1 installerer AD DS og promoveres
- **15-20 min**: DC1 oppretter OUer, grupper og brukere
- **20-30 min**: SRV1, CL1, MGR melder seg inn i domenet
- **30-45 min**: MGR installerer Chocolatey og verktøy

**Stack status:**
- `CREATE_IN_PROGRESS` → Normal deployment pågår
- `CREATE_COMPLETE` → Alt ferdig og klart
- `CREATE_FAILED` → Noe gikk galt (se feilsøking)

## Hva skjer under deployment?

### DC1 - Domain Controller (15-20 minutter)

1. Setter hostname til `dc1`
2. Setter lokalt Administrator-passord
3. Installerer AD DS-rollen og managementverktøy
4. Promoverer til domenekontroller for `InfraIT.sec`
5. Oppretter OU-struktur:
   ```
   InfraIT.sec
   ├── InfraIT_Groups
   ├── InfraIT_Users
   │   ├── Consultants
   │   ├── Finance
   │   ├── HR
   │   ├── IT
   │   └── Sales
   └── InfraIT_Computers
       ├── Servers
       └── Workstations
           ├── Consultants
           ├── Finance
           ├── HR
           ├── IT
           └── Sales
   ```
6. Oppretter sikkerhetssgrupper:
   - **Global Groups**: `g_all_consultants`, `g_all_finance`, `g_all_hr`, `g_all_it`, `g_all_sales`
   - **Domain Local Groups**: `l_fullAccess-*-share`, `l_remoteDesktopNonAdmin`
7. Oppretter 15 brukere (plassert i riktige OUer og grupper)
8. Oppretter din administrative konto: `adm_<admin_username>`
9. Sender signal til Heat at DC er klar

### SRV1 - File Server (5-10 minutter)

1. Setter hostname til `srv1`
2. Venter på at DC1 er klar (tester LDAP port 389)
3. Henter DC1's IP-adresse
4. Setter DC1 som DNS-server
5. Melder seg inn i domenet → `OU=Servers,OU=InfraIT_Computers`
6. Installerer DFS Namespace og File Server-roller

### CL1 - Client (5-10 minutter)

1. Setter hostname til `cl1`
2. Venter på at DC1 er klar
3. Setter DC1 som DNS-server
4. Melder seg inn i domenet → `OU=IT,OU=Workstations,OU=InfraIT_Computers`

### MGR - Management Workstation (10-15 minutter)

1. Setter hostname til `mgr`
2. Venter på at DC1 er klar
3. Setter DC1 som DNS-server
4. Melder seg inn i domenet → `OU=IT,OU=Workstations,OU=InfraIT_Computers`
5. Installerer Chocolatey package manager
6. Installerer utviklerverktøy:
   - PowerShell 7
   - Visual Studio Code
   - Git
7. Installerer RSAT-tools:
   - Active Directory DS-LDS Tools
   - Group Policy Management Tools

## Etter deployment

### Hente tilkoblingsinformasjon

```bash
# Se all output
openstack stack output show infraitsec-lab --all

# Spesifikke IP-adresser
openstack stack output show infraitsec-lab dc1_info
openstack stack output show infraitsec-lab mgr_info
```

### Første pålogging

#### På MGR (anbefalt for administrasjon)

1. Koble til via RDP: `<mgr_public_ip>`
2. Logg inn som:
   ```
   Brukernavn: INFRAIT\adm_<admin_username>
   eller: adm_<admin_username>@InfraIT.sec
   Passord: <domain_admin_password>
   ```
3. Åpne PowerShell 7 eller VS Code

#### Verifiser domenemiljøet

```powershell
# Sjekk domenemedlemskap
Get-ADDomain

# List OUer
Get-ADOrganizationalUnit -Filter * | Select-Object Name, DistinguishedName

# List grupper
Get-ADGroup -Filter * -SearchBase "OU=InfraIT_Groups,DC=InfraIT,DC=sec" | 
    Select-Object Name, GroupScope, GroupCategory

# List brukere
Get-ADUser -Filter * -SearchBase "OU=InfraIT_Users,DC=InfraIT,DC=sec" |
    Select-Object Name, SamAccountName, Enabled

# Test din admin-konto
Get-ADUser adm_<admin_username> -Properties MemberOf | 
    Select-Object Name, MemberOf
```

### Test domenebruker

Test at en av brukerne fungerer:

1. RDP til CL1 eller MGR
2. Logg inn som:
   ```
   Brukernavn: ole.m.larsen@InfraIT.sec
   Passord: <user_default_password>
   ```
3. Brukeren vil bli bedt om å endre passord ved første pålogging

## Logging og feilsøking

### Cloud-init logger

Hver VM har en detaljert logg i `C:\cloud-init-<hostname>.log`

**Finne logger:**
```powershell
# På hver VM
Get-Content C:\cloud-init-dc1.log -Tail 50
Get-Content C:\cloud-init-srv1.log -Tail 50
Get-Content C:\cloud-init-cl1.log -Tail 50
Get-Content C:\cloud-init-mgr.log -Tail 50
```

### Cloudbase-init logger (system)

Windows system-logger fra cloudbase-init:
```
C:\Program Files\Cloudbase Solutions\Cloudbase-Init\log\
```

### Vanlige problemer og løsninger

#### Problem: Stack feiler med `CREATE_FAILED`

**Sjekk:**
```bash
# Se hvilken ressurs som feilet
openstack stack event list infraitsec-lab | grep FAILED

# Se detaljert feilmelding
openstack stack show infraitsec-lab
```

**Mulige årsaker:**
- Ikke nok kvote (CPU, RAM, floating IPs)
- Feil SSH key-navn
- Nettverksproblemer

**Løsning:**
```bash
# Slett stack og prøv igjen
openstack stack delete infraitsec-lab

# Sjekk kvote
openstack quota show
```

#### Problem: DC1 WaitCondition timeout

**Symptom:** Stack feiler etter 30 minutter med `dc1_wait_condition` timeout

**Årsak:** DC1 klarte ikke å fullføre AD DS-installasjon eller sende signal

**Løsning:**
1. Koble til DC1 via RDP
2. Sjekk loggen: `C:\cloud-init-dc1.log`
3. Kjør manuelt hvis nødvendig:
   ```powershell
   # Sjekk om AD DS er installert
   Get-WindowsFeature -Name AD-Domain-Services
   
   # Sjekk om domenet eksisterer
   Get-ADDomain
   ```

#### Problem: SRV1/CL1/MGR klarer ikke å melde seg inn

**Symptom:** Maskiner står i workgroup etter deployment

**Debugging:**
1. Koble til maskinen via RDP (bruk lokalt Administrator-passord)
2. Sjekk DNS-innstillinger:
   ```powershell
   Get-DnsClientServerAddress
   # Skal peke til DC1's IP
   ```
3. Test forbindelse til DC1:
   ```powershell
   Test-NetConnection dc1 -Port 389
   Resolve-DnsName InfraIT.sec
   ```
4. Sjekk cloud-init-loggen for feilmeldinger

**Manuell domain join hvis nødvendig:**
```powershell
# Sett DC1 som DNS (hvis ikke gjort)
$DC1IP = (Resolve-DnsName dc1).IPAddress
$Adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ServerAddresses $DC1IP

# Domain join
$Cred = Get-Credential -Message "INFRAIT\Administrator"
Add-Computer -DomainName InfraIT.sec -Credential $Cred -Restart
```

#### Problem: MGR - Chocolatey eller verktøy ikke installert

**Symptom:** Kommandoer som `choco`, `pwsh`, `code`, `git` ikke funnet

**Løsning:** Installer manuelt via PowerShell (som Administrator):

```powershell
# Installer Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Refresh environment
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Installer verktøy
choco install powershell-core vscode git -y

# Installer RSAT
Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"
Add-WindowsCapability -Online -Name "Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0"
```

## Sikkerhet og best practices

### Passord-håndtering

**VIKTIG:** Standard-passordene i templaten er IKKE sikre for produksjon!

**For lab-formål:**
- Akseptabelt å bruke enkle passord som `P@ssw0rd2025!`
- IKKE bruk sensitive data eller ekte informasjon

**For produksjonslignende miljø:**
- Bruk sterke, unike passord for hver parameter
- Lagre passord sikkert (passord-manager)
- Vurder å bruke Heat-miljøfiler for parametere

**Eksempel på sikker deployment:**
```bash
# Lag en environment-fil med passord
cat > env.yaml <<EOF
parameters:
  key_name: my-key
  admin_username: torivlar
  domain_admin_password: 'Kompleks!Passord#2025$ABC'
  local_admin_password: 'Annet!Sterkt#Passord$123'
  user_default_password: 'Bruker!Standard#Pass$456'
EOF

# Deploy med environment-fil
openstack stack create -t infraitsec-automated.yaml \
  -e env.yaml \
  infraitsec-lab
```

### Brukere må endre passord

Alle domenebrukere (unntatt `adm_<username>`) er konfigurert med:
- `ChangePasswordAtLogon = $true`
- De MÅ endre passord ved første pålogging

### Domenekontroller-sikkerhet

DC1 er eksponert via floating IP for RDP-tilgang. I produksjon:
- Fjern floating IP fra DC1
- Bruk VPN eller bastion host
- Aktiver Windows Firewall
- Implementer Network Security Groups

## Opprydding

### Slette hele miljøet

```bash
# Slett stack (sletter alle VMs, nettverk, etc.)
openstack stack delete infraitsec-lab

# Bekreft sletting
openstack stack list
```

**OBS:** Dette sletter:
- Alle 4 VMs
- Alle floating IPs
- Nettverk og subnett
- Security groups
- **Alt arbeid utført i miljøet går tapt**

### Snapshot før sletting

Hvis du vil beholde arbeidet:

```bash
# Ta snapshot av viktige VMs
openstack server image create --name dc1-snapshot dc1
openstack server image create --name mgr-snapshot mgr

# List snapshots
openstack image list --private
```

## Videreutvikling

### Ting som IKKE er automatisert (kan være øvelser)

Templaten setter opp grunnstrukturen, men studentene må fortsatt:

1. **DFS Namespace-konfigurasjon:**
   - Opprette DFS namespace
   - Konfigurere namespace-servere
   - Opprette mapper i namespace

2. **File Shares:**
   - Opprette shares på SRV1
   - Sette NTFS-permissions
   - Koble DFS namespace til shares

3. **Group Policy Objects:**
   - Opprette GPOer
   - Konfigurere policies
   - Linke GPOer til OUer

4. **Sikkerhetskonfigurasjoner:**
   - Fintuning av permissions
   - Audit policies
   - Security compliance

5. **Backup-løsninger:**
   - Installere VEEAM
   - Konfigurere backup-jobs
   - Teste restore

### Tilpasse templaten

Template kan utvides med:
- Flere servere (f.eks. VEEAM backup server)
- Statiske IP-adresser (endre port-konfigurasjon)
- Pre-konfigurerte GPOer via PowerShell
- Automatisk file share-oppsett
- Syslog/monitoring-konfigurasjon

## Support og kontakt

Ved problemer:
1. Sjekk loggfiler på hver VM
2. Verifiser OpenStack Heat event log
3. Se denne dokumentasjonen
4. Kontakt faglærer hvis problemet vedvarer

## Vedlegg: Brukerkontoer

### Administrative kontoer

| Konto | Passord | Grupper | Formål |
|-------|---------|---------|--------|
| Administrator | domain_admin_password | Domain Admins, Enterprise Admins | Innebygd admin |
| adm_<username> | domain_admin_password | Domain Admins, Enterprise Admins, Schema Admins | Din personlige admin |

### Domenebrukere (må endre passord ved første login)

| Navn | SamAccountName | Avdeling | Tittel |
|------|----------------|----------|--------|
| Ole Magnus Larsen | ole.m.larsen | IT | IT Infrastructure Manager |
| Ingrid Marie Østby | ingrid.m.ostby | IT | System Administrator |
| Astrid Elisabeth Haugen | astrid.e.haugen | HR | HR Director |
| Erik André Solberg | erik.a.solberg | Sales | Senior Sales Manager |
| Kristin Sofie Nilsen | kristin.s.nilsen | Sales | Sales Representative |
| Lars Fredrik Berntsen | lars.f.berntsen | Finance | Financial Controller |
| Pål Henrik Dahl | pal.h.dahl | Consultants | Security Consultant |
| Silje Kristine Andersen | silje.k.andersen | Consultants | Senior Security Consultant |
| Øystein Johan Berg | oystein.j.berg | Consultants | Cloud Security Architect |
| Håkon Thomas Evensen | hakon.t.evensen | Consultants | IAM Consultant |
| Marte Cecilie Ødegård | marte.c.odegard | Consultants | Security Operations Consultant |
| Bjørn Andreas Hagen | bjorn.a.hagen | Consultants | Compliance Consultant |
| Eva Kristin Røed | eva.k.roed | Consultants | Incident Response Consultant |
| Nils Erik Gjerde | nils.e.gjerde | Consultants | Application Security Consultant |
| Åse Maria Viken | ase.m.viken | Consultants | Digital Forensics Consultant |

Alle brukere er medlemmer av sin respektive `g_all_<avdeling>` gruppe.
