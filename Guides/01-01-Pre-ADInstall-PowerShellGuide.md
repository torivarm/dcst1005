# Windows Server PowerShell Guide - Tidssone og Tastaturoppsett

## Viktig - Kjøre PowerShell som Administrator

For å kunne utføre kommandoene i denne guiden, må PowerShell kjøres med administratorrettigheter. Dette kan gjøres på to måter:

1. Høyreklikk på PowerShell-ikonet og velg "Kjør som administrator"
2. Eller søk etter PowerShell i startmenyen, høyreklikk og velg "Kjør som administrator"

Man vil kunne se at PowerShell kjører som administrator ved at vindustittelen viser "Administrator: Windows PowerShell" istedenfor bare "Windows PowerShell".

## Kontrollere Tidssone på Windows Server

For å sjekke hvilken tidssone serveren er satt til, bruker man følgende kommando:

```powershell
Get-TimeZone
```

Denne kommandoen benytter seg av `Get-TimeZone` cmdlet'en som viser nåværende tidssone-innstillinger. Resultatet vil vise Id, DisplayName og StandardName for gjeldende tidssone.

Hvis serveren ikke er satt til norsk tidssone, kan man endre dette med følgende kommando:

```powershell
Set-TimeZone -Id "W. Europe Standard Time"
```

Denne kommandoen bruker `Set-TimeZone` cmdlet'en med `-Id` parameteren. "W. Europe Standard Time" er den korrekte identifikatoren for norsk tidssone (UTC+01:00 Oslo, København, Stockholm).

## Kontrollere Tastaturoppsett

For å sjekke nåværende tastaturoppsett, bruk følgende kommando:

```powershell
Get-WinUserLanguageList
```

Denne cmdlet'en viser alle installerte språk- og tastaturinnstillinger. Man ser på LanguageTag og InputMethodTips for å identifisere tastaturoppsettet.

Hvis norsk tastatur ikke er installert eller satt som standard, kan man legge til dette med følgende kommandoer:

```powershell
$CurrentLanguage = New-WinUserLanguageList -Language "nb-NO"
$CurrentLanguage[0].InputMethodTips.Add("0414:00000414")
Set-WinUserLanguageList -LanguageList $CurrentLanguage -Force
```

La oss bryte ned denne sekvensen:
1. `New-WinUserLanguageList` cmdlet'en oppretter en ny språkliste med norsk (bokmål) som språk
2. `InputMethodTips.Add()` legger til det norske tastaturoppsettet (0414:00000414 er koden for norsk tastaturlayout)
3. `Set-WinUserLanguageList` anvender de nye innstillingene med `-Force` parameteren for å overskrive eksisterende innstillinger

Etter at kommandoene er kjørt, må man logge ut og inn igjen for at endringene skal tre i kraft.

## Nettverkskonfigurasjon

Normalt ville en domenekontroller være konfigurert med en statisk IP-adresse for å sikre stabil tilgang til domenets tjenester. I dette tilfellet, siden maskinene kjører i et OpenStack-miljø hvor IP-adressene styres dynamisk av plattformen, beholder vi den dynamiske IP-konfigurasjonen.

For å se gjeldende IP-konfigurasjon, kan følgende kommandoer benyttes:

```powershell
Get-NetIPAddress
```

Denne kommandoen viser alle IP-adresser konfigurert på maskinen. For mer detaljert informasjon om nettverksadaptere, bruk:

```powershell
Get-NetAdapter
```

For å se full TCP/IP-konfigurasjon inkludert gateway og DNS-servere:

```powershell
Get-NetIPConfiguration -Detailed
```

Denne cmdlet'en gir en omfattende oversikt over:
- IP-adresser (både IPv4 og IPv6)
- Standard gateway
- DNS-serverinnstillinger
- Nettverksadapter status
- DHCP-status

## Viktige Notater
- Alle disse kommandoene må kjøres med administratorrettigheter
- Endringer i tastaturoppsett krever en utlogging for å aktiveres fullstendig
- Tidssoneendringer trer i kraft umiddelbart
- Kommandoene kan verifiseres ved å kjøre de første kommandoene på nytt etter endringene er gjort
- I et produksjonsmiljø ville en domenekontroller normalt ha statisk IP-adresse