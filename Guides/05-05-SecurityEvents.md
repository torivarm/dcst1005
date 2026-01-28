# Windows Security Events - Grunnleggende Guide

**Fagmodul:** Windows Server Administrasjon  
**Tema:** Security Event Logging og overvåking

---

## 📚 Hva er Security Events?

**Security Events** er logger som Windows automatisk skriver når sikkerhetsrelevante hendelser skjer på serveren. Tenk på det som en "overvåkingskamera" som registrerer alt som har med autentisering og tilgang å gjøre.

### Hva lagres?

- 🔐 Pålogginger (vellykkede og mislykkede)
- 👤 Brukeradministrasjon (opprettet, slettet, endret)
- 📁 Filtilgang (hvem åpnet/endret hva)
- 🔑 Policy-endringer (sikkerhetspolicyer)
- 🎫 Kerberos-autentisering
- 🚪 Account lockouts

**Lokasjon:** `C:\Windows\System32\winevt\Logs\Security.evtx`

---

## 🎯 Hva bruker vi det til?

### I cybersikkerhet:
- ✅ Identifisere brute force-angrep
- ✅ Spore kompromitterte kontoer
- ✅ Dokumentere sikkerhetshendelser
- ✅ Etterleve compliance-krav (ISO 27001, PCI-DSS)
- ✅ Forensics etter sikkerhetsbrudd

### I daglig drift:
- 🔍 Troubleshoote påloggingsproblemer
- 📊 Analysere brukeradferd
- 📝 Audit-trails for endringer
- ⚠️ Varsle ved mistenkelig aktivitet

---

## 🖥️ Finne Security Events via GUI

### Metode 1: Event Viewer (lokalt)

1. **Åpne Event Viewer:**
   - Trykk `Windows + R`
   - Skriv: `eventvwr.msc`
   - Trykk Enter

2. **Naviger til Security-loggen:**
   ```
   Event Viewer
   └── Windows Logs
       └── Security
   ```

3. **Se hendelser:**
   - Dobbeltklikk på en hendelse for detaljer
   - Høyreklikk → Filter Current Log for å filtrere

**Hurtigtast:** `Windows + X` → Event Viewer

---

### Metode 2: Computer Management

1. **Åpne Computer Management:**
   - Høyreklikk på Start → Computer Management
   - Eller skriv: `compmgmt.msc`

2. **Naviger:**
   ```
   System Tools
   └── Event Viewer
       └── Windows Logs
           └── Security
   ```

---

### Metode 3: Server Manager

1. **Åpne Server Manager** (starter automatisk ved pålogging)
2. Klikk **Tools** → **Event Viewer**
3. Naviger til **Windows Logs → Security**

---

## 🔍 Filtrere i GUI

### Filter Current Log

**Høyreklikk på Security → Filter Current Log**

**Vanlige filtre:**

| Felt | Eksempel | Resultat |
|------|----------|----------|
| Event ID | `4624` | Vellykkede pålogginger |
| Event ID | `4625` | Mislykkede pålogginger |
| Event ID | `4740` | Account lockouts |
| Logged | `Last hour` | Siste timen |
| User | `Administrator` | Kun administrator-hendelser |

**Tips:** Flere Event IDs samtidig: `4624,4625,4634` (kommaseparert)

---

## 💻 PowerShell - Grunnleggende kommandoer

### 1. Hente de 10 nyeste Security Events

```powershell
Get-EventLog -LogName Security -Newest 10
```

**Output:**
```
Index Time          Type  Source                 EventID Message
----- ----          ----  ------                 ------- -------
12345 Jan 29 14:30  Audit Success Microsoft-Windows... 4624 An account was successfully logged on
12344 Jan 29 14:25  Audit Failure Microsoft-Windows... 4625 An account failed to log on
```

---

### 2. Vellykkede pålogginger (Event ID 4624)

```powershell
Get-EventLog -LogName Security -InstanceId 4624 -Newest 5
```

**Hva er Event ID 4624?**
- Loggføres hver gang noen logger på serveren
- Inneholder: brukernavn, tidspunkt, påloggingstype, IP-adresse

---

### 3. Mislykkede pålogginger (Event ID 4625) - VIKTIG!

```powershell
Get-EventLog -LogName Security -InstanceId 4625 -Newest 10
```

**Hvorfor viktig?**
- Identifiser brute force-angrep
- Se hvem som prøver å logge inn med feil passord
- Spor mistenkelig aktivitet

**Eksempel output:**
```powershell
Get-EventLog -LogName Security -InstanceId 4625 -Newest 3 | 
    Select-Object TimeGenerated, Message | 
    Format-List
```

---

### 4. Strukturert output med Get-WinEvent (moderne metode)

```powershell
Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    ID = 4625
} -MaxEvents 5
```

**Hvorfor Get-WinEvent?**
- Raskere enn Get-EventLog
- Bedre filtrering
- Støtter nyere event logs
- **Anbefalt metode**

---

## 📊 Praktiske eksempler

### Eksempel 1: Finn alle pålogginger siste 24 timer

```powershell
$startTime = (Get-Date).AddHours(-24)

Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    ID = 4624
    StartTime = $startTime
} | Select-Object TimeCreated, Message -First 10
```

---

### Eksempel 2: Hvem har logget inn i dag?

```powershell
Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    ID = 4624
} -MaxEvents 50 | ForEach-Object {
    [PSCustomObject]@{
        Time = $_.TimeCreated
        User = $_.Properties[5].Value
        LogonType = $_.Properties[8].Value
    }
} | Format-Table -AutoSize
```

**Output:**
```
Time                User          LogonType
----                ----          ---------
29.01.2026 14:30:00 Administrator 10
29.01.2026 14:25:00 torivli       2
29.01.2026 14:20:00 backup_svc    5
```

---

### Eksempel 3: Mislykkede pålogginger med detaljer

```powershell
Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    ID = 4625
} -MaxEvents 10 | ForEach-Object {
    [PSCustomObject]@{
        Time = $_.TimeCreated
        User = $_.Properties[5].Value
        Source = $_.Properties[19].Value  # IP-adresse
        Reason = $_.Properties[8].Value    # Logon Type
    }
} | Format-Table -AutoSize
```

**Output:**
```
Time                User          Source          Reason
----                ----          ------          ------
29.01.2026 14:30:00 Administrator 192.168.1.100   3
29.01.2026 14:25:00 testuser      192.168.1.50    10
```

---

### Eksempel 4: Tell antall mislykkede forsøk per bruker

```powershell
Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    ID = 4625
} -MaxEvents 100 | ForEach-Object {
    $_.Properties[5].Value  # Brukernavn
} | Group-Object | 
    Select-Object Count, Name | 
    Sort-Object Count -Descending
```

**Output:**
```
Count Name
----- ----
   15 Administrator
    8 testuser
    3 backup_adm
```

⚠️ **Advarsel:** 15 forsøk på Administrator = mulig brute force-angrep!

---

### Eksempel 5: Account lockouts (Event ID 4740)

```powershell
Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    ID = 4740
} -MaxEvents 10 | ForEach-Object {
    [PSCustomObject]@{
        Time = $_.TimeCreated
        LockedAccount = $_.Properties[0].Value
        LockedBy = $_.Properties[1].Value
    }
} | Format-Table -AutoSize
```

**Hva er account lockout?**
- Kontoen låses etter X mislykkede forsøk (definert i Group Policy)
- Event ID 4740 loggføres når dette skjer

---

## 🔑 Viktige Event IDs - Quick Reference

| Event ID | Beskrivelse | Når brukes det? |
|----------|-------------|-----------------|
| **4624** | Successful Logon | Spor hvem som logger inn |
| **4625** | Failed Logon | Identifiser angrep |
| **4634** | Logoff | Når noen logger ut |
| **4648** | Logon using explicit credentials | Bruk av `runas` |
| **4672** | Special privileges assigned | Admin-rettigheter tildelt |
| **4740** | Account locked out | Konto låst pga. for mange forsøk |
| **4768** | Kerberos TGT requested | Kerberos-autentisering |
| **4771** | Kerberos pre-auth failed | Feil passord (Kerberos) |

---

## 🚀 Avansert eksempel: Overvåk pålogginger live

```powershell
Write-Host "Monitoring failed logons... Press Ctrl+C to stop`n" -ForegroundColor Yellow

while ($true) {
    $events = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        ID = 4625
    } -MaxEvents 1 -ErrorAction SilentlyContinue
    
    if ($events) {
        $user = $events.Properties[5].Value
        $ip = $events.Properties[19].Value
        $time = $events.TimeCreated
        
        Write-Host "[$time] FAILED LOGIN: $user from $ip" -ForegroundColor Red
    }
    
    Start-Sleep -Seconds 5
}
```

**Bruk:** Åpne PowerShell-vindu og overvåk i sanntid!

---

## 📝 Oppgaver for studenter

### Oppgave 1: Grunnleggende utforskning
1. Åpne Event Viewer via GUI
2. Naviger til Security-loggen
3. Finn de 5 nyeste hendelsene
4. Identifiser Event ID og hva de betyr

---

### Oppgave 2: PowerShell basics
1. Hent de 10 nyeste Security Events med PowerShell
2. Filtrer kun Event ID 4624 (vellykkede pålogginger)
3. Hvor mange pålogginger er det totalt?

```powershell
# Hint:
(Get-EventLog -LogName Security -InstanceId 4624).Count
```

---

### Oppgave 3: Sikkerhetsvurdering
1. Sjekk om det er mislykkede pålogginger (Event ID 4625)
2. Hvis ja, hvem prøvde å logge inn?
3. Fra hvilken IP-adresse?
4. Er dette mistenkelig?

---

### Oppgave 4: Eksporter til rapport
Lag et script som:
1. Henter alle mislykkede pålogginger fra siste 7 dager
2. Eksporterer til CSV-fil
3. Åpner filen automatisk i Excel

```powershell
$events = Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    ID = 4625
    StartTime = (Get-Date).AddDays(-7)
}

$events | ForEach-Object {
    [PSCustomObject]@{
        Time = $_.TimeCreated
        User = $_.Properties[5].Value
        IP = $_.Properties[19].Value
    }
} | Export-Csv -Path "C:\Logs\FailedLogons.csv" -NoTypeInformation

Invoke-Item "C:\Logs\FailedLogons.csv"
```

---

## 🔧 Troubleshooting

### Problem: "No events found"

**Årsak:** Audit Policy er ikke aktivert

**Løsning:**
```powershell
# Sjekk audit policy
auditpol /get /category:"Logon/Logoff"

# Aktiver hvis nødvendig
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
```

---

### Problem: "Access Denied" i PowerShell

**Løsning:** Kjør PowerShell som Administrator
- Høyreklikk PowerShell → Run as Administrator

---

### Problem: For mange events, tar lang tid

**Løsning:** Bruk alltid `-MaxEvents` eller `-Newest`
```powershell
# TREGT (henter alle!)
Get-EventLog -LogName Security

# RASKT (kun 100 nyeste)
Get-EventLog -LogName Security -Newest 100
```

---

## ✅ Oppsummering

**Du har nå lært:**
- ✅ Hva Security Events er og hvorfor de er viktige
- ✅ Finne Security-loggen via GUI (Event Viewer)
- ✅ Bruke PowerShell til å hente hendelser
- ✅ Filtrere på Event ID (4624, 4625, etc.)
- ✅ Analysere påloggingsdata
- ✅ Identifisere sikkerhetstrusler

**Neste steg:**
- Lær om remote event log-spørring (`Invoke-Command`)
- Automatiser overvåking med scheduled tasks
- Integrer med SIEM-systemer
- Studer Windows Audit Policy i detalj

---

**Nøkkelkommandoer:**
```powershell
# GUI
eventvwr.msc

# PowerShell - grunnleggende
Get-EventLog -LogName Security -Newest 10
Get-EventLog -LogName Security -InstanceId 4625 -Newest 10

# PowerShell - moderne (anbefalt)
Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4625} -MaxEvents 10
```

---

**Laget for:** 2. semester, Bachelor i Digital infrastruktur i cybersikkerhet  
**Fagansvarlig:** Tor Ivar  
**Testmiljø:** InfraIT.sec domain

---

*Security Events = Din beste venn i sikkerhetshåndtering! 🔒*