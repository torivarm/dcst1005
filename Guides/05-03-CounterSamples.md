# CounterSamples - Direkte tilgang til Performance Counter data

**Tema:** Eksportere performance counter data til CSV  
**Fokus:** CounterSamples-objektet og dets egenskaper

---

## 📊 Hva er CounterSamples?

Når du kjører `Get-Counter`, får du tilbake et `PerformanceCounterSampleSet` objekt. Dette objektet inneholder en egenskap kalt **`CounterSamples`** som er en samling (array) av individuelle `PerformanceCounterSample` objekter - ett for hver teller du har spurt om.

### Objekthierarki

```
Get-Counter returnerer:
└── PerformanceCounterSampleSet
    ├── Timestamp (når målingen ble tatt)
    └── CounterSamples (array av samples)
        ├── [0] PerformanceCounterSample (CPU)
        │   ├── Path: "\Processor(_Total)\% Processor Time"
        │   ├── CookedValue: 15.23
        │   ├── Timestamp: 2026-01-29 14:30:00
        │   └── InstanceName: "_Total"
        ├── [1] PerformanceCounterSample (Memory %)
        └── [2] PerformanceCounterSample (Memory MB)
```

---

## Script-gjennomgang

```powershell
$rootfolder = "C:\Logs"

# Define the counters you want to measure
$counters = @(
    "\Processor(_Total)\% Processor Time",
    "\Memory\% Committed Bytes In Use",
    "\Memory\Available MBytes"
)

# Collect the counter data
$counterData = Get-Counter -Counter $counters

# Export the counter data to a CSV file
$counterData.CounterSamples | Select-Object Path, CookedValue, Timestamp | Export-Csv -Path "$rootfolder\output.csv" -NoTypeInformation
```

### Nøkkellinjen: CounterSamples

```powershell
$counterData.CounterSamples
```

**Hva gjør denne?**
- Aksesserer `CounterSamples`-egenskapen fra `PerformanceCounterSampleSet` objektet
- Returnerer en **array** med 3 `PerformanceCounterSample` objekter (én per teller)
- Gjør dataene klare for videre prosessering i pipeline

---

## Viktige egenskaper i CounterSamples

Hvert `PerformanceCounterSample` objekt inneholder:

| Egenskap | Beskrivelse | Eksempel |
|----------|-------------|----------|
| **Path** | Full tellerbane inkl. server | `\\DC1\processor(_total)\% processor time` |
| **CookedValue** | Kalkulert/prosessert verdi | `15.234567` (bruk `[math]::Round()`) |
| **RawValue** | Ubearbeidet rådata | `123456789` (sjelden brukt) |
| **Timestamp** | Når målingen ble tatt | `2026-01-29 14:30:00` |
| **InstanceName** | Instansnavn | `_Total`, `C:`, `0`, etc. |
| **CounterType** | Type teller | `AverageTimer64`, `RawFraction`, etc. |

### Hvorfor bruke CookedValue?

**CookedValue vs. RawValue:**

```powershell
# RawValue - rå, uberegnede tellerverdier (vanskelig å tolke)
$sample.RawValue  # Output: 2847593847

# CookedValue - kalkulert, lesbar verdi (det du faktisk vil ha)
$sample.CookedValue  # Output: 15.23 (prosent)
```

**CookedValue** er navnet fordi verdien er "tilberedt" (cooked) - Windows har allerede kalkulert den fra rådata til noe menneskelesbart.

---

## Hvorfor er denne tilnærmingen bedre?

### ❌ Uten CounterSamples (tungvint)

```powershell
$counterData = Get-Counter -Counter $counters

# Må manuelt hente ut hver teller
$cpu = $counterData.CounterSamples[0].CookedValue
$memPercent = $counterData.CounterSamples[1].CookedValue
$memAvail = $counterData.CounterSamples[2].CookedValue

# Manuelt lage CSV-struktur
[PSCustomObject]@{
    CPU = $cpu
    MemoryPercent = $memPercent
    MemoryAvailable = $memAvail
} | Export-Csv -Path "output.csv" -NoTypeInformation
```

### ✅ Med CounterSamples (elegant)

```powershell
$counterData = Get-Counter -Counter $counters

# Direkte pipeline - alle tellere automatisk
$counterData.CounterSamples | 
    Select-Object Path, CookedValue, Timestamp | 
    Export-Csv -Path "output.csv" -NoTypeInformation
```

**Fordeler:**
- ✅ Fungerer uansett antall tellere (3 eller 30)
- ✅ Ingen hardkoding av array-indekser
- ✅ Automatisk inkluderer alle tellere
- ✅ Enkel å utvide med flere tellere

---

## Resulterende CSV-fil

**output.csv:**
```csv
Path,CookedValue,Timestamp
"\\dc1\processor(_total)\% processor time",15.234567,29.01.2026 14:30:00
"\\dc1\memory\% committed bytes in use",45.678912,29.01.2026 14:30:00
"\\dc1\memory\available mbytes",3456.000000,29.01.2026 14:30:00
```

---

## Praktiske forbedringer

### Forbedring 1: Avrund CookedValue

```powershell
$counterData.CounterSamples | 
    Select-Object Path, 
                  @{Name='Value'; Expression={[math]::Round($_.CookedValue, 2)}}, 
                  Timestamp | 
    Export-Csv -Path "$rootfolder\output.csv" -NoTypeInformation
```

**Output:**
```csv
Path,Value,Timestamp
"\\dc1\processor(_total)\% processor time",15.23,29.01.2026 14:30:00
```

---

### Forbedring 2: Forenklet Path (kun tellernavn)

```powershell
$counterData.CounterSamples | 
    Select-Object @{Name='Counter'; Expression={($_.Path -split '\\')[-1]}},
                  @{Name='Value'; Expression={[math]::Round($_.CookedValue, 2)}}, 
                  Timestamp | 
    Export-Csv -Path "$rootfolder\output.csv" -NoTypeInformation
```

**Output:**
```csv
Counter,Value,Timestamp
"% processor time",15.23,29.01.2026 14:30:00
"% committed bytes in use",45.68,29.01.2026 14:30:00
"available mbytes",3456.00,29.01.2026 14:30:00
```

---

### Forbedring 3: Legg til Server-kolonne

```powershell
$counterData.CounterSamples | 
    Select-Object @{Name='Server'; Expression={($_.Path -split '\\')[2]}},
                  @{Name='Counter'; Expression={($_.Path -split '\\')[-1]}},
                  @{Name='Value'; Expression={[math]::Round($_.CookedValue, 2)}}, 
                  Timestamp | 
    Export-Csv -Path "$rootfolder\output.csv" -NoTypeInformation
```

**Output:**
```csv
Server,Counter,Value,Timestamp
"dc1","% processor time",15.23,29.01.2026 14:30:00
"dc1","% committed bytes in use",45.68,29.01.2026 14:30:00
"dc1","available mbytes",3456.00,29.01.2026 14:30:00
```

---

## Utforsk CounterSamples interaktivt

```powershell
# Samle data
$counterData = Get-Counter -Counter "\Processor(_Total)\% Processor Time"

# Se hele objektet
$counterData | Get-Member

# Se CounterSamples
$counterData.CounterSamples

# Se alle egenskaper for første sample
$counterData.CounterSamples[0] | Format-List *

# Output:
# Path         : \\dc1\processor(_total)\% processor time
# InstanceName : _total
# CookedValue  : 15.234567890123
# RawValue     : 123456789
# SecondValue  : 987654321
# CounterType  : Timer100Ns
# Timestamp    : 29.01.2026 14:30:00
# ...
```

---

## Vanlige misforståelser

### ❌ Feil: Prøve å eksportere hele objektet

```powershell
# Dette gir mye unødvendig data
$counterData | Export-Csv -Path "output.csv" -NoTypeInformation
```

### ✅ Riktig: Eksporter kun CounterSamples

```powershell
# Dette gir kun de relevante dataene
$counterData.CounterSamples | Export-Csv -Path "output.csv" -NoTypeInformation
```

---

## Oppsummering

🔑 **Nøkkelpunkter:**

- **CounterSamples** er en samling av individuelle måledata
- **CookedValue** er den prosesserte, lesbare verdien (ikke RawValue)
- **Path** inneholder full tellerbane inkludert server
- **Timestamp** viser nøyaktig når målingen ble tatt
- Pipeline med `Select-Object` gir full kontroll over output-format

💡 **Huskeregel:**  
`Get-Counter` returnerer en "boks" (`PerformanceCounterSampleSet`), mens `CounterSamples` er "innholdet" i boksen - de faktiske målingene du kan jobbe med!

---

**Neste steg:** Kombiner med `Invoke-Command` for å samle CounterSamples fra flere servere samtidig! 🚀