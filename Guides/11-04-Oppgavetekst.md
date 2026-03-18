# Oppgave: Hub-Spoke Nettverkstopologi med Azure Firewall

## Case: InfraIT.sec sin nettverksutvidelse i Azure

InfraIT.sec har fullført det initiale nettverksoppsettet i Azure med et segmentert n-tier virtuelt nettverk. Nettverket fungerer godt som ett isolert miljø, men organisasjonen vokser. Nye avdelinger og prosjekter krever sine egne isolerte nettverksmiljøer, og disse miljøene må kommunisere med hverandre på en kontrollert og sporbar måte.

Infrastructure Manager har besluttet at InfraIT.sec skal gå over til en **hub-spoke-topologi** som er standard nettverksarkitektur for enterprise-miljøer i Azure. I denne arkitekturen samles all trafikkontroll i ett sentralt nettverk — huben — mens de individuelle miljøene organiseres som spokes. En **Azure Firewall** i huben blir det eneste stedet trafikk kan passere mellom spokes, og det eneste inngangspunktet for trafikk utenfra.

Denne arkitekturen erstatter ikke det eksisterende n-tier-nettverket — det blir spoke 1 i den nye topologien.

---

## Din rolle

Du er **Cloud Infrastructure Engineer** hos InfraIT.sec og rapporterer til **Infrastructure Manager**. Din oppgave er å implementere hub-spoke-topologien, konfigurere Azure Firewall med DNAT-regler for kontrollert innkommende tilgang, og verifisere at trafikkruting fungerer korrekt ved å demonstrere at innkommende forespørsler på spesifikke porter lander på riktig VM i riktig spoke.

---

## Tekniske krav

### 1. Hub Virtual Network

Opprett et nytt virtuelt nettverk som skal fungere som hub:

| Felt | Verdi |
|---|---|
| Navn | `<prefix>-vnet-hub` |
| Adresserom | `10.100.0.0/16` |
| Region | Norway East |
| Resource Group | `<prefix>-rg-infraitsec-network` |

Huben skal ha følgende subnets:

| Subnet | Adresserom | Formål |
|---|---|---|
| `AzureFirewallSubnet` | `10.100.1.0/26` | Reservert navn — påkrevd av Azure |
| `subnet-management` | `10.100.0.0/24` | Fremtidig administrasjonstilgang |

Opprett en NSG `<prefix>-nsg-management` og knytt den til `subnet-management`. NSGen skal tillate inngående SSH fra `AzureFirewallSubnet` (`10.100.1.0/26`).

### 2. Spoke Virtual Networks

Det eksisterende nettverket fra forrige oppgave blir spoke 1. Opprett to nye spoke-nettverk:

| Nettverk | Adresserom | Subnet | Subnet-adresserom |
|---|---|---|---|
| `<prefix>-vnet-spoke2` | `10.1.0.0/16` | `subnet-workload` | `10.1.0.0/24` |
| `<prefix>-vnet-spoke3` | `10.2.0.0/16` | `subnet-workload` | `10.2.0.0/24` |

### 3. Azure Firewall

> ⚠️ **Kostnadsnote:** Azure Firewall Basic faktureres per time fra det øyeblikket ressursen opprettes. Deploy firewallen **etter** at alle nettverk og peerings er på plass, slik at du er klar til å jobbe videre umiddelbart. Slett firewallen så snart du har presentert oppgaven for læringsassistenten.

Opprett følgende støtteressurser og selve firewallen:

| Ressurs | Navn | Merknad |
|---|---|---|
| Public IP | `<prefix>-pip-fw` | Standard SKU, statisk |
| Firewall Policy | `<prefix>-fwpolicy-hub` | Basic tier |
| Azure Firewall | `<prefix>-fw-hub` | Basic tier, tilknyttet policy og hub VNET |

### 4. VNET Peering

Konfigurer peering mellom hub og hvert spoke. Alle peering-forbindelser skal ha **Allow forwarded traffic** aktivert i begge retninger.

| Peering | Fra | Til |
|---|---|---|
| `hub-to-spoke1` / `spoke1-to-hub` | `<prefix>-vnet-hub` | `<prefix>-vnet-infraitsec` |
| `hub-to-spoke2` / `spoke2-to-hub` | `<prefix>-vnet-hub` | `<prefix>-vnet-spoke2` |
| `hub-to-spoke3` / `spoke3-to-hub` | `<prefix>-vnet-hub` | `<prefix>-vnet-spoke3` |

### 5. User Defined Routes

Opprett én rutetabell per spoke som sender trafikk destined for de andre spokene via firewall private IP:

| Rutetabell | Tilknyttet subnet(s) | Ruter |
|---|---|---|
| `<prefix>-rt-spoke1` | Alle subnets i `vnet-infraitsec` | `10.1.0.0/16` og `10.2.0.0/16` → Firewall |
| `<prefix>-rt-spoke2` | `subnet-workload` i `vnet-spoke2` | `10.0.0.0/16` og `10.2.0.0/16` → Firewall |
| `<prefix>-rt-spoke3` | `subnet-workload` i `vnet-spoke3` | `10.0.0.0/16` og `10.1.0.0/16` → Firewall |

Next hop type for alle ruter: **Virtual appliance** med firewall private IP som adresse.

### 6. Test-VM-er med webserver

Deploy én Linux VM per spoke for å verifisere trafikkruting. VM-ene skal **ikke** ha public IP-adresse — all tilgang skal gå via firewallen.

| VM | Nettverk | Subnet | Privat IP |
|---|---|---|---|
| `<prefix>-vm-web-spoke1` | `vnet-infraitsec` | `subnet-frontend` | `10.0.1.10` |
| `<prefix>-vm-web-spoke2` | `vnet-spoke2` | `subnet-workload` | `10.1.0.10` |
| `<prefix>-vm-web-spoke3` | `vnet-spoke3` | `subnet-workload` | `10.2.0.10` |

**VM-spesifikasjoner:**
- OS: Ubuntu Server 24.04 LTS
- Størrelse: Standard_B1s
- Resource Group: `<prefix>-rg-infraitsec-compute`
- Webserver: nginx, installert og startet automatisk ved oppstart

Hver VM skal vise en enkel nettside som identifiserer hvilken spoke den tilhører.

NSGene tilknyttet VM-enes subnets skal tillate inngående HTTP (port 80) og SSH (port 22) fra `AzureFirewallSubnet` (`10.100.1.0/26`).

### 7. Firewall Policy — DNAT-regler

Konfigurer følgende DNAT-regler i `<prefix>-fwpolicy-hub`:

**HTTP-tilgang (verifisering via nettleser):**

| Regel | Ekstern port | Videresender til |
|---|---|---|
| `dnat-http-spoke1` | `:8081` | `10.0.1.10:80` |
| `dnat-http-spoke2` | `:8082` | `10.1.0.10:80` |
| `dnat-http-spoke3` | `:8083` | `10.2.0.10:80` |

**SSH-tilgang (administrasjon via firewall):**

| Regel | Ekstern port | Videresender til |
|---|---|---|
| `dnat-ssh-spoke1` | `:2221` | `10.0.1.10:22` |
| `dnat-ssh-spoke2` | `:2222` | `10.1.0.10:22` |
| `dnat-ssh-spoke3` | `:2223` | `10.2.0.10:22` |

---

## Testing og verifisering

### Test 1: Peering-status

Verifiser at alle peering-forbindelser viser status **Connected** i Azure Portal.

For hvert spoke-VNET: naviger til **Peerings** og bekreft at det kun finnes én peering-forbindelse — til hub. Det skal ikke finnes direkte peering mellom spokes. Dette er ikke-transitivitet i praksis og er en sentral sikkerhetsmekanisme i topologien.

### Test 2: HTTP-tilgang via DNAT

Åpne en nettleser og naviger til følgende adresser (erstatt med faktisk firewall public IP):

```
http://<firewall-public-ip>:8081   →  Skal vise nettside fra spoke 1
http://<firewall-public-ip>:8082   →  Skal vise nettside fra spoke 2
http://<firewall-public-ip>:8083   →  Skal vise nettside fra spoke 3
```

Hver side skal tydelig identifisere hvilken spoke den serveres fra. Dette bekrefter at firewallen mottar trafikken, utfører DNAT-oversettelse, og videresender til korrekt VM.

### Test 3: Effektive ruter

Verifiser at rutetabellene har effekt på trafikkveien. Naviger til én av VM-ene fra forrige oppgave i spoke 1:

1. Gå til VM → **Networking** → NIC → **Effective routes**
2. Bekreft at ruter for `10.1.0.0/16` og `10.2.0.0/16` viser **Next hop type: Virtual appliance** med firewall private IP som adresse

---

## Leveranse

Du skal vise frem følgende til læringsassistenten:

**1. Topologioversikt**
Vis Peerings-bladet på `<prefix>-vnet-hub` med alle seks peering-forbindelser i status Connected.

**2. Ikke-transitivitet**
Vis Peerings-bladet på ett av spoke-nettverkene og pek på at det kun finnes én forbindelse — til hub.

**3. DNAT-verifisering**
Åpne nettleseren og demonstrer at alle tre HTTP-adresser (`:8081`, `:8082`, `:8083`) returnerer korrekt nettside fra riktig spoke.

**4. Effektive ruter**
Vis effective routes på en NIC i spoke 1 og bekreft at trafikk til de andre spokene rutes via firewall.

---

## ⚠️ Kostnadskontroll — viktig

Azure Firewall Basic koster ca. 0,25 USD per time. Med ti studenter som kjører firewall parallelt over én arbeidsdag tilsvarer det betydelige beløp på den delte tenanten.

**Gjør følgende umiddelbart etter presentasjon:**

1. Slett `<prefix>-fw-hub` — dette stopper billing umiddelbart
2. Slett eller stopp VM-ene i `<prefix>-rg-infraitsec-compute`

Du skal **ikke** slette `<prefix>-vnet-infraitsec` eller tilhørende NSGer og subnets — disse brukes i kommende øvelser.

**Ikke la Azure Firewall stå aktiv unødvendig lenge.** Konfigurer, verifiser, presenter og slett samme dag.

---

## Tips

**Deploy i riktig rekkefølge:**
Opprett alle nettverk, peerings og støtteressurser før du deployer firewallen. Firewall-billing starter ved opprettelse — ikke ved faktisk bruk.

**Bruk PowerShell-scriptet:**
Du har tilgang til `Deploy-HubSpokeVMs.ps1` som automatiserer deployment av VM-er og DNAT-konfigurasjonen. Tilpass variablene øverst i scriptet til ditt prefix og dine subnet-navn. Les gjennom scriptet og forstå hva det gjør før du kjører det.

**Vent på cloud-init:**
Etter at VM-ene er deployet tar det 2–3 minutter før nginx er installert og klar. Forsøker du å åpne nettsiden for tidlig, vil nettleseren ikke få svar. Vent litt og prøv igjen.

**Notatfeltet for firewall private IP:**
Firewall private IP tildeles av Azure og trenger du som next hop i rutetabellene. Noter denne adressen fra firewall Overview-siden før du starter konfigurasjon av rutetabellene.

---

## Ressurser

- Lab-walkthrough: [Hub-Spoke Topologi med Azure Firewall](11-01-HubSpokeNetwork.md)
- Lab-walkthrough: [Deploy-HubSpokeVMs — Hva gjør scriptet?](11-03-HubSpokeVMs-Forklaring.md)
- [Azure Hub-Spoke Network Topology](https://learn.microsoft.com/en-us/azure/architecture/networking/architecture/hub-spoke)
- [Azure Firewall DNAT](https://learn.microsoft.com/en-us/azure/firewall/tutorial-firewall-dnat)
- [User Defined Routes](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview)