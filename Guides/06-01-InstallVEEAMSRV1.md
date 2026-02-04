# Laste ned og installere VEEAM på SRV1

## Innledning

**VEEAM Backup & Replication** er en profesjonell backup-løsning som brukes i mange enterprise-miljøer for sikkerhetskopi av servere, VM-er og data. I denne guiden lærer du hvordan du:

- Kobler til SRV1 via Remote Desktop
- Laster ned VEEAM-installasjonsfil (.iso) og lisensfil direkte til D:\
- Starter installasjonen ved å dobbeltklikke på ISO-filen

> **Hvorfor D:\?** I vårt testmiljø er C:\-disken (boot-disk) begrenset i størrelse. VEEAM-installasjonsfiler er store (4-6 GB), og installasjonen krever betydelig diskplass. Derfor bruker vi D:\-volumet som har mer tilgjengelig plass.

---

## Del 1: Koble til SRV1 via Remote Desktop
- Kjent fremgangsmåte..

## Del 2: Forbered D:\-disken

### Steg 1: Åpne File Explorer
1. Inne på SRV1, klikk på **File Explorer**-ikonet i oppgavelinjen
2. Opprett deretter en mappe som heter InstallFiles. Høyreklikk og velg:
   1. ![alt text](newFolderVEEAM.png)
---

## Del 2: Last ned VEEAM-filer fra filesender.sikt.no

### Steg 1: Få tilgang til nedlastingslenken
1. Lenken for nedlasting ligger i BlackBoard under Undervisningsmateriell.
   1. MERK! Last ned filen på SRV1 maskinen, ikke til din egen maskin. Kopier lenken inn til SRV1.
   2. ![alt text](CopyLinkSRV1.png)
2. Åpne deretter lenken på SRV1 i Edge, og **høyreklikk på Donwnload-knappen og velg Save link as..**
   1. ![alt text](RightClickDownload.png)
3. Velg å **laste ned til D:\InstallFiles mappen som tidligere opprettet**
   1. ![alt text](SaveOnD.png)

**Nedlastingen starter:**
- Du vil se fremdriften nederst i nettleservinduet
- Nedlastingen kan ta **5-20 minutter** avhengig av nettverkshastighet
- En ISO-fil på ~5 GB ved 50 Mbps tar ca. 13 minutter

> **Viktig**: Mens nedlastingen pågår:
> - **Ikke lukk nettleseren**

### Steg 2: Sjekk nedlastingsfremdrift

**Slik ser du fremdriften:**
1. Klikk på **nedlastingsikonet** (pil ned) i øvre høyre hjørne av Edge
2. Eller trykk **Ctrl+J** for å åpne nedlastingsoversikten
3. Du vil se:
   - Filnavn
   - Nedlastet størrelse / Total størrelse
   - Gjenstående tid
   - Fremdriftslinje
![alt text](DownloadISO.png)


### Steg 3: Last ned lisensfilen

**Mens ISO-filen lastes ned** (eller etter at den er ferdig), last ned lisensfilen:

1. Kopier lenken til lisensfilen fra BlackBoard inn til SRV1 og last ned filen.

> **Merk**: Lisensfilen er veldig liten (5 KB) og lastes ned umiddelbart (under 1 sekund).

### Steg 4: Vent til ISO-filen er ferdig nedlastet

**Hvordan vet du at nedlastingen er fullført?**
1. Åpne nedlastingsoversikten (Ctrl+J)
2. Når nedlastingen er ferdig, vil det stå:
   - **"Show in folder"** eller **"Vis i mappe"**
   - Ingen fremdriftslinje
   - Grønn hake eller "Complete"

---

## Del 3: Verifiser nedlastede filer

### Steg 1: Åpne File Explorer og gå til D:\VEEAM
1. Åpne File Explorer (Windows + E)
2. Naviger til **D:\InstallFiles**

### Steg 2: Sjekk at begge filene er der
Du skal nå se to filer:
- **VeeamBackup&Replication_XX.X.X.XXXX.iso** (ca. 3-6 GB)
- **veeam_backup_nfr_XX_XXXXX.lic** (ca. 5 KB)
- 
---

## Del 4: Monter ISO-filen og start installasjonen

### Steg 1: Monter ISO-filen
1. I File Explorer, naviger til **D:\VEEAM**
2. **Dobbeltklikk på ISO-filen** (VeeamBackup&Replication_XX.X.X.XXXX.iso)
3. Windows vil automatisk "montere" ISO-en som et virtuelt DVD-drev
   1. ![alt text](MountISO.png)
   2. ![alt text](SetupEXE.png)
   3. ![alt text](run.png)
4. Hvis du får en "User Account Control"-melding, klikk **Yes**

**Hva skjer:**
- ISO-filen blir behandlet som om du satte inn en DVD
- Et nytt drev dukker opp i **This PC** (f.eks. E:\ eller F:\)
- File Explorer åpner automatisk det nye drevet

---

## Del 5: Følg installasjonsveiviseren

### Steg 1: Velkomstsiden
1. Du vil se VEEAM-velkomstsiden
2. Klikk **Install** under "Veeam ONE"
   1. ![alt text](VEEAMOneInstall.png)
3. Velg **Install Veeam ONE**
   1. ![alt text](InstallOne.png)
4. **"License agreement"**
5. Klikk **I Accept**
6. Velg deretter å finne frem til lisensfilen som en har lastet ned tidligere:
   1. ![alt text](BrowsLicense.png)
   2. ![alt text](LicenseFile.png)
7. Klikk **Next**

> **Viktig**: Hvis du hopper over dette steget, vil VEEAM installeres i trial-modus (30 dager).

### Steg 2: Angi domenekonto for Veeam ONE
![alt text](domainAccountVEEAM.png)
Vent deretter på **System Configuration Check** (kan ta litt tid)

### Steg 3: Velg installasjonsplassering
### 1. Customize Settings
![alt text](CustomizeSettings.png)
### 2. Klikk **Next**, med alle Components markert for installasjon
![alt text](Components.png)
### 3. La Monitoring Database stå til default valg:
![alt text](MonitoringDatabase.png)
### 4. La Reporting Database stå til default valg:
![alt text](ReportingDatabase.png)
### 5. Velg deretter å installere det på D:\ i stedet for på C:\
![alt text](BrowseLocation.png)
### 6. Velg D:\ -> Høyreklikk, og velg New Folder. Navngi mappen VEEAM
![alt text](NewFOlderD.png)
### 7. Dobbeltklikk på mappen VEEAM og velg deretter Select Folder:
![alt text](SelectFolderVEEAM.png)
### 8. Når den er ferdig med å sjekke tilgjengelig diskplass, sjekk at det står til D:\ og trykk deretter Next
![alt text](DriveCorrect.png)
### 9. La det stå til Veeam backup data only
![alt text](VeeamDataOnly.png)
### 10. La alle porter stå til default
![alt text](Ports.png)
### 11. Install - Vil ta litt tid! Det er mye som skal installeres.. Database, applikasjon etc. etc..
![alt text](Install.png)

### Steg 3: Default Backup Repository

**Dette er viktig - vi skal bruke D:\ for backup-lagring!**

1. Du vil se en sti for "Default backup repository"
2. **Standard er C:\Backup** - dette må endres!
3. Klikk **Browse** eller **Bla gjennom**
4. Naviger til **D:\**
5. Klikk **Make New Folder** eller **Opprett ny mappe**
6. Gi mappen navnet **VeeamBackup**
7. Velg denne mappen (D:\VeeamBackup)
8. Klikk **OK** og deretter **Next**

> **Hvorfor D:\?** Backup-filer kan bli svært store og C:\ har begrenset plass.

### Steg 7: Database Configuration
1. VEEAM bruker en database for å holde oversikt over backups
2. **Standard**: VEEAM installerer sin egen SQL Server Express-instans
3. **Anbefaling**: La standardvalgene stå for lab-miljø
4. Klikk **Next**

### Steg 8: Service Account
1. VEEAM trenger en tjenestekonto
2. **Anbefaling for lab**: Bruk **Local System account**
3. I produksjonsmiljø ville man brukt en dedikert domenekonto
4. Klikk **Next**

### Steg 9: Default Gateway Server Ports
1. Her konfigureres porter for kommunikasjon
2. **Anbefaling**: La standardportene stå (9392, 9395, osv.)
3. Klikk **Next**

### Steg 10: Ready to Install
1. Du vil nå se en oppsummering av installasjonsvalg
2. **Verifiser at backup repository er på D:\VeeamBackup**
3. Klikk **Install** for å starte installasjonen

### Steg 11: Installasjonsprosess
- Installasjonen tar **10-20 minutter**
- Du vil se fremdrift for ulike komponenter
- Ikke avbryt installasjonen

### Steg 12: Installation Complete
1. Når installasjonen er ferdig, vil du se "Installation Complete"
2. Huk av for **"Launch Veeam Backup & Replication Console"** hvis du vil åpne programmet
3. Klikk **Finish**

---

## Del 7: Verifiser installasjonen

### Steg 1: Sjekk at VEEAM er installert
1. Åpne **Start-menyen**
2. Søk etter **"Veeam"**
3. Du skal se:
   - **Veeam Backup & Replication Console**
   - **Veeam Backup & Replication Documentation**

### Steg 2: Åpne VEEAM Console
1. Klikk på **Veeam Backup & Replication Console**
2. Hvis du får en User Account Control-melding, klikk **Yes**
3. VEEAM Console åpner
4. Du skal se hovedvinduet med menylinjer og verktøy

### Steg 3: Verifiser lisens
1. I VEEAM Console, klikk på **Menu** (øverst til venstre)
2. Velg **License** eller **Lisens**
3. Sjekk at:
   - Lisenstype vises (NFR - Not For Resale)
   - Utløpsdato vises
   - Status er **Valid**

### Steg 4: Sjekk diskforbruk
1. Åpne File Explorer (Windows + E)
2. Høyreklikk på **D:\**
3. Velg **Properties** eller **Egenskaper**
4. Sjekk **Free space** - du skal fortsatt ha flere GB ledig

---

## Beste Praksis og Tips

### Mappestruktur etter installasjon
Etter installasjonen vil D:\ ha følgende struktur:
```
D:\
├── VEEAM\
│   ├── VeeamBackup&Replication_XX.X.X.XXXX.iso  (kan slettes etter installasjon)
│   └── veeam_backup_nfr_XX_XXXXX.lic            (behold denne!)
└── VeeamBackup\                                  (opprettet under installasjon)
    └── (backup-filer vil lagres her)
```

### Skal jeg slette ISO-filen?
**Anbefaling:**
- **Behold ISO-filen** hvis du har plass (for re-installasjon eller reparasjon)
- **Slett ISO-filen** hvis du trenger diskplass
- **Alltid behold lisensfilen** - den er liten og nødvendig

**Slik sletter du ISO-filen:**
1. Først, **avmonter ISO-filen**:
   - Gå til **This PC** i File Explorer
   - Høyreklikk på det virtuelle DVD-drevet (f.eks. E:\)
   - Velg **Eject** eller **Løs ut**
2. Gå til **D:\VEEAM**
3. Høyreklikk på ISO-filen
4. Velg **Delete**

### Sikkerhetskopiering av lisensfil
**Viktig:**
1. Lisensfilen er verdifull og bør sikkerhetskopieres
2. Kopier **veeam_backup_nfr_XX_XXXXX.lic** til en trygg lokasjon:
   - Lagre en kopi på din lokale PC
   - Eller send til deg selv på e-post
   - Eller lagre i et delt område som ikke slettes

---

## Vanlige Problemer og Løsninger

### Problem: "Nedlastingen stopper ved 50%"
**Mulige årsaker:**
- Nettverksproblemer
- RDP-tilkobling ble brutt

**Løsning:**
1. Sjekk nettverkstilkobling til SRV1
2. Gjenopprett RDP-tilkobling hvis den ble brutt
3. Gå til filesender.sikt.no-lenken igjen
4. Last ned på nytt - de fleste nettlesere fortsetter nedlastingen

### Problem: "ISO-filen monteres ikke når jeg dobbeltklikker"
**Løsning:**
1. Høyreklikk på ISO-filen
2. Velg **Mount** eller **Monter**
3. Hvis dette alternativet ikke finnes:
   - Høyreklikk → **Open with** → **Windows Explorer**

### Problem: "Setup.exe kjører ikke - 'Access Denied'"
**Løsning:**
- Sørg for at du er logget inn med administratorkonto (adm_<brukernavn>)
- Høyreklikk på Setup.exe → **Run as administrator**

### Problem: "Ikke nok plass til installasjon"
**Løsning:**
- Sjekk ledig plass på D:\ (høyreklikk → Properties)
- Du trenger minimum 10 GB ledig for en komfortabel installasjon
- Slett unødvendige filer eller utvid D:\-volumet

### Problem: "Kan ikke finne lisensfilen under installasjon"
**Løsning:**
1. Under installasjon, når du blir bedt om lisensfil
2. Klikk **Browse**
3. Naviger til **D:\VEEAM\**
4. Endre filtype-filteret nederst til **"All Files (*.*)"**
5. Nå skal du se .lic-filen

### Problem: "Installasjonen feiler under Database Configuration"
**Løsning:**
- VEEAM trenger å installere SQL Server Express
- Sørg for at C:\ har minst 2-3 GB ledig for SQL-installasjonen
- Restart SRV1 og prøv på nytt

---

## Oppsummering

Du har nå:
1. ✅ Koblet til SRV1 via Remote Desktop
2. ✅ Opprettet D:\VEEAM-mappe for nedlastede filer
3. ✅ Lastet ned VEEAM ISO-installasjonsfil (4-6 GB) til D:\VEEAM
4. ✅ Lastet ned VEEAM-lisensfil til D:\VEEAM
5. ✅ Montert ISO-filen ved å dobbeltklikke på den
6. ✅ Startet installasjonsveiviseren (Setup.exe)
7. ✅ Fulgt installasjonsveiviseren med fokus på å bruke D:\ for lagring
8. ✅ Verifisert at VEEAM er installert og lisensiert korrekt

---

## Neste Steg

I neste øvelse vil du lære:
- Hvordan konfigurere backup jobs i VEEAM
- Hvordan legge til servere og VM-er for backup
- Hvordan utføre restore-operasjoner
- Hvordan overvåke backup-status

**Gratulerer!** Du har nå installert enterprise backup-software på en profesjonell måte i lab-miljøet.