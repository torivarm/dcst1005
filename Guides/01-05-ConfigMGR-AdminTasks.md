# Installasjon av utviklingsverktøy på Windows 11

## Oversikt
Denne guiden viser hvordan du setter opp et komplett utviklingsmiljø på Windows 11 ved hjelp av PowerShell og Chocolatey package manager.

**Programvare som installeres:**
- **Chocolatey** - Package manager for Windows
- **PowerShell Core** (PowerShell 7+) - Moderne PowerShell-versjon
- **Visual Studio Code** - Kodeeditor
- **Git** - Versjonskontrollsystem

**Maskin:** Windows 11 klient (f.eks. CL1, MGR)

---

## Hva er Chocolatey?

**Chocolatey** er en package manager for Windows, inspirert av Linux-verktøy som `apt` og `yum`.

### Fordeler med Chocolatey:
- ✅ Installer programvare med én kommando
- ✅ Oppdater all programvare sentralt
- ✅ Ingen klikking gjennom installasjonsveivisere
- ✅ Automatisering og scripting
- ✅ Tusenvis av tilgjengelige pakker

**Eksempel:** I stedet for å:
1. Åpne nettleser
2. Søke etter "download Visual Studio Code"
3. Laste ned installer
4. Kjøre installer
5. Klikke "Next, Next, Next, Finish"

...kan du bare skrive: `choco install vscode -y`

---

## Forutsetninger

- Windows 11-maskin med administratorrettigheter
- Internettilgang
- PowerShell 5.1 eller nyere (kommer med Windows 11)

---

## Steg 1: Åpne PowerShell som Administrator

Chocolatey-installasjonen krever administratorrettigheter.

### Metode 1: Fra Start-menyen
1. Klikk på **Start**
2. Søk etter: `PowerShell`
3. **Høyreklikk** på **Windows PowerShell**
4. Velg **Run as administrator**
5. Klikk **Yes** i UAC-dialogen

---

## Steg 2: Sjekk Execution Policy

Før vi installerer Chocolatey, må vi sjekke PowerShells Execution Policy.

```powershell
Get-ExecutionPolicy
```

**Forventet resultat:** `Restricted`, `AllSigned`, eller `RemoteSigned`

### Hvis resultatet er "Restricted":

Du må endre Execution Policy for å tillate script-kjøring:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```

**Forklaring:**
- `Bypass` - Tillater alle scripts å kjøre (kun for denne prosessen)
- `-Scope Process` - Endringen gjelder kun for denne PowerShell-økten
- `-Force` - Ingen bekreftelsesdialog

**Sikkerhetsnote:** Dette er trygt for Chocolatey-installasjonen, og endringen tilbakestilles når du lukker PowerShell.

---

## Steg 3: Installer Chocolatey

Nå skal vi installere Chocolatey package manager.

### 3.1: Kopier og kjør installasjonskommandoen

Kjør følgende kommando i PowerShell (som administrator):

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

**Hva skjer:**
1. Setter midlertidig Execution Policy
2. Aktiverer TLS 1.2 for sikker nedlasting
3. Laster ned og kjører Chocolatey-installasjonsscriptet

**Tid:** Installasjonen tar vanligvis 30-60 sekunder.

### 3.2: Verifiser installasjonen

Etter at installasjonen er fullført, kjør:

```powershell
choco --version
```

**Forventet resultat:** Du ser versjonsnummeret til Chocolatey (f.eks. `2.2.2`)

**Hvis "choco" ikke gjenkjennes:**
- Lukk PowerShell-vinduet
- Åpne et nytt PowerShell-vindu som administrator
- Prøv `choco --version` igjen

---

## Steg 4: Installer PowerShell Core

PowerShell Core (PowerShell 7+) er den nyeste, cross-platform versjonen av PowerShell.

### Hvorfor PowerShell Core?
- ✅ Nyere funksjoner og cmdlets
- ✅ Bedre ytelse
- ✅ Aktiv utvikling (Windows PowerShell 5.1 er i maintenance mode)
- ✅ Cross-platform (Windows, macOS, Linux)
- ✅ Bedre håndtering av moderne API-er

### Installer med Chocolatey:

```powershell
choco install powershell-core -y
```

**Forklaring:**
- `choco install` - Chocolatey-kommando for å installere pakker
- `powershell-core` - Pakkenavnet
- `-y` - Godtar automatisk alle dialoger (yes to all)

**Tid:** Installasjonen tar vanligvis 1-2 minutter.

**Forventet resultat:** Du ser installasjonsfremgang og til slutt:
```
Chocolatey installed 1/1 packages.
```

### Verifiser installasjonen:
Start PowerShell 7.x ved å søke på PowerShell i Start menyen
```powershell
pwsh --version
```

**Forventet resultat:** `PowerShell 7.x.x`

---

## Steg 5: Installer Visual Studio Code

Visual Studio Code (VS Code) er en lett, kraftig kodeeditor fra Microsoft.

### Hvorfor VS Code?
- ✅ Gratis og open source
- ✅ Støtte for mange programmeringsspråk
- ✅ Innebygd Git-integrasjon
- ✅ Tusenvis av extensions
- ✅ Integrert terminal
- ✅ Ekstremt populær i IT-bransjen

### Installer med Chocolatey:

```powershell
choco install vscode -y
```

**Tid:** Installasjonen tar vanligvis 2-3 minutter.

**Forventet resultat:** Du ser installasjonsfremgang og til slutt:
```
Chocolatey installed 1/1 packages.
```

### Verifiser installasjonen:

```powershell
code --version
```

**Forventet resultat:** Versjonsnummer vises (f.eks. `1.85.1`)

---

## Steg 6: Installer Git

Git er et distribuert versjonskontrollsystem for å spore endringer i kode.

### Hvorfor Git?
- ✅ Industristandard for versjonskontroll
- ✅ Nødvendig for å jobbe med GitHub, GitLab, Azure DevOps
- ✅ Spor endringer i kode og konfigurasjoner
- ✅ Samarbeid med andre utviklere
- ✅ Rulle tilbake til tidligere versjoner

### Installer med Chocolatey:

```powershell
choco install git -y
```

**Tid:** Installasjonen tar vanligvis 1-2 minutter.

**Forventet resultat:** Du ser installasjonsfremgang og til slutt:
```
Chocolatey installed 1/1 packages.
```

### Verifiser installasjonen:

**Lukk og åpne PowerShell på nytt** (for å laste inn PATH-endringer), deretter kjør:

```powershell
git --version
```

**Forventet resultat:** `git version 2.x.x.windows.x`

---

## Steg 7: Konfigurer Git med bruker og e-post

Git trenger å vite hvem du er for å knytte commits til deg.

### 7.1: Sett globalt brukernavn

```powershell
git config --global user.name "Ditt Navn"
```

**Eksempel:**
```powershell
git config --global user.name "Ola Nordmann"
```

### 7.2: Sett global e-postadresse

```powershell
git config --global user.email "din.epost@example.com"
```

**Eksempel:**
```powershell
git config --global user.email "ola.nordmann@stud.ntnu.no"
```

### 7.3: Verifiser Git-konfigurasjonen

```powershell
git config --global --list
```

**Forventet resultat:**
```
user.name=Ola Nordmann
user.email=ola.nordmann@infrait.sec
```

### 7.4: Valgfri konfigurasjon - sett standard editor til VS Code

```powershell
git config --global core.editor "code --wait"
```

**Forklaring:** Når Git trenger at du skriver en melding (f.eks. commit message), åpnes VS Code i stedet for Vim eller Notepad.

### 7.5: Valgfri konfigurasjon - sett default branch-navn

```powershell
git config --global init.defaultBranch main
```

**Forklaring:** Nyere Git-versjoner bruker "main" i stedet for "master" som standard branch-navn.

---

## Steg 8: Åpne Visual Studio Code

Nå skal vi åpne VS Code for å installere PowerShell-extension.

### Metode 1: Fra PowerShell
```powershell
code
```

### Metode 2: Fra Start-menyen
1. Klikk på **Start**
2. Søk etter: `Visual Studio Code`
3. Klikk på programmet

**Første gang VS Code åpnes:**
- Du kan bli spurt om å velge tema (lyst/mørkt)
- Du kan bli spurt om å installere ekstra funksjoner
- Bare følg veiviseren eller velg "Skip" for nå

---

## Steg 9: Installer PowerShell Extension i VS Code

PowerShell-extension gir VS Code fantastisk støtte for PowerShell-utvikling.

### Metode 1: Via Extensions-panel (anbefalt)

1. I VS Code, klikk på **Extensions**-ikonet i venstre sidebar
   - Eller trykk `Ctrl + Shift + X`
2. Søk etter: `PowerShell`
3. Finn **PowerShell** extension (utgiver: Microsoft)
4. Klikk **Install**

**Tid:** Installasjonen tar vanligvis 10-30 sekunder.

### Metode 2: Via Quick Open

1. Trykk `Ctrl + P` i VS Code
2. Skriv: `ext install ms-vscode.powershell`
3. Trykk **Enter**

### Metode 3: Via PowerShell (fra terminalen i VS Code)

```powershell
code --install-extension ms-vscode.powershell
```

### 9.1: Verifiser installasjonen

1. Åpne Extensions-panelet (`Ctrl + Shift + X`)
2. Søk etter "PowerShell"
3. Du skal se **PowerShell** extension med en ✓ eller "Installed"

### 9.2: Test PowerShell-extension

1. I VS Code, trykk `Ctrl + N` (ny fil)
2. Skriv: `Write-Host "Hello from PowerShell!"`
3. Trykk `Ctrl + S` for å lagre
4. Gi filen navnet `test.ps1`
5. Du skal se syntax highlighting (farger) i koden
6. Trykk `F5` eller `Ctrl + F5` for å kjøre scriptet

**Forventet resultat:** Du ser "Hello from PowerShell!" i terminalen nederst i VS Code.

---

## Steg 10: Konfigurer VS Code for PowerShell

Her er noen anbefalte innstillinger for PowerShell-utvikling i VS Code.

### 10.1: Sett PowerShell Core som standard

1. Åpne VS Code Settings: `Ctrl + ,`
2. Søk etter: `terminal.integrated.defaultProfile.windows`
3. Velg **PowerShell** (ikke "Windows PowerShell")

---

## Steg 11: Verifiser hele installasjonen

La oss verifisere at alt er installert og konfigurert riktig.

### Opprett et testscript

1. Åpne VS Code
2. Opprett en ny fil: `Ctrl + N`
3. Kopier inn følgende kode:

```powershell
# Verifisering av installasjon
Write-Host "`n=== Verifikasjon av utviklingsmiljø ===" -ForegroundColor Cyan

# Sjekk PowerShell-versjon
Write-Host "`nPowerShell versjon:" -ForegroundColor Green
$PSVersionTable.PSVersion

# Sjekk Chocolatey
Write-Host "`nChocolatey versjon:" -ForegroundColor Green
choco --version

# Sjekk Git
Write-Host "`nGit versjon:" -ForegroundColor Green
git --version

# Sjekk Git-konfigurasjon
Write-Host "`nGit-konfigurasjon:" -ForegroundColor Green
Write-Host "Navn: $(git config --global user.name)"
Write-Host "E-post: $(git config --global user.email)"

# Sjekk VS Code
Write-Host "`nVS Code versjon:" -ForegroundColor Green
code --version

Write-Host "`n=== Alle verktøy er installert! ===" -ForegroundColor Green
```

4. Lagre filen som `verify-install.ps1`
5. Kjør scriptet: `F5`

**Forventet resultat:** Du ser versjoner og konfigurasjon for alle verktøyene.

---

## Nyttige Chocolatey-kommandoer

Nå som du har Chocolatey installert, her er noen nyttige kommandoer:

### Søk etter pakker
```powershell
choco search <pakkenavn>
```

**Eksempel:**
```powershell
choco search python
```

### Liste installerte pakker
```powershell
choco list
```

### Oppgrader en pakke
```powershell
choco upgrade <pakkenavn> -y
```

**Eksempel:**
```powershell
choco upgrade git -y
```

### Oppgrader alle pakker
```powershell
choco upgrade all -y
```

### Avinstaller en pakke
```powershell
choco uninstall <pakkenavn> -y
```

### Få informasjon om en pakke
```powershell
choco info <pakkenavn>
```

---

## Nyttige VS Code-snarveier

| Snarvei | Funksjon |
|---------|----------|
| `Ctrl + P` | Quick Open (åpne filer raskt) |
| `Ctrl + Shift + P` | Command Palette (alle kommandoer) |
| `Ctrl + ,` | Åpne Settings |
| `Ctrl + Shift + X` | Extensions |
| `Ctrl + `` ` (backtick) | Toggle terminal |
| `Ctrl + K, Ctrl + T` | Bytt fargetema |
| `F5` | Kjør/debug script |
| `Ctrl + F5` | Kjør uten debugging |
| `Ctrl + /` | Toggle kommentar |
| `Alt + Shift + F` | Formater dokument |

---

## Nyttige Git-kommandoer for nybegynnere

### Opprett et nytt Git repository
```powershell
git init
```

### Sjekk status på filer
```powershell
git status
```

### Legg til filer for commit
```powershell
git add .               # Legg til alle endrede filer
git add filnavn.ps1    # Legg til en spesifikk fil
```

### Commit endringer
```powershell
git commit -m "Beskrivelse av endringer"
```

### Se commit-historikk
```powershell
git log
git log --oneline      # Kompakt visning
```

### Koble til et remote repository (f.eks. GitHub)
```powershell
git remote add origin https://github.com/brukernavn/repo.git
```

### Push endringer til remote
```powershell
git push -u origin main
```

---

## Installasjon av tilleggsprogramvare via Chocolatey

Her er noen andre nyttige pakker du kan installere via Chocolatey:

### Utviklerverktøy
```powershell
choco install nodejs -y              # Node.js
choco install python -y              # Python
choco install dotnet-sdk -y          # .NET SDK
choco install azure-cli -y           # Azure CLI
choco install terraform -y           # Terraform
```

### Verktøy
```powershell
choco install 7zip -y                # 7-Zip
choco install notepadplusplus -y     # Notepad++
choco install putty -y               # PuTTY
choco install winscp -y              # WinSCP
choco install postman -y             # Postman (API testing)
```

### Browsere
```powershell
choco install firefox -y             # Firefox
choco install googlechrome -y        # Google Chrome
```

---

## Feilsøking

### Problem: "choco: The term 'choco' is not recognized"

**Løsninger:**
1. Lukk PowerShell og åpne på nytt som administrator
2. Kjør: `$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")`
3. Hvis det fortsatt ikke fungerer, restart maskinen

### Problem: "code: The term 'code' is not recognized"

**Løsninger:**
1. Lukk og åpne PowerShell på nytt
2. Restart maskinen
3. Manuelt legg til VS Code i PATH:
   - Åpne Environment Variables
   - Legg til: `C:\Program Files\Microsoft VS Code\bin` i PATH

### Problem: Git-kommandoer fungerer ikke

**Løsninger:**
1. Lukk og åpne PowerShell på nytt
2. Verifiser at Git er installert: `choco list git`
3. Reinstaller: `choco uninstall git -y` og `choco install git -y`

### Problem: PowerShell Extension laster ikke

**Løsninger:**
1. Sjekk at PowerShell Core er installert: `pwsh --version`
2. I VS Code, åpne Output-panel (`Ctrl + Shift + U`)
3. Velg "PowerShell" fra dropdown
4. Les feilmeldinger
5. Prøv å reinstallere extension

---

## Best practices

### 1. Hold programvare oppdatert
Kjør regelmessig:
```powershell
choco upgrade all -y
```

### 2. Bruk Git for alt utviklingsarbeid
- Opprett Git repositories for scripts
- Commit ofte med beskrivende meldinger
- Bruk `.gitignore` for å ekskludere sensitive filer

### 3. Organiser koden din
- Bruk mapper for forskjellige prosjekter
- Kommenter koden din
- Følg PowerShell best practices (godkjente verb, etc.)

### 4. Lær snarveier
- VS Code har mange nyttige snarveier
- Øv på de viktigste (`Ctrl + P`, `Ctrl + Shift + P`, `F5`)

### 5. Utforsk Extensions
- VS Code har tusenvis av extensions
- Søk etter extensions for dine behov (Docker, Kubernetes, Azure, etc.)

---

## Oppsummering

Du har nå installert og konfigurert:
- ✅ **Chocolatey** - Package manager for fremtidige installasjoner
- ✅ **PowerShell Core** - Moderne PowerShell-versjon
- ✅ **Visual Studio Code** - Kodeeditor med PowerShell-støtte
- ✅ **Git** - Versjonskontroll med bruker og e-post konfigurert

**Du er nå klar til å:**
- Skrive og kjøre PowerShell-scripts i VS Code
- Bruke Git for versjonskontroll
- Installere mer programvare via Chocolatey
- Utvikle profesjonelt med moderne verktøy

**Gratulerer!** Du har satt opp et komplett utviklingsmiljø på Windows 11! 🎉