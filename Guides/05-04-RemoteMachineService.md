# Active Directory Service Monitoring med PowerShell

**Fagmodul:** Windows Server Administrasjon  
**Semester:** 2. semester - Bachelor i Digital infrastruktur i cybersikkerhet  
**Tema:** Automatisk overvåking og oppstart av kritiske AD-tjenester

---

## 📋 Innholdsfortegnelse

1. [Introduksjon](#introduksjon)
2. [Hva er NTDS?](#hva-er-ntds)
3. [Script-gjennomgang](#script-gjennomgang)
4. [Feilhåndtering og best practices](#feilhåndtering-og-best-practices)
5. [Praktiske forbedringer](#praktiske-forbedringer)
6. [Øvingsoppgaver](#øvingsoppgaver)

---

## Introduksjon

Som IT-administrator er det kritisk at **Active Directory Domain Services (NTDS)** alltid kjører på Domain Controlleren. Hvis denne tjenesten stopper:

❌ Brukere kan ikke logge inn  
❌ Group Policies blir ikke applisert  
❌ Autentisering feiler  
❌ Hele domenet kan bli utilgjengelig  

Dette scriptet demonstrerer hvordan du kan:
- ✅ Automatisk sjekke om NTDS kjører
- ✅ Starte tjenesten hvis den har stoppet
- ✅ Logge resultater for troubleshooting
- ✅ Implementere proaktiv overvåking

### Cybersikkerhetsperspektiv

**Hvorfor er dette viktig for sikkerhet?**

- **Tilgjengelighet (CIA-triaden):** NTDS er kritisk for domenetilgjengelighet
- **Incident Response:** Rask deteksjon hvis tjenesten stoppes (DoS-angrep?)
- **Auditing:** Logging av når tjenester startes/stoppes
- **Compliance:** Mange rammeverk krever overvåking av kritiske tjenester

---

## Hva er NTDS?

### NTDS = NT Directory Services

**NTDS** er kjernetjenesten i Active Directory og kjører på alle Domain Controllers.

| Aspekt | Detaljer |
|--------|----------|
| **Tjenestenavn** | `NTDS` |
| **Display Name** | `Active Directory Domain Services` |
| **Kjørbar fil** | `C:\Windows\System32\ntdsai.dll` (via lsass.exe) |
| **Database** | `C:\Windows\NTDS\ntds.dit` |
| **Kritisk?** | **JA** - Domenet fungerer ikke uten denne |

### Hva gjør NTDS?

- 🔐 Autentisering av brukere og datamaskiner
- 📁 Lagring av alle AD-objekter (brukere, grupper, OU, etc.)
- 🔄 Replikering mellom Domain Controllers
- 🎫 Utsteding av Kerberos-tickets
- 📋 Håndtering av LDAP-forespørsler

---

## Script-gjennomgang

### Komplett script

```powershell
## Monitoring DC1 Active Directory Services
<# 

Invoke-Command -ComputerName DC1 -ScriptBlock {
    Get-Service | Select-Object DisplayName, ServiceName, Status | Format-Table -AutoSize
}
#> 
# Use the above command to get the list of services running on the DC1 server

$scriptBlock = {
    # Define the service name for Active Directory Domain Services
    $serviceName = "NTDS"

    # Retrieve the current status of the NTDS service
    $serviceStatus = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

    # Check if the service is running
    if ($serviceStatus.Status -ne 'Running') {
        # Attempt to start the service if it is not running
        try {
            Start-Service -Name $serviceName
            Write-Output "The NTDS service was not running and has been started."
        } catch {
            # If an error occurs while starting the service, output the error
            Write-Output "Failed to start the NTDS service. Error: $_"
        }
    } else {
        # If the service is already running, output its status
        Write-Output "The NTDS service is running."
    }
}

Invoke-Command -ComputerName DC1 -ScriptBlock $scriptBlock
```

---

### Del 1: Kommentert kommando (utforskning)

```powershell
<# 

Invoke-Command -ComputerName DC1 -ScriptBlock {
    Get-Service | Select-Object DisplayName, ServiceName, Status | Format-Table -AutoSize
}
#> 
```

**Hva er dette?**

Dette er en **kommentert-ut kommando** (multi-line comment med `<# ... #>`). Den er der som en referanse/hjelpeverktøy.

**Hvis du kjører denne (fjern `<#` og `#>`), får du:**
- Liste over **alle** tjenester på DC1
- Tre kolonner: DisplayName, ServiceName (kort navn), Status
- Formatert som en tabell

**Bruk dette til:**
```powershell
# Finn servicenavn for Active Directory
Invoke-Command -ComputerName DC1 -ScriptBlock {
    Get-Service | Where-Object {$_.DisplayName -like "*Active Directory*"} | 
    Select-Object DisplayName, Name, Status | Format-Table -AutoSize
}
```

**Output:**
```
DisplayName                          Name Status
-----------                          ---- ------
Active Directory Domain Services     NTDS Running
Active Directory Web Services        ADWS Running
```

---

### Del 2: ScriptBlock-definisjon

```powershell
$scriptBlock = {
    # Define the service name for Active Directory Domain Services
    $serviceName = "NTDS"
```

**Hva er et ScriptBlock?**

Et ScriptBlock er en "pakke" med PowerShell-kode som kan:
- Lagres i en variabel
- Sendes til fjernservere
- Kjøres når du vil

**Hvorfor bruke ScriptBlock her?**
- Koden skal kjøres **på DC1**, ikke lokalt
- Vi kan gjenbruke samme logikk for flere servere
- Lettere å teste og vedlikeholde

---

### Del 3: Hent tjenestestatus

```powershell
    # Retrieve the current status of the NTDS service
    $serviceStatus = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
```

**Breakdown:**

| Del | Forklaring |
|-----|------------|
| `Get-Service -Name $serviceName` | Henter informasjon om NTDS-tjenesten |
| `-ErrorAction SilentlyContinue` | Hvis tjenesten ikke finnes: **IKKE** vis feilmelding |
| `$serviceStatus = ...` | Lagrer resultatet i en variabel |

**Hva lagres i `$serviceStatus`?**

Et `ServiceController` objekt med egenskaper som:
```powershell
Name          : NTDS
DisplayName   : Active Directory Domain Services
Status        : Running
StartType     : Automatic
CanStop       : True
CanPauseAndContinue : False
```

**Hvorfor `-ErrorAction SilentlyContinue`?**

Uten denne parameteren:
```powershell
Get-Service -Name "NTDS"
# Hvis NTDS ikke finnes: Rød feilmelding og scriptet stopper!
```

Med parameteren:
```powershell
Get-Service -Name "NTDS" -ErrorAction SilentlyContinue
# Hvis NTDS ikke finnes: $serviceStatus = $null, scriptet fortsetter
```

**Best practice:** Alltid bruk `-ErrorAction` når du sjekker om noe eksisterer!

---

### Del 4: Status-sjekk med if/else

```powershell
    # Check if the service is running
    if ($serviceStatus.Status -ne 'Running') {
```

**Hva betyr `-ne`?**

`-ne` = **N**ot **E**qual (ikke lik)

**Mulige Status-verdier:**

| Status | Beskrivelse |
|--------|-------------|
| `Running` | Tjenesten kjører normalt |
| `Stopped` | Tjenesten er stoppet |
| `Paused` | Tjenesten er pause (sjelden) |
| `StartPending` | Tjenesten holder på å starte |
| `StopPending` | Tjenesten holder på å stoppe |

**Logikken:**

```
Hvis Status IKKE ER 'Running'
    → Da er noe galt!
    → Prøv å starte tjenesten
Ellers
    → Alt er OK
    → Informer at tjenesten kjører
```

**Viktig:** Denne sjekken fanger:
- ✅ `Stopped`
- ✅ `Paused`
- ✅ `StartPending` (midlertidig, men ikke fullstendig startet)
- ✅ `$null` (hvis tjenesten ikke eksisterer)

---

### Del 5: Try/Catch feilhåndtering

```powershell
        # Attempt to start the service if it is not running
        try {
            Start-Service -Name $serviceName
            Write-Output "The NTDS service was not running and has been started."
        } catch {
            # If an error occurs while starting the service, output the error
            Write-Output "Failed to start the NTDS service. Error: $_"
        }
```

**Try/Catch forklart:**

```powershell
try {
    # Prøv å gjøre noe risikabelt
    Start-Service -Name $serviceName
    
} catch {
    # Hvis det feiler, gjør dette i stedet
    Write-Output "Feil: $_"
}
```

**Hvorfor trenger vi dette?**

`Start-Service` kan feile av mange grunner:
- 🔒 Manglende rettigheter
- ⚙️ Tjenesten er i feil tilstand
- 💔 Avhengige tjenester kjører ikke
- 🗂️ Korrupte filer

**Hva er `$_` i catch-blokken?**

`$_` er den **aktuelle feilmeldingen**. Eksempel:

```powershell
catch {
    Write-Output "Feil oppstod: $_"
}

# Output kan være:
# "Feil oppstod: Service 'NTDS' cannot be started due to the following error: 
#  Cannot start service NTDS on computer '.'."
```

---

### Del 6: Success-melding

```powershell
            Write-Output "The NTDS service was not running and has been started."
```

**Write-Output vs. Write-Host:**

| Cmdlet | Bruk | Kan fanges i variabel? |
|--------|------|----------------------|
| `Write-Output` | Standard output (anbefalt) | ✅ Ja |
| `Write-Host` | Direkte til konsoll | ❌ Nei |

**Hvorfor Write-Output?**

```powershell
# Dette fungerer:
$result = Invoke-Command -ComputerName DC1 -ScriptBlock {
    Write-Output "NTDS is running"
}
Write-Host "Result: $result"  # Output: Result: NTDS is running

# Dette fungerer IKKE:
$result = Invoke-Command -ComputerName DC1 -ScriptBlock {
    Write-Host "NTDS is running"
}
Write-Host "Result: $result"  # Output: Result: (tomt!)
```

**Beste praksis:** Bruk `Write-Output` i scripts, `Write-Host` kun for farget konsolluputput.

---

### Del 7: Else-blokken (alt er OK)

```powershell
    } else {
        # If the service is already running, output its status
        Write-Output "The NTDS service is running."
    }
```

**Enkelt:** Hvis Status **ER** 'Running', informer at alt er bra.

---

### Del 8: Kjør scriptet på fjernserver

```powershell
Invoke-Command -ComputerName DC1 -ScriptBlock $scriptBlock
```

**Hva skjer her?**

1. PowerShell kobler til DC1 via WinRM
2. Sender `$scriptBlock` til DC1
3. DC1 kjører koden **lokalt**
4. Resultatet sendes tilbake til din maskin
5. Output vises i konsollen

**Viktig:** Koden kjører **PÅ** DC1, ikke fra din maskin!

---

## Feilhåndtering og best practices

### Problem 1: Hva hvis DC1 er offline?

**Symptom:**
```
[DC1] Connecting to remote server DC1 failed...
```

**Løsning: Legg til connectivity check**

```powershell
if (Test-Connection -ComputerName DC1 -Count 2 -Quiet) {
    Invoke-Command -ComputerName DC1 -ScriptBlock $scriptBlock
} else {
    Write-Host "ERROR: DC1 is not reachable!" -ForegroundColor Red
}
```

---

### Problem 2: Hva hvis NTDS ikke kan startes?

**Scenario:** NTDS er i "disabled" state eller avhengige tjenester mangler.

**Forbedret try/catch:**

```powershell
try {
    Start-Service -Name $serviceName -ErrorAction Stop
    Write-Output "✅ NTDS service started successfully."
    
} catch [System.InvalidOperationException] {
    Write-Output "❌ Cannot start NTDS: Service may be disabled or dependencies missing."
    Write-Output "Error details: $($_.Exception.Message)"
    
} catch {
    Write-Output "❌ Unexpected error starting NTDS: $_"
}
```

---

### Problem 3: Manglende logging

**Forbedring: Legg til logging**

```powershell
$scriptBlock = {
    $serviceName = "NTDS"
    $logFile = "C:\Logs\NTDS_Monitor.log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Sjekk om loggmappe eksisterer
    if (-not (Test-Path "C:\Logs")) {
        New-Item -Path "C:\Logs" -ItemType Directory -Force | Out-Null
    }
    
    $serviceStatus = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    
    if ($serviceStatus.Status -ne 'Running') {
        try {
            Start-Service -Name $serviceName
            $message = "[$timestamp] NTDS was stopped and has been started."
            Write-Output $message
            Add-Content -Path $logFile -Value $message
            
        } catch {
            $message = "[$timestamp] FAILED to start NTDS: $_"
            Write-Output $message
            Add-Content -Path $logFile -Value $message
        }
    } else {
        $message = "[$timestamp] NTDS is running normally."
        Write-Output $message
        Add-Content -Path $logFile -Value $message
    }
}

Invoke-Command -ComputerName DC1 -ScriptBlock $scriptBlock
```

**Resultat:** Alle hendelser logges til `C:\Logs\NTDS_Monitor.log` på DC1 (burde lagt det på et delt felles område for logging som det tas backup av)

**Eksempel loggfil:**
```
[2026-01-29 14:30:15] NTDS is running normally.
[2026-01-29 14:35:20] NTDS was stopped and has been started.
[2026-01-29 14:40:25] NTDS is running normally.
```

---

## Praktiske forbedringer

### Forbedring 1: Overvåk flere tjenester

```powershell
$scriptBlock = {
    $criticalServices = @("NTDS", "DNS", "KDC", "Netlogon", "W32Time")
    
    $results = foreach ($serviceName in $criticalServices) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        
        [PSCustomObject]@{
            ServiceName = $serviceName
            Status = if ($service) { $service.Status } else { "Not Found" }
            Action = if ($service.Status -ne 'Running') { "NEEDS ATTENTION" } else { "OK" }
        }
    }
    
    return $results
}

$status = Invoke-Command -ComputerName DC1 -ScriptBlock $scriptBlock
$status | Format-Table -AutoSize

# Sjekk om noen tjenester trenger oppmerksomhet
$problems = $status | Where-Object Action -eq "NEEDS ATTENTION"
if ($problems) {
    Write-Host "`n⚠️ WARNING: Following services need attention:" -ForegroundColor Yellow
    $problems | Format-Table -AutoSize
}
```

**Output:**
```
ServiceName Status  Action
----------- ------  ------
NTDS        Running OK
DNS         Running OK
KDC         Running OK
Netlogon    Running OK
W32Time     Running OK
```

---

### Forbedring 2: Automatisk restart med retry-logikk

```powershell
$scriptBlock = {
    param($ServiceName, $MaxRetries = 3, $RetryDelaySeconds = 5)
    
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    
    if (-not $service) {
        return "ERROR: Service $ServiceName not found."
    }
    
    if ($service.Status -eq 'Running') {
        return "✅ $ServiceName is already running."
    }
    
    # Try to start the service with retries
    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            Write-Output "Attempt $i of $MaxRetries to start $ServiceName..."
            Start-Service -Name $ServiceName -ErrorAction Stop
            Start-Sleep -Seconds 2
            
            # Verify it actually started
            $service.Refresh()
            if ($service.Status -eq 'Running') {
                return "✅ $ServiceName started successfully on attempt $i."
            }
            
        } catch {
            Write-Output "❌ Attempt $i failed: $($_.Exception.Message)"
            
            if ($i -lt $MaxRetries) {
                Write-Output "Waiting $RetryDelaySeconds seconds before retry..."
                Start-Sleep -Seconds $RetryDelaySeconds
            }
        }
    }
    
    return "❌ CRITICAL: Failed to start $ServiceName after $MaxRetries attempts!"
}

# Kjør med parametere
Invoke-Command -ComputerName DC1 -ScriptBlock $scriptBlock -ArgumentList "NTDS", 3, 5
```

---

### Forbedring 3: E-postvarsel ved problemer

```powershell
$scriptBlock = {
    $serviceName = "NTDS"
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    
    [PSCustomObject]@{
        Server = $env:COMPUTERNAME
        Service = $serviceName
        Status = if ($service) { $service.Status.ToString() } else { "NotFound" }
        Timestamp = Get-Date
        RequiresAlert = ($service.Status -ne 'Running')
    }
}

$result = Invoke-Command -ComputerName DC1 -ScriptBlock $scriptBlock

# Hvis tjenesten ikke kjører, send e-post
if ($result.RequiresAlert) {
    $mailParams = @{
        To = "admin@infraIT.sec"
        From = "monitoring@infraIT.sec"
        Subject = "ALERT: NTDS service down on $($result.Server)"
        Body = @"
CRITICAL ALERT

Server: $($result.Server)
Service: $($result.Service)
Status: $($result.Status)
Time: $($result.Timestamp)

Immediate action required!
"@
        SmtpServer = "smtp.infraIT.sec"
    }
    
    Send-MailMessage @mailParams
    Write-Host "⚠️ Alert email sent to administrator" -ForegroundColor Red
}
```

---

### Forbedring 4: Scheduled Task for kontinuerlig overvåking

**Opprett scheduled task som kjører scriptet hvert 5. minutt:**

```powershell
# Lag script-fil
$monitorScript = @'
$scriptBlock = {
    $serviceName = "NTDS"
    $logFile = "C:\Logs\NTDS_Monitor.log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    if (-not (Test-Path "C:\Logs")) {
        New-Item -Path "C:\Logs" -ItemType Directory -Force | Out-Null
    }
    
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    
    if ($service.Status -ne 'Running') {
        try {
            Start-Service -Name $serviceName
            Add-Content -Path $logFile -Value "[$timestamp] ⚠️ NTDS was stopped and has been restarted."
        } catch {
            Add-Content -Path $logFile -Value "[$timestamp] ❌ FAILED to start NTDS: $_"
        }
    }
}

Invoke-Command -ComputerName DC1 -ScriptBlock $scriptBlock
'@

# Lagre scriptet
$scriptPath = "C:\Scripts\Monitor-NTDS.ps1"
$monitorScript | Out-File -FilePath $scriptPath -Encoding UTF8

# Opprett scheduled task
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration ([TimeSpan]::MaxValue)
$principal = New-ScheduledTaskPrincipal -UserId "InfraIT\adm_torivli" -LogonType Password -RunLevel Highest

Register-ScheduledTask -TaskName "Monitor-NTDS-Service" -Action $action -Trigger $trigger -Principal $principal -Description "Monitors and restarts NTDS service if stopped"

Write-Host "✅ Scheduled task created: Runs every 5 minutes" -ForegroundColor Green
```

---

## Øvingsoppgaver

### Oppgave 1: Test grunnscriptet

1. Kjør det grunnleggende scriptet mot DC1
2. Verifiser at NTDS kjører
3. Manuelt stopp NTDS: `Stop-Service -Name NTDS` (på DC1)
4. Kjør scriptet igjen - verifiser at det starter tjenesten

**Forventet resultat:**
```
The NTDS service was not running and has been started.
```

---

### Oppgave 2: Legg til flere tjenester

Utvid scriptet til å også overvåke:
- DNS
- KDC (Kerberos Key Distribution Center)
- Netlogon

**Hint:** Bruk en array og loop gjennom tjenestene.

---

### Oppgave 3: Implementer fargekodet output

Modifiser scriptet til å bruke farger:
- 🟢 Grønn: Tjenesten kjører
- 🟡 Gul: Tjenesten ble startet
- 🔴 Rød: Kunne ikke starte tjenesten

**Hint:**
```powershell
Write-Host "✅ Service is running" -ForegroundColor Green
Write-Host "⚠️ Service was started" -ForegroundColor Yellow
Write-Host "❌ Failed to start" -ForegroundColor Red
```

---

### Oppgave 4: Lag en dashboard-funksjon

Lag en funksjon som viser status for alle kritiske AD-tjenester i et dashboard-format:

```
============================================
  Active Directory Health Dashboard
  Server: DC1
  Time: 2026-01-29 14:30:00
============================================

Service                Status      Uptime
-------                ------      ------
NTDS                   Running     5d 12h
DNS                    Running     5d 12h
KDC                    Running     5d 12h
Netlogon               Running     5d 12h
W32Time                Running     5d 12h

Overall Health: ✅ ALL SYSTEMS OPERATIONAL
```

---

### Oppgave 5: Advanced - Multi-DC monitoring

Lag et script som overvåker NTDS på **alle** Domain Controllers i domenet:

**Hint:**
```powershell
# Finn alle Domain Controllers
$allDCs = Get-ADDomainController -Filter * | Select-Object -ExpandProperty Name

# Loop gjennom og sjekk hver
foreach ($dc in $allDCs) {
    Invoke-Command -ComputerName $dc -ScriptBlock $scriptBlock
}
```

---

## Oppsummering

I denne modulen har du lært:

✅ **NTDS-tjenesten:** Kritisk for Active Directory-funksjonalitet  
✅ **ScriptBlocks:** Pakke kode for remote execution  
✅ **Get-Service:** Hente tjenestestatus  
✅ **Start-Service:** Starte stoppede tjenester  
✅ **Try/Catch:** Robust feilhåndtering  
✅ **Invoke-Command:** Kjøre kommandoer på fjernservere  
✅ **Logging:** Dokumentere service-hendelser  
✅ **Best practices:** Proaktiv overvåking og automatisering  

### Viktige takeaways

🔑 **Nøkkelkonsepter:**
- Alltid bruk `-ErrorAction SilentlyContinue` når du sjekker om noe eksisterer
- Try/Catch gir robust feilhåndtering
- `Write-Output` (ikke `Write-Host`) i scripts som returnerer data
- Logging er essensielt for troubleshooting
- Automatiser repetitive overvåkingsoppgaver

### Neste steg

- Utforsk **Get-EventLog** for å analysere service start/stopp events
- Lær om **Windows Service Recovery Actions** (automatisk restart)
- Implementer **SCOM** eller **Nagios** for enterprise monitoring
- Studer **Active Directory replication** monitoring

---

## Nyttige kommandoer - Quick Reference

```powershell
# Sjekk NTDS status
Get-Service -Name NTDS

# Start NTDS
Start-Service -Name NTDS

# Stopp NTDS (FARLIG - kun for testing!)
Stop-Service -Name NTDS -Force

# Sjekk alle AD-tjenester
Get-Service | Where-Object {$_.DisplayName -like "*Active Directory*"}

# Sjekk service dependencies
Get-Service -Name NTDS -DependentServices

# Sjekk hva NTDS avhenger av
Get-Service -Name NTDS -RequiredServices

# Sjekk Event Log for NTDS-hendelser
Get-EventLog -LogName "Directory Service" -Newest 10

# Restart NTDS (FARLIG!)
Restart-Service -Name NTDS -Force
```

---

## Sikkerhetsvarsler

⚠️ **VIKTIG:**

1. **ALDRI restart NTDS i produksjon uten godkjenning**
2. **Test alltid i lab-miljø først**
3. **Ha backup før du gjør endringer på DC**
4. **Sjekk replikeringsstatus før/etter restart**
5. **Varsle brukere om planlagt nedetid**
6. **Dokumenter alle endringer**

---

**Laget for:** 2. semester, Bachelor i Digital infrastruktur i cybersikkerhet  
**Fagansvarlig:** Tor Ivar  
**Testmiljø:** InfraIT.sec domain (DC1, SRV1, CL1, MGR)  
**Forutsetninger:** PowerShell Remoting aktivert, administrative rettigheter
