# Laste ned og installere VEEAM Data Platform Permium (tidligere Backup & Replication) på SRV1
# - Denne gjennomgangen vil ta tid, og det er en del venting.. 
# - Gjør den samtidig som noe annet :D

## Innledning

**VEEAM Data Platform Permium** er en profesjonell backup-løsning som brukes i mange enterprise-miljøer for sikkerhetskopi av servere, VM-er og data. I denne guiden lærer du hvordan du:

- Kobler til SRV1 via Remote Desktop
- Laster ned VEEAMDataPlatformPremim-installasjonsfil (.iso) direkte til D:\
- Starter installasjonen ved å dobbeltklikke på ISO-filen

> **Hvorfor D:\?** I vårt testmiljø er C:\-disken (boot-disk) begrenset i størrelse. VEEAM-installasjonsfiler er store (20 GB), og installasjonen krever betydelig diskplass. Derfor bruker vi D:\-volumet som har mer tilgjengelig plass.

**SJEKK C:\ Siden det vil også opprettes filer og database på C:\ underveis i installasjonen** 
- **UTFØR FØLGENDE STEG:**
> ![alt text](SjekkC.png)
> ![alt text](EmptyBin.png)

**FJERN WINDOWS UPDATE FILES**
>To remove downloaded Windows update files on Windows Server, stop the Windows Update service, delete the contents of C:\Windows\SoftwareDistribution\Download, and restart the service. This clears pending, failed, or downloaded update cache files to free up disk space. 

Steps to Clean Up Update Files
- Delete Downloaded Files
  - Navigate to C:\Windows\SoftwareDistribution\Download.
  - Select all files and folders, and delete them (use Shift+Delete for permanent removal / Shift + Right Click with Mouse and Delete).
    - ![alt text](DeleteAll.png)
    - ![alt text](DeleteFiles.png)
    - Om det ligger filer i Søppelbøtta etter at du har slettet installasjonsfiler, Empty Recycle Bin igjen:
    - ![alt text](EmptyBin.png)

---

## Del 2: Last ned VEEAM filer fra filesender.sikt.no

### Steg 1: Få tilgang til nedlastingslenken
1. Lenken for nedlasting ligger i BlackBoard under Undervisningsmateriell.
2. MERK! Last ned filen på SRV1 maskinen, ikke til din egen maskin. Kopier lenken inn til SRV1.
3. Åpne deretter lenken på SRV1 i Edge, og **høyreklikk på Donwnload-knappen og velg Save link as..**
   1. ![alt text](RightClickDownload.png)
4. Opprett en mappe på D:\ som heter InstallFiles å **laste ned til D:\InstallFiles** (se bort i fra VeeamONE filen, ikke relevant for oss)
   1. ![alt text](VEEAMBandRDL.png)

### Steg 2: Last ned lisensfil
1. Kopier lenken for lisensfilen fra BlackBoard over til SRV1
2. Last ned filen på SRV1, kan også legges på InstallFiles-mappen på D:\

### Steg 3: Se oversikt over tilgjengelige filer
Du vil nå se en liste over filer som kan lastes ned:
- **VeeamDataPlatformPremim_XX.X.X.XXXX.iso** - Installasjonsfil (ca. 20+ GB) - Stor fil, vil ta litt tid før den er ferdig nedlastet
- **Veeam_data_platform_premium_evalution_1000.lic** - Lisensfil. (ca 2KB)
- Klikk på **nedlastingsikonet** (pil ned) i øvre høyre hjørne av Edge
- Eller trykk **Ctrl+J** for å åpne nedlastingsoversikten
![alt text](FileAndSize2.png)



## Del 3: Monter ISO-filen og start installasjonen

### Steg 1: Monter ISO-filen
1. I File Explorer, naviger til **D:\InstallFiles**
2. **Dobbeltklikk på ISO-filen** (VeeamDataPlatformPremim_XX.X.X.XXXX.iso) ‼️ **MERK: Kan fort ta 3-7 minutter** før den faktisk dukker opp i File Explorer som eget drev (sånn som vises på bildet under E:)
3. Windows vil automatisk "montere" ISO-en som et virtuelt DVD-drev

**Hva skjer:**
- ISO-filen blir behandlet som om du satte inn en DVD
- Et nytt drev dukker opp i **This PC** (f.eks. E:\ eller F:\)
- File Explorer åpner automatisk det nye drevet

### Steg 2: Finn installasjonsveiviseren
Når ISO-en er montert, skal du se innholdet av installasjonsmediet:
- **Setup.exe** - Dette er installasjonsprogrammet 

### Steg 3: Start installasjonen
1. **Dobbeltklikk på Setup.exe** ‼️ **MERK: Kan fort ta 3-7 minutter** før selve installasjons veiviseren starter
2. Hvis du får en "User Account Control"-melding, klikk **Yes** eller **Ja**
3. VEEAM Data Platform Premium installasjonsveiviser starter
   1. ![alt text](VEEAMSetupDPP.png)

---

## Del 4: Følg installasjonsveiviseren

### Steg 1: Velkomstsiden
1. Du vil se VEEAM-velkomstsiden
2. Klikk **Install** og velg deretter Data Platform Premium
   1. ![alt text](DataPlatformPremium13.png)

### Steg 2: Lisensavtale
1. **"I accept the terms in the license agreement"**
1. Klikk **I Accept**

### Steg 3: Program Features
1. Her kan du velge hvilke komponenter som skal installeres
2. **Anbefaling for lab-miljø**: La alle standardvalg stå
3. Klikk **Next**
   1. ![alt text](ProgramFeatures.png)

### Steg 4: Lisensinstallasjon
1. Du vil bli bedt om å velge en lisensfil
2. Klikk **Browse** eller **Bla gjennom**
   1. ![alt text](BrowsLicense2.png)
3. Naviger til **D:\InstallFiles\veeam_backup_nfr_XX_XXXXX.lic**
4. Velg lisensfilen og klikk **Open**
5. Klikk **Next**

> **Viktig**: Hvis du hopper over dette steget, vil VEEAM installeres i trial-modus (30 dager).

### Steg 5: Service Account
1. Skriv inn passordet til din adm_bruker for domenet. Dobbeltsjekk at du også er innlogget som denne brukeren ved å trykke på Windows-iconet nede på startmenyen.
   1. ![alt text](PasswordAdmDomain.png)

## Del 5: System Configuration Check
1. Denne tar fort 15 minutter +. Hvis den sier Reboot, reboot.
   1. ![alt text](reboot.png)
2. Godta at den rebooter for å fullføre required components.
3. Remote Desktop vil avsluttes ved reboot. Gi maskinen litt tid til å restarte, og start deretter Remote Desktop igjen mot maskinen igjen og fortsett installasjonen.
4. Finn frem til D:\InstallFiles og klikk på installasjonsfilen for Veeam Data Platform Premium. **MERK! Tar litt tid**
5. Når det vises VEEAM i File Explorer, start **Setup** igjen. **MERK!** Det vil ta litt tid før selve installasjonsvinduet dukker opp etter at har klikket på Setup.
6. Når installasjonsvinduet endelig kommer opp igjen, Klikk INSTALL og følg veiviseren:
   1. ![alt text](InstallV2.png)
   2. ![alt text](WaitForSetup.png)
   3. ![alt text](LicenseV2.png)
   4. ![alt text](Nextv2.png)
   5. ![alt text](LicenseV22.png)
   6. ![alt text](LicenseV3.png)
   7. ![alt text](NextV3.png)
   8. ![alt text](CredentialsV2.png)
   9. ![alt text](CustomizationV2.png)
   10. ![alt text](Nextv4.png)
   11. ![alt text](Nextv5.png)
   12. ![alt text](Nextv6.png)
   13. ![alt text](ViktigV3.png)
   14. ![alt text](NewFolderV4.png)
   15. ![alt text](SelectFolderV2.png)
   16. ![alt text](Nextv7.png)
   17. ![alt text](Nextv8.png)
   18. ![alt text](Nextv9.png)
   19. ![alt text](InstallV4.png)
   20. ![alt text](TakeForever.png)

### Steg 20 føles ut som vil ta evig. Sett på, la det stå.


### Steg 12: Installation Complete
1. Når installasjonen er ferdig, vil du se "Installation Complete"
1. Klikk **Finish**

---


### Skal jeg slette ISO-filen?
**Anbefaling:**
- **Behold ISO-filen** hvis du har plass (for re-installasjon eller reparasjon)
- **Slett ISO-filen** Vi trenger diskplassen, slett filen :D
- **Alltid behold lisensfilen** - den er liten og nødvendig

**Slik sletter du ISO-filen:**
1. Først, **avmonter ISO-filen**:
   - Gå til **This PC** i File Explorer
   - Høyreklikk på det virtuelle DVD-drevet (f.eks. E:\)
   - Velg **Eject** eller **Løs ut**
2. Gå til **D:\InstallFiles**
3. Høyreklikk på ISO-filen
4. Velg **Delete**
5. Velg deretter å Empyt Recycle Bin
   1. ![alt text](EmptyBin.png)

---

## Vanlige Problemer og Løsninger

### Problem: "ISO-filen monteres ikke når jeg dobbeltklikker"
**Løsning:**
1. Høyreklikk på ISO-filen
2. Velg **Mount** eller **Monter**
3. Hvis dette alternativet ikke finnes:
   - Høyreklikk → **Open with** → **Windows Explorer**
   - 

### Problem: "Installasjonen feiler under Database Configuration"
**Løsning:**
- VEEAM trenger å installere SQL Server Express
- Sørg for at C:\ har minst 2-3 GB ledig for SQL-installasjonen
- Restart SRV1 og prøv på nytt

---

## Oppsummering

Du har nå:
1. ✅ Koblet til SRV1 via Remote Desktop
2. ✅ Opprettet D:\InstallFiles-mappe for nedlastede filer
3. ✅ Lastet ned VEEAM ISO-installasjonsfil (4-6 GB) til D:\InstallFiles
4. ✅ Lastet ned VEEAM-lisensfil til D:\InstallFiles
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