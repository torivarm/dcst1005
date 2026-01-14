# Installasjon av PowerShell Core via PSRemoting (Sikker metode)

## Oversikt
Denne guiden viser hvordan du installerer PowerShell Core på domenemaskinene **uten** å installere package managers som Chocolatey. Dette er en mer sikker tilnærming som ligner på hvordan enterprise-miljøer deployerer software.

**Metode:** Remote installasjon fra MGR ved hjelp av MSI-fil  
**Fordeler:**
- ✅ Ingen 3rd party package managers på servere/klienter
- ✅ Kontrollert software deployment
- ✅ Følger enterprise best practices
- ✅ Holder Domain Controller ren og minimal

---

## Forutsetninger

1. **Last ned PowerShell Core MSI** på MGR-maskinen
   - Gå til: https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows?view=powershell-7.5#msi 
   - Klikk på MSI Last ned: `PowerShell-7.5.4-win-x64.msi` (eller nyeste versjon)
   - Lagre i: `C:\install\`

2. **Logg inn på MGR** som din domain admin

3. **Åpne PowerShell som Administrator** på MGR

---

## Konsept: PowerShell Remoting

**PowerShell Remoting (PSRemoting)** lar deg kjøre kommandoer på fjerne maskiner over nettverket.

### To måter å bruke PSRemoting:

1. **Enter-PSSession** - Interaktiv sesjon (som SSH)
   - Du "går inn" i maskinen og jobber der
   - Godt for testing og feilsøking
   - Avsluttes med `Exit-PSSession`

2. **New-PSSession + Invoke-Command** - Persistent sesjon (for automatisering)
   - Oppretter en sesjon du kan bruke flere ganger
   - Perfekt for å kopiere filer og kjøre scripts
   - Mer effektivt for automatisering

---

## Steg 1: Test PSRemoting-tilkobling

Før vi installerer, skal vi teste at PSRemoting fungerer til alle maskiner.

```powershell
# Test interaktiv tilkobling til hver maskin
Enter-PSSession -ComputerName dc1
# Du er nå "inne" på DC1
# Skriv: hostname (for å bekrefte)
# Skriv: exit (for å gå ut)

Enter-PSSession -ComputerName srv1
# Test på SRV1
exit

Enter-PSSession -ComputerName cl1
# Test på CL1
exit
```

**Hva skjer:**
- Prompten endres til `[dc1]: PS C:\>` når du er koblet til
- Du kan kjøre kommandoer som om du satt ved maskinen
- `exit` eller `Exit-PSSession` avslutter forbindelsen

**Hvis det fungerer:** Gå videre til Steg 2.  
**Hvis det IKKE fungerer:** Gå til Feilsøking-seksjonen nederst.

---

## Steg 2: Installer PowerShell Core på DC1

Nå skal vi installere PowerShell Core på DC1 ved å bruke en persistent sesjon.

### 2.1: Opprett en PSSession til DC1

```powershell
$session = New-PSSession -ComputerName dc1
```

**Forklaring:**
- `New-PSSession` oppretter en persistent forbindelse til DC1
- Lagres i variabelen `$session` for gjenbruk
- Forblir åpen til du lukker den eller PowerShell avsluttes

### 2.2: Opprett install-mappen på DC1 (hvis den ikke finnes)

```powershell
Invoke-Command -Session $session -ScriptBlock {
    if (-not (Test-Path "C:\install")) {
        New-Item -Path "C:\install" -ItemType Directory -Force | Out-Null
        Write-Host "Opprettet C:\install mappe på $env:COMPUTERNAME"
    } else {
        Write-Host "C:\install finnes allerede på $env:COMPUTERNAME"
    }
}
```

**Forklaring:**
- `Test-Path` sjekker om mappen eksisterer
- `New-Item -ItemType Directory` oppretter mappen hvis den ikke finnes
- `-Force` sikrer at mappen opprettes uten bekreftelse
- `Out-Null` skjuler output (mappen opprettes i bakgrunnen)

**Hvorfor dette er viktig:** `Copy-Item` feiler hvis målmappen ikke eksisterer på remote-maskinen!

### 2.3: Kopier MSI-filen til DC1

```powershell
Copy-Item -Path "C:\install\PowerShell-7.5.4-win-x64.msi" -Destination "C:\install" -ToSession $session
```

**Forklaring:**
- `Copy-Item` kopierer filen fra MGR til DC1
- `-Path` er filens lokasjon på MGR
- `-Destination` er hvor filen lagres på DC1
- `-ToSession` bruker PSSession til å kopiere over nettverket

**Resultat:** Filen `PowerShell-7.5.4-win-x64.msi` ligger nå i `C:\install\` på DC1

### 2.4: Installer MSI-filen på DC1

```powershell
Invoke-Command -Session $session -ScriptBlock {
    Start-Process "msiexec.exe" -ArgumentList "/i C:\install\PowerShell-7.5.4-win-x64.msi /quiet /norestart" -Wait
}
```

**Forklaring:**
- `Invoke-Command` kjører en kommando på fjern maskin
- `-Session $session` bruker den eksisterende sesjonen til DC1
- `-ScriptBlock { ... }` er koden som kjøres på DC1
- `Start-Process msiexec.exe` starter Windows Installer
  - `/i` = Install
  - `/quiet` = Ingen brukerinteraksjon (silent install)
  - `/norestart` = Ikke restart automatisk
  - `-Wait` = Vent til installasjonen er ferdig før scriptet fortsetter

**Tid:** Installasjonen tar vanligvis 1-2 minutter.


### 2.6: Lukk sesjonen (valgfritt)

```powershell
Remove-PSSession $session
```

**Forklaring:**
- Lukker forbindelsen til DC1
- Frigjør ressurser
- Ikke strengt nødvendig (lukkes automatisk når du lukker PowerShell)

---

## Steg 3: Installer på SRV1

Gjenta samme prosess for SRV1:

```powershell
# Opprett sesjon
$session = New-PSSession -ComputerName srv1

# Opprett install-mappen hvis den ikke finnes
Invoke-Command -Session $session -ScriptBlock {
    if (-not (Test-Path "C:\install")) {
        New-Item -Path "C:\install" -ItemType Directory -Force | Out-Null
    }
}

# Kopier MSI
Copy-Item -Path "C:\install\PowerShell-7.5.4-win-x64.msi" -Destination "C:\install" -ToSession $session

# Installer
Invoke-Command -Session $session -ScriptBlock {
    Start-Process "msiexec.exe" -ArgumentList "/i C:\install\PowerShell-7.5.4-win-x64.msi /quiet /norestart" -Wait
}

# Verifiser
Invoke-Command -Session $session -ScriptBlock { $PSVersionTable }

# Lukk sesjon
Remove-PSSession $session
```

---

## Steg 4: Installer på CL1 (Her må en Aktiver PSRemoting først)
Logg inn på CL1 via Remote Desktop og kjør følgende kommando i PowerShell som administrator:
```powershell
Enable-PSRemoting -Force
```

Gjenta samme prosess for CL1:

```powershell
# Opprett sesjon
$session = New-PSSession -ComputerName cl1

# Opprett install-mappen hvis den ikke finnes
Invoke-Command -Session $session -ScriptBlock {
    if (-not (Test-Path "C:\install")) {
        New-Item -Path "C:\install" -ItemType Directory -Force | Out-Null
    }
}

# Kopier MSI
Copy-Item -Path "C:\install\PowerShell-7.5.4-win-x64.msi" -Destination "C:\install" -ToSession $session

# Installer
Invoke-Command -Session $session -ScriptBlock {
    Start-Process "msiexec.exe" -ArgumentList "/i C:\install\PowerShell-7.5.4-win-x64.msi /quiet /norestart" -Wait
}

# Verifiser
Invoke-Command -Session $session -ScriptBlock { $PSVersionTable }

# Lukk sesjon
Remove-PSSession $session
```

---

## Automatisert script for alle maskiner

For å installere på alle maskiner samtidig, bruk dette scriptet:

```powershell
# Definer maskiner
$computers = @("dc1", "srv1", "cl1")

# Installer på hver maskin
foreach ($computer in $computers) {
    Write-Host "`nInstallerer PowerShell Core på $computer..." -ForegroundColor Cyan
    
    # Opprett sesjon
    $session = New-PSSession -ComputerName $computer
    
    # Opprett install-mappen hvis den ikke finnes
    Write-Host "  Sjekker/oppretter C:\install mappe..." -ForegroundColor Yellow
    Invoke-Command -Session $session -ScriptBlock {
        if (-not (Test-Path "C:\install")) {
            New-Item -Path "C:\install" -ItemType Directory -Force | Out-Null
        }
    }
    
    # Kopier MSI
    Write-Host "  Kopierer installasjonsfil..." -ForegroundColor Yellow
    Copy-Item -Path "C:\install\PowerShell-7.5.4-win-x64.msi" -Destination "C:\install" -ToSession $session
    
    # Installer
    Write-Host "  Installerer (dette tar 1-2 minutter)..." -ForegroundColor Yellow
    Invoke-Command -Session $session -ScriptBlock {
        Start-Process "msiexec.exe" -ArgumentList "/i C:\install\PowerShell-7.5.4-win-x64.msi /quiet /norestart" -Wait
    }
    
    # Verifiser
    Write-Host "  Verifiserer installasjon..." -ForegroundColor Yellow
    $version = Invoke-Command -Session $session -ScriptBlock { 
        (Get-Item "C:\Program Files\PowerShell\7\pwsh.exe").VersionInfo.ProductVersion 
    }
    Write-Host "  ✓ PowerShell Core $version installert på $computer" -ForegroundColor Green
    
    # Lukk sesjon
    Remove-PSSession $session
}

Write-Host "`nInstallasjon fullført på alle maskiner!" -ForegroundColor Green
```

---

## Feilsøking: Hvis PSRemoting ikke fungerer

### Problem: "Access is denied" eller kan ikke koble til

Dette skyldes vanligvis at PSRemoting ikke er aktivert på målmaskinen.

### Løsning: Aktiver PSRemoting på målmaskinen

**Du må logge inn på hver maskin (DC1, SRV1, CL1) og kjøre følgende:**

#### Metode 1: Aktiver PSRemoting (anbefalt)

```powershell
Enable-PSRemoting -Force
```

**Forklaring:**
- Aktiverer PSRemoting på maskinen
- Konfigurerer Windows Remote Management (WinRM)
- `-Force` hopper over bekreftelsesdialog

**Hva skjer:**
- WinRM-tjenesten startes og settes til automatisk start
- Brannmurregler opprettes for PSRemoting
- Listener opprettes for innkommende forespørsler

#### Metode 2: Aktiver Kerberos-autentisering (hvis nødvendig)

```powershell
winrm set winrm/config/service/auth '@{Kerberos="true"}'
```

**Forklaring:**
- Aktiverer Kerberos-autentisering for WinRM
- Kerberos er den anbefalte autentiseringsmetoden i domener
- Mer sikker enn NTLM

#### Metode 3: Verifiser autentiseringsinnstillinger

```powershell
winrm get winrm/config/service/auth
```

**Forventet resultat:**
```
Auth
    Basic = false
    Kerberos = true
    Negotiate = true
    Certificate = false
    ...
```

**Viktig:** `Kerberos = true` bør være aktivert i domenemiljøer.

### Problem: "The WinRM client cannot process the request"

**Løsning:** Sjekk at WinRM-tjenesten kjører:

```powershell
# Sjekk status
Get-Service WinRM

# Start tjenesten hvis den ikke kjører
Start-Service WinRM

# Sett til automatisk start
Set-Service WinRM -StartupType Automatic
```

### Problem: Brannmur blokkerer tilkobling

**Løsning:** Sjekk brannmurregler:

```powershell
# Vis PSRemoting-brannmurregler
Get-NetFirewallRule -Name "WINRM-HTTP-In-TCP*"

# Aktiver regel hvis deaktivert
Enable-NetFirewallRule -Name "WINRM-HTTP-In-TCP"
```

---

## Hvorfor denne metoden er bedre enn Chocolatey

### Sammenligning:

| Aspekt | MSI via PSRemoting | Chocolatey på alle maskiner |
|--------|-------------------|----------------------------|
| **Sikkerhet** | ✅ Høy - Ingen 3rd party package managers | ⚠️ Lavere - Ukjente maintainers |
| **Kontroll** | ✅ Full kontroll over hva som installeres | ⚠️ Pakker kan endres av andre |
| **Audit** | ✅ MSI-filer er signerte og verifiserbare | ⚠️ Vanskelig å auditere pakker |
| **Enterprise** | ✅ Standard tilnærming i produksjon | ❌ Ikke anbefalt i enterprise |
| **Kompleksitet** | 🟡 Krever litt mer arbeid | 🟢 Enklere (men mindre sikkert) |
| **DC-hygiene** | ✅ Holder DC minimal og sikker | ❌ Ekstra software på DC |

### Best practice i enterprise:
- **Domain Controllers** skal være minimale og kun kjøre nødvendige tjenester
- Software deployment skal være kontrollert og auditert
- Bruk MSI/EXE-filer direkte i stedet for package managers

---

## Oppsummering

Du har nå lært:

1. **PSRemoting-konseptet:**
   - `Enter-PSSession` for interaktiv testing
   - `New-PSSession` for persistent forbindelse
   - `Invoke-Command` for å kjøre kommandoer remotely

2. **Sikker software deployment:**
   - Kopierer MSI-fil til målmaskin med `Copy-Item`
   - Installerer med `msiexec.exe` (silent install)
   - Verifiserer installasjon

3. **Feilsøking:**
   - Aktiver PSRemoting med `Enable-PSRemoting`
   - Aktiver Kerberos-autentisering
   - Sjekk WinRM-tjeneste og brannmur

4. **Enterprise best practices:**
   - Ikke installer package managers på alle maskiner
   - Bruk kontrollerte MSI/EXE-installasjoner
   - Hold Domain Controllers minimale

**Resultat:** PowerShell Core er nå installert på alle maskiner i domenet på en sikker og kontrollert måte! 🎉