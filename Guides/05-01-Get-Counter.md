# PowerShell Performance Monitoring med Get-Counter

**Fagmodul:** Windows Server Administrasjon  
**Semester:** 2. semester - Bachelor i Digital infrastruktur i cybersikkerhet  
**Tema:** Systemovervåking og ytelsesmåling med PowerShell

---

## 📋 Innholdsfortegnelse

1. [Introduksjon](#introduksjon)
2. [Hva er Microsoft.PowerShell.Diagnostics?](#hva-er-microsoftpowershelldiagnostics)
3. [Grunnleggende konsepter](#grunnleggende-konsepter)
4. [Praktiske eksempler](#praktiske-eksempler)
5. [Avanserte scenarioer](#avanserte-scenarioer)
6. [Øvingsoppgaver](#øvingsoppgaver)

---

## Introduksjon

I dette dokumentet skal vi utforske hvordan vi kan bruke PowerShell til å overvåke systemytelse på Windows Server. Dette er en kritisk ferdighet for IT-administratorer som må:

- Identifisere ytelsesflaskehalser i infrastrukturen
- Overvåke ressursbruk i sanntid
- Dokumentere system-baseline for senere sammenligning
- Proaktiv feilsøking før problemene eskalerer
- Oppfylle krav til logging og overvåking i cybersikkerhet

**Hvorfor er dette viktig for cybersikkerhet?**  
Unormal ressursbruk kan være første tegn på:
- Malware eller kryptomining på servere
- DDoS-angrep som belaster systemet
- Kompromitterte kontoer som utfører uautoriserte oppgaver
- Datainnbrudd hvor store mengder data eksfiltreres

---

## Hva er Microsoft.PowerShell.Diagnostics?

`Microsoft.PowerShell.Diagnostics` er en innebygd PowerShell-modul som gir tilgang til Windows Performance Counters (ytelsestellere). Denne modulen inneholder primært cmdleten `Get-Counter`, som lar oss hente ut detaljert informasjon om systemets ytelse.

### Hva er Performance Counters?

Performance Counters er Windows sitt innebygde system for å måle og rapportere ressursbruk. Tenk på dem som "måleinstrumenter" innebygd i operativsystemet som konstant registrerer data om:

- CPU-bruk (prosessorbelastning)
- Minneforbruk (RAM-bruk)
- Disk I/O (les/skriv-operasjoner)
- Nettverkstrafikk
- Prosesser og tråder
- Og mye mer...

**Windows Performance Monitor (perfmon.exe)** bruker de samme tellerne, men med `Get-Counter` får vi:
- Automatisering via skript
- Mulighet til å eksportere data
- Integrasjon med andre PowerShell-kommandoer
- Fjernovervåking av andre servere

---

## Grunnleggende konsepter

### Counter Sets (Tellersett)

Et **Counter Set** er en samling av relaterte ytelsestellere. For eksempel:
- `Processor` - alle tellere relatert til CPU
- `Memory` - alle tellere relatert til minne
- `PhysicalDisk` - alle tellere relatert til harddisker

### Counter (Teller)

En individuell **Counter** er én spesifikk måling, som:
- `\Processor(_Total)\% Processor Time` - Total CPU-bruk i prosent
- `\Memory\Available MBytes` - Tilgjengelig minne i megabytes

### Syntaks for Counter Paths

Counter paths følger denne strukturen:
```
\[ComputerName]\CounterSet[(Instance)]\Counter
```

**Eksempel:**
```
\Processor(_Total)\% Processor Time
```
- `Processor` = Counter Set
- `_Total` = Instance (her: alle CPUer samlet)
- `% Processor Time` = Selve telleren

---

## Praktiske eksempler

### Steg 1: Liste alle tilgjengelige Counter Sets

```powershell
Get-Counter -ListSet *
```

**Hva gjør denne kommandoen?**  
- `-ListSet *` bruker wildcard (`*`) for å hente ALLE tilgjengelige counter sets
- Dette gir deg en oversikt over alle målbare ressurser på systemet

**Forventet output:**  
Du vil se en liste med objekter som inneholder:
- `CounterSetName` - Navnet på tellersettet
- `Description` - Beskrivelse av hva det måler
- `Counter` - Liste over alle tellere i settet

---

### Steg 2: Liste kun navnene på Counter Sets

```powershell
Get-Counter -ListSet * | Select-Object -ExpandProperty CounterSetName
```

**Hva gjør denne kommandoen?**  
- Vi tar output fra forrige kommando
- `Select-Object -ExpandProperty CounterSetName` plukker ut KUN navnet
- Dette gir en ryddig liste uten ekstra informasjon

**Pedagogisk poeng:**  
Dette er et godt eksempel på PowerShells pipeline (`|`) - vi sender output fra én kommando videre til neste for prosessering.

**Eksempel output:**
```
Processor
Memory
Network Interface
PhysicalDisk
LogicalDisk
Process
...
```

---

### Steg 3: Finne CPU-relaterte Counter Sets

```powershell
Get-Counter -ListSet * | Where-Object {$_.CounterSetName -like "*Processor*"} | Select-Object -ExpandProperty CounterSetName
```

**Hva gjør denne kommandoen?**  
1. `Get-Counter -ListSet *` - Henter alle counter sets
2. `Where-Object {$_.CounterSetName -like "*Processor*"}` - Filtrerer resultatet
   - `$_` refererer til hvert objekt i pipeline
   - `-like "*Processor*"` søker etter teksten "Processor" (wildcard på begge sider)
3. `Select-Object -ExpandProperty CounterSetName` - Viser kun navnet

**Forventet output:**
```
Processor
Processor Information
Per Processor Network Activity Cycles
Hyper-V Hypervisor Logical Processor
...
```
![alt text](GetCPU.png)

**Hvorfor er dette nyttig?**  
I stedet for å bla gjennom hundrevis av counter sets, finner vi raskt det vi trenger!

---

### Steg 4: Finne minne-relaterte Counter Sets

```powershell
Get-Counter -ListSet * | Where-Object {$_.CounterSetName -like "*Memory*"} | Select-Object -ExpandProperty CounterSetName
```

**Hva gjør denne kommandoen?**  
Samme prinsipp som Steg 3, men nå søker vi etter alt relatert til minne.

**Forventet output:**
```
Memory
Cache
Paging File
Per Processor Network Activity Memory
```

**Cybersikkerhetsaspekt:**  
Uvanlig høyt minneforbruk kan indikere:
- Minnelekkasjer i applikasjoner
- Skadelig programvare som opererer i minnet
- Utilsiktet oppstart av ressurskrevende prosesser

---

### Steg 5: Liste alle tellere for Processor

```powershell
Get-Counter -ListSet Processor | Select-Object -ExpandProperty Counter
```

**Hva gjør denne kommandoen?**  
- Henter kun `Processor` counter set (ikke alle)
- Ekspanderer `Counter`-egenskapen for å se alle individuelle tellere

**Forventet output:**
```
\Processor(*)\% Processor Time
\Processor(*)\% User Time
\Processor(*)\% Privileged Time
\Processor(*)\Interrupts/sec
\Processor(*)\% DPC Time
\Processor(*)\% Interrupt Time
\Processor(*)\DPCs Queued/sec
\Processor(*)\DPC Rate
...
```

**Nøkkelinformasjon:**  
- `(*)` betyr "alle instanser" - hvis du har 4 CPU-kjerner får du data for alle
- `(_Total)` gir deg samlede tall for alle kjerner

---

### Steg 6: Hente faktiske CPU-målinger

```powershell
Get-Counter -Counter "\Processor(*)\% Processor Time" -SampleInterval 2 -MaxSamples 10
```

**Hva gjør denne kommandoen?**  
- `-Counter "\Processor(*)\% Processor Time"` - Spesifiserer hvilken teller vi vil måle
- `-SampleInterval 2` - Tar en ny måling hvert 2. sekund
- `-MaxSamples 10` - Tar totalt 10 målinger, deretter stopper kommandoen

**Tidsforbruk:**  
Denne kommandoen vil kjøre i 20 sekunder (10 samples × 2 sekunder)

**Forventet output:**
```
Timestamp                 CounterSamples
---------                 --------------
29.01.2026 10:15:32      \\MGR\processor(0)\% processor time : 15.2
                          \\MGR\processor(1)\% processor time : 18.7
                          \\MGR\processor(_total)\% processor time : 16.95

29.01.2026 10:15:34      \\MGR\processor(0)\% processor time : 12.1
                          \\MGR\processor(1)\% processor time : 14.3
                          \\MGR\processor(_total)\% processor time : 13.2
...
```

**Praktisk bruk:**  
Dette er perfekt for å:
- Sjekke CPU-belastning under en operasjon
- Dokumentere ytelse før og etter endringer
- Identifisere CPU-knapphet

**Beste praksis:**  
En sunn Windows Server bør ha gjennomsnittlig CPU under 70%. Konsistent bruk over 80% indikerer behov for:
- Ytelsesoptimalisering
- Oppgradering av hardware
- Undersøkelse av prosesser som bruker mest CPU

---

### Steg 7: Finne disk-relaterte Counter Sets

```powershell
Get-Counter -ListSet * | Where-Object {$_.CounterSetName -like "*Disk*"} | Select-Object -ExpandProperty CounterSetName
```

**Hva gjør denne kommandoen?**  
Finner alle counter sets relatert til disk-aktivitet.

**Forventet output:**
```
LogicalDisk
PhysicalDisk
```

**Forskjellen:**
- **PhysicalDisk** - Fysiske disker (f.eks. SSD, HDD)
- **LogicalDisk** - Logiske volumer/partisjoner (C:, D:, etc.)

**I en VM-verden:**  
PhysicalDisk refererer fortsatt til den virtuelle disken som er presentert for VM-en.

---

### Steg 8: Liste alle tellere for PhysicalDisk

```powershell
Get-Counter -ListSet PhysicalDisk | Select-Object -ExpandProperty Counter
```

**Forventet output:**
```
\PhysicalDisk(*)\Current Disk Queue Length
\PhysicalDisk(*)\% Disk Time
\PhysicalDisk(*)\Avg. Disk Queue Length
\PhysicalDisk(*)\% Disk Read Time
\PhysicalDisk(*)\% Disk Write Time
\PhysicalDisk(*)\Avg. Disk sec/Transfer
\PhysicalDisk(*)\Avg. Disk sec/Read
\PhysicalDisk(*)\Avg. Disk sec/Write
\PhysicalDisk(*)\Disk Transfers/sec
\PhysicalDisk(*)\Disk Reads/sec
\PhysicalDisk(*)\Disk Writes/sec
\PhysicalDisk(*)\Disk Bytes/sec
...
```

**Viktige disk-tellere å kjenne:**

| Teller | Beskrivelse | Hva er bra? |
|--------|-------------|-------------|
| `% Disk Time` | Hvor mye disken er opptatt | < 80% |
| `Current Disk Queue Length` | Antall ventende I/O-operasjoner | < 2 |
| `Avg. Disk sec/Read` | Gjennomsnittlig lesetid | < 15ms (SSD), < 25ms (HDD) |
| `Avg. Disk sec/Write` | Gjennomsnittlig skrivetid | < 15ms (SSD), < 25ms (HDD) |

**Cybersikkerhetsaspekt:**  
Uvanlig disk-aktivitet kan indikere:
- Ransomware som krypterer filer (høy write-aktivitet)
- Datainnbrudd med datafangst
- Logging av keystrokes eller screenshots

---

## Avanserte scenarioer

### Eksempel 1: Sammenligne CPU og minne samtidig

```powershell
Get-Counter -Counter "\Processor(_Total)\% Processor Time", "\Memory\Available MBytes" -SampleInterval 1 -MaxSamples 5
```

**Resultat:**  
Du får målinger av både CPU og tilgjengelig minne samtidig, nyttig for å se sammenhenger.

---

### Eksempel 2: Eksportere data til CSV for analyse

```powershell
Get-Counter -Counter "\Processor(_Total)\% Processor Time" -SampleInterval 2 -MaxSamples 30 | 
    Export-Counter -Path "C:\Logs\CPU_Monitoring.csv" -FileFormat CSV
```

**Fordeler:**
- Data kan analyseres i Excel
- Lag trendrapporter
- Dokumentasjon for change management

---

### Eksempel 3: Kontinuerlig overvåking med varsel

```powershell
while ($true) {
    $cpuUsage = (Get-Counter "\Processor(_Total)\% Processor Time").CounterSamples.CookedValue
    
    if ($cpuUsage -gt 80) {
        Write-Host "ADVARSEL: CPU-bruk er $([math]::Round($cpuUsage,2))%" -ForegroundColor Red
        # Her kan du legge til e-postvarsel, logging, etc.
    } else {
        Write-Host "CPU-bruk: $([math]::Round($cpuUsage,2))%" -ForegroundColor Green
    }
    
    Start-Sleep -Seconds 5
}
```

**Bruk Ctrl+C for å stoppe scriptet**

---

### Eksempel 4: Overvåke fjernserver

```powershell
Get-Counter -Counter "\Processor(_Total)\% Processor Time" -ComputerName "SRV1" -SampleInterval 2 -MaxSamples 5
```

**Forutsetninger:**
- WinRM må være aktivert på målserveren
- Du må ha administrative rettigheter
- Brannmur må tillate Remote Management

---

## Øvingsoppgaver

### Oppgave 1: Grunnleggende utforskning
1. Kjør kommandoen for å liste alle Counter Sets
2. Tell hvor mange Counter Sets som finnes på din server
3. Finn alle Counter Sets som har med "Network" å gjøre

**Tips:** Bruk `Measure-Object` for å telle

---

### Oppgave 2: Minne-analyse
1. Finn navnet på Counter Set for minne
2. List ut alle tellere for minne
3. Hent 5 samples av "Available MBytes" med 3 sekunders intervall
4. Hvor mye ledig minne har serveren din?

---

### Oppgave 3: Disk-ytelse
1. Hent ut en måling av `\PhysicalDisk(_Total)\% Disk Time`
2. Start en operasjon som bruker mye disk (f.eks. kopier en stor fil)
3. Mål `% Disk Time` igjen - hva ser du?

---

### Oppgave 4: Lag et overvåkingsscript
Lag et PowerShell-script som:
1. Måler CPU, minne og disk samtidig
2. Tar 10 målinger med 2 sekunders intervall
3. Eksporterer resultatene til en CSV-fil
4. Gir en oppsummering med gjennomsnitt

**Bonus:** Legg til farget output avhengig av verdiene

---

### Oppgave 5: Troubleshooting-scenario
Du får melding om at SRV1 går tregt. Bruk `Get-Counter` til å:
1. Sjekke CPU-bruk
2. Sjekke tilgjengelig minne
3. Sjekke disk queue length
4. Lag en konklusjon om hva problemet kan være

---

## Oppsummering

I denne modulen har du lært:

✅ Hva Microsoft.PowerShell.Diagnostics-modulen er  
✅ Hvordan bruke `Get-Counter` til å liste tilgjengelige ytelsestellere  
✅ Filtrere og søke etter spesifikke Counter Sets  
✅ Hente ut faktiske ytelsesmålinger  
✅ Overvåke CPU, minne og disk-ressurser  
✅ Eksportere data for videre analyse  

---

## Nyttige ressurser

- [Microsoft Docs: Get-Counter](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.diagnostics/get-counter)
- [Performance Counter Architecture](https://learn.microsoft.com/en-us/windows/win32/perfctrs/performance-counters-portal)
- [PowerShell Gallery](https://www.powershellgallery.com/) - for utvidede overvåkingsmoduler

---

**Laget for:** 2. semester, Bachelor i Digital infrastruktur i cybersikkerhet  
**Fagansvarlig:** Tor Ivar  
**Testmiljø:** InfraIT.sec domain (DC1, SRV1, CL1, MGR)

---
