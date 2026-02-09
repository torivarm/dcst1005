# Lab: Windows Admin Center og OSConfig - Moderne Domene-administrasjon

## Læringsmål
Etter denne laben skal du kunne:
- Installere og konfigurere Windows Admin Center (WAC) (om ikke alt installert i tidligere gjennomgang)
- Administrere domene-maskiner via web-basert GUI
- Forstå forskjellen mellom tradisjonell (GPO) og moderne (OSConfig) administrasjon
- Implementere configuration management med OSConfig
- Evaluere når du skal bruke GPO vs OSConfig vs hybrid approach

---

## Forutsetninger

**Lab-miljø:**
- **mgr.infrait.sec** - IT Admin workstation (Windows 11)
- **dc1.infrait.sec** - Domain Controller (Windows Server 2025)
- **srv1.infrait.sec** - Member Server (Windows Server 2025)
- **cl1.infrait.sec** - Client workstation (Windows 11)

**Påkrevd:**
- Innlogget som `adm_<brukernavn>` med Domain Admin rettigheter

---

## Teorigrunnlag

### Hva er Windows Admin Center?

**Windows Admin Center (WAC)** er Microsofts moderne, web-baserte administrasjonsverktøy for Windows Server og Windows 10/11.

**Erstatter:**
- ❌ Server Manager (GUI)
- ❌ MMC snap-ins (spredt over mange verktøy)
- ❌ Remote Desktop for server-administrasjon

**Fordeler:**
- ✅ **Web-basert** - Tilgang fra enhver moderne browser
- ✅ **Sentralisert** - Én konsoll for alle servere
- ✅ **Modern UI** - Rask, responsiv, intuitive
- ✅ **Sikker** - HTTPS, certificate-based authentication
- ✅ **Extensible** - Supports extensions/plugins

---

### Hva er OSConfig?

**OSConfig (OS Configuration)** er Microsofts **nye generasjon configuration management** for Windows.

**Moderne alternativ til:**
- Group Policy (GPO) - 1990-tallet teknologi
- PowerShell DSC - Kompleks, tungrodd

**OSConfig kjennetegn:**
- 📄 **Deklarativ** - Beskriv ønsket tilstand, ikke hvordan
- 🔄 **Continuous enforcement** - Automatisk drift correction
- 🌐 **Cloud-native** - Integrert med Azure Arc
- 📊 **JSON/YAML-basert** - DevOps-friendly configuration
- 🔍 **Built-in compliance** - Reporting og drift detection

---

### Group Policy vs OSConfig - Når skal du bruke hva?

| Scenario | Best Choice | Hvorfor |
|----------|-------------|---------|
| **Etablert enterprise med AD** | GPO | Mature, støttet overalt, mange policies |
| **Hybrid/Cloud environment** | OSConfig | Cloud-native, Azure Arc integration |
| **DevOps/Infrastructure as Code** | OSConfig | Version control, automated deployment |
| **Security baselines** | GPO | Microsoft baselines er GPO-basert |
| **Modern workloads (containers, etc.)** | OSConfig | Designed for modern infrastructure |
| **Legacy compatibility** | GPO | OSConfig krever nyere OS-versjoner |

**Beste praksis:** **Hybrid approach** - Bruk begge!
- GPO for domain-wide policies og security baselines
- OSConfig for granular, modern configuration management

---

## Del 1: Installer Windows Admin Center

### Steg 1.1: Last ned Windows Admin Center

På **mgr.infrait.sec**:
- https://go.microsoft.com/fwlink/?linkid=2220149&clcid=0x409&culture=en-us&country=us
- Kjør filen WindowsAdminCenter2511.exe i mappen Downloads
    - Velg følgende i Wizarden:
      - Accept these therms.....
      - Express setup
      - Generate a self-signed certificate
      - Install updates automatically
      - next, next, next....Install
```
Select installation mode
      Express setup

Login Authentication/Authorization Selection
      HTML Form Login

Network access
      Localhost access only

Port Numbers
      External Port:      6600
      Internal Port Range Start (Inclusive):      6601
      Internal Port Range End (Exclusive):      6610

Select TLS certificate
      Generate a self-signed certificate (expires in 60 days)

Fully qualified domain name
      mgr-new.InfraIT.sec

Trusted Hosts 
      Allow access to any computer

WinRM over HTTPS
      HTTP. Default communication mechanism.

Automatic updates
      Install updates automatically (recommended)

Send diagnostic data to Microsoft
      Required diagnostic data

Log File
      C:\Users\ADM_ME~1\AppData\Local\Temp\Setup Log 2026-02-09 #001.txt
```
![alt text](WAC-Done.png)

---

### Steg 1.3: Verifiser Installasjon og Åpne WAC

**Ved første åpning:**

1. **Certificate Warning** → Klikk "Advanced" → "Continue to localhost (unsafe)"
2. **Windows Security prompt** → Autentiser med `infrait\adm_<brukernavn>`
![alt text](WarningWAC.png)
![alt text](WarningWAC2.png)

---

## Del 2: Legg til Domene-maskiner i Windows Admin Center

### Steg 2.1: Manuell Metode - Legg til Enkeltmaskiner

**I Windows Admin Center:**

1. Klikk **"+ Add"** øverst til venstre
2. Velg **"Servers"**
3. Velg Search Active Directory
4. Huk av for DC1 og SRV1
5. Klikk **"Add"**
6. For `cl1.infrait.sec` velger en `Windows PCs` i stedet for `Servers`

![alt text](SearchADServer.png)
![alt text](MachinesImported.png)

**Forventet resultat:**
```
All Connections:
  ✓ dc1.infrait.sec (Windows Server 2025)
  ✓ srv1.infrait.sec (Windows Server 2025)
  ✓ cl1.infrait.sec (Windows 11)
  ✓ mgr.infrait.sec (Windows 11) - Local
```


---

### Steg 2.3: Verifiser Tilkobling til Maskiner

**I Windows Admin Center:**

1. Klikk på **dc1.infrait.sec** i connection listen
2. WAC vil koble til serveren og vise dashboard
3. Verifiser at du ser:
   - **Overview** - CPU, Memory, Disk usage
   - **Tools menu** - Events, Performance, Processes, etc.

Installer Active Directory for å få tilgang til Users And Computers i Web GUI:
![alt text](ADUnCWebGUI.png)

Etterpå vil du kunne se AD Users and Computers i Web GUI:
![alt text](WebGUIADunc.png)

---

## Del 3: Utforsk Windows Admin Center

### Steg 3.1: Kjør Basic Server Management Tasks

**Oppgave:** Utforsk hver maskin og kjør vanlige admin-oppgaver.

#### Task 1: Sjekk System Health på SRV1

1. I WAC, koble til **srv1.infrait.sec**
2. Gå til **Overview**
3. Observer:
   - CPU utilization
   - Memory usage
   - Disk space
   - Network activity

**Sammenlign med tradisjonell metode:**
```powershell
# Tradisjonell måte (PowerShell Remoting)
Invoke-Command -ComputerName srv1.infrait.sec -ScriptBlock {
    Get-CimInstance Win32_Processor | Select-Object LoadPercentage
    Get-CimInstance Win32_OperatingSystem | Select-Object @{
        Name='MemoryUsagePercent'
        Expression={[math]::Round((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory) / $_.TotalVisibleMemorySize) * 100, 2)}
    }
    Get-PSDrive C | Select-Object Used, Free
}
```

**Refleksjon:** Hva er enklere? GUI eller PowerShell?

---

#### Task 3: Sjekk Event Logs

1. Gå til **Events**
2. Filtrer på:
   - **Log:** System
   - **Level:** Error, Warning
   - **Time range:** Last 24 hours

3. Klikk på et event for detaljer

**Sammenlign med:**
```powershell
# Tradisjonell måte
Get-WinEvent -ComputerName srv1.infrait.sec -FilterHashtable @{
    LogName = 'System'
    Level = 2,3  # Error, Warning
    StartTime = (Get-Date).AddDays(-1)
} -MaxEvents 50
```

---

#### Task 4: Performance Monitoring

1. Gå til **Performance Monitor**
2. Legg til counters:
   - Processor: % Processor Time
   - Memory: Available MBytes
   - Network Interface: Bytes Total/sec

3. Observer real-time performance

---

## Del 4: Introduksjon til OSConfig

### Steg 4.1: Hva er OSConfig og Hvorfor Bruke Det?

**OSConfig** (OS Configuration) er Microsofts moderne configuration engine.

```powershell
Write-Host @"

╔══════════════════════════════════════════════════════════════╗
║                    OSCONFIG OVERVIEW                         ║
╚══════════════════════════════════════════════════════════════╝

TRADISJONELL APPROACH (Group Policy):
  ┌─────────────┐
  │ GPMC Editor │ → GPO → Registry/Files
  └─────────────┘
  
  Problemer:
    ✗ Ikke cloud-native
    ✗ Complex troubleshooting
    ✗ Ingen native version control
    ✗ Krever domain membership

MODERNE APPROACH (OSConfig):
  ┌──────────────┐
  │ JSON/YAML    │ → OSConfig Agent → Desired State
  │ Config File  │
  └──────────────┘
  
  Fordeler:
    ✓ Deklarativ configuration
    ✓ Version control (Git)
    ✓ Cloud og on-prem
    ✓ Continuous compliance enforcement
    ✓ Works with or without domain

"@ -ForegroundColor Cyan
```

---

### Steg 4.2: Installer OSConfig på Domene-maskiner

OSConfig er **innebygd** i Windows Server 2025 og Windows 11 24H2+, men må aktiveres.

```powershell
Write-Host "`n=== Aktivering av OSConfig på Domene-maskiner ===" -ForegroundColor Cyan

$Computers = @('dc1', 'srv1', 'cl1')

foreach ($Computer in $Computers) {
    Write-Host "`nAktiverer OSConfig på $Computer.infrait.sec..." -ForegroundColor Yellow
    
    Invoke-Command -ComputerName "$Computer.infrait.sec" -ScriptBlock {
        
        # Sjekk om OSConfig er installert
        $OSConfigPath = "C:\Program Files\OSConfig"
        
        if (Test-Path $OSConfigPath) {
            Write-Host "  ✓ OSConfig allerede installert" -ForegroundColor Green
        } else {
            Write-Host "  ℹ OSConfig installeres automatisk med Windows Server 2025/Win11 24H2" -ForegroundColor Cyan
            Write-Host "  ℹ Hvis ikke tilgjengelig, kan det installeres via:" -ForegroundColor Gray
            Write-Host "    - Windows Optional Features" -ForegroundColor Gray
            Write-Host "    - Azure Connected Machine agent (Azure Arc)" -ForegroundColor Gray
        }
        
        # Aktiver og start OSConfig service
        try {
            $OSConfigService = Get-Service -Name "OSConfigAgent" -ErrorAction SilentlyContinue
            
            if ($OSConfigService) {
                if ($OSConfigService.StartType -ne 'Automatic') {
                    Set-Service -Name "OSConfigAgent" -StartupType Automatic
                    Write-Host "  ✓ OSConfig service satt til Automatic" -ForegroundColor Green
                }
                
                if ($OSConfigService.Status -ne 'Running') {
                    Start-Service -Name "OSConfigAgent"
                    Write-Host "  ✓ OSConfig service startet" -ForegroundColor Green
                }
                
                Write-Host "  ✓ OSConfig er aktivt på $env:COMPUTERNAME" -ForegroundColor Green
            } else {
                Write-Host "  ⚠ OSConfig service ikke funnet" -ForegroundColor Yellow
                Write-Host "  Dette er normalt hvis OS-versjonen ikke støtter OSConfig ennå" -ForegroundColor Gray
            }
            
        } catch {
            Write-Host "  ⚠ Kunne ikke aktivere OSConfig: $_" -ForegroundColor Yellow
        }
    }
}
```

**Merk:** Hvis OSConfig ikke er tilgjengelig på dine maskiner (eldre OS-versjoner), kan du fortsatt følge konseptene - det viktige er å forstå **hvordan moderne configuration management fungerer**.

---

### Steg 4.3: Opprett din Første OSConfig Configuration

OSConfig bruker **JSON eller YAML** filer for å definere desired state.

**Eksempel: Konfigurer PowerShell Logging via OSConfig**

```powershell
Write-Host "`n=== Opprett OSConfig Configuration ===" -ForegroundColor Cyan

# Opprett config directory
$ConfigPath = "C:\OSConfig\Configurations"
New-Item -Path $ConfigPath -ItemType Directory -Force | Out-Null

# Definer configuration i JSON
$ConfigJSON = @"
{
  "name": "PowerShellLoggingConfig",
  "version": "1.0",
  "description": "Enable PowerShell Script Block Logging for security monitoring",
  "modules": [
    {
      "name": "Registry",
      "settings": {
        "registryValues": [
          {
            "keyPath": "HKLM\\Software\\Policies\\Microsoft\\Windows\\PowerShell\\ScriptBlockLogging",
            "valueName": "EnableScriptBlockLogging",
            "valueType": "DWord",
            "valueData": 1,
            "ensure": "Present"
          },
          {
            "keyPath": "HKLM\\Software\\Policies\\Microsoft\\Windows\\PowerShell\\ScriptBlockLogging",
            "valueName": "EnableScriptBlockInvocationLogging",
            "valueType": "DWord",
            "valueData": 1,
            "ensure": "Present"
          }
        ]
      }
    }
  ]
}
"@

# Lagre configuration
$ConfigFile = "$ConfigPath\PowerShellLogging.json"
$ConfigJSON | Out-File -FilePath $ConfigFile -Encoding UTF8

Write-Host "✓ Configuration opprettet: $ConfigFile" -ForegroundColor Green

# Vis innhold
Write-Host "`nConfiguration innhold:" -ForegroundColor Cyan
Get-Content $ConfigFile | Write-Host -ForegroundColor White
```

---

### Steg 4.4: Deploy OSConfig Configuration til Maskiner

```powershell
Write-Host "`n=== Deploy OSConfig Configuration ===" -ForegroundColor Cyan

$Computers = @('srv1')  # Test på én maskin først

foreach ($Computer in $Computers) {
    Write-Host "`nDeploying configuration til $Computer.infrait.sec..." -ForegroundColor Yellow
    
    # Kopier config file til target maskin
    $RemoteConfigPath = "\\$Computer.infrait.sec\C$\OSConfig\Configurations"
    
    if (-not (Test-Path $RemoteConfigPath)) {
        New-Item -Path $RemoteConfigPath -ItemType Directory -Force | Out-Null
    }
    
    Copy-Item -Path $ConfigFile -Destination $RemoteConfigPath -Force
    
    Write-Host "  ✓ Configuration file kopiert" -ForegroundColor Green
    
    # Apply configuration via OSConfig
    Invoke-Command -ComputerName "$Computer.infrait.sec" -ScriptBlock {
        param($ConfigFilePath)
        
        # Merk: OSConfig kommandoer kan variere avhengig av versjon
        # Dette er konseptuelt eksempel
        
        try {
            # Metode 1: Via osconfig.exe CLI (hvis tilgjengelig)
            $OSConfigExe = "C:\Program Files\OSConfig\osconfig.exe"
            
            if (Test-Path $OSConfigExe) {
                & $OSConfigExe apply --config $ConfigFilePath
                Write-Host "  ✓ Configuration applied via osconfig.exe" -ForegroundColor Green
            } else {
                # Metode 2: Manuell application (for demo purposes)
                Write-Host "  ℹ OSConfig CLI ikke funnet, applying manuelt..." -ForegroundColor Cyan
                
                # Les config
                $Config = Get-Content $ConfigFilePath | ConvertFrom-Json
                
                # Apply registry settings
                foreach ($Module in $Config.modules) {
                    if ($Module.name -eq 'Registry') {
                        foreach ($RegValue in $Module.settings.registryValues) {
                            $KeyPath = $RegValue.keyPath -replace '\\\\', '\'
                            
                            # Opprett nøkkel hvis den ikke eksisterer
                            if (-not (Test-Path $KeyPath)) {
                                New-Item -Path $KeyPath -Force | Out-Null
                            }
                            
                            # Sett verdi
                            Set-ItemProperty -Path $KeyPath `
                                           -Name $RegValue.valueName `
                                           -Value $RegValue.valueData `
                                           -Type $RegValue.valueType `
                                           -Force
                            
                            Write-Host "    ✓ Set $KeyPath\$($RegValue.valueName) = $($RegValue.valueData)" -ForegroundColor Gray
                        }
                    }
                }
                
                Write-Host "  ✓ Configuration applied manuelt" -ForegroundColor Green
            }
            
        } catch {
            Write-Host "  ✗ Feil ved application: $_" -ForegroundColor Red
        }
        
    } -ArgumentList "C:\OSConfig\Configurations\PowerShellLogging.json"
}
```

---

### Steg 4.5: Verifiser at OSConfig Configuration Ble Applisert

```powershell
Write-Host "`n=== Verifiser OSConfig Application ===" -ForegroundColor Cyan

$Computer = 'srv1'

Write-Host "Sjekker PowerShell logging på $Computer.infrait.sec..." -ForegroundColor Yellow

$Result = Invoke-Command -ComputerName "$Computer.infrait.sec" -ScriptBlock {
    $RegPath = 'HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging'
    
    if (Test-Path $RegPath) {
        Get-ItemProperty -Path $RegPath | Select-Object `
            EnableScriptBlockLogging,
            EnableScriptBlockInvocationLogging
    } else {
        "Registry path not found"
    }
}

if ($Result.EnableScriptBlockLogging -eq 1) {
    Write-Host "✓ PowerShell Script Block Logging: ENABLED" -ForegroundColor Green
} else {
    Write-Host "✗ PowerShell Script Block Logging: NOT ENABLED" -ForegroundColor Red
}

if ($Result.EnableScriptBlockInvocationLogging -eq 1) {
    Write-Host "✓ PowerShell Invocation Logging: ENABLED" -ForegroundColor Green
} else {
    Write-Host "- PowerShell Invocation Logging: Not enabled" -ForegroundColor Gray
}

Write-Host @"

╔══════════════════════════════════════════════════════════════╗
║                  OSCONFIG SUCCESS!                           ║
╚══════════════════════════════════════════════════════════════╝

Configuration ble deployed via:
  ✓ Deklarativ JSON configuration file
  ✓ OSConfig engine
  ✓ Uten Group Policy!

Fordeler:
  ✓ Version control (kan lagres i Git)
  ✓ Infrastructure as Code
  ✓ Enklere testing og deployment
  ✓ Fungerer uten domain (også cloud VMs)

"@ -ForegroundColor Cyan
```

---

## Del 5: Avansert OSConfig - Domene-bred Deployment

### Steg 5.1: Opprett Mer Komplekse Configurations

**Eksempel: Multi-Setting Security Configuration**

```powershell
Write-Host "`n=== Avansert OSConfig: Security Hardening ===" -ForegroundColor Cyan

$AdvancedConfig = @"
{
  "name": "SecurityHardeningBaseline",
  "version": "2.0",
  "description": "Comprehensive security hardening for Windows servers",
  "modules": [
    {
      "name": "Registry",
      "settings": {
        "registryValues": [
          {
            "keyPath": "HKLM\\Software\\Policies\\Microsoft\\Windows\\PowerShell\\ScriptBlockLogging",
            "valueName": "EnableScriptBlockLogging",
            "valueType": "DWord",
            "valueData": 1,
            "ensure": "Present"
          },
          {
            "keyPath": "HKLM\\SYSTEM\\CurrentControlSet\\Services\\LanmanServer\\Parameters",
            "valueName": "RequireSecuritySignature",
            "valueType": "DWord",
            "valueData": 1,
            "ensure": "Present"
          },
          {
            "keyPath": "HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU",
            "valueName": "NoAutoRebootWithLoggedOnUsers",
            "valueType": "DWord",
            "valueData": 0,
            "ensure": "Present"
          }
        ]
      }
    },
    {
      "name": "Services",
      "settings": {
        "services": [
          {
            "name": "Spooler",
            "startupType": "Disabled",
            "ensure": "Present"
          },
          {
            "name": "RemoteRegistry",
            "startupType": "Disabled",
            "ensure": "Present"
          }
        ]
      }
    },
    {
      "name": "WindowsFeatures",
      "settings": {
        "features": [
          {
            "name": "SMB1Protocol",
            "ensure": "Absent"
          }
        ]
      }
    }
  ]
}
"@

$AdvancedConfigFile = "C:\OSConfig\Configurations\SecurityHardening.json"
$AdvancedConfig | Out-File -FilePath $AdvancedConfigFile -Encoding UTF8

Write-Host "✓ Advanced configuration created: $AdvancedConfigFile" -ForegroundColor Green
```

---

### Steg 5.2: Deploy til Alle Servere Samtidig

```powershell
Write-Host "`n=== Mass Deployment til Alle Servere ===" -ForegroundColor Cyan

$Servers = @('dc1', 'srv1')  # Alle servers i domenet

foreach ($Server in $Servers) {
    Write-Host "`nDeploying til $Server.infrait.sec..." -ForegroundColor Yellow
    
    # Kopier config
    $RemotePath = "\\$Server.infrait.sec\C$\OSConfig\Configurations"
    Copy-Item -Path $AdvancedConfigFile -Destination $RemotePath -Force
    
    # Apply configuration
    Invoke-Command -ComputerName "$Server.infrait.sec" -ScriptBlock {
        param($ConfigFile)
        
        Write-Host "  Applying security hardening configuration..." -ForegroundColor Cyan
        
        # Simulert OSConfig apply (actual implementation vil variere)
        $Config = Get-Content $ConfigFile | ConvertFrom-Json
        
        # Apply registry settings
        foreach ($Module in $Config.modules) {
            if ($Module.name -eq 'Registry') {
                foreach ($RegValue in $Module.settings.registryValues) {
                    $KeyPath = $RegValue.keyPath -replace '\\\\', '\'
                    
                    if (-not (Test-Path $KeyPath)) {
                        New-Item -Path $KeyPath -Force | Out-Null
                    }
                    
                    Set-ItemProperty -Path $KeyPath `
                                   -Name $RegValue.valueName `
                                   -Value $RegValue.valueData `
                                   -Type $RegValue.valueType `
                                   -Force
                }
            }
            
            # Apply service settings
            if ($Module.name -eq 'Services') {
                foreach ($Svc in $Module.settings.services) {
                    try {
                        Set-Service -Name $Svc.name -StartupType $Svc.startupType -ErrorAction Stop
                        Write-Host "    ✓ Service $($Svc.name) set to $($Svc.startupType)" -ForegroundColor Gray
                    } catch {
                        Write-Host "    ⚠ Could not configure service $($Svc.name): $_" -ForegroundColor Yellow
                    }
                }
            }
        }
        
        Write-Host "  ✓ Configuration applied on $env:COMPUTERNAME" -ForegroundColor Green
        
    } -ArgumentList "C:\OSConfig\Configurations\SecurityHardening.json"
}

Write-Host "`n✓ Mass deployment completed!" -ForegroundColor Green
```

---

### Steg 5.3: Compliance Verification

```powershell
Write-Host "`n=== OSConfig Compliance Verification ===" -ForegroundColor Cyan

$Servers = @('dc1', 'srv1')

$ComplianceReport = foreach ($Server in $Servers) {
    Write-Host "Checking compliance on $Server.infrait.sec..." -ForegroundColor Yellow
    
    $Compliance = Invoke-Command -ComputerName "$Server.infrait.sec" -ScriptBlock {
        
        $Results = @{
            Server = $env:COMPUTERNAME
            Checks = @{}
        }
        
        # Check PowerShell Logging
        $PSLoggingPath = 'HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging'
        if (Test-Path $PSLoggingPath) {
            $PSLogging = Get-ItemProperty -Path $PSLoggingPath
            $Results.Checks['PowerShell Logging'] = ($PSLogging.EnableScriptBlockLogging -eq 1)
        } else {
            $Results.Checks['PowerShell Logging'] = $false
        }
        
        # Check SMB Signing
        $SMBConfig = Get-SmbServerConfiguration
        $Results.Checks['SMB Signing'] = ($SMBConfig.RequireSecuritySignature -eq $true)
        
        # Check Print Spooler
        $Spooler = Get-Service -Name Spooler
        $Results.Checks['Print Spooler Disabled'] = ($Spooler.StartType -eq 'Disabled')
        
        # Check RemoteRegistry
        $RemoteReg = Get-Service -Name RemoteRegistry
        $Results.Checks['RemoteRegistry Disabled'] = ($RemoteReg.StartType -eq 'Disabled')
        
        return $Results
    }
    
    $Compliance
}

# Generate compliance report
Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║              OSCONFIG COMPLIANCE REPORT                      ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta

foreach ($ServerCompliance in $ComplianceReport) {
    Write-Host "`n$($ServerCompliance.Server):" -ForegroundColor Cyan
    
    $CompliantCount = 0
    $TotalChecks = $ServerCompliance.Checks.Count
    
    foreach ($Check in $ServerCompliance.Checks.Keys) {
        $Status = $ServerCompliance.Checks[$Check]
        
        if ($Status) {
            Write-Host "  ✓ $Check" -ForegroundColor Green
            $CompliantCount++
        } else {
            Write-Host "  ✗ $Check" -ForegroundColor Red
        }
    }
    
    $CompliancePercentage = [math]::Round(($CompliantCount / $TotalChecks) * 100)
    Write-Host "`n  Compliance Score: $CompliantCount/$TotalChecks ($CompliancePercentage%)" -ForegroundColor $(
        if ($CompliancePercentage -eq 100) { 'Green' }
        elseif ($CompliancePercentage -ge 75) { 'Yellow' }
        else { 'Red' }
    )
}
```

---

## Del 6: Windows Admin Center + OSConfig Integration

### Steg 6.1: Administrer OSConfig via WAC

**I Windows Admin Center:**

1. Koble til **srv1.infrait.sec**
2. Gå til **Settings** (nederst i venstremenyen)
3. Under **Configuration Management**, sjekk om OSConfig er tilgjengelig

**Merk:** Full OSConfig integration i WAC kan variere avhengig av versjon.

---

### Steg 6.2: Alternativer - Azure Arc for Cloud Management

Hvis du vil ta dette til neste nivå:

```powershell
Write-Host @"

╔══════════════════════════════════════════════════════════════╗
║           NEXT LEVEL: AZURE ARC INTEGRATION                  ║
╚══════════════════════════════════════════════════════════════╝

OSConfig + Azure Arc = Cloud-native Configuration Management

Med Azure Arc kan du:
  ✓ Manage on-prem servers fra Azure Portal
  ✓ Deploy OSConfig via Azure Policy
  ✓ Centralized compliance dashboard
  ✓ Integration med Azure Security Center
  ✓ Hybrid cloud management

Installation (krever Azure subscription):
  
  1. Install Azure Connected Machine agent:
     azcmagent connect --tenant-id <id> --subscription-id <id>
  
  2. Deploy configurations via Azure Policy
  
  3. Monitor compliance i Azure Portal

For lab purposes uten Azure:
  → Bruk lokal OSConfig deployment (som vi har gjort)

"@ -ForegroundColor Cyan
```

---

## Del 7: GPO vs OSConfig - Sammenligning

### Steg 7.1: Samme Configuration, To Metoder

**Oppgave:** Implementer "Disable Print Spooler" på to forskjellige måter.

#### Metode 1: Group Policy

```powershell
Write-Host "=== Metode 1: Group Policy ===" -ForegroundColor Cyan

# Opprett GPO
New-GPO -Name "Test - Disable Print Spooler" -Comment "Testing GPO approach"

# Konfigurer GPO (må gjøres manuelt i GPMC)
Write-Host @"

MANUELLE STEG I GPMC:
1. Edit 'Test - Disable Print Spooler'
2. Computer Configuration → Preferences → Control Panel Settings → Services
3. New → Service
   - Startup: Disabled
   - Service name: Spooler
   - Action: Update

4. Link til test OU

"@ -ForegroundColor Yellow

# Link GPO
New-GPLink -Name "Test - Disable Print Spooler" -Target "OU=Servers,DC=infrait,DC=sec" -LinkEnabled Yes
```

#### Metode 2: OSConfig

```powershell
Write-Host "`n=== Metode 2: OSConfig ===" -ForegroundColor Cyan

$OSConfigDisableSpooler = @"
{
  "name": "DisablePrintSpooler",
  "version": "1.0",
  "modules": [
    {
      "name": "Services",
      "settings": {
        "services": [
          {
            "name": "Spooler",
            "startupType": "Disabled",
            "ensure": "Present"
          }
        ]
      }
    }
  ]
}
"@

$TestConfigFile = "C:\OSConfig\Configurations\Test-DisableSpooler.json"
$OSConfigDisableSpooler | Out-File -FilePath $TestConfigFile -Encoding UTF8

Write-Host "✓ OSConfig configuration created" -ForegroundColor Green
Write-Host "  Deployment: Copy + Apply (scriptable, version controlled)" -ForegroundColor Gray
```

**Sammenligning:**

| Aspekt | Group Policy | OSConfig |
|--------|-------------|----------|
| **Configuration method** | GUI (GPMC) | Code (JSON/YAML) |
| **Version control** | Vanskelig | Enkelt (Git) |
| **Deployment** | Link til OU | Script deployment |
| **Scope** | Domain-bound | Domain eller standalone |
| **Testing** | Complex (separate OU) | Simple (JSON file) |
| **Documentation** | Manual | Self-documenting (code) |
| **Cloud support** | Nei | Ja (Azure Arc) |

---

## Del 8: Refleksjonsspørsmål og Best Practices

### Diskuter i Grupper

**1. Windows Admin Center vs Traditional Tools**

- Når ville du brukt WAC over Remote Desktop?
- Er WAC egnet for alle administrative oppgaver?
- Hva er security implikasjonene av web-based management?

**2. OSConfig vs Group Policy**

- I hvilke scenarioer er OSConfig bedre enn GPO?
- Når bør du fortsatt bruke GPO?
- Kan de brukes sammen? (Hint: Ja!)

**3. Infrastructure as Code**

- Hva er fordelene med å lagre configurations som JSON/YAML?
- Hvordan ville du implementert versjonskontroll for OSConfig?
- Hvordan tester du en configuration før production deployment?

**4. Hybrid Approach**

Design en strategi som bruker både GPO og OSConfig:

```
GPO for:
  - Domain-wide security policies
  - User policies
  - Microsoft Security Baselines

OSConfig for:
  - Server-specific configurations
  - Application settings
  - Cloud-hybrid scenarios
  - Rapid deployment / testing
```

---

## Del 9: Praktisk Oppgave - Bygg din Egen Solution

### Oppgave: Implementer "Nightly Security Scan" via OSConfig

**Mål:** Opprett en OSConfig configuration som:

1. Aktiverer Windows Defender scheduled scan
2. Konfigurerer scanning time til 02:00
3. Enable real-time protection
4. Deploy til alle servere
5. Verifiser compliance

**Starter-kode:**

```json
{
  "name": "WindowsDefenderScheduledScan",
  "version": "1.0",
  "description": "Configure Windows Defender nightly security scan",
  "modules": [
    {
      "name": "Registry",
      "settings": {
        "registryValues": [
          {
            "keyPath": "HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows Defender\\Scan",
            "valueName": "ScheduleDay",
            "valueType": "DWord",
            "valueData": 0,
            "ensure": "Present"
          },
          {
            "keyPath": "HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows Defender\\Scan",
            "valueName": "ScheduleTime",
            "valueType": "DWord",
            "valueData": 120,
            "ensure": "Present"
          }
        ]
      }
    }
  ]
}
```

**Din oppgave:**
1. Fullfør configuration (legg til real-time protection settings)
2. Deploy til alle servere
3. Verifiser med PowerShell at settings er applisert
4. Lag en compliance report

---

## Oppsummering

Du har nå lært:

- ✅ Installere og konfigurere Windows Admin Center
- ✅ Administrere domene-maskiner via web GUI
- ✅ Forstå OSConfig og moderne configuration management
- ✅ Implementere configurations via JSON
- ✅ Deploy og verifisere configurations på tvers av domenet
- ✅ Sammenligne tradisjonelle (GPO) og moderne (OSConfig) approaches
- ✅ Designe hybrid management strategier

**Nøkkelinnsikt:**

> "The future of Windows management is hybrid: Group Policy for domain-wide security policies, OSConfig for granular, code-driven configuration management, and cloud integration via Azure Arc."

**Next Steps:**
- Integrer OSConfig med Git for version control
- Explore Azure Arc for cloud-native management
- Automate compliance reporting
- Build CI/CD pipeline for configuration deployment

---

## Referanser

- [Windows Admin Center Documentation](https://learn.microsoft.com/en-us/windows-server/manage/windows-admin-center/overview)
- [OSConfig on GitHub](https://github.com/microsoft/osconfig)
- [Azure Arc Overview](https://azure.microsoft.com/en-us/services/azure-arc/)
- [Infrastructure as Code Best Practices](https://learn.microsoft.com/en-us/devops/deliver/what-is-infrastructure-as-code)
- [Modern Management for Windows](https://learn.microsoft.com/en-us/mem/configmgr/core/understand/introduction)