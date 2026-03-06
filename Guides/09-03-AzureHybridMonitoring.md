# Azure Monitor - Sentralisert Logging og Performance Monitoring

## Oversikt

I denne øvelsen skal du sette opp Azure Monitor Agent på dine Arc-enabled maskiner og samle logs til en sentral Log Analytics Workspace. Dette gir deg innsikt i performance, sikkerhetshendelser, og systemhelse på tvers av hele infrastrukturen din.

**Hva er Azure Monitor?**
Azure Monitor er Microsofts observability-plattform som samler, analyserer, og visualiserer telemetri-data fra on-premises og cloud-ressurser. I stedet for å logge inn på hver maskin for å sjekke Event Viewer eller Performance Monitor, får du all data sentralisert på ett sted.

**Læringsmål:**
- Opprette og konfigurere Log Analytics Workspace
- Definere Data Collection Rules for kostnadseffektiv logging
- Installere Azure Monitor Agent via Arc
- Skrive grunnleggende KQL (Kusto Query Language) queries
- Analysere performance og sikkerhetshendelser
- Forstå trade-offs mellom datamengde og kostnad

**Estimert tid:** 60-75 minutter

---

## Forutsetninger

- [ ] Azure Arc-enabled maskiner: DC1, SRV1, MGR, CL1 (fra forrige øvelse)
- [ ] Managed Identity enabled på alle maskiner (fra forrige øvelse)
- [ ] Tilgang til Resource Group: `<prefix>-rg-infraitsec-arc`
- [ ] Rolle: "Contributor" eller "Log Analytics Contributor" på Resource Group

**Verifiser Managed Identity:**
```powershell
# I Azure Cloud Shell
Get-AzConnectedMachine -ResourceGroupName "<prefix>-rg-infraitsec-arc" | 
    Select-Object Name, @{Name='Identity';Expression={$_.Identity.Type}} | 
    Format-Table -AutoSize
```

Alle maskiner skal ha `Identity: SystemAssigned`. Hvis ikke, gå tilbake til forrige øvelse.

---

## Del 1: Opprett Log Analytics Workspace

Log Analytics Workspace er databasen hvor alle logs lagres. Tenk på den som en sentral SQL-database for telemetri.

### Steg 1.1: Opprett Workspace

1. Logg inn på [Azure Portal](https://portal.azure.com)

2. Søk etter **"Log Analytics workspaces"**

3. Klikk **"+ Create"**

4. **Basics:**
   - **Subscription:** Din subscription
   - **Resource group:** `<prefix>-rg-infraitsec-arc`
   - **Name:** `<prefix>-law-infraitsec`
     - Eksempel: `eg06-law-infraitsec`
     - Navnet må være unikt innenfor din subscription
   - **Region:** `North Europe`

5. **Pricing tier:**
   - La stå på **"Pay-as-you-go"** (default)
   - Dette betyr du betaler kun for data du faktisk sender inn
   - Ingen månedlig fixed cost

6. **Tags:** (valgfritt)
```
   Owner: <dittbrukernavn>
   Environment: Lab
   Course: InfraIT-Cyber
```

7. Klikk **"Review + Create"** → **"Create"**

8. Vent på deployment (~1-2 minutter)

**Hva er Log Analytics Workspace?**

En Log Analytics Workspace fungerer som en container for logging-data. All telemetri fra dine maskiner sendes hit, lagres i tabeller (som `Perf`, `SecurityEvent`, `Event`), og kan queries med KQL. Du betaler for datamengden som sendes inn (ingestion) og hvor lenge data lagres (retention).

### Steg 1.2: Verifiser Workspace

1. Når deployment er ferdig, klikk **"Go to resource"**

2. Under **"Overview"** skal du se:
   - **Status:** Active
   - **Resource ID:** `/subscriptions/.../resourceGroups/<prefix>-rg-infraitsec-arc/providers/Microsoft.OperationalInsights/workspaces/<prefix>-law-infraitsec`

3. Venstre meny → **"Usage and estimated costs"**
   - **Data volume (last 31 days):** 0 GB (ingen data ennå)
   - **Estimated monthly cost:** ~€0 (før vi begynner å sende data)

4. Noter **Workspace ID** (trenger denne senere):
   - Venstre meny → **"Properties"**
   - Kopier **Workspace ID** (f.eks. `abc12345-6789-...`)

---

## Del 2: Opprett Data Collection Rule (DCR)

Data Collection Rules definerer HVILKE data som skal samles fra maskinene. Vi konfigurerer en kostnadseffektiv regel som samler nok data til å være nyttig, uten å bli for dyrt.

### Steg 2.1: Opprett DCR

1. I Azure Portal, søk etter **"Monitor"**

2. Venstre meny → **"Data Collection Rules"**

3. Klikk **"+ Create"**

4. **Basics:**
   - **Rule name:** `dcr-infraitsec-basic`
   - **Subscription:** Din subscription
   - **Resource group:** `<prefix>-rg-infraitsec-arc`
   - **Region:** `North Europe`
   - **Platform Type:** `Windows`

5. Klikk **"Next: Resources >"**

### Steg 2.2: Legg til Arc Machines som Resources

1. Klikk **"+ Add resources"**

2. **Scope:** Velg din Resource Group: `<prefix>-rg-infraitsec-arc`

3. **Filter på "Resource type":** `Servers - Azure Arc`

4. **Velg alle dine 4 maskiner:**
   - ☑ DC1-<prefix>
   - ☑ SRV1-<prefix>
   - ☑ MGR-<prefix>
   - ☑ CL1-<prefix>

5. Klikk **"Apply"**

6. Verifiser at alle 4 maskiner vises under "Resources"

7. Klikk **"Next: Collect and deliver >"**

### Steg 2.3: Konfigurer Data Sources (Performance Counters)

**Dette er kritisk for å holde kostnadene nede - følg nøye!**

1. Klikk **"+ Add data source"**

2. **Data source type:** `Performance Counters`

3. **Basic configuration:**
   - **Sampling rate:** `60 seconds` (data samles hvert minutt)

4. Under **"Performance counters"**, velg KUN disse (fjern resten):

   **Processor:**
   - ☑ `\Processor(_Total)\% Processor Time`

   **Memory:**
   - ☑ `\Memory\Available MBytes`
   - ☑ `\Memory\% Committed Bytes In Use`

   **Logical Disk:**
   - ☑ `\LogicalDisk(_Total)\% Free Space`
   - ☑ `\LogicalDisk(_Total)\Free Megabytes`
   - ☑ `\LogicalDisk(_Total)\Disk Reads/sec`
   - ☑ `\LogicalDisk(_Total)\Disk Writes/sec`

   **Network Adapter:**
   - ☑ `\Network Adapter(_Total)\Bytes Received/sec`
   - ☑ `\Network Adapter(_Total)\Bytes Sent/sec`

**Hvorfor kun disse counters?**

Vi samler de viktigste metrics for troubleshooting (CPU, memory, disk, network) uten å samle hundrevis av andre counters som sjelden brukes. Dette holder datamengden lav (~100 MB/maskin/måned) men gir fortsatt god innsikt.

5. Klikk **"Next: Destination >"**

6. **Destination type:** `Azure Monitor Logs`

7. **Subscription:** Din subscription

8. **Account or namespace:** Velg din Log Analytics Workspace: `<prefix>-law-infraitsec`

9. Klikk **"Add data source"**

### Steg 2.4: Konfigurer Data Sources (Windows Event Logs)

1. Klikk **"+ Add data source"** igjen

2. **Data source type:** `Windows Event Logs`

3. **Configure event logs to collect:**

   **Application:**
   - ☑ `Critical`
   - ☑ `Error`
   - ☑ `Warning`
   - ☐ `Information` (IKKE velg - for mye data!)
   - ☐ `Verbose` (IKKE velg)

   **System:**
   - ☑ `Critical`
   - ☑ `Error`
   - ☑ `Warning`
   - ☐ `Information` (IKKE velg)
   - ☐ `Verbose` (IKKE velg)

   **Security:**
   - ☐ La stå blank (vi konfigurerer Security Events separat)

**Hvorfor kun Error og Warning?**

Information og Verbose nivåer genererer enorme mengder data (tusenvis av events per dag) som sjelden er nyttige. Ved å kun samle Critical, Error, og Warning får vi det viktigste uten å drukne i støy.

4. Klikk **"Next: Destination >"**

5. **Destination type:** `Azure Monitor Logs`

6. **Account or namespace:** Velg `<prefix>-law-infraitsec`

7. Klikk **"Add data source"**

### Steg 2.5: Konfigurer Data Sources (Security Events)

1. Klikk **"+ Add data source"** igjen

2. **Data source type:** `Windows Security Events`

3. **Ruleset:** Velg **"Common"**

   **Hva er "Common"?**
   - **All Security Events:** 100% av security events (VELDIG dyrt! ~500 MB/maskin/dag)
   - **Common:** Kun de viktigste security events (~200 MB/maskin/måned) ← VI BRUKER DENNE
   - **Minimal:** Kun kritiske events (~50 MB/maskin/måned, men mister mye nyttig data)

   Common inkluderer: Failed logins, privilege escalation, account changes, group membership changes, firewall events, osv.

4. Klikk **"Next: Destination >"**

5. **Destination type:** `Azure Monitor Logs`

6. **Account or namespace:** Velg `<prefix>-law-infraitsec`

7. Klikk **"Add data source"**

### Steg 2.6: Review og Create

1. Klikk **"Review + create"**

2. Verifiser konfigurasjonen:
   - **3 data sources** definert (Performance Counters, Windows Event Logs, Security Events)
   - **4 resources** (dine Arc machines)
   - **1 destination** (din Log Analytics Workspace)

3. Klikk **"Create"**

4. Vent på deployment (~2-3 minutter)

**Hva skjer nå?**

Azure deployer Data Collection Rule til alle 4 maskinene. Dette triggerer automatisk installasjon av Azure Monitor Agent på hver maskin (hvis den ikke allerede er installert). Agenten begynner deretter å samle data i henhold til DCR og sender den til Log Analytics Workspace via HTTPS.

---

## Del 3: Verifiser Agent Installasjon

Azure Monitor Agent installeres automatisk som en "extension" på Arc-enabled machines når du oppretter en DCR.

### Steg 3.1: Sjekk Agent Status i Portal

1. Azure Portal → **Azure Arc** → **Machines**

2. Klikk på **DC1-<prefix>**

3. Venstre meny → **Extensions**

4. Du skal se:
   - **Name:** `AzureMonitorWindowsAgent`
   - **Status:** `Succeeded` (kan ta 5-10 minutter før den går fra "Creating" til "Succeeded")
   - **Version:** (nyeste versjon)

5. Gjenta for SRV1, MGR, CL1

**Hvis Status = "Failed":**

Klikk på extension → se **"Status message"** for feilmelding. Vanlige problemer:
- Managed Identity ikke enabled → gå tilbake til forrige øvelse
- Network connectivity issues → sjekk at port 443 er åpen

### Steg 3.2: Verifiser Agent på Maskinen

**På DC1 (eller hvilken som helst maskin):**
```powershell
# Sjekk om Azure Monitor Agent service kjører
Get-Service -Name AzureMonitorWindowsAgent

# Skal vise Status: Running
```

**Sjekk agent configuration:**
```powershell
# Vis Data Collection Rules som er assigned til denne maskinen
Get-ChildItem "C:\WindowsAzure\Extensions\Microsoft.Azure.Monitor.AzureMonitorWindowsAgent" -Recurse -Filter "*.config" | 
    Select-Object FullName, LastWriteTime
```

Hvis filer finnes og er nylig oppdatert (< 15 min) → agenten er konfigurert.

---

## Del 4: Vent på Data og Verifiser Ingestion

Data begynner å strømme inn til Log Analytics etter ~10-15 minutter. La oss verifisere at data kommer inn.

### Steg 4.1: Sjekk Data Ingestion

1. Azure Portal → **Log Analytics workspaces** → `<prefix>-law-infraitsec`

2. Venstre meny → **"Logs"**

3. **Lukk** "Queries" popup hvis den vises

4. Kjør denne query i query-vinduet:
```kusto
Heartbeat
| where TimeGenerated > ago(1h)
| summarize count() by Computer
| order by count_ desc
```

**Klikk "Run"**

**Forventet output (etter ~15 minutter):**
```
Computer       count_
DC1            15
SRV1           15
MGR            15
CL1            15
```

Heartbeat sendes hvert 5. minutt, så etter 15 min bør du ha ~3 heartbeats per maskin.

**Hvis ingen resultater:**

- Vent 5 minutter til og prøv igjen
- Sjekk at agent status er "Succeeded" i portal
- Sjekk at DCR er "Associated" med maskinene

### Steg 4.2: Sjekk Performance Data
```kusto
Perf
| where TimeGenerated > ago(1h)
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| summarize avg(CounterValue) by Computer
| order by avg_CounterValue desc
```

**Forventet output:**
```
Computer       avg_CounterValue
SRV1           15.234
DC1            8.123
MGR            5.567
CL1            3.221
```

Viser gjennomsnittlig CPU-bruk siste time per maskin.

### Steg 4.3: Sjekk Security Events
```kusto
SecurityEvent
| where TimeGenerated > ago(1h)
| summarize count() by Computer, EventID
| order by count_ desc
| take 10
```

**Forventet output:**
```
Computer  EventID  count_
DC1       4624     87      # Successful logon
DC1       4672     45      # Special privileges assigned
SRV1      5156     23      # Windows Firewall connection
...
```

**Gratulerer!** Data strømmer nå inn til Log Analytics! 🎉

---

## Del 5: Grunnleggende KQL (Kusto Query Language)

KQL er query-språket for Azure Monitor, Azure Sentinel, Azure Data Explorer, og Application Insights. Det er kraftig og essensielt for moderne cloud operations.

**KQL Syntax Basics:**
```kusto
TableName                    // Velg tabell
| where TimeGenerated > ago(1h)   // Filtrer på tid
| where Computer == "DC1"          // Filtrer på verdi
| summarize count() by EventID     // Aggreger data
| order by count_ desc             // Sorter
| take 10                          // Limit resultater
```

La oss kjøre praktiske queries!

### Query 1: CPU Usage Over Time

**Scenario:** Du vil se CPU-bruk for alle maskiner siste 24 timer.
```kusto
Perf
| where TimeGenerated > ago(24h)
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| where InstanceName == "_Total"
| summarize avg(CounterValue) by Computer, bin(TimeGenerated, 1h)
| render timechart
```

**Klikk "Run" og velg "Chart" view**

**Hva gjør denne query?**

- `Perf` tabellen inneholder alle performance counters
- `ago(24h)` = siste 24 timer
- `bin(TimeGenerated, 1h)` = grupper data i 1-times intervaller
- `render timechart` = visualiser som linjegraf

**Tolkning:**

Du ser en graf med 4 linjer (en per maskin). Hvis en linje er konsekvent høy (> 80%), kan maskinen trenge mer CPU eller har en prosess som spiser ressurser.

---

### Query 2: Memory Availability

**Scenario:** Sjekk om noen maskiner går tom for minne.
```kusto
Perf
| where TimeGenerated > ago(6h)
| where ObjectName == "Memory" and CounterName == "Available MBytes"
| summarize avg(CounterValue) by Computer
| extend AvailableGB = avg_CounterValue / 1024
| project Computer, AvailableGB
| order by AvailableGB asc
```

**Forventet output:**
```
Computer  AvailableGB
CL1       2.456
MGR       3.123
SRV1      4.789
DC1       6.234
```

**Tolkning:**

Hvis en maskin har < 1 GB available memory konstant → memory pressure, bør vurdere å øke RAM.

---

### Query 3: Disk Space Analysis

**Scenario:** Identifiser maskiner som nærmer seg full disk.
```kusto
Perf
| where TimeGenerated > ago(1h)
| where ObjectName == "LogicalDisk" and CounterName == "% Free Space"
| where InstanceName == "C:"
| summarize avg(CounterValue) by Computer
| extend FreeSpacePercent = round(avg_CounterValue, 2)
| project Computer, FreeSpacePercent
| order by FreeSpacePercent asc
```

**Forventet output:**
```
Computer  FreeSpacePercent
SRV1      15.67
DC1       34.23
MGR       56.89
CL1       78.45
```

**Tolkning:**

Hvis FreeSpacePercent < 10% → kritisk, trenger disk cleanup eller expansion.

---

### Query 4: Failed Login Attempts

**Scenario:** Identifiser potensielle brute-force angrep eller feilkonfigurasjoner.
```kusto
SecurityEvent
| where TimeGenerated > ago(24h)
| where EventID == 4625  // Failed logon
| summarize FailedLogins = count() by Computer, Account, IpAddress
| where FailedLogins > 5
| order by FailedLogins desc
```

**Forventet output:**
```
Computer  Account           IpAddress      FailedLogins
DC1       testuser          192.168.1.100  23
SRV1      administrator     192.168.1.50   12
```

**Tolkning:**

Mange failed logins kan indikere:
- Bruker glemte passord
- Brute-force angrep
- Misconfigured service account

---

### Query 5: Service Status Monitoring

**Scenario:** Sjekk om kritiske Windows Services kjører.
```kusto
Event
| where TimeGenerated > ago(1h)
| where Source == "Service Control Manager"
| where EventLevelName == "Error"
| where RenderedDescription contains "stopped"
| project TimeGenerated, Computer, RenderedDescription
| order by TimeGenerated desc
```

**Forventet output:**
```
TimeGenerated           Computer  RenderedDescription
2025-03-06 14:23:45     SRV1      The Windows Update service entered the stopped state.
```

**Tolkning:**

Viser services som har stoppet. Hvis kritiske services stopper (SQL Server, IIS, etc.) → potential downtime.

---

### Query 6: Top 10 Most Frequent Events

**Scenario:** Forstå hva som skjer mest på systemene.
```kusto
Event
| where TimeGenerated > ago(24h)
| summarize count() by EventID, Source, Computer
| order by count_ desc
| take 10
```

**Forventet output:**
```
EventID  Source                   Computer  count_
7036     Service Control Manager  DC1       1234
4624     Microsoft-Windows-...    DC1       567
1074     User32                   SRV1      234
...
```

**Tolkning:**

Gir oversikt over systemaktivitet. High-frequency events kan være normale (service starts/stops) eller indikere problemer (repeterende errors).

---

### Query 7: Network Traffic Analysis

**Scenario:** Se hvilke maskiner som sender/mottar mest data.
```kusto
Perf
| where TimeGenerated > ago(6h)
| where ObjectName == "Network Adapter"
| where CounterName in ("Bytes Received/sec", "Bytes Sent/sec")
| summarize avg(CounterValue) by Computer, CounterName
| extend AvgMBps = avg_CounterValue / 1024 / 1024
| project Computer, CounterName, AvgMBps
| order by AvgMBps desc
```

**Forventet output:**
```
Computer  CounterName           AvgMBps
SRV1      Bytes Sent/sec        15.67
SRV1      Bytes Received/sec    8.34
DC1       Bytes Sent/sec        5.23
...
```

**Tolkning:**

SRV1 sender mest data (file server) som forventet. Uventet høy trafikk kan indikere data exfiltration eller misconfiguration.

---

### Query 8: System Uptime

**Scenario:** Se når maskiner sist ble rebootet.
```kusto
Event
| where TimeGenerated > ago(30d)
| where Source == "EventLog" and EventID == 6005  // Event log service started
| summarize LastBoot = max(TimeGenerated) by Computer
| extend UptimeDays = datetime_diff('day', now(), LastBoot)
| project Computer, LastBoot, UptimeDays
| order by UptimeDays desc
```

**Forventet output:**
```
Computer  LastBoot             UptimeDays
SRV1      2025-02-15 08:23:11  19
DC1       2025-03-01 14:56:32  5
MGR       2025-03-05 09:12:45  1
CL1       2025-03-06 07:34:21  0
```

**Tolkning:**

Lang uptime kan være bra (stabil) eller dårlig (manglende patching). Best practice er månedlig reboot for patch deployment.

---

### Query 9: Error Events Summary

**Scenario:** Få oversikt over alle errors siste 24 timer.
```kusto
Event
| where TimeGenerated > ago(24h)
| where EventLevelName == "Error"
| summarize ErrorCount = count() by Computer, Source
| where ErrorCount > 5
| order by ErrorCount desc
```

**Forventet output:**
```
Computer  Source                      ErrorCount
DC1       Microsoft-Windows-DNS       45
SRV1      Disk                        23
MGR       Application Error           12
```

**Tolkning:**

Mange errors fra samme source → undersøk videre. DNS errors på DC1 kan indikere nettverksproblemer.

---

### Query 10: Custom Alert Query

**Scenario:** Find maskiner med lav disk space OG høy CPU samtidig (potensielt problem).
```kusto
let LowDiskSpace = Perf
| where TimeGenerated > ago(1h)
| where ObjectName == "LogicalDisk" and CounterName == "% Free Space"
| where InstanceName == "C:"
| summarize AvgFreeSpace = avg(CounterValue) by Computer
| where AvgFreeSpace < 20;
let HighCPU = Perf
| where TimeGenerated > ago(1h)
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| summarize AvgCPU = avg(CounterValue) by Computer
| where AvgCPU > 70;
LowDiskSpace
| join kind=inner (HighCPU) on Computer
| project Computer, AvgFreeSpace, AvgCPU
```

**Forventet output:**
```
Computer  AvgFreeSpace  AvgCPU
SRV1      15.23         78.45
```

**Tolkning:**

SRV1 har BÅDE lav disk space OG høy CPU → prioriter troubleshooting her!

---

## Del 6: Lag Dashboard (Valgfritt)

Du kan lagre dine favoritt-queries som et dashboard for rask tilgang.

### Steg 6.1: Opprett Dashboard

1. I Log Analytics workspace → **Logs**

2. Kjør en query (f.eks. CPU Usage Over Time fra Query 1)

3. Klikk **"Pin to dashboard"** (nål-ikon øverst til høyre)

4. **Create new** → Navn: `InfraIT Monitoring Dashboard`

5. Gjenta for andre nyttige queries (Memory, Disk Space, Failed Logins)

6. Åpne dashboard:
   - Azure Portal → **Dashboard** (øverst til venstre)
   - Velg din dashboard fra dropdown

**Resultat:**

Et sentralisert dashboard med live data fra alle maskinene dine. Perfekt for daglig drift-monitoring!

---

## Del 7: Forstå Kostnader og Optimalisering

### Steg 7.1: Sjekk Current Data Ingestion

1. Log Analytics workspace → **Usage and estimated costs**

2. Under **"Data volume (last 31 days)"** ser du total datamengde

3. **Breakdown by table:**
   - `Perf`: ~400-600 MB (performance counters)
   - `SecurityEvent`: ~600-800 MB (security events)
   - `Event`: ~200-400 MB (Windows event logs)
   - **Total per måned:** ~1.2-1.8 GB (4 maskiner)

**Kostnad:**
- 1.5 GB × €2.76/GB = **~€4.14 per måned** per student

Dette er innenfor Scenario A-estimatet!

### Steg 7.2: Cost Optimization Tips

**Hvis kostnaden blir for høy:**

1. **Reduser sampling rate:** 60 sek → 120 sek (halverer Perf data)
2. **Fjern verbose counters:** Behold kun CPU, Memory, Disk % (ikke Reads/Writes/sec)
3. **Security Events:** Common → Minimal (halverer SecurityEvent data)
4. **Retention:** 30 dager → 7 dager (gratis uansett, men mindre historical data)

**Men for denne labben:**

Scenario A-konfigurasjonen er allerede optimalisert. Ingen endringer nødvendig!

---

## Del 8: Cleanup (Kun ved Lab Reset)

**ADVARSEL:** Gjør kun dette hvis du skal avslutte kurset eller rebuilde miljøet!

### Slett Data Collection Rule
```powershell
# Azure Cloud Shell
Remove-AzDataCollectionRule -ResourceGroupName "<prefix>-rg-infraitsec-arc" -Name "dcr-infraitsec-basic"
```

**Dette:**
- Stopper data collection
- Fjerner Azure Monitor Agent extensions fra Arc machines
- SLETTER IKKE eksisterende data i Log Analytics

### Slett Log Analytics Workspace
```powershell
Remove-AzOperationalInsightsWorkspace -ResourceGroupName "<prefix>-rg-infraitsec-arc" -Name "<prefix>-law-infraitsec" -Force
```

**Dette:**
- Sletter workspace
- Sletter ALL innsamlet data (permanent!)
- Stopper all fakturering

---

## Troubleshooting

### Problem: "No data in Log Analytics after 30 minutes"

**Sjekk:**

1. **Agent status:**
```powershell
   # På maskinene
   Get-Service -Name AzureMonitorWindowsAgent
   # Skal være Running
```

2. **DCR association:**
   - Azure Portal → Data Collection Rules → `dcr-infraitsec-basic` → Resources
   - Verifiser at alle 4 maskiner er listed

3. **Managed Identity:**
```powershell
   # Azure Cloud Shell
   Get-AzConnectedMachine -ResourceGroupName "<prefix>-rg-infraitsec-arc" -Name "DC1-<prefix>" | Select-Object -ExpandProperty Identity
   # Type skal være SystemAssigned
```

4. **Network connectivity:**
```powershell
   # På maskinene
   Test-NetConnection -ComputerName "management.azure.com" -Port 443
   # Skal være TcpTestSucceeded: True
```

---

### Problem: "High data ingestion cost"

**Symptom:** Usage and estimated costs viser > 5 GB/måned per student

**Løsning:**

1. Sjekk hvilken tabell som bruker mest data:
```kusto
   Usage
   | where TimeGenerated > ago(7d)
   | summarize DataGB = sum(Quantity) / 1024 by DataType
   | order by DataGB desc
```

2. Hvis `SecurityEvent` er høyest:
   - Endre DCR fra "Common" til "Minimal"

3. Hvis `Perf` er høyest:
   - Øk sampling rate fra 60 → 120 sekunder
   - Fjern counters du ikke bruker

4. Hvis `Event` er høyest:
   - Fjern "Information" level (kun Error/Warning)

---

### Problem: "Query returns no results"

**Sjekk:**

1. **Time range:** Utvid `ago(1h)` til `ago(24h)`
2. **Table name:** Sjekk at table eksisterer:
```kusto
   search *
   | summarize count() by $table
```
3. **Column names:** KQL er case-sensitive! `computer` ≠ `Computer`

---

### Problem: "Extension installation failed"

**Symptom:** AzureMonitorWindowsAgent extension status = "Failed"

**Løsning:**

1. Sjekk error message:
   - Arc machine → Extensions → Klikk på failed extension → "Status message"

2. Common errors:
   - **"Managed Identity not found"** → Enable Managed Identity på maskinen
   - **"Network connectivity"** → Sjekk port 443 utgående
   - **"Insufficient permissions"** → DCR må ha "Contributor" på workspace

3. Prøv manuell re-install:
   - Slett extension
   - Re-create DCR (trigger ny install)

---

## Refleksjonsspørsmål

1. **Sentralisert Logging:**
   - Hva er fordelene med Log Analytics vs. å logge inn på hver maskin for å sjekke Event Viewer?
   - Hvilke trade-offs er det mellom local logging og sentralisert logging?

2. **Data Collection Strategy:**
   - Hvorfor valgte vi "Common" security events istedenfor "All"?
   - I hvilke scenarier ville du valgt "All" selv om det er dyrere?

3. **KQL Skills:**
   - Sammenlign KQL med SQL. Hva er likt? Hva er forskjellig?
   - Hvordan kan KQL-skills brukes utenfor Azure Monitor? (Hint: Sentinel, Data Explorer)

4. **Cost Management:**
   - Hvordan balanserer en organisasjon behovet for data (observability) mot kostnad?
   - Hva ville du gjort hvis budsjettet kun tillot 500 MB/måned?

5. **Alerting:**
   - Hvilke metrics bør ha alerts i et produksjonsmiljø?
   - Hva er forskjellen mellom reactive (manual query) og proactive (automated alert) monitoring?

6. **Retention:**
   - Hvorfor er 30 dager default retention? Når ville du valgt lengre (90, 365 dager)?
   - Hva er compliance-krav for logging i finanssektoren vs. retail?

---

## Neste Steg

Nå som du har sentralisert logging, kan du gå videre med:

1. **Azure Blob Storage Backup** - Automatisk backup fra SRV1 til cloud
2. **Azure File Sync** - Replikér DFS folders for disaster recovery
3. **Azure Key Vault** - Sentralisert secret management med Managed Identity
4. **Advanced Monitoring** (valgfritt) - VM Insights, dependency mapping, custom alerts

**Du har nå moderne observability i hybrid cloud-miljøet ditt!** 🎉

---

## Ressurser

- [Azure Monitor Documentation](https://learn.microsoft.com/en-us/azure/azure-monitor/)
- [KQL Quick Reference](https://learn.microsoft.com/en-us/azure/data-explorer/kql-quick-reference)
- [Data Collection Rules](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/data-collection-rule-overview)
- [Azure Monitor Pricing](https://azure.microsoft.com/en-us/pricing/details/monitor/)
- [Log Analytics Query Examples](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/example-queries)