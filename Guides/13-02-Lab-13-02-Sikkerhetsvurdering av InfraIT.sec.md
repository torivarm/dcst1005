# Oppgave 13: Sikkerhetsvurdering av InfraIT.sec sin Azure-infrastruktur

## Bakgrunn

InfraIT.sec AS er et lite norsk IT-konsulentselskap med 15 ansatte. Selskapet håndterer sensitive data som ansattinformasjon, lønnsdata og konfidensielle kundeavtaler.

De siste månedene har selskapet migrert infrastrukturen sin til Microsoft Azure. Migreringen ble gjennomført under tidspress av en ekstern konsulent som ikke lenger er tilgjengelig. Daglig leder er bekymret for at oppsettet inneholder sikkerhetsfeil som kan eksponere sensitive data mot internett eller gi uautoriserte brukere for bred tilgang.

Du har blitt engasjert som ekstern sikkerhetsrådgiver for å gjennomgå infrastrukturen.

---

## Din oppgave

Infrastrukturen inneholder **8 sikkerhetsmessige svakheter** fordelt på nettverkssikkerhet, identitet og tilgang, og ressurskonfigurasjon. Din oppgave er å finne dem, utbedre dem og verifisere at utbedringen er korrekt gjennomført.

**Sett opp infrastrukturen** ved å følge Lab 13-01.

**Utforsk infrastrukturen** systematisk i Azure Portal og Azure Cloud Shell. Undersøk nettverkskonfigurasjon, tilgangsinnstillinger og ressurskonfigurasjon. Tenk som en angriper: hva er eksponert, hvem har tilgang, og hva kan misbrukes?

**Utbedr svakhetene** du finner i Azure Portal eller via Azure Cloud Shell.

**Verifiser** at hver utbedring er korrekt ved å kjøre verifiseringsscriptet fra hint-systemet. Et korrekt utbedret funn gir følgende output i Cloud Shell:

```
OK:   [beskrivelse av hva som er korrekt konfigurert]
```

**Trenger du hjelp?** Hint-systemet på **https://torivarm.github.io/hintdemo/** gir deg veiledning til hvert funn. Hint-bruk registreres (testing, ingen påvirkning av vurdering) og synliggjøres for faglærer.

---

## Leveranse

Presenter hvert funn. Vis output fra scriptet, `OK`-output, i Azure Cloud Shell med ressursnavnet med ditt prefiks synlig.

---

## Opprydding

Slett alle ressurser når du har presentert funnene dine:

```bash
PREFIX="<ditt-prefiks>"
az group delete --name "${PREFIX}-rg-infraitsec-hub"      --yes --no-wait
az group delete --name "${PREFIX}-rg-infraitsec-frontend" --yes --no-wait
az group delete --name "${PREFIX}-rg-infraitsec-backend"  --yes --no-wait
```