# Lab: Infrastructure Hardening med Microsoft Security Compliance Toolkit

## Læringsmål
Etter denne laben skal du kunne:
- Forstå hva Microsoft Security Compliance Toolkit (SCT) er og hvorfor det er viktig
- Laste ned og analysere security baselines for ulike OS-versjoner
- Importere og implementere security baselines via Group Policy
- Verifisere at hardening-tiltak er korrekt implementert
- Forstå trade-offs mellom sikkerhet og funksjonalitet
- Utvide baselines med egne custom hardening-settings

---

## Forutsetninger

**Påkrevde administrative rettigheter:**
- Innlogget som `adm_<brukernavn>` på **mgr.infrait.sec**
- Medlemskap i gruppen `Domain Admins` eller `Group Policy Creator Owners`

**Lab-miljø:**
- **dc1.infrait.sec** - Domain Controller (Windows Server 2025)
- **srv1.infrait.sec** - File Server med DFS (Windows Server 2025)
- **cl1.infrait.sec** - Klient-maskin (Windows 11)
- **mgr.infrait.sec** - IT Admin workstation (Windows 11)

**Verktøy som skal være installert på mgr:**
- Group Policy Management Console (GPMC)
- PowerShell 5.1 eller nyere
- Remote Server Administration Tools (RSAT)
- Internett-tilgang (for nedlasting av toolkit)

---

## Teorigrunnlag

### Hva er Microsoft Security Compliance Toolkit?

Microsoft Security Compliance Toolkit (SCT) er en samling av **security baselines** - forhåndskonfigurerte Group Policy Objects som implementerer Microsofts anbefalte sikkerhetskonfigurasjoner.

**Baselines er utviklet av:**
- Microsoft Security Response Center (MSRC)
- National Security Agency (NSA)
- Defense Information Systems Agency (DISA)
- Center for Internet Security (CIS)

### Hva dekker baselines?

Security baselines konfigurerer:

| Kategori | Eksempler på Settings |
|----------|----------------------|
| **Account Policies** | Passordkompleksitet, account lockout, Kerberos policies |
| **Audit Policies** | Hva som logges i Security Event Log |
| **User Rights** | Hvem kan logge på lokalt, starte services, ta backup |
| **Security Options** | SMB signing, LDAP signing, anonymous access |
| **Windows Defender** | Real-time protection, cloud protection, PUA blocking |
| **PowerShell Logging** | Script block logging, transcription, constrained language mode |
| **Network Security** | Disable SMBv1, TLS 1.0/1.1, NetBIOS |
| **Service Hardening** | Disable Print Spooler, Remote Registry, unnecessary services |

### Viktige prinsipper:

**Defense in Depth:** Baselines implementerer multiple lag av sikkerhet, slik at en enkelt feil ikke kompromitterer hele systemet.

**Least Privilege:** Settings reduserer rettigheter til minimum nødvendig for normal drift.

**Audit & Accountability:** Økt logging slik at angrep kan oppdages og analyseres.

### Baseline-versjoner du må kjenne til:

![alt text](OsVersion.png)

```
Windows 11 24H2 Security Baseline
├── Workstation baseline (for klienter som CL1 og MGR)
└── Ikke for servere!

Windows Server 2025 Security Baseline
├── Member Server baseline (for SRV1)
└── Domain Controller baseline (for DC1)

Microsoft 365 Apps Security Baseline
└── Hardening for Office-applikasjoner
```

**VIKTIG:** Du kan IKKE bruke Windows 11 baseline på servere eller Server baseline på klienter!

---

## Del 1: Last ned Security Compliance Toolkit

### Steg 1.1: Download toolkit

På **mgr.infrait.sec**, åpne PowerShell som Administrator:

```powershell
# Opprett working directory
$ToolkitPath = "C:\SecurityBaseline"
New-Item -Path $ToolkitPath -ItemType Directory -Force

# Naviger til mappen
Set-Location $ToolkitPath

# Download URL (oppdateres jevnlig av Microsoft)
$DownloadUrl = "https://www.microsoft.com/en-us/download/details.aspx?id=55319"

Write-Host @"
Microsoft Security Compliance Toolkit må lastes ned manuelt.

1. Åpne Edge/Chrome
2. Gå til: $DownloadUrl
3. Last ned nyeste versjon (f.eks. 'Security Compliance Toolkit 1.0')
4. Huk av for alle filene og velg last ned
5. Pakk ut .zip-filene og kopier mappene over til: $ToolkitPath

Trykk Enter når nedlastingen er fullført...
"@

Read-Host
```
![alt text](MarkerAlt.png)
![alt text](AllowDownloadAll.png)
![alt text](ExtractWin11Server25.png)
![alt text](CopyFoldersToV2.png)

**Du skal se mapper som:**
```
Name
----
Windows 11 24H2 Security Baseline
Windows Server 2025 Security Baseline
Microsoft Edge Security Baseline
Microsoft 365 Apps for Enterprise
Policy Analyzer
LGPO Tool
```

---

## Del 2: Analyser Security Baselines

### Steg 2.1: Utforsk Windows Server 2025 Baseline

![alt text](WinServBaseline.png)

```powershell
# Naviger til Server 2025 baseline
# List innhold
Get-ChildItem -Recurse | Select-Object FullName
```
![alt text](pwshServBaseline.png)

**Viktige filer:**

```
GPOs\
├── {GUID}-DomainSecurity\      # Domain-wide policies
├── {GUID}-MemberServer\        # For member servers (SRV1)
└── {GUID}-DomainController\    # For DC (DC1)

Scripts\
├── Baseline-LocalInstall.ps1   # Installerer baseline lokalt (IKKE for domain!)
└── Baseline-ADImport.ps1       # Importerer til Active Directory

Documentation\
└── Windows Server 2025 Security Baseline.xlsx  # Forklarer hver setting
```

### Steg 2.2: Les dokumentasjonen (VIKTIG i produksjonssammenheng!)
- Ligger i mappen Documentation
  - ![alt text](docsinFolder.png)
- MERK! Vi har ikke Excel på MGR, last ned filen fra Microsoft på egen PC for å lese.
  - ![alt text](ExcelDocServ25.png)


**Nøkkelinformasjon i dokumentasjonen:**

- **Policy Setting Name:** Hva policyen heter i GPO
- **Help text:** Hva denne innstillingen gjør

---

## Del 3: Implementer Security Baselines via GPO

### Steg 3.1: Importer Baselines til Active Directory

På **mgr.infrait.sec**, kjør PowerShell som Administrator:

- Naviger til Scripts-mappen for Server 2025 - I mitt eksempel er det C:\SecurityBaseline\Windows Server 2025 Security Baseline\Windows Server 2025 Security Baseline - 2506\Scripts
![alt text](ScriptFolderGPOImport.png)

**Hva gjør Baseline-ADImport.ps1?**

1. Kopierer GPO-backups til SYSVOL på Domain Controller
2. Importerer GPO-er til Active Directory via `Import-GPO` cmdlet
3. Oppretter GPO-er med navnene:
   - `MSFT Windows Server 2025 - Domain Security`
   - `MSFT Windows Server 2025 - Member Server`
   - `MSFT Windows Server 2025 - Domain Controller`

**Kjør import-scriptet:**

```powershell
# Kjør AD import (krever Domain Admin rettigheter!)
.\Baseline-ADImport.ps1

<#
FORVENTET OUTPUT:

Importing the following GPOs:

MSFT Internet Explorer 11 - Computer
MSFT Internet Explorer 11 - User
MSFT Windows Server 2025 v2506 - Defender Antivirus
MSFT Windows Server 2025 v2506 - Domain Controller
MSFT Windows Server 2025 v2506 - Domain Controller Virtualization Based Security
MSFT Windows Server 2025 v2506 - Domain Security
MSFT Windows Server 2025 v2506 - Member Server
MSFT Windows Server 2025 v2506 - Member Server Credential Guard


{4A17861B-5A04-4C85-9D2C-39941A77FCBF}: MSFT Internet Explorer 11 - Computer

DisplayName      : MSFT Internet Explorer 11 - Computer
DomainName       : InfraIT.sec
Owner            : InfraIT\Domain Admins
Id               : 16e64b61-c56f-4866-9e6b-8bdf5cc8bb01
GpoStatus        : UserSettingsDisabled
Description      : 
CreationTime     : 2/8/2026 3:46:50 PM
ModificationTime : 2/8/2026 3:46:52 PM
UserVersion      : 
ComputerVersion  : 
WmiFilter        : 

{6825461D-6DE3-4E24-A982-14D56D4AF997}: MSFT Internet Explorer 11 - User
DisplayName      : MSFT Internet Explorer 11 - User
DomainName       : InfraIT.sec
Owner            : InfraIT\Domain Admins
Id               : c5d8c015-4728-414a-b6bc-8a9e094f9c59
GpoStatus        : ComputerSettingsDisabled
Description      : 
CreationTime     : 2/8/2026 3:46:52 PM
ModificationTime : 2/8/2026 3:46:53 PM
UserVersion      : 
ComputerVersion  : 
WmiFilter        : 

{AA5E941F-A7C5-4D42-AB6C-6873614DBF72}: MSFT Windows Server 2025 v2506 - Defender Antivirus
DisplayName      : MSFT Windows Server 2025 v2506 - Defender Antivirus
DomainName       : InfraIT.sec
Owner            : InfraIT\Domain Admins
Id               : 32dc6d0a-d474-43f9-bec3-84efb8fb9094
GpoStatus        : UserSettingsDisabled
Description      : 
CreationTime     : 2/8/2026 3:46:53 PM
ModificationTime : 2/8/2026 3:46:54 PM
..
..
..
..
..
#>
```
I Group Policy Manager kan en nå se alle de nyopprettede Group Policy objektene som er opprettet:
![alt text](ImportedGPOs.png)
**Hvis feil:** Se [Troubleshooting](#troubleshooting-1) nedenfor.

---

### Steg 3.2: Importer Windows 11 Baseline

Gjenta prosessen for Windows 11:

![alt text](ImportGPOWin11.png)

# Kjør import
.\Baseline-ADImport.ps1

```Powershell
<#
FORVENTET OUTPUT:

Importing the following GPOs:

MSFT Internet Explorer 11 - Computer
MSFT Internet Explorer 11 - User
MSFT Windows 11 24H2 - BitLocker
MSFT Windows 11 24H2 - Computer
MSFT Windows 11 24H2 - Credential Guard
MSFT Windows 11 24H2 - Defender Antivirus
MSFT Windows 11 24H2 - Domain Security
MSFT Windows 11 24H2 - User


{BB10D67B-FBEA-4CD0-8E5F-09AC67C07670}: MSFT Internet Explorer 11 - Computer

DisplayName      : MSFT Internet Explorer 11 - Computer
DomainName       : InfraIT.sec
Owner            : InfraIT\Domain Admins
Id               : 16e64b61-c56f-4866-9e6b-8bdf5cc8bb01
GpoStatus        : UserSettingsDisabled
Description      : 
CreationTime     : 2/8/2026 3:46:50 PM
ModificationTime : 2/8/2026 3:54:34 PM
UserVersion      : 
ComputerVersion  : 
WmiFilter        : 

{BF76B495-48DD-4A15-AFFF-E9E20A6C9AAB}: MSFT Internet Explorer 11 - User
DisplayName      : MSFT Internet Explorer 11 - User
DomainName       : InfraIT.sec
Owner            : InfraIT\Domain Admins
Id               : c5d8c015-4728-414a-b6bc-8a9e094f9c59
GpoStatus        : ComputerSettingsDisabled
Description      : 
CreationTime     : 2/8/2026 3:46:52 PM
ModificationTime : 2/8/2026 3:54:36 PM
..
..
..
..
..
..
```

---

### Steg 3.3: Verifiser at GPO-er er importert

```powershell
# List alle MSFT baseline GPO-er
Get-GPO -All | Where-Object { $_.DisplayName -like "MSFT*" } | 
    Select-Object DisplayName, CreationTime, ModificationTime |
    Format-Table -AutoSize
```

**Du skal se:**
```
DisplayName                                                                      CreationTime        ModificationTime
-----------                                                                      ------------        ----------------
MSFT Internet Explorer 11 - Computer                                             2/8/2026 3:46:50 PM 2/8/2026 3:54:34 PM
MSFT Windows 11 24H2 - Credential Guard                                          2/8/2026 3:54:39 PM 2/8/2026 3:54:40 PM
MSFT Windows Server 2025 v2506 - Defender Antivirus                              2/8/2026 3:46:53 PM 2/8/2026 3:46:54 PM
MSFT Windows Server 2025 v2506 - Member Server                                   2/8/2026 3:46:59 PM 2/8/2026 3:47:02 PM
MSFT Windows 11 24H2 - BitLocker                                                 2/8/2026 3:54:36 PM 2/8/2026 3:54:36 PM
MSFT Windows 11 24H2 - Domain Security                                           2/8/2026 3:54:43 PM 2/8/2026 3:54:44 PM
MSFT Windows 11 24H2 - Computer                                                  2/8/2026 3:54:37 PM 2/8/2026 3:54:38 PM
MSFT Windows 11 24H2 - User                                                      2/8/2026 3:54:45 PM 2/8/2026 3:54:46 PM
MSFT Windows Server 2025 v2506 - Domain Controller Virtualization Based Security 2/8/2026 3:46:57 PM 2/8/2026 3:46:58 PM
MSFT Windows Server 2025 v2506 - Member Server Credential Guard                  2/8/2026 3:47:02 PM 2/8/2026 3:47:02 PM
MSFT Windows 11 24H2 - Defender Antivirus                                        2/8/2026 3:54:42 PM 2/8/2026 3:54:42 PM
MSFT Windows Server 2025 v2506 - Domain Security                                 2/8/2026 3:46:58 PM 2/8/2026 3:46:58 PM
MSFT Windows Server 2025 v2506 - Domain Controller                               2/8/2026 3:46:54 PM 2/8/2026 3:46:56 PM
MSFT Internet Explorer 11 - User                                                 2/8/2026 3:46:52 PM 2/8/2026 3:54:36 PM
```

---

### Steg 3.4 Dobbeltsjekk at maskiner ligger i riktige OUer:**

```powershell
# Flytt Domain Controller
Get-ADComputer -Identity DC1 | Move-ADObject -TargetPath "OU=Domain Controllers,DC=infrait,DC=sec"

# Flytt Member Server
Get-ADComputer -Identity SRV1 | Move-ADObject -TargetPath "OU=Servers,OU=InfraIT_Computers,DC=infrait,DC=sec"

# Flytt Workstations (MGR-NEW er mest trolig navnet etter at en har opprettet ny MGR maskin for større diskplass)
Get-ADComputer -Identity CL1 | Move-ADObject -TargetPath "OU=HR,OU=Workstations,OU=InfraIT_Computers,DC=infrait,DC=sec"
Get-ADComputer -Identity MGR-new | Move-ADObject -TargetPath "OU=IT,OU=Workstations,OU=InfraIT_Computers,DC=infrait,DC=sec"

# Verifiser plassering
Get-ADComputer -Filter * | Select-Object Name, DistinguishedName
```
![alt text](OUlocationMachines.png)

---

### Steg 3.5: Link Baselines til riktige OUer

**‼️KRITISK‼️: Husk at når en linker en GPO med en OU påvirker det maskinen/brukerne i denne OU-en.**
> **1. Det er viktig å linke riktig baseline til riktig maskintype!**
>
> **2. Det er viktg å husk at i produksjon kan en ikke linke GPO med OU uten å først gjennomføre tester og undersøke at systemene fungerer som tiltenkt**
>
> **3. Husk å ha riktig target om en ikke har samme oppsett som i gjennomgang / MarkDowns / videoer**
>
> **4. En vet ikke alt hvordan dette påvirker maskiner / brukere før en har gått igjennom Group Policy innstillingene som settes. Se eksempel fra Excel-filen under:**
> ![alt text](ExampleGPO.png)

```powershell
# Link Domain Controller baseline
New-GPLink -Name "MSFT Windows Server 2025 v2506 - Domain Controller" `
           -Target "OU=Domain Controllers,DC=infrait,DC=sec" `
           -LinkEnabled Yes `
           -Order 1

Write-Host "✓ Linket DC baseline til Domain Controllers OU" -ForegroundColor Green
```

```powershell
# Link Member Server baseline
New-GPLink -Name "MSFT Windows Server 2025 v2506 - Member Server" `
           -Target "OU=Servers,OU=InfraIT_Computers,DC=infrait,DC=sec" `
           -LinkEnabled Yes `
           -Order 1

Write-Host "✓ Linket Member Server baseline til Servers OU" -ForegroundColor Green
```
![alt text](MemberServerGPO.png)

Etter at GPO er linket, kan en kjøre `Enter-PSSession srv1` og deretter `gpresult /r /scope:computer` som viser hvilke GPO-er som er lastet for denne maskinen. 

![alt text](PSSessionSRV1GPResoult.png)

```powershell
# Link Windows 11 Computer baseline ‼️MERK‼️ Om en har MGR maskinen i IT OU-en, vil denne Group Policy-innstillingen det påvirke MRG-maskinen.
New-GPLink -Name "MSFT Windows 11 24H2 - Computer" `
           -Target "OU=Workstations,OU=InfraIT_Computers,DC=infrait,DC=sec" `
           -LinkEnabled Yes `
           -Order 1

Write-Host "✓ Linket Windows 11 baseline til Workstations OU" -ForegroundColor Green
```

```powershell
# Link Windows 11 User baseline (gjelder brukere som logger på workstations)
New-GPLink -Name "MSFT Windows 11 24H2 - User" `
           -Target "OU=Workstations,OU=InfraIT_Computers,DC=infrait,DC=sec" `
           -LinkEnabled Yes `
           -Order 2

Write-Host "✓ Linket Windows 11 User baseline til Workstations OU" -ForegroundColor Green
````

```powershell
# Link Domain Security (gjelder alle maskiner i domenet)
New-GPLink -Name "MSFT Windows Server 2025 v2506 - Domain Security" `
           -Target "DC=infrait,DC=sec" `
           -LinkEnabled Yes

Write-Host "✓ Linket Domain Security til root domain" -ForegroundColor Green
```

**Hva gjør Order?**
- **Order 1** = Høyest prioritet (appliseres sist, overskriver andre GPO-er)
- **Order 10** = Lavest prioritet (appliseres først)

---

### Steg 3.6: Tvinge GPO-oppdatering

```powershell
# Tving Group Policy oppdatering på alle maskiner
$Computers = @('dc1', 'srv1', 'cl1')

foreach ($Computer in $Computers) {
    Write-Host "`nOppdaterer Group Policy på $Computer.infrait.sec..." -ForegroundColor Cyan
    
    Invoke-Command -ComputerName "$Computer.infrait.sec" -ScriptBlock {
        gpupdate /force
    } -ErrorAction Continue
}

Write-Host "`n⚠️  VIKTIG: Noen settings krever reboot for å tre i kraft!" -ForegroundColor Yellow
Write-Host "For PRODUKSJONSMILJØER: Planlegg en restart av maskiner i et maintenance vindu når det ikke påvirker mange brukere" -ForegroundColor Yellow
```

---

## Del 4: Verifiser Hardening Implementation

### Steg 4.1: Sjekk appliserte GPO-er

```PowerShell
$Computers = @('dc1', 'srv1', 'cl1')

foreach ($Computer in $Computers) {
    Write-Host "`nSjekker hvilke GPO-er som er aktive for $Computer.infrait.sec..." -ForegroundColor Cyan
    
    Invoke-Command -ComputerName "$Computer.infrait.sec" -ScriptBlock {
        gpresult /r /scope:computer
    }
}
```

**Forventet output for SRV1:**
```
Applied Group Policy Objects
-----------------------------
    MSFT Windows Server 2025 - Member Server
    MSFT Windows Server 2025 - Domain Security
    Default Domain Policy
```

---

### Steg 4.2: Test spesifikke hardening-settings (MERK! Legg ved mgr (eventuelt mgr-new) i listen for å teste "egen arbeidsstasjon")

#### Test 1: Er SMBv1 deaktivert?

```powershell
# SMBv1 er en KRITISK sårbarhet (EternalBlue/WannaCry)
$Computers = @('dc1', 'srv1', 'cl1')

foreach ($Computer in $Computers) {
    $SMBStatus = Invoke-Command -ComputerName "$Computer.infrait.sec" -ScriptBlock {
        # Denne metoden fungerer alltid!
        $SMBConfig = Get-SmbServerConfiguration
        $SMBConfig.EnableSMB1Protocol
    }
    
    if ($SMBStatus -eq $false) {
        Write-Host "✓ $Computer : SMBv1 protokoll er DEAKTIVERT (sikker)" -ForegroundColor Green
    } else {
        Write-Host "✗ $Computer : SMBv1 protokoll er AKTIVERT (SÅRBAR!)" -ForegroundColor Red
    }
}
```

```PowerShell
✓ dc1 : SMBv1 protokoll er DEAKTIVERT (sikker)
✓ srv1 : SMBv1 protokoll er DEAKTIVERT (sikker)
✓ cl1 : SMBv1 protokoll er DEAKTIVERT (sikker)
```

---

#### Test 2: Er PowerShell Script Block Logging aktivert?

```powershell
# PowerShell logging er kritisk for å oppdage angrep
$Computers = @('dc1', 'srv1', 'cl1')

foreach ($Computer in $Computers) {
    $PSLogging = Invoke-Command -ComputerName "$Computer.infrait.sec" -ScriptBlock {
        $RegPath = 'HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging'
        
        if (Test-Path $RegPath) {
            Get-ItemProperty -Path $RegPath | Select-Object EnableScriptBlockLogging
        } else {
            [PSCustomObject]@{ EnableScriptBlockLogging = "NOT CONFIGURED" }
        }
    }
    
    if ($PSLogging.EnableScriptBlockLogging -eq 1) {
        Write-Host "✓ $Computer : PowerShell logging AKTIVERT" -ForegroundColor Green
    } else {
        Write-Host "✗ $Computer : PowerShell logging IKKE aktivert" -ForegroundColor Red
    }
}
```

```powershell
✗ dc1 : PowerShell logging AKTIVERT
✓ srv1 : PowerShell logging AKTIVERT
✓ cl1 : PowerShell logging AKTIVERT
```

---

#### Test 3: Er Windows Defender real-time protection aktivert?

```powershell
$Computers = @('dc1', 'srv1', 'cl1')

foreach ($Computer in $Computers) {
    $DefenderStatus = Invoke-Command -ComputerName "$Computer.infrait.sec" -ScriptBlock {
        Get-MpPreference | Select-Object DisableRealtimeMonitoring, DisableBehaviorMonitoring
    }
    
    if ($DefenderStatus.DisableRealtimeMonitoring -eq $false) {
        Write-Host "✓ $Computer : Defender Real-time Protection AKTIVERT" -ForegroundColor Green
    } else {
        Write-Host "✗ $Computer : Defender Real-time Protection DEAKTIVERT" -ForegroundColor Red
    }
}
```

---

#### Test 4: Sjekk Audit Policies

```powershell
# Advanced Audit Policies er kritisk for å oppdage innbrudd
Invoke-Command -ComputerName dc1.infrait.sec -ScriptBlock {
    # Sjekk kritiske audit kategorier
    auditpol /get /category:"Logon/Logoff" | Select-String "Success and Failure"
    auditpol /get /category:"Account Logon" | Select-String "Success and Failure"
}
```

**Forventet:** Success and Failure logging for kritiske events.

---

## Del 5: Custom Hardening Utover Baselines

Baselines dekker mye, men noen ting må du konfigurere selv basert på ditt miljø.

### Steg 5.1: Opprett Custom Hardening GPO

```powershell
# Opprett ny GPO for custom hardening
New-GPO -Name "Corporate - Custom Security Settings" -Comment "Additional hardening beyond Microsoft baselines"

# Link til domenet (lavere prioritet enn baselines)
New-GPLink -Name "Corporate - Custom Security Settings" `
           -Target "DC=infrait,DC=sec" `
           -LinkEnabled Yes
```
![alt text](EditCustomCorpGPO.png)

### Steg 5.2: Konfigurer Additional Hardening

I GPMC, edit `Corporate - Custom Security Settings`:

#### A) Deaktiver Legacy Protocols (eksempel)

**Computer Configuration → Policies → Windows Settings → Security Settings → Local Policies → Security Options**

```
Network security: LAN Manager authentication level
→ Send NTLMv2 response only. Refuse LM & NTLM

Network security: Minimum session security for NTLM SSP
→ Require NTLMv2 session security + Require 128-bit encryption
```
![alt text](LanManagerVisual.png)

**Hvorfor?** LM og NTLM er gammelt og lett å cracke. NTLMv2 er minimum for sikkerhet.

---

#### B) BONUSOPPGAVE: Disable NetBIOS over TCP/IP

Dette krever PowerShell-script via GPO startup:

**Computer Configuration → Policies → Windows Settings → Scripts → Startup**

Legg til script: `C:\Windows\SYSVOL\domain\scripts\Disable-NetBIOS.ps1`

**Script innhold:**

```powershell
# Disable NetBIOS på alle nettverksadaptere
Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled=TRUE" | ForEach-Object {
    $_.SetTcpipNetbios(2)  # 2 = Disable NetBIOS
}
```

**Hvorfor?** NetBIOS er legacy protocol som kan brukes i angrep (LLMNR/NetBIOS poisoning).

---

#### C) Windows Defender ASR Rules (Attack Surface Reduction)

**Computer Configuration → Policies → Administrative Templates → Windows Components → Microsoft Defender Antivirus → Microsoft Defender Exploit Guard → Attack Surface Reduction**

Aktiver følgende ASR rules:

```
Enable Attack Surface Reduction rules: Enabled

ASR Rules (sett til "Block"):
- Block executable content from email client and webmail
- Block Office applications from creating child processes
- Block Office applications from injecting into other processes
- Block credential stealing from LSASS (lsass.exe)
- Block untrusted and unsigned processes from USB
```
1. Dobbeltklikk "Configure Attack Surface Reduction rules"
2. Velg "Enabled"
3. Klikk "Show..." under Options

4. Legg til disse GUID-ene (Name = GUID, Value = 1):
```

**GUID-er å legge til:**

| Name (GUID) | Value | Beskrivelse |
|-------------|-------|-------------|
| `BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550` | `1` | Block executable from email |
| `D4F940AB-401B-4EFC-AADC-AD5F3C50688A` | `1` | Block Office child processes |
| `75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84` | `1` | Block Office injection |
| `9E6C4E1F-7D60-472F-BA1A-A39EF669E4B2` | `1` | Block LSASS credential theft |
| `B2B3F03D-6A65-4F7B-A9C7-1C7EF74A9BA4` | `1` | Block untrusted USB processes |

**Value:**
- `1` = Block
- `0` = Disabled  
- `2` = Audit only

**Klikk OK → OK**


**Hvorfor?** ASR rules blokkerer vanlige angrepsmetoder som malware bruker.

---

#### D) Enable Windows Firewall Logging

**Computer Configuration → Policies → Windows Settings → Security Settings → Windows Defender Firewall with Advanced Security**

For hver profil (Domain, Private, Public):

```
Firewall state: On
Inbound connections: Block (default)
Outbound connections: Allow (default)

Logging:
- Log dropped packets: Yes
- Log successful connections: Yes
- Log file path: %SystemRoot%\System32\LogFiles\Firewall\pfirewall.log
- Size limit: 16384 KB
```

---

### Steg 5.3: Deploy Custom Hardening

```powershell
# Tving GPO oppdatering
gpupdate /force /target:computer

# Verifiser at custom GPO er applisert
gpresult /r | Select-String "Corporate - Custom Security Settings"
```
---

### Scenario 2: SMB Relay Attack Test

**Test om SMB signing er konfigurert:**

```powershell
# Sjekk SMB signing settings
Invoke-Command -ComputerName srv1.infrait.sec -ScriptBlock {
    Get-SmbServerConfiguration | Select-Object RequireSecuritySignature, EnableSecuritySignature
}
```

Dette ser forvirrende ut ved første øyekast, men er faktisk korrekt og sikker konfigurasjon.

```
RequireSecuritySignature : True   ← KREVET
EnableSecuritySignature  : False  ← Ikke "enabled"???
```
Realitet: Dette er perfekt sikker konfigurasjon fra Microsoft Baseline!
Hvorfor Enable=False når Require=True?
Forklaring:
Når `RequireSecuritySignature = True`:

Serveren KREVER at ALL SMB-trafikk er signert
`EnableSecuritySignature` blir irrelevant (har ingen effekt)
Signing er ALLTID PÅ uavhengig av "Enable" setting

**Hvis True:** SMB relay attacks er blokkert.

---

### Scenario 3: PowerShell Execution Monitoring

**Test at Script Block Logging fungerer:**

```powershell
# Kjør et PowerShell-script på cl1
Invoke-Command -ComputerName cl1.infrait.sec -ScriptBlock {
    # Dette skal logges i Event Log
    Write-Host "Testing PowerShell logging"
    Get-Process | Select-Object -First 5
}

# Sjekk at script ble logget
Invoke-Command -ComputerName cl1.infrait.sec -ScriptBlock {
    Get-WinEvent -LogName "Microsoft-Windows-PowerShell/Operational" -FilterXPath "*[System[EventID=4104]]" -MaxEvents 5 |
        Select-Object TimeCreated, Message
}
```

**Forventet:** Event ID 4104 viser hele scriptet som ble kjørt.

```
Testing PowerShell logging

 NPM(K)    PM(M)      WS(M)     CPU(s)      Id  SI ProcessName                                  PSComputerName
 ------    -----      -----     ------      --  -- -----------                                  --------------
      9     1.64       9.90       0.25    5056   0 AggregatorHost                               cl1.infrait.sec
     20     1.91       5.78       1.47     556   0 csrss                                        cl1.infrait.sec
     11     1.68       6.01       1.67     636   1 csrss                                        cl1.infrait.sec
     25    18.71      54.81       7.92     800   1 dwm                                          cl1.infrait.sec
      7     1.46       4.66       0.12     948   0 fontdrvhost                                  cl1.infrait.sec
```

```
TimeCreated    : 2/9/2026 12:47:55 PM
Message        : Creating Scriptblock text (1 of 1):

                     # Dette skal logges i Event Log
                     Write-Host "Testing PowerShell logging"
                     Get-Process | Select-Object -First 5


                 ScriptBlock ID: f82e796f-55ec-4c22-ae42-67b7fd4183af
                 Path:
PSComputerName : cl1.infrait.sec
RunspaceId     : afd21550-cc6f-4256-84f4-8fc83139c056
```

---

## Troubleshooting

### Problem 1: Import-GPO feiler med "Access Denied"

**Symptom:**
```
Import-GPO : Access is denied
```

**Årsak:** Du har ikke Domain Admin rettigheter.

**Løsning:**
```powershell
# Verifiser group membership
whoami /groups | Select-String "Domain Admins"

# Hvis ikke medlem, legg til:
Add-ADGroupMember -Identity "Domain Admins" -Members "adm_<brukernavn>"

# Logg ut og inn igjen for at membership skal tre i kraft
```

---

### Problem 2: Baseline gjør at applikasjoner slutter å fungere

**Symptom:** Etter baseline-implementering fungerer ikke en legacy applikasjon.

**Diagnose:**

```powershell
# Generer detaljert GPResult
gpresult /h C:\GPOReport.html

# Åpne i browser og se hvilke settings som er endret
Start-Process C:\GPOReport.html
```

**Løsning:**

1. **Identifiser problematisk setting** i dokumentasjonen
2. **Opprett Security Filtering eller WMI Filter** for å ekskludere maskiner som trenger legacy-funksjonalitet
3. **Eller:** Opprett en separat GPO som overstyrer kun den spesifikke settingen

**Eksempel:** Hvis legacy app trenger SMBv1:

```powershell
# Opprett GPO som re-enabler SMBv1 (UNNGÅ DETTE!)
New-GPO -Name "Exception - Legacy App Server"

# Edit GPO manuelt og enable SMBv1
# Link kun til serveren som trenger det
```

**Bedre løsning:** Oppgrader applikasjonen!

---

## Refleksjonsspørsmål

1. **Hva er forskjellen mellom "Member Server" og "Domain Controller" baselines?**
   - Hvorfor kan du ikke bruke samme baseline for begge?
   - Hva skjer hvis du linker feil baseline til feil maskintype?

2. **Hvorfor er SMBv1 så farlig at Microsoft disable-r det i baselines?**
   - Hvilke angrep bruker SMBv1?
   - Hva er trade-off ved å disable SMBv1?

3. **Hvorfor er PowerShell Script Block Logging viktig?**
   - Hva kan en angriper gjøre uten logging?
   - Hva er ytelsespåvirkningen av å logge ALT PowerShell kjører?

4. **Når ville du IKKE implementert Microsoft Security Baselines?**
   - Gi eksempler på miljøer hvor baselines er for restriktive
   - Hvordan kan du tilpasse baselines til ditt miljø?

5. **Hva er "Defense in Depth" og hvordan implementerer baselines dette?**
   - Gi eksempler på multiple lag av sikkerhet fra baselines
   - Hva skjer hvis ett lag feiler?


---

## Oppsummering

Du har nå lært:
- ✅ Hva Microsoft Security Compliance Toolkit er og hvorfor det er viktig
- ✅ Hvordan laste ned, installere og analysere security baselines
- ✅ Importere og implementere baselines via Group Policy
- ✅ Verifisere at hardening er korrekt applisert via PowerShell
- ✅ Utvide baselines med custom security settings
- ✅ Feilsøke vanlige problemer med security baselines

**Dette er fundamentet for enterprise infrastructure hardening!**

---

## Neste Steg

1. **Kombiner med Windows Update Management** (forrige lab)
2. **Implementer Centralized Logging** (Windows Event Forwarding)
3. **Deploy LAPS** (Local Administrator Password Solution)
4. **Configure Just-In-Time Admin Access**

**Du har nå bygget en robust, hardened enterprise infrastruktur! 🎉**

---

## Referanser

- [Microsoft Security Compliance Toolkit Download](https://www.microsoft.com/en-us/download/details.aspx?id=55319)
- [Windows Security Baselines Documentation](https://learn.microsoft.com/en-us/windows/security/operating-system-security/device-management/windows-security-configuration-framework/windows-security-baselines)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks)
- [DISA STIGs](https://public.cyber.mil/stigs/)
- [NSA Cybersecurity Guidance](https://www.nsa.gov/Press-Room/Cybersecurity-Advisories-Guidance/)