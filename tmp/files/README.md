# InfraIT.sec - Automated Active Directory Lab Environment

Automatisert deployment av komplett Active Directory-miljø for InfraIT.sec via OpenStack Heat.

## Quick Start

```bash
# 1. Rediger parameters.yaml med dine verdier
cp parameters.yaml.example parameters.yaml
nano parameters.yaml

# 2. Deploy
openstack stack create -t infraitsec-automated.yaml \
  -e parameters.yaml \
  infraitsec-lab

# 3. Overvåk deployment (30-45 minutter)
openstack stack event list infraitsec-lab --follow

# 4. Hent tilkoblingsinformasjon
openstack stack output show infraitsec-lab --all
```

## Hva blir deployet?

| VM | Rolle | Flavor | Beskrivelse |
|----|-------|--------|-------------|
| **DC1** | Domain Controller | gx3.4c16r | Active Directory + DNS |
| **SRV1** | File Server | gx3.4c8r | DFS Namespace |
| **CL1** | Client | gx3.2c8r | Test workstation |
| **MGR** | Management | gx3.4c16r | Admin workstation + tools |

### Automatisk konfigurert:

✅ Active Directory-domene: `InfraIT.sec`  
✅ Komplett OU-struktur (Groups, Users, Computers)  
✅ 11 sikkerhetssgrupper (Global + Domain Local)  
✅ 15 domenebrukere med realistiske roller  
✅ Din personlige admin-konto: `adm_<brukernavn>`  
✅ Alle maskiner domain-joined  
✅ MGR med Chocolatey, PowerShell 7, VS Code, Git, RSAT  

## Filer

- `infraitsec-automated.yaml` - Heat template
- `parameters.yaml.example` - Eksempel på parameter-fil
- `BRUKERVEILEDNING.md` - Detaljert dokumentasjon

## Ressurskrav

- 4 instanser
- 28 vCPUs totalt
- 40 GB RAM totalt
- 4 floating IPs

## Sikkerhet

**VIKTIG:** Standard-passord er IKKE sikre for produksjon!

Endre passord i `parameters.yaml` før deployment.

## Første pålogging

**Admin-konto:**
```
Brukernavn: adm_<ditt_brukernavn>@InfraIT.sec
Passord: <domain_admin_password>
```

**Test-bruker:**
```
Brukernavn: ole.m.larsen@InfraIT.sec
Passord: <user_default_password>
(må endres ved første login)
```

## Support

Se `BRUKERVEILEDNING.md` for:
- Detaljert deployment-prosess
- Feilsøkings-guide
- Logging og debugging
- Videreutvikling

## License

Laget for undervisningsformål ved NTNU.
