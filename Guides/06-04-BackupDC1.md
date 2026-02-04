# Opprette Backup av DC1 i VEEAM Backup & Replication

## Innledning

**VEEAM Backup & Replication Console** er det sentrale administrasjonsverktøyet for å administrere backups i VEEAM-miljøet. Nå som du har installert VEEAM Backup & Replication på SRV1 og VEEAM Agent på DC1, er det på tide å konfigurere en faktisk backup job.

### Administrasjonsalternativer

Det finnes to måter å administrere VEEAM på:

1. **Fra SRV1** (anbefalt for denne øvelsen):
   - VEEAM Backup & Replication Console er allerede installert på SRV1
   - Direkte tilgang til backup-serveren
   - Enklest oppsett for lab-miljø

2. **Fra MGR** (profesjonell tilnærming):
   - Installér VEEAM Backup & Replication Console på MGR
   - Koble til VEEAM Backup & Replication Server på SRV1
   - Sentralisert administrasjon fra dedikert management-maskin
   - Dette er best practice i produksjonsmiljøer

> **I denne guiden**: Vi bruker SRV1 siden VEEAM Console allerede er installert der. I et senere avsnitt viser vi kort hvordan du kan installere Console på MGR for fremtidig bruk.

### Hva skal vi oppnå?

I denne guiden lærer du hvordan du:
- Åpner VEEAM Backup & Replication Console på SRV1
- Legger til DC1 som en "managed computer"
- Oppretter en backup job for DC1
- Konfigurerer hva som skal backupes (disk, System State)
- Setter opp backup-schedule
- Kjører første backup manuelt
- Verifiserer at backup er vellykket

---

## Del 1: Åpne VEEAM Console på SRV1

### Steg 1: Koble til SRV1
1. Åpne Remote Desktop Connection (mstsc)
2. Koble til **SRV1.InfraIT.sec**
3. Logg inn med **InfraIT\adm_<dittbrukernavn>**

### Steg 2: Start VEEAM Backup & Replication Console
1. Åpne **Start**-menyen
2. Søk etter **"Veeam Backup"**
3. Klikk på **Veeam Backup & Replication Console**
4. Hvis du får User Account Control-melding, klikk **Yes**

### Steg 3: Første gangs oppstart
Hvis dette er første gang du åpner VEEAM Console:
1. Du kan bli bedt om å koble til en backup server
2. **Server name** skal være: **localhost** (siden vi er på SRV1)
3. Klikk **Connect**

VEEAM Console åpner nå med hovedgrensesnittet.

### Steg 4: Gjør deg kjent med grensesnittet

**Hovedområder i VEEAM Console:**
- **Øverst**: Menybar og verktøylinje
- **Venstre**: Navigasjonspanel med:
  - **Home** - Dashboard og oversikt
  - **Backup & Replication** - Jobber og infrastruktur
  - **Inventory** - Beskyttede objekter
  - **History** - Logg over kjørte jobber
- **Midten**: Arbeidsområde
- **Nederst**: Status og meldinger

---

## Del 2: Legge til DC1 som Managed Computer

Før du kan opprette en backup job for DC1, må du legge til serveren i VEEAM-infrastrukturen.

### Steg 1: Åpne Backup Infrastructure
1. I venstre navigasjonspanel, klikk på **Backup Infrastructure**
2. Ekspander **Backup Infrastructure** hvis den ikke allerede er åpen

### Steg 2: Legg til Managed Server
1. Høyreklikk på **Managed Servers** (under Backup Infrastructure)
2. Velg **Add Server...**
3. Veiviseren **"New Windows Server"** eller **"Add Server"** åpnes

### Steg 3: Velg servertype
Du vil se valg for forskjellige servertyper:
- **Microsoft Windows** ← Velg dette
- VMware vSphere
- Microsoft Hyper-V
- Osv.

1. Velg **Microsoft Windows**
2. Klikk **Next**

### Steg 4: Oppgi servernavn
1. I feltet **Server name or IP address**, skriv: **DC1.InfraIT.sec**
2. Alternativt kan du skrive IP-adressen til DC1
3. Klikk **Next**

### Steg 5: Velg credentials
VEEAM trenger legitimasjon for å koble til DC1:

1. Klikk på **Add...** for å legge til nye credentials
2. I dialogen som åpnes:
   - **Username**: `InfraIT\adm_<dittbrukernavn>`
   - **Password**: ditt administrative passord
   - **Description**: `DC1 Admin` (valgfritt, men anbefalt)
3. Klikk **OK**
4. Velg den nyopprettede credential fra listen
5. Klikk **Next**

### Steg 6: Test tilkobling
1. VEEAM tester tilkoblingen til DC1
2. Du skal se en grønn hake hvis tilkoblingen lykkes
3. Hvis det feiler:
   - Sjekk at DC1 er pålogget på nettverket
   - Verifiser brukernavn og passord
   - Sjekk at VEEAM Agent kjører på DC1
4. Klikk **Next**

### Steg 7: Velg komponenter å installere
VEEAM vil spørre om den skal installere ekstra komponenter på DC1:
- **Veeam Data Mover** (anbefalt - brukes til dataoverføring)

1. La standardvalgene stå (Veeam Data Mover skal være huket av)
2. Klikk **Next**

### Steg 8: Review og Apply
1. Du vil se en oppsummering av innstillingene
2. Verifiser at alt ser riktig ut:
   - Server: DC1.InfraIT.sec
   - Credentials: InfraIT\adm_<brukernavn>
3. Klikk **Apply**

### Steg 9: Vent på ferdigstillelse
- VEEAM installerer nødvendige komponenter på DC1
- Dette tar vanligvis **1-3 minutter**
- Du vil se fremdrift i veiviseren
- Når det er ferdig, klikk **Finish**

### Steg 10: Verifiser at DC1 er lagt til
1. I **Backup Infrastructure**, under **Managed Servers**
2. Du skal nå se **DC1.InfraIT.sec** i listen
3. Serveren skal ha status **Available** (grønn)

---

## Del 3: Opprette Backup Job for DC1

Nå som DC1 er lagt til som en managed server, kan du opprette en backup job.

### Steg 1: Start New Backup Job Wizard
1. I VEEAM Console, klikk på **Home** i venstre panel
2. I ribbonmenyen øverst, finn seksjonen **Backup Job**
3. Klikk på **Backup Job** → **Windows computer...**
4. Alternativt: Høyreklikk på **Jobs** under **Backup & Replication** → **Add job** → **Windows computer...**

Veiviseren **"New Agent Backup Job"** åpnes.

### Steg 2: Job Name og Mode
På første side:

**Name:**
1. Gi jobben et beskrivende navn: `Backup-DC1`

**Operating mode:**
Du får to valg:
- **Managed by backup server** (anbefalt) ← Velg dette
- **Managed by agent**

2. Velg **Managed by backup server**
   - Dette betyr at SRV1 styrer backup-jobben
   - Backup-schedule og policy administreres sentralt

3. Klikk **Next**

### Steg 3: Velg DC1 som backup-mål
1. Klikk på **Add...** for å legge til computere
2. I dialogen som åpnes, se **Computers** i venstre panel
3. Ekspander **Managed servers**
4. Finn og huk av for **DC1.InfraIT.sec**
5. Klikk **OK**
6. DC1 skal nå vises i listen over computere som skal backupes
7. Klikk **Next**

### Steg 4: Backup Mode (Hva skal backupes?)
Dette er et viktig valg som bestemmer hva som backupes på DC1:

Du får tre hovedvalg:
- **Entire computer** - Hele maskinen (anbefalt for DC)
- **Volume level backup** - Spesifikke disker/volumes
- **File level backup** - Kun spesifikke filer/mapper

**For DC1 (Domain Controller):**
1. Velg **Entire computer**
   - Dette inkluderer alle disker (C:\)
   - Inkluderer System State (Active Directory-database)
   - Muliggjør full Bare Metal Recovery
2. Klikk **Next**

### Steg 5: Backup Storage (Hvor skal backup lagres?)
Du må nå velge hvor backup-dataene skal lagres:

1. Klikk på **Choose...** for å velge backup repository
2. Du vil se en liste over tilgjengelige repositories:
   - **Default Backup Repository** (lokalisert på D:\VeeamBackup)
3. Velg **Default Backup Repository**
4. Klikk **OK**

**Storage settings:**
- **Restore points to keep on disk**: Endre til `7`
  - Dette betyr at VEEAM beholder de siste 7 backup-kopiene
  - Eldre backups slettes automatisk

5. Klikk **Next**

### Steg 6: Guest Processing (Avanserte innstillinger)
Dette steget konfigurerer hvordan VEEAM håndterer data under backup:

**Application-aware processing:**
- Huk av for **Enable application-aware processing**
- Dette sikrer konsistente backups av Active Directory

**VSS settings:**
- La standardvalgene stå
- Dette sikrer at System State inkluderes i backupen

**Guest OS credentials:**
- Velg de samme credentials du brukte tidligere (InfraIT\adm_<brukernavn>)

Klikk **Next**

### Steg 7: Schedule (Når skal backup kjøre?)
Nå konfigurerer du når backup-jobben skal kjøres automatisk:

**Schedule options:**
1. Huk av for **Run the job automatically**
2. Velg schedule-type: **Daily**

**Daily schedule:**
- **Days**: Velg **Everyday** eller spesifikke dager
- **Time**: Velg et tidspunkt, for eksempel: **22:00** (10 PM)
  - Velg et tidspunkt utenfor arbeidstid
  - Unngå tidspunkt med mye nettverkstrafikk

**Additional options:**
- **Automatic retry**: Huk av for **Retry failed items**
  - Retry times: `3`
  - Await before each retry attempt: `10 minutes`

Klikk **Next**

### Steg 8: Summary og Finish
1. Gjennomgå alle innstillingene:
   - Job name: Backup-DC1
   - Computer: DC1.InfraIT.sec
   - Backup mode: Entire computer
   - Repository: Default Backup Repository
   - Schedule: Daily at 22:00
2. Huk av for **Run the job when I click Finish** (valgfritt - for å teste umiddelbart)
3. Klikk **Finish**

---

## Del 4: Kjør første backup manuelt

Selv om du har konfigurert en automatisk schedule, er det lurt å kjøre første backup manuelt for å teste at alt fungerer.

### Steg 1: Finn backup-jobben
1. I VEEAM Console, gå til **Home** → **Jobs** i venstre panel
2. Du skal nå se **Backup-DC1** i listen over jobber
3. Status skal være **Stopped** eller **Idle**

### Steg 2: Start backup-jobben
1. Høyreklikk på **Backup-DC1**
2. Velg **Start**
3. Jobben begynner umiddelbart

### Steg 3: Overvåk backup-prosessen
**Status i Jobs-listen:**
- Status endres til **Running**
- Du vil se et lasteikon

**Detaljert fremdrift:**
1. Dobbeltklikk på **Backup-DC1** for å åpne detaljvinduet
2. Du vil se:
   - **Current state**: Hva jobben gjør akkurat nå (f.eks. "Processing", "Creating snapshot")
   - **Progress bar**: Prosentvis fremdrift
   - **Processed**: Hvor mye data som er behandlet
   - **Speed**: Overføringshastighet (MB/s)
   - **Time left**: Estimert gjenstående tid

**Typisk backup-prosess:**
1. **Starting job** (1-2 min)
2. **Creating snapshot** (1-2 min)
3. **Processing volume** (5-30 min, avhengig av datamengde)
4. **Finalizing** (1-2 min)

> **Merk**: Første backup (full backup) tar lengst tid. Senere incremential backups går mye raskere.

### Steg 4: Vent til backup er fullført
- En full backup av DC1 tar vanligvis **10-30 minutter**
- Avhenger av:
  - Mengden data på DC1
  - Nettverkshastighet
  - Disk I/O på SRV1

**Ikke avbryt backup-jobben** mens den kjører.

### Steg 5: Sjekk resultat
Når backup-jobben er ferdig:

**Status endres til:**
- **Success** (grønn hake) - Alt gikk bra
- **Warning** (gult trekant) - Backup fullført, men med advarsler
- **Failed** (rødt kryss) - Backup feilet

**Ved Success:**
1. Dobbeltklikk på jobben for å se detaljer
2. I fanen **Statistics**, se:
   - **Processed**: Total mengde data som ble backet opp
   - **Duration**: Hvor lang tid backup tok
   - **Transfer rate**: Gjennomsnittlig hastighet

**Ved Warning eller Failed:**
1. Dobbeltklikk på jobben
2. Gå til fanen **Logs** eller **Session details**
3. Les feilmeldinger og advarsler
4. Se "Feilsøking" senere i denne guiden

---

## Del 5: Verifiser backup-data

Etter at backup er fullført, bør du verifisere at dataene faktisk er lagret.

### Steg 1: Sjekk Backup Repository
1. I VEEAM Console, gå til **Backup Infrastructure** → **Backup Repositories**
2. Dobbeltklikk på **Default Backup Repository**
3. Se **Used space** - dette skal ha økt etter backup

### Steg 2: Sjekk via File Explorer
1. Åpne File Explorer på SRV1
2. Gå til **D:\VeeamBackup**
3. Du skal nå se en mappe for backup-jobben: **Backup-DC1**
4. Inne i denne mappen:
   - **.vbk-fil** (full backup)
   - **.vbm-fil** (metadata)
   - Senere vil du også se **.vib-filer** (incremental backups)

### Steg 3: Sjekk backup size
1. Høyreklikk på **Backup-DC1**-mappen
2. Velg **Properties**
3. Se **Size on disk** - dette viser hvor mye plass backupen bruker

**Forventet størrelse:**
- En "naken" DC1 med Active Directory: 8-15 GB
- Størrelsen avhenger av hvor mye data som er på C:\ og i AD-databasen

### Steg 4: Se backup history
1. I VEEAM Console, gå til **History** i venstre panel
2. Finn **Backup-DC1** i listen
3. Du skal se en rad med:
   - **Job name**: Backup-DC1
   - **Start time**: Når backup startet
   - **End time**: Når backup ble fullført
   - **Status**: Success/Warning/Failed
   - **Details**: Klikk for å se detaljert logg

---

## Del 6: Teste Restore (Valgfritt, men anbefalt)

Det er viktig å verifisere at du faktisk kan gjenopprette data fra backup.

### Steg 1: Opprett en testfil på DC1
1. Koble til DC1 via RDP
2. Åpne **Notepad**
3. Skriv: `Dette er en testfil for å verifisere VEEAM restore`
4. Lagre filen som **C:\test-backup.txt**
5. Lukk filen

### Steg 2: Kjør en ny backup
1. Gå tilbake til VEEAM Console på SRV1
2. Høyreklikk på **Backup-DC1**
3. Velg **Start** for å kjøre en incremental backup
4. Vent til backup er fullført (går raskt, kun endringer backupes)

### Steg 3: Slett testfilen på DC1
1. På DC1, gå til **C:\**
2. Slett **test-backup.txt**
3. Tøm papirkurven

### Steg 4: Restore filen fra backup
1. I VEEAM Console på SRV1, gå til **Home** → **Backups** → **Disk (Agents)**
2. Ekspander **Backup-DC1**
3. Du vil se **DC1.InfraIT.sec** → Ekspander denne
4. Du vil se backup-punkter (restore points) med datoer
5. Høyreklikk på det nyeste backup-punktet
6. Velg **Restore guest files** → **Microsoft Windows**
7. Veiviseren åpnes

**I restore wizard:**
1. **Restore point**: Det nyeste punktet skal være valgt → **Next**
2. **Restore reason**: Skriv "Test restore" → **Next**
3. File Explorer-vindu åpner med innholdet av backupen
4. Naviger til **C:\**
5. Finn **test-backup.txt**
6. Høyreklikk på filen → **Restore** → **Overwrite** → **To the following location:**
7. Velg **C:\** på DC1
8. Klikk **Restore**

### Steg 5: Verifiser restore
1. Gå tilbake til DC1
2. Sjekk **C:\** - **test-backup.txt** skal være tilbake
3. Åpne filen for å verifisere innholdet

**Hvis filen er tilbake og innholdet stemmer - SUKSESS!** Din backup og restore-prosedyre fungerer.

---

## Del 7: Installere VEEAM Console på MGR (Valgfritt)

For sentralisert administrasjon kan du installere VEEAM Console på MGR-maskinen.

### Steg 1: Koble til MGR
1. Koble til MGR via Remote Desktop
2. Logg inn med **adm_<dittbrukernavn>**

### Steg 2: Tilgang til installer
Du har to alternativer:

**Alternativ A: Last ned fra VEEAM**
1. Gå til https://www.veeam.com/downloads.html
2. Last ned **"Veeam Backup & Replication Console"**

**Alternativ B: Kopier fra SRV1**
1. Gå til `\\SRV1\C$\Program Files\Veeam\Backup and Replication\Console`
2. Kopier installasjonsfiler til MGR

### Steg 3: Installer VEEAM Console
1. Dobbeltklikk på **Veeam.Backup.Console.Installer.exe**
2. Følg installasjonsveiviseren
3. Dette installerer kun Console, ikke hele Backup Server

### Steg 4: Koble til SRV1
1. Åpne VEEAM Console på MGR
2. Skriv inn **SRV1.InfraIT.sec** som backup server
3. Oppgi credentials: **InfraIT\adm_<dittbrukernavn>**
4. Klikk **Connect**

Nå kan du administrere VEEAM fra MGR!

---

## Beste Praksis

### Backup-strategi
**3-2-1 regelen:**
- **3** kopier av data (original + 2 backups)
- **2** forskjellige medietyper (disk og tape/cloud)
- **1** kopi offsite (i vårt lab: kun 1 kopi på D:\)

### Retention policy
- **Domain Controllers**: Minimum 14 dagers backup history
- **Kritiske servere**: 30+ dager
- **Test restore regelmessig**: Minst månedlig

### Monitoring
- **Sjekk backup-status daglig**
- **Sett opp e-postvarsler** for feilede jobber (konfigureres i VEEAM settings)
- **Overvåk disk space** på D:\VeeamBackup

### Sikkerhet
- **Krypter backups** (kan aktiveres i job settings)
- **Beskytt backup repository** med riktige NTFS-tilganger
- **Test disaster recovery-prosedyrer**

### Dokumentasjon
Dokumenter for hver backup job:
- **Job name**: Backup-DC1
- **Servers covered**: DC1.InfraIT.sec
- **Backup type**: Entire computer (System State inkludert)
- **Schedule**: Daglig kl. 22:00
- **Retention**: 7 restore points
- **Repository**: D:\VeeamBackup
- **Siste suksessfulle backup**: [Dato og tid]

---

## Vanlige Problemer og Feilsøking

### Problem: "Cannot connect to DC1"
**Symptomer:** Feil når du legger til DC1 som managed server

**Løsninger:**
1. Sjekk at VEEAM Agent kjører på DC1:
   - Gå til DC1 → Services → **Veeam Agent for Microsoft Windows** (Running)
2. Sjekk nettverksforbindelse:
   - På SRV1, kjør: `ping DC1.InfraIT.sec`
3. Sjekk Windows Firewall på DC1
4. Verifiser credentials (brukernavn og passord)

### Problem: "Backup job fails with VSS error"
**Symptomer:** Jobben feiler under "Creating snapshot"

**Løsninger:**
1. Sjekk at Volume Shadow Copy-tjenesten kjører på DC1:
   - Services → **Volume Shadow Copy** (Running)
2. Kjør på DC1 (PowerShell som admin):
   ```powershell
   vssadmin list writers
   ```
   - Alle writers skal være i "Stable" state
3. Restart VSS-tjenesten:
   ```powershell
   Restart-Service VSS
   ```

### Problem: "Not enough disk space on repository"
**Symptomer:** Backup feiler med "Insufficient disk space"

**Løsninger:**
1. Sjekk ledig plass på D:\ på SRV1
2. Reduser retention (færre restore points)
3. Slett gamle backup-filer manuelt
4. Utvid D:\-volumet i OpenStack

### Problem: "Backup takes too long"
**Symptomer:** Backup kjører i flere timer

**Løsninger:**
1. Første full backup tar lengst tid - dette er normalt
2. Sjekk nettverksbåndbredde mellom DC1 og SRV1
3. Sjekk disk I/O på SRV1 (Task Manager → Performance → Disk)
4. Vurder å kjøre backup på nattetid når belastningen er lav

### Problem: "Warning: Unable to truncate log files"
**Symptomer:** Backup fullføres med warning

**Løsning:**
- Dette er en vanlig warning for AD-backups
- Active Directory transaction logs kan ikke alltid truncates
- Backupen er fortsatt gyldig
- Hvis dette bekymrer deg, kjør dcdiag på DC1 for å sjekke AD-helse

### Problem: "Job shows as 'Running' but makes no progress"
**Løsninger:**
1. Vent 15-20 minutter (jobben kan henge på I/O)
2. Sjekk Task Manager på DC1 for CPU/Disk-aktivitet
3. Stop jobben:
   - Høyreklikk på jobben → **Stop**
4. Kjør jobben på nytt

---

## Overvåking og vedlikehold

### Daglige oppgaver
- **Sjekk backup-status** i VEEAM Console
- **Les feilmeldinger og warnings**
- **Verifiser at scheduled jobs kjører**

### Ukentlige oppgaver
- **Gjennomgå backup statistics** (hvor mye data, hvor lang tid)
- **Sjekk disk space på D:\VeeamBackup**
- **Test restore av noen få filer** (stikkprøve)

### Månedlige oppgaver
- **Full restore-test** av en VM eller server
- **Oppdater VEEAM** hvis nye versjoner er tilgjengelige
- **Gjennomgå retention policy** - er 7 dager nok?

### Kvartalsvis
- **Disaster recovery-test**: Simuler full server-feil og øv på restore
- **Dokumentasjonsgjennomgang**: Oppdater prosedyrer og kontaktinformasjon

---

## Oppsummering

Du har nå:
1. ✅ Åpnet VEEAM Backup & Replication Console på SRV1
2. ✅ Lagt til DC1 som managed server i VEEAM
3. ✅ Opprettet en backup job for DC1
4. ✅ Konfigurert backup til å inkludere hele maskinen (Entire computer)
5. ✅ Satt opp daglig backup schedule kl. 22:00
6. ✅ Kjørt første backup manuelt og verifisert at den lykkes
7. ✅ Testet restore av en fil for å verifisere at backup fungerer
8. ✅ Lært beste praksis for backup-administrasjon

---

## Neste Steg

Nå som DC1 er beskyttet med backup, kan du utvide backup-strategien:

### Forslag til videre arbeid:
1. **Opprett backup job for SRV1** (file server)
2. **Opprett backup job for CL1** (client-maskin)
3. **Konfigurer e-postvarsler** i VEEAM for å få beskjed om feilede jobber
4. **Utforsk advanced settings** som komprimering og kryptering
5. **Test full bare-metal restore** av DC1 til en ny VM

### Praktiske øvelser:
1. Simuler en katastrofe: Slett en viktig fil på DC1 og restore den
2. Opprett en kopi-jobb som flytter backup til en ekstern lokasjon
3. Dokumenter din backup-strategi i en driftsmanual

**Gratulerer!** Du har nå implementert enterprise-grade backup for din domenekontroller og kan beskytte kritiske data i ditt lab-miljø.