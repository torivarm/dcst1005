# Oppgave 12: Sikker tilgjengeliggjøring av intern applikasjon i Azure

## Bakgrunn

InfraIT.sec har i en årrekke kjørt et internt system for ansatte og lønnsinformasjon på en lokal server i serverrommet. Systemet er utviklet internt, har aldri gjennomgått en sikkerhetsgjennomgang, og mangler autentisering på applikasjonsnivå. Systemet kan ikke sikres i sin nåværende form, men må holdes i drift inntil et nytt og moderne HR-system er ferdig utviklet og klart til å ta over.

Ledelsen i InfraIT.sec har besluttet at systemet midlertidig skal migreres til Azure. Siden applikasjonen ikke kan sikres på applikasjonsnivå, skal nettverksarkitekturen kompensere: applikasjonen skal kjøre i et isolert Azure-miljø uten noen form for eksponering mot internett, og kun være tilgjengelig for ansatte som er autentisert via Microsoft Entra ID og tilkoblet via godkjent VPN.

## Din oppgave

Du skal sette opp infrastrukturen som gjør dette mulig, deploye applikasjonen og dokumentere at tilgangskravene er oppfylt.

Det er ingen krav til ekesisterende Resource Groups eller annen infrastruktur før denne øvingen, deployment script oppretter det som er nødvendig fra bunn. Dvs. en kan, om en vil, slette unna det en har fra før og begynne på et nytt oppsett uten noen eksisterende VNET, subnet eller NSG-er.

Følg Lab 12-01 og Lab 12-02 for oppsett av infrastruktur, VPN Gateway og AKS-cluster med applikasjon.

## Dokumentasjonskrav

Du skal presentere følgende til læringsassistent:

**1. VPN-tilkobling etablert**
Azure VPN Client på din egen maskin med status **Connected** og tildelt IP-adresse fra adressepoolen `172.16.0.0/24`. (eller `172.16.0.0/27`, kommer litt an på konfigurasjonen)

**2. Applikasjonen nådd via intern adresse**
Bruk av nettleser på egen maskin med applikasjonen lastet fra den **interne IP-adressen** (10.1.x.x) — ikke fra et offentlig endepunkt.

**3. Applikasjonen fungerer**
Legg til og fjern ansatte i applikasjonen via nettleseren. Bonus, se også om du finner samme informasjon i Azure Portal under: Storage account -> Storage browser -> Tables -> employees.

**4. Applikasjonen ikke tilgjengelig uten VPN**
Skjermbilde som viser at applikasjonen ikke er nåbar når VPN-tilkoblingen er frakoblet — nettleseren skal vise timeout eller tilkoblingsfeil på samme interne adresse.
