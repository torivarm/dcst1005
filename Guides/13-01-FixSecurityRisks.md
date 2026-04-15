# Lab 13-01: Klargjøring av InfraIT.sec sikkerhetsvurderingsmiljø

I denne labben setter du opp infrastrukturen du skal gjennomføre sikkerhetsvurderingen på. Du bruker VS Code på din egen maskin til å kjøre PowerShell-scriptet som oppretter nettverks- og backend-ressursene, og deretter Azure Cloud Shell til å deploye kundeportalen.

Når infrastrukturen er på plass, går du videre til Lab 13-02 der selve sikkerhetsvurderingen gjennomføres.

> **Merk om kostnader:** Infrastrukturen inneholder en VM og en AKS-lignende konfigurasjon som faktureres per time. Slett alle ressurser samme dag etter at du har presentert funnene dine for læringsassistent.

---

## Forutsetninger

Følgende må være på plass på din lokale maskin før du starter:

PowerShell 7 er installert. Sjekk med `pwsh --version` i terminalen.

Az PowerShell-modulen er installert. Sjekk med:

```powershell
Get-Module -Name Az -ListAvailable | Select-Object Name, Version
```

Azure CLI er installert. Sjekk med `az --version` i terminalen. Azure CLI kreves fordi scriptet bruker `az webapp`-kommandoer for å opprette App Service med korrekt Python-runtime.

VS Code er installert med PowerShell-extension.

Hvis noen av disse mangler, installer dem fra tidligere lab-instruksjoner før du fortsetter.

---

## Del 1 — Last ned og klargjør scripts

### Steg 1.1 — Last ned scriptfilene

Last ned følgende to filer fra Github og lagre dem i en mappe du benytter til script for DCST1005

- [Deploy infrastructure, security lab](13-00-Deploy-InfraITsec-SecurityLab.ps1)
- [Deploy App Service Cloud Shell Portal](13-00-Deploy-AppService-Portal.sh)

### Steg 1.2 — Åpne mappen i VS Code

Åpne VS Code og velg **File → Open Folder**. Naviger til mappen der du lagret scriptfilene og åpne den.

Du skal nå se begge filene i VS Code sin filutforsker til venstre.

### Steg 1.3 — Finn din Tenant ID

Du trenger Tenant ID fra Azure Portal. Naviger til **Microsoft Entra ID → Overview** og kopier verdien fra feltet **Tenant ID**.

| Felt | Eksempel |
|------|---------|
| Tenant ID | `ec25d615-a67b-411a-9073-de7880b3b8a3` |

Ha denne verdien klar — du trenger den i neste steg.

---

## Del 2 — Kjør deployment-scriptet fra VS Code

### Steg 2.1 — Åpne et PowerShell-terminalvindu

I VS Code velger du **Terminal → New Terminal**. Kontroller at terminalen bruker PowerShell 7 — du skal se `PS` i prompten. Hvis du ser `bash` eller `zsh`, klikk på pilen ved siden av `+` i terminalfeltet og velg **PowerShell**.

### Steg 2.2 — Kjør scriptet

Naviger til mappen der scriptet ligger og kjør det:

```powershell
.\13-00-Deploy-InfraITsec-SecurityLab.ps1
```

```powershell
# Mac / Linux
./13-00-Deploy-InfraITsec-SecurityLab.ps1
```

### Steg 2.3 — Skriv inn prefiks og Tenant ID

Scriptet spør deg om to verdier:

```
Skriv inn prefiks (f.eks. on03): on03
Skriv inn Tenant ID: ec25d615-a67b-411a-9073-de7880b3b8a3
```

Skriv inn ditt eget prefiks og Tenant ID-en du kopierte i Steg 1.3.

### Steg 2.4 — Autentiser mot Azure

Scriptet åpner en nettleserside der du logger inn med din `@stud.ntnu.no`-konto. Logg inn og gå tilbake til VS Code.

Hvis nettleservinduet ikke åpner seg automatisk, vil du se en device authentication-kode i terminalen. Gå da til `https://microsoft.com/devicelogin` og skriv inn koden.

### Steg 2.5 — Følg med på fremdriften

Scriptet kjører gjennom 11 steg og skriver statusmeldinger underveis:

| Farge | Betydning |
|-------|-----------|
| Grønn `[NY]` | Ressursen ble opprettet |
| Gul `[EKSISTERER]` | Ressursen fantes allerede, hoppet over |
| Cyan `[OPPDATERT]` | Ressursen ble endret |

Scriptet tar omtrent 5–10 minutter å fullføre. VM-opprettelsen tar lengst tid.

### Steg 2.6 — Verifiser oppsummeringen

Når scriptet er ferdig skal du se en oppsummeringsblokk som dette:

```
═══════════════════════════════════════════════════════════════
 DEPLOYMENT FULLFORT — on03
═══════════════════════════════════════════════════════════════
 Hub:
   on03-vnet-hub (10.0.0.0/16)
   on03-vm-jumpbox — Public IP: 20.x.x.x
 Frontend:
   on03-vnet-frontend (10.1.0.0/16)
   https://on03-app-infraitsec.azurewebsites.net
 Backend:
   on03-vnet-backend (10.2.0.0/16)
   on03stginfraisec | on03-kv-infraitsec | on03-sql-infraitsec
═══════════════════════════════════════════════════════════════
 NESTE STEG:
   Kjør Deploy-AppService-Portal.sh i Azure Cloud Shell
═══════════════════════════════════════════════════════════════
```

Noter deg App Service-URL-en — du trenger den for å verifisere portalen i Del 3.

---

## Del 3 — Deploy kundeportalen i Azure Cloud Shell

PowerShell-scriptet opprettet App Service med riktig runtime, men uten innhold. Dette steget deployer selve kundeportalen.

### Steg 3.1 — Åpne Azure Cloud Shell

Naviger til [portal.azure.com](https://portal.azure.com) og klikk på Cloud Shell-ikonet øverst i navigasjonsfeltet. Velg **Bash** hvis du får valget.

### Steg 3.2 — Last opp Bash-scriptet

Klikk på opplastingsikonet i Cloud Shell-verktøylinjen (ser ut som en mappe med pil opp) og velg `Deploy-AppService-Portal.sh` fra din lokale maskin.

Alternativt kan du laste opp via Cloud Shell's filoverføringsfunksjon:

```bash
# Verifiser at filen er lastet opp
ls ~/ | grep Deploy
```

Du skal se `Deploy-AppService-Portal.sh` i output.

### Steg 3.3 — Gi scriptet kjøretillatelse og kjør det

```bash
chmod +x ~/Deploy-AppService-Portal.sh
bash ~/Deploy-AppService-Portal.sh
```

### Steg 3.4 — Skriv inn prefiks

Scriptet spør etter ditt prefiks:

```
Skriv inn ditt prefiks (f.eks. on03): on03
```

Skriv inn det samme prefikset du brukte i Del 2.

### Steg 3.5 — Vent på deployment

Scriptet gjennomfører følgende steg automatisk:

- Setter Python 3.11 som runtime på App Service
- Oppretter applikasjonsfiler (Flask-app og HTML)
- Pakker filene og deployer via zip
- Setter oppstartkommando og restarter App Service
- Verifiserer at portalen svarer

Når scriptet er ferdig skal du se:

```
═══════════════════════════════════════════════════════
 DEPLOYMENT FULLFORT — on03
═══════════════════════════════════════════════════════
 App Service: https://on03-app-infraitsec.azurewebsites.net
 Status:      HTTP 200 — kundeportalen er oppe
═══════════════════════════════════════════════════════
```

Hvis status viser en annen HTTP-kode, vent 1–2 minutter og last inn URL-en på nytt i nettleseren.

---

## Del 4 — Verifiser infrastrukturen

### Steg 4.1 — Åpne kundeportalen

Åpne URL-en `https://<prefix>-app-infraitsec.azurewebsites.net` i nettleseren. Du skal se InfraIT.sec sin kundeportal med en innloggingsside.

Legg merke til at portalen ikke krever autentisering for å vise innhold — enhver som kjenner URL-en kan nå den.

### Steg 4.2 — Sjekk resource groups i Azure Portal

Naviger til **Resource groups** i Azure Portal. Du skal se tre nye resource groups:

| Resource group | Innhold |
|----------------|---------|
| `<prefix>-rg-infraitsec-hub` | VNET, NSG, jumpbox-VM, Public IP |
| `<prefix>-rg-infraitsec-frontend` | VNET, App Service Plan, App Service |
| `<prefix>-rg-infraitsec-backend` | VNET, Storage Account, Key Vault, SQL Server, ACR |

### Steg 4.3 — Verifiser at blob-innhold er tilgjengelig

Åpne følgende URL direkte i nettleseren uten å logge inn i Azure:

```
https://<prefix>stginfraisec.blob.core.windows.net/interne-dokumenter/ansattliste-2024.txt
```

Erstatt `<prefix>` med ditt eget prefiks. Hvis du ser innholdet i filen, er infrastrukturen korrekt satt opp og klar for sikkerhetsvurderingen.

---

## Del 5 — Start sikkerhetsvurderingen

Infrastrukturen er nå klar. Gå videre til **Lab 13-02: Sikkerhetsvurdering av InfraIT.sec** og start gjennomgangen av de 8 sikkerhetsmessige svakhetene.

Hint-systemet er tilgjengelig på **[URL]** hvis du trenger hjelp underveis.