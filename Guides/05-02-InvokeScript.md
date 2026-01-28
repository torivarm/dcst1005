# Remote Performance Monitoring med PowerShell

**Fagmodul:** Windows Server Administrasjon  
**Semester:** 2. semester - Bachelor i Digital infrastruktur i cybersikkerhet  
**Tema:** Fjernovervåking av serverytelse med Invoke-Command

---

## 📋 Innholdsfortegnelse

1. [Introduksjon](#introduksjon)
2. [Script-gjennomgang](#script-gjennomgang)
3. [Konsepter og teori](#konsepter-og-teori)
4. [Praktiske forbedringer](#praktiske-forbedringer)
5. [Troubleshooting](#troubleshooting)
6. [Øvingsoppgaver](#øvingsoppgaver)

---

## Introduksjon

Som IT-administrator har du sjelden muligheten til å fysisk sitte ved hver enkelt server. I enterprise-miljøer kan du ha hundrevis av servere spredt over flere lokasjoner. **PowerShell Remoting** er løsningen som lar deg administrere og overvåke disse serverene sentralt.

I dette dokumentet skal vi utforske et praktisk script som:
- ✅ Overvåker CPU-bruk på flere servere samtidig
- ✅ Sjekker minnestatus (både brukt og tilgjengelig)
- ✅ Viser resultater i sanntid
- ✅ Demonstrerer enterprise-best practices

### Hvorfor er dette viktig?

**I cybersikkerhetsperspektiv:**
- Identifiser kompromitterte servere med unormal ressursbruk
- Overvåk kritiske servere uten å installere agenter
- Sentral logging av ytelsesdata
- Rask respons ved sikkerhetsincidenter

**I driftsperspektiv:**
- Skalerbar overvåking av infrastruktur
- Proaktiv kapasitetsplanlegging
- Redusert tid til feilidentifikasjon
- Automatiserte health checks

---

## Script-gjennomgang

Gjennomgang av scriptet linje for linje:

### Komplett script

```powershell
$scriptblock = { 
    # Processor Total
    Get-Counter '\Processor(_Total)\% Processor Time' | ForEach-Object { $_.CounterSamples }

    # Memory Total and Available (in MB)
    Get-Counter '\Memory\% Committed Bytes In Use' | ForEach-Object { $_.CounterSamples }
    Get-Counter '\Memory\Available MBytes' | ForEach-Object { $_.CounterSamples }
}

Invoke-Command -ComputerName dc1,srv1 -ScriptBlock $scriptblock | ForEach-Object {
    # Displaying the results
    Write-Host "Counter: $($_.Path)"
    Write-Host "Value: $($_.CookedValue)"
    Write-Host "---------------------------"
}
```

---

### Del 1: ScriptBlock-definisjon

```powershell
$scriptblock = { 
    # Processor Total
    Get-Counter '\Processor(_Total)\% Processor Time' | ForEach-Object { $_.CounterSamples }

    # Memory Total and Available (in MB)
    Get-Counter '\Memory\% Committed Bytes In Use' | ForEach-Object { $_.CounterSamples }
    Get-Counter '\Memory\Available MBytes' | ForEach-Object { $_.CounterSamples }
}
```

**Hva er et ScriptBlock?**

Et ScriptBlock er en samling PowerShell-kommandoer pakket i krøllparenteser `{ }`. Du kan tenke på det som en "oppskrift" av kommandoer som skal kjøres senere.

```powershell
# Analogt med en funksjon, men mer fleksibel
$scriptblock = { Write-Host "Dette kjøres ikke ennå!" }

# Kjør scriptet
& $scriptblock  # Output: Dette kjøres ikke ennå!
```

**Hvorfor bruke ScriptBlock her?**
- Vi må sende koden til fjernservere for utførelse
- Koden pakkes og sendes "as-is" til hver server
- Hver server kjører sin egen kopi av scriptet

---

#### Linje 1: CPU-måling

```powershell
Get-Counter '\Processor(_Total)\% Processor Time' | ForEach-Object { $_.CounterSamples }
```

**Breakdown:**
1. `Get-Counter '\Processor(_Total)\% Processor Time'` - Henter CPU-bruk (alle kjerner samlet)
2. `| ForEach-Object { $_.CounterSamples }` - Ekstraherer selve tellerdata fra objektet

**Hva er `$_.CounterSamples`?**

`Get-Counter` returnerer et `PerformanceCounterSampleSet` objekt som inneholder:
- `Timestamp` - Når målingen ble tatt
- `CounterSamples` - Selve måledataene

Ved å bruke `.CounterSamples` får vi tilgang til:
- `Path` - Full tellerbane (f.eks. `\\DC1\processor(_total)\% processor time`)
- `InstanceName` - Instansnavn (f.eks. `_Total`)
- `CookedValue` - Den faktiske verdien (f.eks. 15.23)

---

#### Linje 2-3: Minnemålinger

```powershell
Get-Counter '\Memory\% Committed Bytes In Use' | ForEach-Object { $_.CounterSamples }
Get-Counter '\Memory\Available MBytes' | ForEach-Object { $_.CounterSamples }
```

**To viktige minne-tellere:**

| Teller | Beskrivelse | Hva betyr verdien? |
|--------|-------------|-------------------|
| `\Memory\% Committed Bytes In Use` | Prosentandel av commited memory i bruk | Høy verdi (>80%) = minnepress |
| `\Memory\Available MBytes` | Tilgjengelig fysisk minne i MB | Lav verdi (<200MB) = kritisk |

**Committed Memory vs. Physical Memory:**
- **Physical Memory:** Faktisk RAM installert i serveren
- **Committed Memory:** Minne som er reservert (inkludert page file)

---

### Del 2: Remote utførelse

```powershell
Invoke-Command -ComputerName dc1,srv1 -ScriptBlock $scriptblock | ForEach-Object {
    # Displaying the results
    Write-Host "Counter: $($_.Path)"
    Write-Host "Value: $($_.CookedValue)"
    Write-Host "---------------------------"
}
```

#### Invoke-Command forklart

```powershell
Invoke-Command -ComputerName dc1,srv1 -ScriptBlock $scriptblock
```

**Parametere:**
- `-ComputerName dc1,srv1` - Liste over servere (kommaseparert)
- `-ScriptBlock $scriptblock` - Koden som skal kjøres på hver server

**Hva skjer?**
1. PowerShell oppretter en sesjon til DC1 og SRV1
2. ScriptBlock sendes til begge serverne
3. Hver server kjører scriptet **lokalt** på seg selv
4. Resultater sendes tilbake til din maskin
5. Sesjonen lukkes automatisk

**Viktig:** Koden kjører **på målserverne**, ikke på din lokale maskin!

---

#### Pipeline-prosessering av resultater

```powershell
| ForEach-Object {
    Write-Host "Counter: $($_.Path)"
    Write-Host "Value: $($_.CookedValue)"
    Write-Host "---------------------------"
}
```

**Hva er `$_` her?**

`$_` er det gjeldende objektet i pipeline. For hvert CounterSample-objekt som returneres:
- `$_.Path` - Full tellerbane inkludert servernavn
- `$_.CookedValue` - Den kalkulerte verdien (ferdig prosessert)

**Eksempel output:**
```
Counter: \\dc1\processor(_total)\% processor time
Value: 12.5436721847208
---------------------------
Counter: \\dc1\memory\% committed bytes in use
Value: 45.2341234567890
---------------------------
Counter: \\dc1\memory\available mbytes
Value: 3456
---------------------------
Counter: \\srv1\processor(_total)\% processor time
Value: 8.93245678901234
---------------------------
Counter: \\srv1\memory\% committed bytes in use
Value: 38.1234567890123
---------------------------
Counter: \\srv1\memory\available mbytes
Value: 4523
---------------------------
```

---

## Konsepter og teori

### PowerShell Remoting arkitektur

```
[Din maskin - MGR]
       |
       | WinRM (Port 5985/5986)
       |
   [WS-Man Protocol]
       |
    -------
   |       |
[DC1]   [SRV1]
   |       |
Execute Execute
Script  Script
   |       |
Return  Return
Results Results
```

**Nøkkelpunkter:**
- Bruker **WS-Management protokollen** (standard webservice protocol)
- Kryptert kommunikasjon (selv over HTTP ved bruk av Kerberos)
- Autentisering via Kerberos (domain) eller NTLM (workgroup)
- Støtter både interactive og non-interactive sessions

---

### ScriptBlock vs. Invoke-Expression

**ScriptBlock (anbefalt):**
```powershell
$script = { Get-Service }
Invoke-Command -ComputerName SRV1 -ScriptBlock $script
```

**Invoke-Expression (FARLIG!):**
```powershell
$command = "Get-Service"
Invoke-Expression $command  # ❌ Utsatt for injection attacks
```

**Hvorfor er ScriptBlock sikrere?**
- Definert ved compile-time
- Ingen dynamisk string-evaluering
- Beskyttet mot command injection

---

### Parallell vs. Sekvensiell utførelse

```powershell
# Dette scriptet kjører PARALLELT
Invoke-Command -ComputerName dc1,srv1 -ScriptBlock $scriptblock
```

**Hva betyr parallell kjøring?**
- Begge servere kjører scriptet **samtidig**
- Ikke "først DC1, deretter SRV1"
- Raskere total kjøretid

**Tidsbesparelse:**
```
Sekvensiell: 2 servere × 3 sekunder = 6 sekunder
Parallell:   max(3 sekunder, 3 sekunder) = 3 sekunder
```

**Begrensninger:**
- Standard: 32 samtidige tilkoblinger
- Endre med: `-ThrottleLimit` parameter

```powershell
# Øk til 64 samtidige tilkoblinger
Invoke-Command -ComputerName (1..100 | ForEach-Object { "Server$_" }) `
               -ScriptBlock $scriptblock `
               -ThrottleLimit 64
```

---

## Praktiske forbedringer

### Forbedring 1: Strukturert output med objekter

I stedet for `Write-Host`, returner objekter for videre prosessering:

```powershell
$scriptblock = { 
    $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples
    $memPercent = (Get-Counter '\Memory\% Committed Bytes In Use').CounterSamples
    $memAvailable = (Get-Counter '\Memory\Available MBytes').CounterSamples
    
    [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        CPU_Percent = [math]::Round($cpu.CookedValue, 2)
        Memory_Percent = [math]::Round($memPercent.CookedValue, 2)
        Memory_Available_MB = [math]::Round($memAvailable.CookedValue, 2)
    }
}

# Kjør og vis som tabell
$results = Invoke-Command -ComputerName dc1,srv1 -ScriptBlock $scriptblock
$results | Format-Table -AutoSize

# Eller eksporter til CSV
$results | Export-Csv -Path "C:\Logs\ServerHealth_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv" -NoTypeInformation
```

**Output:**
```
ComputerName Timestamp           CPU_Percent Memory_Percent Memory_Available_MB
------------ ---------           ----------- -------------- -------------------
DC1          2026-01-29 14:30:15       12.54          45.23              3456.00
SRV1         2026-01-29 14:30:15        8.93          38.12              4523.00
```

---

### Forbedring 2: Feilhåndtering

Legg til robust error handling:

```powershell
$scriptblock = { 
    try {
        $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples
        $memPercent = (Get-Counter '\Memory\% Committed Bytes In Use').CounterSamples
        $memAvailable = (Get-Counter '\Memory\Available MBytes').CounterSamples
        
        [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            Status = "Success"
            CPU_Percent = [math]::Round($cpu.CookedValue, 2)
            Memory_Percent = [math]::Round($memPercent.CookedValue, 2)
            Memory_Available_MB = [math]::Round($memAvailable.CookedValue, 2)
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            Status = "Failed"
            CPU_Percent = $null
            Memory_Percent = $null
            Memory_Available_MB = $null
            ErrorMessage = $_.Exception.Message
        }
    }
}

$results = Invoke-Command -ComputerName dc1,srv1,offline-server -ScriptBlock $scriptblock -ErrorAction SilentlyContinue

# Vis suksessfulle
$results | Where-Object Status -eq "Success" | Format-Table -AutoSize

# Vis feilede
$results | Where-Object Status -eq "Failed" | Format-Table ComputerName, ErrorMessage -AutoSize
```

---

### Forbedring 3: Fargekodet output med terskelverdier

```powershell
$scriptblock = { 
    $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples
    $memPercent = (Get-Counter '\Memory\% Committed Bytes In Use').CounterSamples
    $memAvailable = (Get-Counter '\Memory\Available MBytes').CounterSamples
    
    [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        CPU = [math]::Round($cpu.CookedValue, 2)
        MemoryPercent = [math]::Round($memPercent.CookedValue, 2)
        MemoryAvailableMB = [math]::Round($memAvailable.CookedValue, 2)
    }
}

$results = Invoke-Command -ComputerName dc1,srv1 -ScriptBlock $scriptblock

foreach ($server in $results) {
    Write-Host "`n=== $($server.ComputerName) ===" -ForegroundColor Cyan
    
    # CPU Status
    $cpuColor = if ($server.CPU -gt 80) { "Red" } elseif ($server.CPU -gt 60) { "Yellow" } else { "Green" }
    Write-Host "  CPU: $($server.CPU)%" -ForegroundColor $cpuColor
    
    # Memory Status
    $memColor = if ($server.MemoryPercent -gt 90) { "Red" } elseif ($server.MemoryPercent -gt 75) { "Yellow" } else { "Green" }
    Write-Host "  Memory Used: $($server.MemoryPercent)%" -ForegroundColor $memColor
    Write-Host "  Memory Available: $($server.MemoryAvailableMB) MB" -ForegroundColor $memColor
}
```

**Output:**
```
=== DC1 ===
  CPU: 12.54% (Grønn)
  Memory Used: 45.23% (Grønn)
  Memory Available: 3456.00 MB (Grønn)

=== SRV1 ===
  CPU: 85.32% (Rød)
  Memory Used: 92.15% (Rød)
  Memory Available: 412.50 MB (Rød)
```

---

### Forbedring 4: Kontinuerlig overvåking med loop

```powershell
$scriptblock = { 
    $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples
    $memPercent = (Get-Counter '\Memory\% Committed Bytes In Use').CounterSamples
    $memAvailable = (Get-Counter '\Memory\Available MBytes').CounterSamples
    
    [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        Timestamp = Get-Date -Format "HH:mm:ss"
        CPU = [math]::Round($cpu.CookedValue, 2)
        MemPercent = [math]::Round($memPercent.CookedValue, 2)
        MemAvailMB = [math]::Round($memAvailable.CookedValue, 2)
    }
}

Write-Host "Kontinuerlig overvåking startet. Trykk Ctrl+C for å stoppe..." -ForegroundColor Yellow
Write-Host ""

while ($true) {
    Clear-Host
    Write-Host "=== Server Health Dashboard ===" -ForegroundColor Cyan
    Write-Host "Sist oppdatert: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host ""
    
    $results = Invoke-Command -ComputerName dc1,srv1 -ScriptBlock $scriptblock -ErrorAction SilentlyContinue
    $results | Format-Table -AutoSize
    
    Start-Sleep -Seconds 5
}
```

---

### Forbedring 5: Logging til fil

```powershell
$logPath = "C:\Logs\ServerMonitoring"
if (-not (Test-Path $logPath)) {
    New-Item -Path $logPath -ItemType Directory -Force | Out-Null
}

$scriptblock = { 
    $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples
    $memPercent = (Get-Counter '\Memory\% Committed Bytes In Use').CounterSamples
    $memAvailable = (Get-Counter '\Memory\Available MBytes').CounterSamples
    
    [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        Timestamp = Get-Date
        CPU_Percent = [math]::Round($cpu.CookedValue, 2)
        Memory_Percent = [math]::Round($memPercent.CookedValue, 2)
        Memory_Available_MB = [math]::Round($memAvailable.CookedValue, 2)
    }
}

# Overvåk hvert 30. sekund i 10 minutter
$duration = 10  # minutter
$interval = 30  # sekunder
$samples = ($duration * 60) / $interval

for ($i = 1; $i -le $samples; $i++) {
    Write-Progress -Activity "Server Monitoring" -Status "Sample $i av $samples" -PercentComplete (($i / $samples) * 100)
    
    $results = Invoke-Command -ComputerName dc1,srv1 -ScriptBlock $scriptblock
    
    # Append til CSV
    $logFile = "$logPath\ServerHealth_$(Get-Date -Format 'yyyyMMdd').csv"
    $results | Export-Csv -Path $logFile -NoTypeInformation -Append
    
    # Sjekk for kritiske verdier
    $critical = $results | Where-Object { $_.CPU_Percent -gt 90 -or $_.Memory_Percent -gt 90 }
    if ($critical) {
        $critical | ForEach-Object {
            $alert = "[ALERT] $($_.ComputerName) - CPU: $($_.CPU_Percent)% | Memory: $($_.Memory_Percent)%"
            Write-Host $alert -ForegroundColor Red
            Add-Content -Path "$logPath\Alerts_$(Get-Date -Format 'yyyyMMdd').txt" -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $alert"
        }
    }
    
    if ($i -lt $samples) {
        Start-Sleep -Seconds $interval
    }
}

Write-Host "`nOvervåking fullført. Logg lagret i: $logFile" -ForegroundColor Green
```

---

## Troubleshooting

### Problem 1: "Access is denied"

**Feilmelding:**
```
[dc1] Connecting to remote server dc1 failed with the following error message : 
Access is denied.
```

**Løsninger:**

1. **Sjekk administrative rettigheter:**
```powershell
# Sjekk om du kjører som administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
```

2. **Bruk riktig administratorkonto:**
```powershell
# Spesifiser credentials
$cred = Get-Credential -UserName "InfraIT\adm_torivli" -Message "Enter admin password"
Invoke-Command -ComputerName dc1 -Credential $cred -ScriptBlock { $env:COMPUTERNAME }
```

3. **Sjekk Remote Management Users gruppe:**
```powershell
# På målserveren
Get-LocalGroupMember -Group "Remote Management Users"
```

---

### Problem 2: "WinRM cannot process the request"

**Feilmelding:**
```
WinRM cannot process the request. The following error occurred while using 
Kerberos authentication: Cannot find the computer dc1.
```

**Løsninger:**

1. **DNS-problemer:**
```powershell
# Test DNS-oppløsning
Resolve-DnsName dc1.InfraIT.sec

# Alternativt bruk FQDN
Invoke-Command -ComputerName dc1.InfraIT.sec -ScriptBlock { hostname }
```

2. **Test WS-Man connectivity:**
```powershell
Test-WSMan -ComputerName dc1
```

3. **Sjekk TrustedHosts (for workgroup):**
```powershell
# Kun nødvendig utenfor domene
Get-Item WSMan:\localhost\Client\TrustedHosts
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "dc1,srv1" -Force
```

---

### Problem 3: Timeout eller treg respons

**Symptom:**
Kommandoen henger i lang tid før den returnerer.

**Løsninger:**

1. **Reduser timeout:**
```powershell
$sessionOption = New-PSSessionOption -OpenTimeout 10000  # 10 sekunder
Invoke-Command -ComputerName dc1,srv1 -ScriptBlock $scriptblock -SessionOption $sessionOption
```

2. **Test nettverksforbindelse:**
```powershell
Test-Connection -ComputerName dc1 -Count 2 -Quiet
```

3. **Bruk AsJob for lange operasjoner:**
```powershell
$job = Invoke-Command -ComputerName dc1,srv1 -ScriptBlock $scriptblock -AsJob
Wait-Job $job
Receive-Job $job
```

---

### Problem 4: "Performance counter ... is not valid"

**Feilmelding:**
```
The specified object was not found on the computer.
```

**Løsninger:**

1. **Verifiser at telleren eksisterer på målserveren:**
```powershell
Invoke-Command -ComputerName dc1 -ScriptBlock {
    Get-Counter -ListSet Memory | Select-Object -ExpandProperty Counter
}
```

2. **Bruk riktig tellernavn for OS-versjonen:**
```powershell
# Noen tellere har forskjellige navn på forskjellige Windows-versjoner
# Sjekk tilgjengelige tellere først
```

---

## Øvingsoppgaver

### Oppgave 1: Grunnleggende remote monitoring

1. Aktiver WinRM på DC1 og SRV1 (hvis ikke allerede aktivert)
2. Test remote connectivity med `Test-WSMan`
3. Kjør det grunnleggende scriptet og verifiser output
4. Identifiser hvilken server som har høyest CPU-bruk

**Forventet tidsbruk:** 10-15 minutter

---

### Oppgave 2: Utvid med disk-overvåking

Utvid scriptet til også å inkludere disk-informasjon:
- `\PhysicalDisk(_Total)\% Disk Time`
- `\PhysicalDisk(_Total)\Current Disk Queue Length`

**Hint:**
```powershell
$disk = (Get-Counter '\PhysicalDisk(_Total)\% Disk Time').CounterSamples
```

---

### Oppgave 3: Lag strukturert output

Modifiser scriptet til å returnere objekter i stedet for `Write-Host`:
1. Bruk `[PSCustomObject]` for strukturert data
2. Eksporter resultatene til CSV
3. Åpne CSV-filen i Excel og analyser dataene

**Bonus:** Legg til fargekodet konsoll-output basert på terskelverdier

---

### Oppgave 4: Implementer feilhåndtering

Legg til error handling i scriptet:
1. Bruk `try/catch` rundt Get-Counter kommandoer
2. Håndter situasjonen hvor en server er offline
3. Logg feil til en separat fil

**Test:** Legg til en ikke-eksisterende server i listen og se at scriptet håndterer det

---

### Oppgave 5: Avansert - Multi-server dashboard

Lag et komplett overvåkningsscript som:
1. Leser serverliste fra en tekstfil
2. Kjører kontinuerlig overvåking (hvert 10. sekund)
3. Viser fargekodet dashboard i konsollen
4. Logger til CSV når verdier overskrider terskler
5. Sender e-postvarsel ved kritiske hendelser (bonus)

**Struktur:**
```
C:\Scripts\
  ├── Monitor-Servers.ps1
  ├── ServerList.txt
  └── Logs\
      ├── ServerHealth_20260129.csv
      └── Alerts_20260129.txt
```

---

## Oppsummering

I denne modulen har du lært:

✅ **PowerShell Remoting:** Hvordan kjøre kommandoer på fjernservere  
✅ **ScriptBlocks:** Pakking av kode for remote execution  
✅ **Invoke-Command:** Multi-server management  
✅ **Performance Monitoring:** Overvåke CPU, minne og disk  
✅ **Parallell kjøring:** Effektiv skalerbar administrasjon  
✅ **Feilhåndtering:** Robust error handling i enterprise-scripts  
✅ **Best practices:** Strukturert output og logging  

### Neste steg

- Utforsk **PowerShell Sessions** (`New-PSSession`) for persistent connections
- Lær om **PowerShell Jobs** for asynkron kjøring
- Studer **PowerShell Desired State Configuration (DSC)** for konfigurasjonsstyring
- Implementer **Just Enough Administration (JEA)** for sikker delegering

---

## Nyttige kommandoer - Quick Reference

```powershell
# Test remote connectivity
Test-WSMan -ComputerName DC1

# Enkel remote command
Invoke-Command -ComputerName DC1 -ScriptBlock { Get-Service }

# Med credentials
$cred = Get-Credential
Invoke-Command -ComputerName DC1 -Credential $cred -ScriptBlock { Get-Service }

# Persistent session
$session = New-PSSession -ComputerName DC1
Invoke-Command -Session $session -ScriptBlock { Get-Process }
Remove-PSSession $session

# Interactive session
Enter-PSSession -ComputerName DC1
# ... kommandoer ...
Exit-PSSession

# Copy files to remote server
Copy-Item -Path "C:\Scripts\script.ps1" -Destination "C:\Scripts\" -ToSession $session
```

---

## Sikkerhetsbeste praksis

⚠️ **Viktige sikkerhetshensyn:**

1. **Bruk alltid dedikerte admin-kontoer** (`adm_<brukernavn>`)
2. **Aktiver PowerShell logging** (Module/Script Block Logging)
3. **Begrens WinRM til administrative nettverk**
4. **Bruk HTTPS for WinRM når mulig**
5. **Implementer JEA for begrenset delegering**
6. **Audit remote sessions** via Windows Event Logs
7. **Roter credentials regelmessig**

**Event Logs å overvåke:**
- Event ID 4648: Logon med explicit credentials
- Event ID 4688: Process creation (PowerShell.exe)
- PowerShell Operational Log: Event ID 4103/4104

---

**Laget for:** 2. semester, Bachelor i Digital infrastruktur i cybersikkerhet  
**Fagansvarlig:** Tor Ivar  
**Testmiljø:** InfraIT.sec domain (DC1, SRV1, CL1, MGR)  
**Forutsetninger:** Grunnleggende PowerShell-kunnskap, Get-Counter-modulen

---

*Lykke til med remote monitoring! 🚀*