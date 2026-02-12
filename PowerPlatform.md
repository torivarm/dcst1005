# Oversikt Business Use Cases - Power Platform

## Power Automate
1. Fravær og feriegodkjenning
2. Innkommende faktura-håndtering
3. Onboarding av nye ansatte
4. Hendelsesrapportering (HMS/sikkerhet)
5. Kundehenvendelser fra nettskjema til CRM
6. Automatisk distribusjon av ukerapporter
7. Sosiale media-overvåking og respons
8. Automatisk lagerpåfyll (retail/industri)
9. Automatisk møtereferat og oppfølging
10. Compliance og GDPR-forespørsler

## Power Apps
1. Utstyrslån og ressursbooking
2. Feltinspeksjonsapp (bygg, vedlikehold, HMS)
3. Reiseregning og utleggsføring
4. Kunnskapsbase og FAQ-portal (intern)
5. Varslingsapp for IT-drift
6. Opplærings- og onboarding-tracker
7. Idébank og innovasjonsportal
8. Model-driven app: Case management
9. Timeføringssystem
10. Besøksregistrering (resepsjon)

## Power BI
1. HR-analytics: Turnover og sykefravær
2. Salgs- og pipeline-rapportering (CRM)
3. Prosjektøkonomi og ressursallokering
4. Innkjøpsanalyse og leverandørstyring
5. Kundeservice: Ticket-analyse
6. Operasjonell dashbord (produksjon/logistikk)
7. Markedsførings-ROI og kampanjeanalyse
8. Finansiell rapportering (P&L, balanse)
9. Eiendomsforvaltning: Energiforbruk
10. Helseanalyse: Pasientflyt og ventetider

## Dataverse
1. CRM-lite: Kunde- og kontaktstyring
2. Asset management: IT-utstyr og inventar
3. Prosjektportefølje-styring
4. Incident og problem management (ITIL)
5. Employee skill matrix og kompetansekartlegging
6. Kontrakts- og avtalestyring
7. Grant management (offentlig sektor)
8. Quality management: Non-conformance og CAPA
9. Customer feedback og complaint management
10. Event og konferanseadministrasjon

## Power Pages
1. Kundeportal: Support og case-tracking
2. Leverandørportal: Onboarding og fakturering
3. Partnerportal: Reseller og distributor management
4. Jobbportal: Søknad og rekruttering
5. Medlemsportal: Forening/fagorganisasjon

## Copilot Studio
1. IT-support helpdesk bot
2. HR-bot for ansatte (policies og benefits)
3. Kundeservice FAQ-bot (ekstern)
4. Onboarding-bot for nye ansatte
5. Møterom- og ressursbooking-bot
6. Lead qualification bot (salg)
7. Faciliteter og eiendomsservice-bot
8. Opplærings- og kurs-veileder bot
9. Compliance og policy-guide bot
10. Reisehjelp og expense-bot


# Business Use Cases for Power Platform-komponenter

## Power Automate - Use Cases

### 1. **Fravær og feriegodkjenning**
**Problem:**
Tradisjonelt system med e-post frem og tilbake mellom ansatt, leder og HR. Mye manuell registrering i Excel, tap av oversikt, forsinket behandling.

**Løsning:**
- Ansatt fyller ut Power Apps-skjema
- Power Automate sender godkjenningsforespørsel til leder
- Ved godkjenning: Oppdaterer SharePoint/Dataverse
- Sender kopi til HR
- Oppdaterer Outlook-kalender
- Trigger på ny ansatt hvis fravær > 10 dager

**Hvorfor relevant i kurset:**
- Demonstrerer end-to-end automatisering
- Enkel å forstå for alle (alle har tatt ferie)
- Viser godkjenningsflyter (approval flows)
- Tydelig ROI: Sparer HR mange timer per måned
- Introduserer Power Fx og betingelser

---

### 2. **Innkommende faktura-håndtering**
**Problem:**
Fakturaer kommer på e-post, må manuelt registreres i økonomisystem, sendes til godkjenner, følges opp.

**Løsning:**
- Trigger: Ny e-post med vedlegg (.pdf) i delt innboks
- AI Builder leser fakturainformasjon (OCR)
- Oppretter case i Dynamics/Dataverse
- Sender til riktig godkjenner basert på beløp/kategori
- Ved godkjenning: Eksporterer til økonomisystem via API
- Arkiverer i SharePoint med metadata

**Hvorfor relevant i kurset:**
- Viser AI-integrasjon (AI Builder)
- Kompleks flyt med flere beslutningspunkter
- HTTP-requests til eksterne systemer
- Reelt kostnadsproblem i alle virksomheter
- Demonstrerer ROI: 70-80% tidssparing

---

### 3. **Onboarding av nye ansatte**
**Problem:**
Ny ansatt skal ha IT-utstyr, tilganger, opplæring, fadder, møter - mye koordinering mellom mange avdelinger.

**Løsning:**
- Trigger: Nyansatt registrert i HR-system
- Oppretter Teams-kanal for onboarding
- Sender automatisk velkomst-epost med info
- Oppretter oppgaver i Planner for IT, HR, leder
- Bestiller utstyr fra IT-portal (via HTTP)
- Booker introduksjonsmøter i kalender
- Sender reminder 1 uke før oppstart

**Hvorfor relevant i kurset:**
- Demonstrerer parallelle prosesser
- Integrering på tvers av M365
- Scheduled flows (datobaserte triggere)
- Alle virksomheter har onboarding
- Viser hvordan redusere "første dag-kaos"

---

### 4. **Hendelsesrapportering (HMS/sikkerhet)**
**Problem:**
Ansatte skal rapportere avvik, nestenulykker, sikkerhetsobservasjoner. Ofte papirskjema eller e-post som blir borte.

**Løsning:**
- Power App for å registrere hendelse (mobil-vennlig)
- Power Automate mottar innsending
- Kategoriserer alvorlighetsgrad automatisk
- Sender varsel til HMS-koordinator og leder
- Hvis kritisk: Eskalerer umiddelbart til toppledelse
- Oppretter sak i system for oppfølging
- Sender bekreftelse til innmelder

**Hvorfor relevant i kurset:**
- Viktig for offentlig sektor og industri
- Viser mobile scenarios
- Betingelseslogikk (if kritisk, then...)
- Integrering med Power Apps
- Compliance og dokumentasjon

---

### 5. **Kundehenvendelser fra nettskjema til CRM**
**Problem:**
Kunder sender henvendelser via web-skjema. Manuell overføring til CRM, treghet i oppfølging, ingen automatisk klassifisering.

**Løsning:**
- Trigger: Microsoft Forms submission
- Power Automate analyserer innhold (AI/nøkkelord)
- Klassifiserer type henvendelse (salg, support, klage)
- Oppretter case i Dynamics 365/Dataverse
- Fordeler til riktig team basert på kategori
- Sender kvitteringsmail til kunde med saksnummer
- Setter opp reminder hvis ikke behandlet innen 24t

**Hvorfor relevant i kurset:**
- Klassisk kundeservice-scenario
- Viser text analytics
- Demonstrerer SLA-håndtering (timers)
- Forms → Automate → Dataverse integrasjon
- Relevant for både privat og offentlig (henvendelser til kommune)

---

### 6. **Automatisk distribusjon av ukerapporter**
**Problem:**
Hver mandag må noen manuelt kjøre Power BI-rapport, eksportere til PDF, sende til distributionsliste.

**Løsning:**
- Scheduled trigger: Hver mandag kl 08:00
- Henter data fra Power BI API
- Genererer PDF-rapport
- Sender personalisert e-post til hver leder med deres avdelings tall
- Logger utsending i SharePoint
- Sender sammendrag til toppledelse

**Hvorfor relevant i kurset:**
- Scheduled flows (tid-basert)
- Power BI integrasjon
- "Set it and forget it"-prinsippet
- Frigjør tid hver uke
- Demonstrerer dataeksport

---

### 7. **Sosiale media-overvåking og respons**
**Problem:**
Bedriften må overvåke omtale på Twitter/LinkedIn, men har ikke ressurser til 24/7 monitorering.

**Løsning:**
- Trigger: Når bedriftsnavn nevnes (Twitter connector)
- Sentiment-analyse (AI Builder)
- Hvis negativt: Varsler PR-team via Teams umiddelbart
- Hvis positivt: Logger i database for markedsføring
- Hvis spørsmål: Oppretter support-ticket
- Dashboard i Power BI for trender

**Hvorfor relevant i kurset:**
- Moderne kommunikasjonsutfordring
- AI/sentiment analysis
- Multi-kanal (sosiale medier, Teams, Power BI)
- Relevant for markedsavdelinger
- Krisehåndtering

---

### 8. **Automatisk lagerpåfyll (retail/industri)**
**Problem:**
Manuell telling av lager, sen bestilling fører til tomme hyller eller overskuddslager.

**Løsning:**
- Scheduled trigger: Daglig kl 06:00
- Henter lagerdata fra ERP (via API)
- Beregner forbruk og prognose
- Hvis under minstenivå: Oppretter bestilling automatisk
- Sender ordre til leverandør (e-post/API)
- Logger i Dataverse
- Varsler lagersjef via Teams

**Hvorfor relevant i kurset:**
- Industri/varehandel scenario
- API-integrasjoner
- Beregninger i flow (expressions)
- Viser supply chain automation
- Tydelig business value

---

### 9. **Automatisk møtereferat og oppfølging**
**Problem:**
Etter møter glemmes oppgaver, ingen strukturert oppfølging, referat blir ikke skrevet.

**Løsning:**
- Trigger: Teams-møte avsluttet
- Henter møtenotater fra OneNote/Teams
- AI Builder ekstraherer action items
- Oppretter oppgaver i Planner/To Do for ansvarlige
- Sender sammendrag til deltakere
- Reminder 2 dager før deadline
- Oppdaterer møtekalender med lenke til referat

**Hvorfor relevant i kurset:**
- Dagligdags scenario (alle har møter)
- AI for tekstekstraksjon
- Task management
- Viser Microsoft 365-integrasjon
- Produktivitetsgevinst

---

### 10. **Compliance og GDPR-forespørsler**
**Problem:**
Når kunde ber om innsyn/sletting av persondata (GDPR), må man manuelt søke i mange systemer.

**Løsning:**
- Trigger: GDPR-forespørsel via web-skjema
- Verifiserer identitet (BankID-integrasjon)
- Søker automatisk i alle registrerte systemer (Dataverse, SharePoint, CRM)
- Kompilerer rapport med all data
- Logger forespørsel (compliance-krav)
- Sender kryptert til kunde innen lovpålagt frist
- Reminder til DPO hvis ikke behandlet

**Hvorfor relevant i kurset:**
- Lovpålagt for alle virksomheter
- Compliance-fokus
- Multi-system integrasjon
- Sikkerhet og kryptering
- Viser alvoret i automatisering

---

## Power Apps - Use Cases

### 1. **Utstyrslån og ressursbooking**
**Problem:**
Møterom, biler, utstyr bookes via e-post eller post-it lapper. Dobbeltbooking, ingen oversikt.

**Løsning:**
- Canvas app med oversikt over tilgjengelige ressurser
- Kalendervisning med bookinger
- Søk og filter (etter dato, type, lokasjon)
- Book ved å trykke på ledig tidspunkt
- Automatisk sjekk av tilgjengelighet
- QR-kode for utsjekking/innsjekking
- Push-notification når booking nærmer seg

**Hvorfor relevant i kurset:**
- Enkel app å bygge (godt startprosjekt)
- Viser Gallery, Forms, og Calendar controls
- Integrasjon med SharePoint som backend
- Alle kjenner problemet
- Mobil-først design

---

### 2. **Feltinspeksjonsapp (bygg, vedlikehold, HMS)**
**Problem:**
Inspektører bruker papirskjema, må skrive av til PC senere, bilder tas på privat mobil og må overføres.

**Løsning:**
- Offline-kapabel app (synkroniserer når tilbake på nett)
- Sjekkliste basert på inspeksjonstype
- Ta bilde direkte i app (kamera-integrasjon)
- GPS-tagging av lokasjon
- Digital signatur for godkjenning
- Generer PDF-rapport på stedet
- Send til Power Automate for oppfølging av avvik

**Hvorfor relevant i kurset:**
- Viser offline-funksjonalitet
- Kamera og GPS (mobile capabilities)
- Relevante for bygg, olje/gass, offentlig sektor
- Demonstrerer verdien av "paperless"
- ROI: Timer spart per inspeksjon

---

### 3. **Reiseregning og utleggsføring**
**Problem:**
Ansatte samler kvitteringer, fyller ut Excel, sender til økonomi som må godkjenne og registrere manuelt.

**Løsning:**
- Ta bilde av kvittering (OCR med AI Builder)
- Automatisk utfylling av beløp, dato, kategori
- Velg prosjekt/koststed fra dropdown
- Submit sender til Power Automate for godkjenning
- Leder godkjenner i Teams
- Automatisk eksport til lønn/regnskap
- Status-tracking for ansatt

**Hvorfor relevant i kurset:**
- AI Builder OCR-funksjonalitet
- Integrasjon med Power Automate
- Form-design og validering
- Alle virksomheter har utlegg
- Viser image handling

---

### 4. **Kunnskapsbase og FAQ-portal (intern)**
**Problem:**
Ansatte spør de samme spørsmålene om IT, HR, policy. Svar finnes i ulike dokumenter.

**Løsning:**
- Søkbar database (Dataverse)
- Kategorisert innhold (IT, HR, Økonomi)
- Søkefunksjon med auto-suggest
- "Var dette nyttig?"-feedback
- Populære artikler fremhevet
- Forslag nye spørsmål-funksjon
- Analytics på søk (finne gap i dokumentasjon)

**Hvorfor relevant i kurset:**
- Dataverse som backend
- Search funksjonalitet
- User feedback loops
- Reduserer support-henvendelser
- Self-service kultur

---

### 5. **Varslingsapp for IT-drift**
**Problem:**
IT-drift må varsle brukere om planlagt nedetid, men e-post drukner i innboks.

**Løsning:**
- App viser aktive varsler (trafikklys)
- Push-notifikasjoner ved kritiske hendelser
- Statusside for alle systemer (oppe/nede)
- Abonner på spesifikke systemer
- Timeline med hendelseshistorikk
- Eskalering ved langvarig nedetid
- Integrasjon med Azure Monitor

**Hvorfor relevant i kurset:**
- Notifications og alerts
- Real-time data
- API-integrasjon (Azure)
- IT-fokusert (relevant for studenter)
- Dashboard-design

---

### 6. **Opplærings- og onboarding-tracker**
**Problem:**
HR vet ikke hvem som har fullført obligatorisk opplæring (GDPR, brannvern, HMS).

**Løsning:**
- App viser ansattes opplæringsstatus
- Sjekkliste for obligatoriske kurs
- Marker som fullført (med bevis/sertifikat)
- Automatisk reminder ved utløp
- Manager-view for å se sitt team
- Rapport-generering for compliance
- Integrasjon med LMS-system

**Hvorfor relevant i kurset:**
- Multiple user personas (ansatt vs leder)
- Compliance tracking
- Date calculations og reminders
- Relevant for HR-avdelinger
- Viser security trimming (RLS)

---

### 7. **Idébank og innovasjonsportal**
**Problem:**
Ansatte har gode ideer, men ingen strukturert måte å dele og følge opp.

**Løsning:**
- Submit-idé med beskrivelse og kategori
- Voting/like-funksjon
- Kommentarfelt for diskusjon
- Status-tracking (under vurdering, godkjent, implementert)
- Topplist over populære ideer
- Admin-view for evaluering
- Gamification (poeng for vedtatte ideer)

**Hvorfor relevant i kurset:**
- Community/social features
- Voting mechanisms
- Gamification elements
- Innovasjonskultur (populært tema)
- Viser brukerengasjement

---

### 8. **Model-driven app: Case management**
**Problem:**
Kundehenvendelser håndteres i diverse systemer, ingen helhetlig oversikt.

**Løsning (Model-driven):**
- Dataverse tabeller: Case, Customer, Product
- Business process flow (fra åpen → løst)
- Automatiske statusoppdateringer
- SLA-tracking med eskalering
- Knowledge base-integrasjon
- Dashboard for ledelse
- Mobile-responsiv

**Hvorfor relevant i kurset:**
- Introduserer Model-driven apps
- Business process flows
- Dataverse relasjoner
- Enterprise-scenario
- Sammenligning Canvas vs Model-driven

---

### 9. **Timeføringssystem**
**Problem:**
Konsulenter fører timer i Excel, må konsolideres av controller, fakturering forsinkes.

**Løsning:**
- Daglig/ukentlig timeføring
- Velg prosjekt og aktivitet
- Validering mot arbeidstimer (max 24t/dag)
- Godkjenning av prosjektleder
- Automatisk faktura-underlag
- Rapportering på prosjektnivå
- Historikk og redigering

**Hvorfor relevant i kurset:**
- Common business scenario (konsulent, bygg, IT)
- Form validation
- Approval workflows
- Data aggregation
- Demonstrerer kompleks forretningslogikk

---

### 10. **Besøksregistrering (resepsjon)**
**Problem:**
Besøkende må signere i bok, manuell varsling av vert, ingen oversikt over hvem som er i bygget.

**Løsning:**
- Tablet i resepsjon
- Besøkende registrerer navn og hvem de skal møte
- Automatisk SMS/Teams-varsel til vert
- Print besøksmerke (QR-kode)
- Check-out ved utgang
- Sikkerhetsoversikt (hvem er inne nå)
- Besøkshistorikk for compliance

**Hvorfor relevant i kurset:**
- Kiosk mode
- Printer-integrasjon
- Real-time notifications
- Sikkerhet og compliance
- Simple, men nyttig app

---

## Power BI - Use Cases

### 1. **HR-analytics: Turnover og sykefravær**
**Problem:**
HR har data på ansatte, men ingen god oversikt over trender, høy turnover oppdages for sent.

**Løsning:**
- Import fra HR-system (Excel/SQL)
- Visualiseringer:
  - Turnover rate per avdeling (siste 12 mnd)
  - Sykefravær per måned (trendlinje)
  - Gjennomsnittlig ansiennitet
  - Aldersfordeling
  - Exit-intervju insights
- Drilldown til avdeling/team
- Forecast for fremtidig turnover (trendbased)

**Hvorfor relevant i kurset:**
- HR har mye uutnyttet data
- Demonstrerer time-intelligence (YTD, MOM)
- Forecasting
- Viktig for ledelse
- Viser verdien av datadrevet HR

---

### 2. **Salgs- og pipeline-rapportering (CRM)**
**Problem:**
Selgere rapporterer i CRM, men ledelsen ser ikke real-time status på pipeline og forecast.

**Løsning:**
- Koble til Dynamics 365/Dataverse
- Visualiseringer:
  - Sales funnel (leads → opportunities → closed won)
  - Forecast vs actual (kolonne + linje)
  - Win rate per selger
  - Average deal size
  - Sales by region (map)
- Slicers: Tidsperiode, produkt, region
- Mobile-optimalisert for ledelse

**Hvorfor relevant i kurset:**
- Classic business intelligence
- Funnel analysis
- KPI cards
- Map visualization
- Alle med salg trenger dette

---

### 3. **Prosjektøkonomi og ressursallokering**
**Problem:**
Prosjektledere vet ikke om de er i budsjett før månedslutt, ressurser overallokeres.

**Løsning:**
- Datakilder: Project Online, timeføring, budsjett
- Visualiseringer:
  - Budsjett vs faktisk (gauge/KPI)
  - Burn rate (linje-graf)
  - Ressursallokering per person (100%+= overalloker)
  - Margin per prosjekt
  - Prognose til slutt
- Alerts ved budsjettoverskridelse
- Drilldown til kostnadstype

**Hvorfor relevant i kurset:**
- Prosjektstyring er vanlig
- Budsjettovervåking kritisk
- Multiple data sources
- Calculated measures (variance, %)
- Conditional formatting

---

### 4. **Innkjøpsanalyse og leverandørstyring**
**Problem:**
Innkjøp fra mange leverandører, ingen oversikt over volumrabatter, compliance.

**Løsning:**
- Data fra ERP-system
- Visualiseringer:
  - Spend per leverandør (treemap)
  - Spend per kategori (donut)
  - Avtalepris vs faktisk pris (scatter plot)
  - Leveransetid-analyse
  - Compliance % (leverandør-evaluering)
- Identifiser konsolideringsmuligheter
- Contract expiry tracking

**Hvorfor relevant i kurset:**
- Procurement er stort område
- Cost savings opportunities
- Compliance tracking
- Scatter plots og treemaps (andre visualiseringer)
- Strategisk verdi

---

### 5. **Kundeservice: Ticket-analyse**
**Problem:**
Mange support-tickets, men vet ikke hva som driver volum eller SLA-brudd.

**Løsning:**
- Data fra support-system (ServiceNow, Zendesk)
- Visualiseringer:
  - Ticket volume over tid
  - Average resolution time per kategori
  - SLA compliance % (target line)
  - Top 10 issues (pareto)
  - Customer satisfaction scores
  - First call resolution rate
- Alerts ved SLA-breach trend

**Hvorfor relevant i kurset:**
- Service desk er universelt
- SLA monitoring kritisk
- Pareto analysis
- Trend detection
- Continuous improvement data

---

### 6. **Operasjonell dashbord (produksjon/logistikk)**
**Problem:**
Produksjonsledelse vet ikke real-time status på linjer, nedetid oppdages for sent.

**Løsning:**
- Koble til IoT/OPC-data (via Azure)
- Visualiseringer:
  - OEE (Overall Equipment Effectiveness) gauge
  - Produksjon vs target (kolonne)
  - Nedetid per maskin (bar chart)
  - Quality metrics (scatter)
  - Real-time status (trafikklys)
- Auto-refresh hvert minutt
- Alerts ved avvik

**Hvorfor relevant i kurset:**
- Industri 4.0 / IoT integration
- Real-time dashboards
- OEE er industri-standard
- Viser Power BI's capabilities
- Kritisk for operasjonell excellence

---

### 7. **Markedsførings-ROI og kampanjeanalyse**
**Problem:**
Markedsføring bruker mye penger, men vet ikke hva som faktisk driver salg.

**Løsning:**
- Data fra Google Analytics, Facebook Ads, CRM
- Visualiseringer:
  - ROI per kanal (column chart)
  - Customer acquisition cost
  - Conversion funnel (web → lead → customer)
  - Campaign performance matrix
  - Attribution modeling
- Slicers: Kampanje, periode, produkt
- What-if parameters for budsjett-allokering

**Hvorfor relevant i kurset:**
- Marketing bruker mye penger
- Multiple source integration (web, ads, CRM)
- Attribution er komplekst
- What-if analysis
- Strategisk for markedsavdelinger

---

### 8. **Finansiell rapportering (P&L, balanse)**
**Problem:**
CFO venter til månedslutt for regnskapsrapporter, ingen real-time innsikt.

**Løsning:**
- Koble til økonomisystem (ERP)
- Visualiseringer:
  - P&L statement (matrix)
  - Balance sheet
  - Cash flow waterfall
  - Revenue vs costs (combo chart)
  - Budget variance analysis
  - Key ratios (ROE, ROA, etc.)
- Drillthrough til kontodetail
- YTD, QTD, MTD calculations

**Hvorfor relevant i kurset:**
- Finance er universelt
- Complex calculations (DAX)
- Hierarkier (konto-struktur)
- Regulatory requirement
- Executive-level reporting

---

### 9. **Eiendomsforvaltning: Energiforbruk**
**Problem:**
Kommuner/eiendomsselskap har mange bygg, ingen oversikt over energibruk og optimalisering.

**Løsning:**
- Data fra smart meters/sensorer
- Visualiseringer:
  - Energiforbruk per bygg (map)
  - Trend over tid (seasonal patterns)
  - Cost per kWh
  - Benchmark mot liknende bygg
  - Temperature vs consumption (scatter)
  - Anomaly detection
- Sustainability reporting (CO2)

**Hvorfor relevant i kurset:**
- Sustainability er hot topic
- IoT/sensor data
- Geospatial analysis
- Anomaly detection
- Relevant for offentlig sektor

---

### 10. **Helseanalyse: Pasientflyt og ventetider**
**Problem:**
Sykehus vet ikke hvor flaskehalser er, ventetider varierer mye.

**Løsning:**
- Data fra pasientadministrativt system
- Visualiseringer:
  - Average wait time per avdeling
  - Patient flow sankey diagram
  - Capacity utilization % per time of day
  - Readmission rates
  - Length of stay distribution
  - Seasonal patterns
- Privacy-compliant (aggregert data)

**Hvorfor relevant i kurset:**
- Healthcare er stort område
- Sankey diagrams (flow visualization)
- Time-of-day analysis
- Privacy considerations
- Offentlig sektor relevans

---

## Dataverse - Use Cases

### 1. **CRM-lite: Kunde- og kontaktstyring**
**Problem:**
SMB har kunder i Excel, e-post, og hodene til selgerne. Ingen delt sanhet.

**Løsning:**
- Dataverse tabeller: Account, Contact, Opportunity
- Relasjoner: Account → Contacts (1:N)
- Business rules: Automatisk kategorisering
- Views: Mine kunder, Hot leads, Lost opportunities
- Power App for registrering
- Power Automate for oppfølging
- Power BI for analyse

**Hvorfor relevant i kurset:**
- Grunnleggende datamodellering
- Relasjoner (1:N, N:N)
- Viser hvorfor Dataverse > Excel
- Fundament for andre apps
- Demonstrerer hele Power Platform-stacken

---

### 2. **Asset management: IT-utstyr og inventar**
**Problem:**
Ingen vet hvor utstyr er, hvem som har det, når service er, når leasing utløper.

**Løsning:**
- Tabeller: Asset, Employee, Location, Vendor
- Relasjoner: Asset → Employee (utlånt til)
- Calculated fields: Days until lease expiry
- Rollup fields: Total asset value per location
- Business rules: Alert hvis service overdue
- Integration med QR/barcode scanning
- Audit history (hvem hadde PC tidligere)

**Hvorfor relevant i kurset:**
- Asset tracking er universelt
- Calculated og Rollup columns
- Business logic
- Audit trail
- Integration med scanning

---

### 3. **Prosjektportefølje-styring**
**Problem:**
Mange prosjekter, spredt informasjon, ingen helhetlig styring eller ressursallokering.

**Løsning:**
- Tabeller: Project, Task, Resource, Milestone
- Relasjoner: Project → Tasks (1:N), Resource → Tasks (N:N)
- Rollup: Total hours per project
- Business Process Flow: Initiation → Planning → Execution → Close
- Security roles: PM vs Portfolio Manager
- Integration med Project Online
- Power BI for portfolio dashboard

**Hvorfor relevant i kurset:**
- Many-to-many relationships
- Business Process Flows
- Role-based security
- Complex business scenario
- PMO-relevans

---

### 4. **Incident og problem management (ITIL)**
**Problem:**
IT-support bruker SharePoint eller Excel, ingen strukturert ITIL-prosess.

**Løsning:**
- Tabeller: Incident, Problem, Change, CMDB
- Relasjoner: Incident → Problem (N:1)
- Status reason chains (New → Assigned → Resolved)
- SLA-beregninger (auto-eskalering)
- Knowledge articles linking
- Root cause analysis tracking
- Integration med monitoring tools

**Hvorfor relevant i kurset:**
- ITIL er industry standard
- Status transitions
- SLA calculations
- Knowledge management
- IT-relevans for studenter

---

### 5. **Employee skill matrix og kompetansekartlegging**
**Problem:**
HR vet ikke hvilke kompetanser organisasjonen har, vanskelig å finne riktig person for oppdrag.

**Løsning:**
- Tabeller: Employee, Skill, Certification, Project
- N:N: Employee <-> Skills (med nivå: beginner/intermediate/expert)
- Rollup: Skills count per employee
- Views: Find expert in [skill]
- Gap analysis: Required vs available
- Succession planning
- Learning path suggestions

**Hvorfor relevant i kurset:**
- Many-to-many med attributes
- Skill-based resourcing
- HR analytics
- Gap analysis
- Talent management

---

### 6. **Kontrakts- og avtalestyring**
**Problem:**
Kontrakter ligger i filserver, ingen varsel ved utløp, ikke oversikt over forpliktelser.

**Løsning:**
- Tabeller: Contract, Vendor, ContractLine, Renewal
- Calculated: Days to expiry
- Business rules: Alert 90 days before expiry
- Workflow: Renewal approval process
- Document management (integrasjon med SharePoint)
- Spend rollup per vendor
- Compliance tracking

**Hvorfor relevant i kurset:**
- Date calculations
- Workflow automation
- Document integration
- Procurement relevans
- Compliance requirement

---

### 7. **Grant management (offentlig sektor)**
**Problem:**
Kommune/fylke har mange tilskuddsordninger, manuell søknadsbehandling, ingen oppfølging av middelbruk.

**Løsning:**
- Tabeller: Grant Program, Application, Applicant, Payment
- Business Process Flow: Application → Review → Approval → Disbursement → Reporting
- Calculated: Remaining budget
- Rollup: Total disbursed per program
- Integration med bank (payment processing)
- Reporting requirements tracking
- Audit trail

**Hvorfor relevant i kurset:**
- Public sector scenario
- Complex approval flows
- Budget tracking
- Compliance heavy
- Multi-step processes

---

### 8. **Quality management: Non-conformance og CAPA**
**Problem:**
Produksjonsbedrift må håndtere avvik og korrigerende tiltak, papirbasert system.

**Løsning:**
- Tabeller: Non-Conformance, CAPA (Corrective/Preventive Action), Root Cause
- Relasjoner: NC → CAPA (1:N)
- Status tracking: Open → Investigating → Action → Verified → Closed
- Recurrence detection (same root cause)
- 5 Why analysis tracking
- Integration med production data
- Trend analysis for continuous improvement

**Hvorfor relevant i kurset:**
- ISO 9001 relevans
- Manufacturing scenario
- Root cause analysis
- Continuous improvement
- Process maturity

---

### 9. **Customer feedback og complaint management**
**Problem:**
Kundefeedback kommer via e-post, telefon, sosiale medier - ingen felles system.

**Løsning:**
- Tabeller: Feedback, Customer, Product, Resolution
- Sentiment scoring (AI integration)
- Automatic categorization
- Escalation rules (kritisk klage)
- Resolution tracking og SLA
- Product improvement backlog
- NPS calculation
- Closed-loop feedback (tilbakemelding til kunde)

**Hvorfor relevant i kurset:**
- Customer experience management
- Multi-channel input
- AI/sentiment analysis
- Product development link
- Service recovery

---

### 10. **Event og konferanseadministrasjon**
**Problem:**
Planlegger konferanse, manuell håndtering av påmeldinger, agenda, speakers, feedback.

**Løsning:**
- Tabeller: Event, Session, Speaker, Attendee, Registration
- N:N: Attendee <-> Session (med kapasitet-sjekk)
- Registration workflow med betalingsstatus
- Automated confirmations og reminders
- Check-in app (QR-code)
- Session feedback collection
- Certificate generation
- Post-event survey

**Hvorfor relevant i kurset:**
- Event management er vanlig
- Complex registrations
- Capacity management
- Multiple user journeys
- End-to-end scenario

---

## Power Pages - Use Cases

### 1. **Kundeportal: Support og case-tracking**
**Problem:**
Kunder ringer eller mailer support, ingen self-service, ingen oversikt over egne saker.

**Løsning:**
- Eksternt nettsted (Power Pages)
- Kunde logger inn (B2C authentication)
- Oppretter support-case (form)
- Ser status på egne saker
- Oppdaterer med tilleggsinfo
- Chat med support agent
- Knowledge base med FAQs
- Download dokumenter/fakturaer

**Hvorfor relevant i kurset:**
- External portal (sikkerhet viktig)
- Self-service reduserer support-load
- Customer empowerment
- Integration med internal Dataverse
- B2C authentication

---

### 2. **Leverandørportal: Onboarding og fakturering**
**Problem:**
Nye leverandører må fylle ut masse skjema, sende på e-post, manuell registrering.

**Løsning:**
- Leverandør registrerer seg selv
- Fyller ut onboarding-skjema (firmainfor, bankkonto, sertifiseringer)
- Upload dokumenter (org.nummer, forsikringer)
- Approval workflow (intern)
- Portal for å laste opp fakturaer
- Tracking av betalingsstatus
- Performance scorecards

**Hvorfor relevant i kurset:**
- B2B portal
- Onboarding automation
- Document upload
- Reduces admin overhead
- Vendor management

---

### 3. **Partnerpotal: Reseller og distributor management**
**Problem:**
Partnere trenger tilgang til produktinfo, priser, markedsmateriell, ordrestatus.

**Løsning:**
- Partner logger inn (tiered access: Silver/Gold/Platinum)
- Produktkatalog med partnerpriser
- Download markedsmateriell
- Submit deal registration
- Order placement og tracking
- Rebate/incentive tracking
- Training og sertifisering
- Partner scorecard

**Hvorfor relevant i kurset:**
- Channel management
- Tiered access (role-based)
- E-commerce elements
- Partner ecosystem
- Incentive management

---

### 4. **Jobbportal: Søknad og rekruttering**
**Problem:**
Kandidater søker via e-post, manuell sortering, dårlig kandidatopplevelse.

**Løsning:**
- Offentlig jobbsøk (ingen login)
- Filter på lokasjon, kategori, stillingsnivå
- Submit søknad (CV-upload)
- Kandidatportal: Se søknadsstatus
- Automatisk avslag/invitasjon til intervju
- Scheduler intervju (integrasjon med kalender)
- Post-intervju feedback
- Onboarding-trigger ved ansettelse

**Hvorfor relevant i kurset:**
- Public-facing
- Recruitment automation
- Candidate experience
- Integration with HR processes
- ATS (Applicant Tracking System)

---

### 5. **Medlemsportal: Forening/fagorganisasjon**
**Problem:**
Medlemmer betaler via faktura, ringer om informasjon, manuell administrasjon.

**Løsning:**
- Medlemmer logger inn
- Se medlemsstatus og historikk
- Forny medlemskap (online betaling)
- Registrer til events/kurs
- Download medlemsfordeler
- Forum/community
- Memberskap tier-benefits
- Automatic renewal reminders

**Hvorfor relevant i kurset:**
- Membership management
- Payment integration
- Community features
- Self-service
- Non-profit relevans

---

# Business Use Cases for Copilot Studio

## Copilot Studio - Use Cases

### 1. **IT-support helpdesk bot**
**Problem:**
IT-helpdesk overveldes med repeterende spørsmål om passord-reset, VPN-problemer, programvareinstallasjoner. Lang ventetid på telefon.

**Løsning:**
- Bot tilgjengelig 24/7 i Teams
- Topics: Passord-reset, VPN setup, printer-problemer, programvare-lisenser
- Self-service guide for vanlige problemer
- Samler informasjon før eskalering
- Oppretter ticket automatisk hvis ikke løst (integrasjon med Power Automate)
- Eskalerer til agent ved komplekse issues
- Sporer løsningsrate og vanligste problemer

**Hvorfor relevant i kurset:**
- Mest vanlige chatbot use case
- Reduserer helpdesk-load med 40-60%
- Alle organisasjoner har IT-support
- Viser topic design og escalation
- Teams-integrasjon
- Tydelig ROI (timer spart)

---

### 2. **HR-bot for ansatte (policies og benefits)**
**Problem:**
HR må svare på de samme spørsmålene om feriedager, foreldrepermisjon, sykmelding, benefits. Ansatte finner ikke policies.

**Løsning:**
- Bot i Teams eller intranett
- Topics: Feriedager (hvor mange har jeg?), Foreldrepermisjon, Sykmelding, Benefits, Pensjonsordning
- Integrasjon med HR-system (hent personlige data via Power Automate)
- "Hvor mye ferie har jeg igjen?" → henter fra Dataverse
- Link til relevante policies
- Book møte med HR-rådgiver
- Anonym Q&A for sensitive spørsmål

**Hvorfor relevant i kurset:**
- HR bruker mye tid på repeterende spørsmål
- Personalisering (mine data vs generelt)
- Sikkerhet og privacy viktig
- Self-service kultur
- Integration med backend systems

---

### 3. **Kundeservice FAQ-bot (ekstern)**
**Problem:**
Kunder ringer eller mailer om åpningstider, returer, leveringsstatus, produktinfo. Overveldende volum.

**Løsning:**
- Bot på nettside og i kundeportal
- Topics: Åpningstider, Returer/reklamasjoner, Spore forsendelse, Produktspesifikasjoner, Betalingsmetoder
- "Hvor er pakken min?" → API-kall til fraktselskap
- Generer returetikett
- Eskalerer til live chat ved komplekse issues
- Sentiment-analyse → prioriterer negative henvendelser
- Multilingual support (norsk/engelsk)

**Hvorfor relevant i kurset:**
- External-facing bot (annen sikkerhet)
- API-integrasjoner
- Sentiment analysis
- Live agent handoff
- Customer experience
- 24/7 availability-verdi

---

### 4. **Onboarding-bot for nye ansatte**
**Problem:**
Nye ansatte bombarderes med informasjon første uke, glemmer viktig info, tør ikke spørre "dumme" spørsmål.

**Løsning:**
- Bot som følger nyansatt fra dag 1
- Proaktive meldinger: "Dag 1: Hei! Her er det viktigste for i dag..."
- Topics: Hvor er kantina, WiFi-passord, Bestille utstyr, Møte teamet, Systemer og tilganger
- Guided tour gjennom systemer
- Quiz om sikkerhets-policies
- Book 1:1 med leder/fadder
- Feedback-innsamling: "Hvordan går det?"
- Eskalerer bekymringer til HR

**Hvorfor relevant i kurset:**
- Proactive messaging (ikke bare reactive)
- Progressive disclosure av info
- Reduces onboarding-stress
- Skaler onboarding uten å øke HR-ressurser
- Gamification (quiz)

---

### 5. **Møterom- og ressursbooking-bot**
**Problem:**
Ansatte må søke i Outlook, prøve forskjellige rom, dobbeltbooking skjer, utstyr ikke tilgjengelig.

**Løsning:**
- Bot i Teams: "Book møterom for 10 personer kl 14 i morgen"
- Sjekker tilgjengelighet (Graph API)
- Foreslår alternativer hvis ikke ledig
- "Trenger du projektor?" → sjekker utstyr-tilgjengelighet
- Booker automatisk
- Sender bekreftelse med kart/etasje
- Reminder 15 min før møte
- "Avbestill meeting" → frigir rom

**Hvorfor relevant i kurset:**
- Natural language processing (dato/tid/antall)
- Calendar integration (Graph API)
- Convenience bot (productivity)
- Variables og context handling
- Reduce meeting-frustration

---

### 6. **Lead qualification bot (salg)**
**Problem:**
Salg får mange leads fra web, telefon, events. Må manuelt kvalifisere, mye tid brukt på ikke-kvalifiserte leads.

**Løsning:**
- Bot på nettside: "Hva kan vi hjelpe deg med?"
- Stiller kvalifiserende spørsmål: Industri, størrelse, budsjett, timeline, beslutningsrolle
- Scorer lead basert på svar (BANT-metodikk)
- Høy score → booker møte med selger automatisk
- Lav score → sender til nurture-kampanje
- Mellom → sendes til innsidde sales
- Oppretter lead i CRM (Dynamics/Dataverse)
- Varsel til riktig selger

**Hvorfor relevant i kurset:**
- Sales automation
- Lead scoring logic
- CRM integration
- Calendar booking
- Branch logic (if/then)
- Revenue impact

---

### 7. **Faciliteter og eiendomsservice-bot**
**Problem:**
Ansatte må sende e-post eller ringe vaktmester for problemer (lys, temperatur, renhold). Treghet og ingen tracking.

**Løsning:**
- Bot i Teams: "Rapporter problem"
- Topics: Temperatur for høy/lav, Lysrør ute, Renholdsforespørsel, Låst ute, Parkering
- "Hvilket rom?" → dropdown med bygning/etasje/rom
- Ta bilde av problem
- Oppretter service-ticket (Dataverse)
- Fordeler til riktig tekniker
- Sender status-oppdateringer
- "Løst"-bekreftelse med rating

**Hvorfor relevant i kurset:**
- Facilities management
- Image upload capability
- Ticket creation og routing
- Status tracking
- User feedback loop
- Improves workplace satisfaction

---

### 8. **Opplærings- og kurs-veileder bot**
**Problem:**
Ansatte vet ikke hvilke kurs de bør ta, hvordan melde seg på, status på egen kompetanseutvikling.

**Løsning:**
- Bot: "Hva vil du lære?"
- Anbefaler kurs basert på rolle/karrieremål
- "Hvor mange kurs har jeg fullført i år?"
- Påmeldingsprosess: Sjekk ledig plass → Book → Send til leder for godkjenning
- Reminder før kursstart
- Post-kurs evaluering
- Sertifikat-download
- Karriereveiledning: "Hva må jeg ta for å bli leder?"

**Hvorfor relevant i kurset:**
- Learning & Development
- Recommendation engine
- Approval workflows
- Personal development focus
- Integration med LMS
- Career pathing

---

### 9. **Compliance og policy-guide bot**
**Problem:**
Ansatte vet ikke regler for gaver, interessekonflikter, GDPR, compliance. Leser ikke lange dokumenter.

**Løsning:**
- Bot: "Kan jeg ta imot gave fra leverandør?"
- Guided Q&A med scenarios
- "Gaveverdi over 500 kr?" → må rapporteres
- "Er du i innkjøpsrolle?" → strengere regler
- Lenker til relevant policy
- Rapporterings-skjema direkte i bot
- Annual compliance quiz
- Anonyme spørsmål (whistleblower-lite)
- Tracking av hvem har lest policies

**Hvorfor relevant i kurset:**
- Risk management
- Regulatory compliance
- Scenario-based guidance
- Anonymous options
- Ethics og governance
- Prevents violations

---

### 10. **Reisehjelp og expense-bot**
**Problem:**
Ansatte usikre på reisepolcy, hva som dekkes, hvordan booke, kvittering-håndtering.

**Løsning:**
- Bot: "Planlegg reise"
- Sjekker policy: Klasse tillatt, hotellbudsjett
- "Kan jeg fly business?" → basert på reisetid/posisjon
- Book fly/hotell (integrasjon med reisebyrå-API)
- "Last opp kvittering" → OCR og kategorisering
- Automatisk utleggsskjema
- Send til leder for godkjenning
- "Status på utleggsrefusjon?"
- Travel tips for destinasjon

**Hvorfor relevant i kurset:**
- Travel & Expense automation
- Policy enforcement
- OCR/AI Builder integration
- Expense claim workflow
- User convenience
- Compliance (company policy)

---

## Bonus Use Cases (kortversjoner)

### 11. **Restaurant/kantinebestilling-bot**
- Bestill lunsj via Teams
- Daglig meny
- Matallergier-håndtering
- Forhåndsbestilling til møter
- Betalingsintegrasjon

### 12. **Inventar og forsynings-bot**
- "Bestill kontormateriell"
- Lagersjekk
- Automatisk godkjenning under terskel
- Tracking av leveranse
- Budget-sjekk

### 13. **Feedback og undersøkelser-bot**
- Proaktiv pulsundersøkelse
- Exit interview
- Event feedback
- NPS-målinger
- Anonyme surveys

### 14. **Salgsassistent-bot (intern)**
- "Finn case study for finans"
- Produktinformasjon
- Prisinformasjon (basert på tilgangsnivå)
- Konkurranseanalyse
- Sales playbooks

### 15. **E-handel produktrådgiver**
- "Hjelp meg velge laptop"
- Guided product selection
- Sammenligning
- Add to cart
- Ordrestatus

---

## Oppsummering: Hvorfor Copilot Studio i kurset

### 1. **Conversational AI-trenden**
- Alle forventer chat-interface nå
- GenAI gjør bots smartere (Copilot-funksjoner)
- Natural language er fremtiden

### 2. **Lavthengende frukt (ROI)**
- FAQ-bots gir umiddelbar verdi
- 24/7 tilgjengelighet
- Skaler support uten å ansette mer

### 3. **Power Platform-integrasjon**
- Trigger Power Automate flows
- Opprette data i Dataverse
- Bruke Power BI-data
- Komplett løsning

### 4. **Progressiv læring**
- Start enkelt: FAQ
- Så: Backend integration
- Til slutt: AI/sentiment/handoff

### 5. **User adoption**
- Folk er komfortable med chat
- Teams-integrasjon → møter brukerne der de er
- Lower barrier enn å lære nytt system

### 6. **Differensiering**
- Få nettbaserte kurs dekker chatbots grundig
- AI/Copilot-vinkel er hot
- Fremtidsrettet
