# Eksamensguide – DCST1005 Digital Infrastruktur og Cybersikkerhet

> Dette dokumentet gir deg en oversikt over hva du bør prioritere inn mot eksamen, og hva som ikke vil bli testet. Les gjennom hele dokumentet og bruk det aktivt i eksamensforberedelsene dine.

---

## Active Directory og PowerShell-automatisering

### ✅ Eksamensrelevant

**Active Directory-struktur og administrasjon:**
- Hva er Organizational Units (OU-er), grupper og brukere – og hvordan henger de sammen?
- Opprette og administrere brukere, grupper og OU-er
- Melde inn maskiner i et domene

**PowerShell-automatisering:**
- `Import-CSV` for å lese data fra fil og bruke den som input i scripts
- `ForEach-Object` for å iterere over en samling objekter
- `If-Else` for betinget logikk
- `Try-Catch` for feilhåndtering og logging av utfall
- Kjenn til oppbyggingen av PowerShell, verb-substantiv, gangen i script og bruk av kjent logikk som nevnt ovenfor.
- Øv på hvordan du kan sette opp et forlag på Pseudo-kode for noen use-case allerede gjennomført i fagets praktiske lab.

### ❌ Ikke eksamensrelevant
- Selve installasjonen av Active Directory (AD DS)
- Oppsett av MGR-VM og RSAT
- Oppsett og konfigurasjon av OpenStack-miljøet
- Installasjon av pakkehåndterere og utviklingsverktøy
- Skriv PowerShell-kode fra scratch

---

## Group Policy

### ✅ Eksamensrelevant

**Hva er Group Policy?**
- Hva Group Policy (GPO) er og hvilken rolle det spiller i en Windows-infrastruktur
- Hvordan GPO-er arves og anvendes på OU-er, brukere og maskiner
- Forskjellen på tvungen policy (enforced) og deaktivering av arv (block inheritance)

**Praktisk bruk:**
- Konfigurere og distribuere innstillinger til brukere og maskiner via GPO
- User vs Computer
- Eksempler på typiske bruksområder: installasjoner, skrivebordsinnstillinger, tilgangsstyring

**NTFS- og delte tillatelser (Shared Permissions):**
- Forskjellen på NTFS-tillatelser og delte tillatelser (Share Permissions)
- Hvordan disse samvirker når en bruker aksesserer en ressurs over nettverket

### ❌ Ikke eksamensrelevant
- Installasjon og konfigurasjon av DFS Namespace og DFS Replication
- Windows Storage generelt (utover NTFS- og delte tillatelser)

---

## Overvåking av infrastruktur (Monitor your infrastructure)

### ❌ Ikke eksamensrelevant
- Dette temaet vil ikke bli testet på eksamen.

---

## Backup

### ❌ Ikke eksamensrelevant
- VEEAM og backup-oppsett vil ikke bli testet på eksamen.

---

## Herding av infrastruktur (Hardening)

### ❌ Ikke eksamensrelevant

---

## Sky og styring – introduksjon til Azure (Cloud and Governance)

### ✅ Eksamensrelevant

**Azure-styringsstruktur:**
- Management Groups, Subscriptions, Resource Groups og ressurshierarkiet
- Bruk av Tags for organisering og kostnadssporing
- Role-Based Access Control (RBAC) – hva er roller, hvem tildeles de, og på hvilket nivå?

**Azure Policy:**
- Hva er Azure Policy, og hvorfor brukes det?
- Eksempler: begrense tillatte lokasjoner, håndheve Tags, begrense ressurs-SKU

**Kostnadsstyring:**
- Grunnleggende forståelse av Azure Cost Management og kostnadskontroll

---

## Hybrid sky – Azure Arc og Azure File Sync

### ❌ Ikke eksamensrelevant

---

## Nettverkstjenester i Azure

### ✅ Eksamensrelevant

**Grunnleggende nettverksbygging:**
- Hva er et Virtual Network (VNet), og hvordan deles det opp i subnett?
- Network Security Groups (NSG) – hva er de, hvordan fungerer regler, og hvordan knyttes de til ressurser?
- Opprette og konfigurere virtuelle maskiner i Azure med korrekt nettverksoppsett

**Avansert nettverkstopologi – kun det som er brukt i praktisk lab:**
- Hub-spoke-topologi: hva er det, og hvorfor brukes det?
- VNet Peering mellom hub og spoke
- Azure Firewall (Basic-nivå): hva gjør den, og hvordan styrer den trafikk mellom nett?
- Point-to-Site VPN Gateway med OpenVPN og Entra ID-autentisering: hva er det, og hvilken tilgangskontroll gir det?

> **Merk:** For pensumdokumentet «Advanced networking in public cloud» er det **kun de tjenestene og topologiene dere har brukt i praktisk lab** som er eksamensrelevant.

---

## Compute, Storage og AKS

### ✅ Eksamensrelevant

**Compute:**
- Hva er Azure Kubernetes Service (AKS), og hva løser det?
- Grunnleggende forståelse av containerbasert kjøring og hvorfor det brukes i skyen

**Storage:**
- Azure-lagringstjenester på overordnet nivå: hva finnes, og når brukes hva?
- Azure Container Registry (ACR): hva er det, og hvordan henger det sammen med AKS?

**Nettverk i denne konteksten:**
- Hvordan kobles AKS til eksisterende VNet og eksponeres via intern load balancer?
- Sammenhengen mellom VPN Gateway-tilgang og adgang til interne tjenester (tilsvarende NTNU sitt eget VPN-opplegg)

### ❌ Ikke eksamensrelevant
- Detaljert oppsett og deployment-scripts for lab-miljøet
- Uke 16 – sikkerhetskonfigurasjonsøvingen (finn feil i lab) vil ikke bli testet på eksamen

---

## Oppsummering – hva bør du prioritere?

| Tema | Prioritet |
|---|---|
| Active Directory – struktur, administrasjon, PowerShell | ⭐⭐⭐ Høy |
| Group Policy – konsept, bruk, arv | ⭐⭐⭐ Høy |
| NTFS og delte tillatelser | ⭐⭐ Middels |
| Herding av infrastruktur | ❌ Ikke relevant |
| Azure styringsstruktur og RBAC | ⭐⭐ Middels |
| Azure Policy og Tags | ⭐⭐ Middels |
| VNet, subnett og NSG | ⭐⭐⭐ Høy |
| Hub-spoke, Azure Firewall, VPN Gateway | ⭐⭐⭐ Høy |
| Hybrid sky – Arc og File Sync | ❌ Ikke relevant |
| AKS og ACR – overordnet forståelse | ⭐ Lav–middels |
| Azure kostnadsstyring | ⭐ Lav–middels |
| OpenStack-oppsett, VEEAM, DFS, overvåking, hardening, Arc/File Sync | ❌ Ikke relevant |