# Oppgave 13: Sikkerhetsvurdering av InfraIT.sec sin Azure-infrastruktur

## Bakgrunn

InfraIT.sec AS er et lite norsk IT-konsulentselskap med 15 ansatte. Selskapet håndterer sensitive data som ansattinformasjon, lønnsdata og konfidensielle kundeavtaler.

De siste månedene har selskapet migrert infrastrukturen sin til Microsoft Azure. Migreringen ble gjennomført under tidspress av en ekstern konsulent som ikke lenger er tilgjengelig. Daglig leder er bekymret for at oppsettet inneholder sikkerhetsfeil som kan eksponere sensitive data mot internett eller gi uautoriserte brukere for bred tilgang.

Du har blitt engasjert som ekstern sikkerhetsrådgiver for å gjennomgå infrastrukturen.

---

## Din oppgave

Infrastrukturen inneholder **8 sikkerhetsmessige svakheter** fordelt på nettverkssikkerhet, identitet og tilgang, og ressurskonfigurasjon. Din oppgave er å finne dem, utbedre dem og verifisere at utbedringen er korrekt gjennomført.

**Sett opp infrastrukturen** ved å følge Lab 13-01 før du begynner.

---

## Infrastrukturen

Etter deployment finner du følgende i Azure Portal:

**`<prefix>-rg-infraitsec-hub`**
Hub-nettverk med management-subnet. Inneholder en Linux jumpbox-VM som brukes for administrasjonstilgang til det interne nettverket.

**`<prefix>-rg-infraitsec-frontend`**
Frontend-nettverk med en App Service som kjører kundeportalen til InfraIT.sec. Portalen er eksponert mot internett.

**`<prefix>-rg-infraitsec-backend`**
Backend-nettverk med de interne tjenestene: Azure SQL Database med ansattdata, Blob Storage med interne dokumenter, og Key Vault som skal beskytte tilgangsnøkler og passord.

---

## Kom i gang

**Start her:** Åpne kundeportalen i nettleseren:

```
https://<prefix>-app-infraitsec.azurewebsites.net
```

Tenk over hva du ser. Hva skjer når du forsøker å logge inn? Hva burde ha skjedd?

**Gå deretter systematisk gjennom infrastrukturen** ved å undersøke hver resource group i Azure Portal og Azure Cloud Shell. For hver tjeneste — still deg disse spørsmålene:

- Hvem har nettverkstilgang til denne tjenesten, og er det begrenset til de som faktisk trenger det?
- Hvordan autentiseres tilgang til tjenesten, og er det den sikreste metoden?
- Er ressurskonfigurasjonen i tråd med prinsippet om minste privilegium?

Gjennomgå tjenestene i denne rekkefølgen: jumpbox-VM, App Service, Key Vault, Storage Account, SQL Server. Avslutt med å vurdere nettverkstopologien mellom de tre spoke-ene.

**For hver svakhet du finner:** forstå hvorfor det er et problem, utbedr det i Azure Portal eller Azure Cloud Shell, og kjør deretter verifiseringsscriptet for å bekrefte at utbedringen er korrekt.

Et vellykket utbedret funn gir følgende output i Cloud Shell:

```
OK:   [beskrivelse av hva som er korrekt konfigurert]
```

---

## Trenger du hjelp?

Hint-systemet på **[https://torivarm.github.io/hintdemo/](https://torivarm.github.io/hintdemo/)** gir deg veiledning til hvert funn. Av en eller annen grunn har siden problemer med Chrome hos meg, men fungerer i alle andre nettlesere. Det er to nivåer: en forklaring av hva du bør se etter, og et verifiseringsscript. Prøv alltid å finne svakheten selv før du åpner et hint — hint-bruk registreres (for egen testing, ingen påvirkning av øvingsvurdering).

---

## Leveranse

Presenter til læringsassistent på lab. For hvert funn skal det vise `OK`-output i Azure Cloud Shell med ressursnavnet med ditt prefiks synlig.

---

## Opprydding

Slett alle ressurser når du har presentert funnene dine:

```bash
PREFIX="<ditt-prefiks>"
az group delete --name "${PREFIX}-rg-infraitsec-hub"      --yes --no-wait
az group delete --name "${PREFIX}-rg-infraitsec-frontend" --yes --no-wait
az group delete --name "${PREFIX}-rg-infraitsec-backend"  --yes --no-wait
```