# Opprette virtuelle maskiner i OpenStack med Heat Templates

## Innledning

I denne øvelsen skal du lære å opprette virtuelle maskiner i OpenStack ved hjelp av Heat templates. Heat er OpenStacks orkestreringstjeneste som lar deg definere infrastruktur som kode, på samme måte som Terraform gjør for Azure.

## Hva er en Heat Template?

En Heat template er en YAML- eller JSON-fil som beskriver ressursene du ønsker å opprette i OpenStack. Når du oppretter en **stack** fra en template, vil Heat automatisk opprette alle ressursene som er definert i templaten.

## Steg 1: Opprett Key Pair

⚠️ **Viktig**: Du må opprette et key pair FØR du oppretter stacken. Dette er nødvendig for å kunne hente ut passordet fra Windows-instansene senere.

### Opprett Key Pair via Dashboard (Horizon)

1. Logg inn på OpenStack Dashboard
2. Naviger til **Compute → Key Pairs** i venstremenyen
3. Klikk på **Create Key Pair**
   1. ![alt text](CreateKeyPair.png)
4. Fyll ut:
   - **Key Pair Name**: Gi nøkkelen et beskrivende navn (f.eks. `ditt-navn-key`)
   - **Key Type**: Velg **SSH Key** (standard)
5. Klikk **Create Key Pair**
6. **Last ned den private nøkkelen** (.pem-fil) som automatisk lastes ned
   - ⚠️ **VIKTIG**: Denne filen lastes kun ned én gang! Lagre den på et trygt sted
   - Du trenger denne filen senere for å hente passordet til Windows-VM-en


## Steg 3: Opprett en Stack

1. Naviger til **Orchestration → Stacks** i venstremenyen
2. Klikk på **Launch Stack**
3. Velg **Template Source**: (her kan alle alternativer velges, men det enkleste er å vise direkte til URL)
   - **File**: Last opp din Heat template fra lokal maskin
   - **Direct Input**: Lim inn template-innholdet direkte
   - **URL**: Angi URL til templaten
     - https://raw.githubusercontent.com/torivarm/dcst1005/refs/heads/main/heat-template-v26-dcst1005.yaml
4. Klikk **Next**
   1. ![alt text](CreateStacks.png)
5. Fyll ut stackdetaljer:
   - **Stack Name**: Gi stacken et beskrivende navn (f.eks. `dcst1005-lab`)
   - **Key Name**: Skriv inn navnet på key pair-et du opprettet
   - **Password**: Oppgi passordet ditt for din NTNU-konto.
6. Klikk **Launch** for å opprette stacken
   1. ![alt text](LaunchStack.png)

## Steg 4: Stack-opprettelsen

- Stacken vil nå begynne opprettelsen av alle ressurser
- Status vil vise **CREATE_IN_PROGRESS**
- Vent til statusen endres til **CREATE_COMPLETE**
- MERK!! Dette kan ta flere minutter før VM-ene er klar til å hente ut passord. Ca. 10 minutter etter Create Complete

💡 **Tips**: Klikk på stack-navnet for å se detaljert informasjon og eventuelle feilmeldinger.

## Steg 5: Finn din virtuelle maskin

1. Naviger til **Compute → Instances**
2. Her vil du se alle VM-ene som ble opprettet av stacken
   1. ![alt text](Instances.png)

## Steg 6: Hent Instance Password

For å koble til Windows-VM-er med Remote Desktop trenger du passordet. Dette passordet er kryptert og må dekrypteres med den private nøkkelen du lastet ned i steg 1.

### Via Dashboard (Horizon)

Skriv ned, for din egen del, informasjon for hver maskin: maskinnavnet, IP-adresse, brukernavn og passord (ikke god praksis å skrive brukernavn og passord i klartekst, men vi trenger den informasjonen nå). Vi starter med passord først:
```
DC1, 10.212.170.139, Admin, dfd2!Dsdfksd_da23rjf
SRV1, 10.212.170.134, Admin, 3124pgsdlsdjlljfm
CL1, 10.212.170.123, Admin, rfdfks232!mlfsjdfl_
MGR, 10.212.170.114, Admin, R34fdfs234jnc__
```

1. Gå til **Compute → Instances**
2. Finn din VM i listen
3. Vent til VM-en har status **Active** og har kjørt i minst 10 minutter (Windows trenger tid til å initialisere)
4. Klikk på dropdown-menyen (▼) til høyre for VM-en
5. Velg **Retrieve Password**
6. Du vil se et dialogvindu hvor du kan:
   - **Choose File**: Last opp din private key (.pem-fil fra steg 1)
7. Klikk **Decrypt Password**
8. Kopier passordet som vises
   1. ![alt text](DecryptPassword.png)

## Steg 7: Finn offentlig IP-adresse (Floating IP)

1. I **Compute → Instances**, se i kolonnen **IP Address**
2. Din VM vil ha både:
   - En **privat IP** (f.eks. 192.168.x.x)
   - En **offentlig IP** (Floating IP, f.eks. 10.x.x.x)
![alt text](IPAddresses.png)

## Steg 8: Koble til med Remote Desktop

### Windows

1. Åpne **Remote Desktop Connection** (mstsc.exe) 
   - Søk etter "Remote Desktop" i Start-menyen (På norsk Windows: Eksternt skrivebord)
   - ![alt text](rdp-win11.png)
2. Trykk på "Show Options":
   - ![alt text](highlightShowOptions.png)
3. Skriv inn informasjonen for en av maskinene, og velg deretter å lagre filen. Gi den et navn som indikerer hvilken maskin du ønsker koble deg til. Eksempelvis CL1, for Client 1, eller DC1 for Domene Controller 1 etc.
   1. ![alt text](saveRDPfile.png)
   2. ![alt text](saveRDP.png)
4. Trykk deretter på Connect. Huk av for ```Don't ask me again for connections for this computer```. Trykk connect igjen, og når du blir spurt om passord, lim inn passordet hentet for maskinen fra steg 6
5. Godta sertifikatadvarselen, og velg å alltid godta (hvis du får en)
   1. ![alt text](UserPassword.png)
   2. ![alt text](cert.png)

### macOS

1. Last ned **Windows App** fra App Store
2. Klikk **+ tegnet til høyre**
3. Velg Add PC:
   1. ![alt text](MacAddPC.png)
4. Fyll detter inn:
   1. ![alt text](AddPCMac.png)
5. Klikk **Add** og deretter dobbeltklikk på PC-en for å koble til

## Feilsøking

### Kan ikke hente passord
- ✅ Sjekk at du bruker riktig private key (.pem-fil fra steg 1)
- ✅ Kontroller at VM-en har fullført oppstarten (vent 5-10 minutter)
- ✅ Sjekk at key pair-navnet i Heat templaten matcher det du opprettet
- ✅ Hvis du får tom respons, vent lenger - Windows trenger tid til å initialisere

### Får ikke tilkobling med RDP
- ✅ Kontroller at du bruker den **offentlige** IP-adressen, ikke den private
- ✅ Vent til VM-en er helt ferdig med oppstarten (10-15 minutter for Windows)
- ✅ Sjekk at du bruker riktig brukernavn: `Admin`

### Stack-opprettelse feiler
- ✅ Kontroller at templaten er gyldig YAML/JSON
- ✅ Sjekk at key pair-navnet eksisterer i OpenStack
- ✅ Les feilmeldingene i Stack-detaljene

### Mistet private key
- ❌ Hvis du har mistet .pem-filen, kan du IKKE hente ut passordet
- 💡 Løsning: Slett stacken og opprett en ny med et nytt key pair

⚠️ **Husk**: Den private nøkkelen (.pem-fil) er lagret lokalt på din maskin. OpenStack har kun den offentlige nøkkelen.

## Oppsummering

- ✅ Opprette et key pair i OpenStack
- ✅ Laste ned og lagre private key
- ✅ Opprette en stack fra en Heat template
- ✅ Hente instance password for Windows-VM med private key
- ✅ Finne offentlig IP-adresse
- ✅ Koble til VM via Remote Desktop
