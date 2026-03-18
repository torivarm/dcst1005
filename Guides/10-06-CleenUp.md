# Azure Resource Cleanup og Kostnadsoptimalisering

## Oversikt

I denne avsluttende øvelsen skal du rydde opp i Azure-ressursene du har opprettet gjennom lab-serien. Riktig cleanup er kritisk for å unngå unødvendige kostnader og demonstrere god cloud resource management.

**Hvorfor er Cleanup Viktig?**

Cloud-kostnader er basert på forbruk - ressurser du ikke bruker koster fortsatt penger. En glemt VM som kjører 24/7 kan koste €30-50 per måned. Over tid summerer dette seg til betydelige beløp. Profesjonell cloud-administrasjon handler like mye om å rydde opp som å deploye.

**Hva Skal Slettes:**

I denne øvelsen fokuserer vi primært på:
- Virtual Machines (compute ressurser)
- Tilhørende ressurser (disks, NICs, public IPs)


**Læringsmål:**
- Forstå Azure resource dependencies
- Slette ressurser trygt og effektivt
- Verifisere at kostnader stopper
- Identifisere og fjerne "zombie resources"
- Implementere best practices for resource lifecycle management

**Estimert tid:** 20-30 minutter

---

## Forutsetninger

- [ ] Fullført tidligere lab-øvelser
- [ ] VMs deployed i `<prefix>-rg-infraitsec-compute` (eller lignende)
- [ ] Networking i `<prefix>-rg-infraitsec-network` (eller lignende)
- [ ] Tilgang til Cost Management

---

## Del 0: Shortcut
**Velg å slett hele resource group som inneholder alle VM-ene:
`<prefix>-rg-infraitsec-compute` (MERK, det er mye nyttig info i stegene under)**

## Del 1: Pre-Cleanup Assessment

### Steg 1.1: Inventar av Ressurser

**Før du sletter noe - dokumenter hva du har:**

1. Azure Portal → **"Resource groups"**

2. Klikk på hver resource group og noter:

**Compute RG (`<prefix>-rg-infraitsec-compute`):**
```
Virtual Machines: (eller de navnene en har valgt)
- <prefix>-vm-frontend (Ubuntu)
- <prefix>-vm-backend (Ubuntu)
- <prefix>-vm-data (Ubuntu)

Network Interfaces: (auto-created med VMs)
- <prefix>-vm-web01-nic
- <prefix>-vm-linux01-nic
- osv.

Disks:
- <prefix>-vm-web01_OsDisk
- <prefix>-vm-linux01_OsDisk
- osv.

Public IP Addresses:
- <prefix>-vm-web01-pip
- <prefix>-vm-linux01-pip
- osv.
```

**Network RG (`<prefix>-rg-infraitsec-network`):**
```
Virtual Network:
- <prefix>-vnet-infraitsec

Subnets: (del av VNet)
- subnet-frontend
- subnet-backend
- subnet-data

Network Security Groups:
- <prefix>-nsg-frontend
- <prefix>-nsg-backend
- <prefix>-nsg-data
```


### Steg 1.3: Identifiser Hva som skal slettes 

**MÅ slettes (koster mye):**
- ✅ Virtual Machines
- ✅ Disks (if orphaned/unused)
- ✅ Static Public IPs (hvis ikke i bruk)

**Kan beholdes (billig eller gratis):**
- ⚠️ VNet, subnets (gratis)
- ⚠️ NSGs (gratis)

**Anbefaling for lab:**
- Slett compute RG umiddelbart (stopper største kostnader)
- Behold network/arc RG hvis du skal fortsette med andre øvelser
- Slett alt til slutt når hele kurset er ferdig

---

## Del 2: Stop Running VMs (Deallocate)

**Før permanent sletting - stopp VMs for å umiddelbart redusere kostnader.**

### Steg 2.1: Stop Alle VMs

1. Portal → **"Virtual machines"**

2. **Filter:** Resource group = `<prefix>-rg-infraitsec-compute`

3. **Velg alle VMs:**
   - ☑ `<prefix>-vm-frontend`
   - ☑ `<prefix>-vm-backend`

4. Øverst → **"Stop"**

5. Bekreft: **"Yes"**

**Azure stopper VMs:**
- Status: Running → Stopping → Stopped (deallocated)
- Tid: ~2-3 minutter per VM

### Steg 2.2: Verifiser Deallocated Status

**VIKTIG:** Status MÅ vise "Stopped (deallocated)", IKKE bare "Stopped"!

**Stopped (deallocated):** ✅ Compute charges stopper  
**Stopped:** ❌ Compute charges fortsetter!

**Sjekk status:**

1. Refresh VM-listen

2. Alle VMs skal vise: **"Stopped (deallocated)"**

**Hvis "Stopped" (uten deallocated):**
- Høyreklikk VM → **"Stop"** (igjen)
- Eller bruk PowerShell:
```powershell
  Stop-AzVM -ResourceGroupName "<prefix>-rg-infraitsec-compute" -Name "<vm-name>" -Force
```

### Steg 2.3: Umiddelbar Kostnadsbesparelse

**Etter deallocate:**

**Før (Running):**
```
5 VMs × €1.20/dag (B1s/B2s blandet) = €6/dag
```

**Etter (Deallocated):**
```
Compute: €0/dag
Storage (disks): ~€0.20/dag
Public IPs: ~€0.10/dag
Total: ~€0.30/dag (95% reduksjon!)
```

**Men ressurser eksisterer fortsatt** - vi må slette dem for permanent cleanup.

---

## Del 3: Delete Compute Resource Group

**Dette er den primære cleanup-operasjonen.**

### Steg 3.1: Forstå Hva Som Slettes

**Når du sletter en Resource Group, slettes ALT inni:**
```
<prefix>-rg-infraitsec-compute
├── Virtual Machines (3 stk)
├── Network Interfaces (3 stk - auto-created)
├── Disks (3 OS disks + eventuelle data disks)
├── Public IP Addresses (3 stk)
└── Eventuelt: Boot diagnostics storage accounts
```

**Hva slettes IKKE:**
- VNet, subnets, NSGs (i network RG)
- Arc machines
- Andre resource groups

**Dette er trygt fordi:**
- VMs er i separat RG fra networking
- Ingen dependencies utenfor denne RG
- Network infrastructure gjenbrukes

### Steg 3.2: Slett Compute Resource Group

**⚠️ VIKTIG: Dette er permanent - kan ikke angres!**

1. Portal → **"Resource groups"**

2. Klikk på `<prefix>-rg-infraitsec-compute`

3. Øverst → **"Delete resource group"**

4. **Confirmation:**
   - Azure viser hva som slettes (liste over ressurser)
   - **CRITICAL:** Du må skrive nøyaktig navn på resource group

5. **Type resource group name:**
```
   <prefix>-rg-infraitsec-compute
```
   - CASE-SENSITIVE!
   - Ingen mellomrom før/etter
   - Eksempel: `eg06-rg-infraitsec-compute`

6. ☑ **"Apply force delete for selected Virtual machines and Virtual machine scale sets"**
   - Dette tvinger rask sletting uten graceful shutdown
   - Anbefales for lab cleanup

7. Klikk **"Delete"**

**Azure starter deletion process:**
```
Activity Log (live updates):
14:23:15 - Delete Virtual Machine 'vm-linux01' - Running
14:23:45 - Delete Virtual Machine 'vm-web01' - Succeeded
14:24:10 - Delete Network Interface 'vm-web01-nic' - Running
14:24:15 - Delete Public IP 'vm-web01-pip' - Running
14:24:30 - Delete Disk 'vm-web01_OsDisk' - Running
...
14:27:45 - Delete Resource Group - Succeeded
```

**Total slettingstid:** 5-10 minutter

---

## Del 4: Verifiser Sletting

### Steg 4.1: Sjekk at Resource Group er Borte

1. Portal → **"Resource groups"**

2. **Liste skal IKKE inneholde:** `<prefix>-rg-infraitsec-compute`

**Hvis fortsatt synlig:**
- Vent 1-2 minutter (caching)
- Refresh siden
- Status skal vise "Deleting" eller være helt borte

### Steg 4.2: Sjekk for Orphaned Resources

**Selv med "delete with VM" enabled, kan noen ressurser bli liggende.**

**Sjekk disks:**

1. Portal → Søk **"Disks"**

2. **Filter:** Resource group = Any

3. **Søk etter:** Ditt prefix i navn

**Skal IKKE se:**
- `<prefix>-vm-web01_OsDisk`
- `<prefix>-vm-linux01_OsDisk`
- Osv.

**Hvis orphaned disks finnes:**
- Klikk på disk → **"Delete"**
- Bekreft

**Sjekk NICs:**

1. Portal → Søk **"Network interfaces"**

2. Filtrer og søk på prefix

**Skal IKKE se NICs** fra slettede VMs.

**Sjekk Public IPs:**

1. Portal → Søk **"Public IP addresses"**

2. **Status skal være:**
   - IKKE listet (hvis slettet)
   - Eller: "Not associated" (hvis IP reserved, men ikke i bruk)

**Unassociated static IPs koster penger!** Slett dem:
- Velg IP → **"Delete"**

---

## Hva Nå?

**Hvis du skal fortsette med flere Azure-labs:**
- Behold network RG (`<prefix>-rg-infraitsec-network`)
- Behold Arc/monitoring RG (hvis relevant)
- Deploy nye compute resources etter behov


**Profesjonell cloud administration:**
- Regular cleanup audits (weekly/monthly)
- Cost alerting på alle subscriptions
- Clear tagging og naming conventions
- Resource lifecycle policies

**Gratulerer med fullført Azure Infrastructure lab-serie!** 🎉

Du har nå praktisk erfaring med:
- Azure networking (VNet, NSG, segmentation)
- Virtual machines (Windows & Linux)
- Hybrid monitoring (Arc + Log Analytics)
- Network diagnostics (Network Watcher)
- Cost management og resource cleanup

**Dette er verdifulle enterprise cloud skills!** 🚀

---

## Ressurser

- [Azure Cost Management Documentation](https://learn.microsoft.com/en-us/azure/cost-management-billing/)
- [Resource Group Best Practices](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/overview)
- [Azure Advisor Cost Recommendations](https://learn.microsoft.com/en-us/azure/advisor/advisor-cost-recommendations)
- [Resource Tagging Strategy](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-tagging)
- [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/)