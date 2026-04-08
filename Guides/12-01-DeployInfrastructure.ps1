# =============================================================================
# Deploy-InfraITsec-HubSpoke.ps1
# Baseline hub-spoke nettverksinfrastruktur for DCST1005 - InfraIT.sec
# =============================================================================
# Dette scriptet setter opp følgende ressurser i Microsoft Azure:
#   - To Resource Groups (network og compute)
#   - Hub VNET med GatewaySubnet og ManagementSubnet
#   - Spoke VNET med AKSSubnet
#   - NSG på ManagementSubnet
#   - VNET Peering (hub <-> spoke) uten gateway transit (aktiveres i neste lab)
#
# Scriptet er idempotent: det kan kjøres flere ganger uten feil.
# Ressurser som allerede eksisterer hoppes over med en gul melding.
#
# Kjøres fra VS Code med PowerShell-extension mot din Azure-tenant.
# Autentisering skjer via nettleser (Connect-AzAccount).
# =============================================================================

# -----------------------------------------------------------------------------
# STEG 1 — Konfigurer ditt prefiks og tenant-informasjon
# -----------------------------------------------------------------------------
# Erstatt verdiene under med ditt eget prefiks (f.eks. "on03") og
# Tenant ID fra Azure Portal (Entra ID -> Overview -> Tenant ID)

$prefix   = "tim84"               # <-- ENDRE TIL DITT EGET PREFIKS (f.eks. "on03")
$tenantId = "ec25d615-a67b-411a-9073-de7880b3b8a3"  # <-- ENDRE TIL DIN TENANT ID
$location = "norwayeast"

# -----------------------------------------------------------------------------
# STEG 2 — Autentiser mot Azure
# -----------------------------------------------------------------------------
# Autentisering åpner en nettleserside der du logger inn med din
# @stud.ntnu.no-konto. Bruk -UseDeviceAuthentication om nettleservinduet
# ikke åpner seg automatisk.

Write-Host "`n[1/8] Autentiserer mot Azure..." -ForegroundColor Cyan

Connect-AzAccount -Tenant $tenantId

Write-Host "Autentisering vellykket." -ForegroundColor Green

# -----------------------------------------------------------------------------
# STEG 3 — Definer navnekonvensjon og adresseplan
# -----------------------------------------------------------------------------

# Resource Group navn
$rgNetwork = "$prefix-rg-infraitsec-network"
$rgCompute = "$prefix-rg-infraitsec-compute"

# VNET navn
$hubVnetName   = "$prefix-vnet-hub"
$spokeVnetName = "$prefix-vnet-spoke"

# Subnett navn
$gatewaySubnetName      = "GatewaySubnet"        # Eksakt navn er et Azure-krav
$managementSubnetName   = "$prefix-snet-management"
$aksSubnetName          = "$prefix-snet-aks"

# NSG navn
$managementNsgName = "$prefix-nsg-management"

# Peering navn
$peeringHubToSpoke = "$prefix-peer-hub-to-spoke"
$peeringSpokeToHub = "$prefix-peer-spoke-to-hub"

# Adresseplan
$hubVnetPrefix          = "10.0.0.0/16"
$gatewaySubnetPrefix    = "10.0.0.0/27"   # /27 er anbefalt minimum for VPN Gateway
$managementSubnetPrefix = "10.0.1.0/24"

$spokeVnetPrefix        = "10.1.0.0/16"
$aksSubnetPrefix        = "10.1.0.0/24"   # kubenet-nettverksplugin, /24 er tilstrekkelig

# Tags som settes på alle ressurser
$tags = @{
    Environment = "Lab"
    Owner       = $prefix
}

# -----------------------------------------------------------------------------
# Hjelpefunksjon for konsistent statusmelding
# -----------------------------------------------------------------------------

function Write-Status {
    param(
        [string]$Message,
        [ValidateSet("Created", "Exists", "Updated", "Error")]
        [string]$Status
    )
    switch ($Status) {
        "Created" { Write-Host "  [NY]          $Message" -ForegroundColor Green }
        "Exists"  { Write-Host "  [EKSISTERER]  $Message" -ForegroundColor Yellow }
        "Updated" { Write-Host "  [OPPDATERT]   $Message" -ForegroundColor Cyan }
        "Error"   { Write-Host "  [FEIL]        $Message" -ForegroundColor Red }
    }
}

function Write-PeeringStatus {
    param([string]$Name, [string]$State)
    if ($State -eq "Connected") {
        Write-Host "   $Name : $State" -ForegroundColor Green
    } else {
        Write-Host "   $Name : $State" -ForegroundColor Red
    }
}

# -----------------------------------------------------------------------------
# STEG 4 — Opprett Resource Groups
# -----------------------------------------------------------------------------

Write-Host "`n[2/8] Oppretter Resource Groups..." -ForegroundColor Cyan

foreach ($rgName in @($rgNetwork, $rgCompute)) {
    $existingRg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
    if ($existingRg) {
        Write-Status -Message $rgName -Status "Exists"
    } else {
        New-AzResourceGroup -Name $rgName -Location $location -Tag $tags -Force | Out-Null
        Write-Status -Message $rgName -Status "Created"
    }
}

# -----------------------------------------------------------------------------
# STEG 5 — Opprett NSG for ManagementSubnet
# -----------------------------------------------------------------------------
# GatewaySubnet skal IKKE ha NSG - dette er et Azure-krav.
# AKS-subnettet administrerer sine egne nettverksregler internt og
# får derfor heller ikke en custom NSG her.

Write-Host "`n[3/8] Oppretter NSG for ManagementSubnet..." -ForegroundColor Cyan

$managementNsg = Get-AzNetworkSecurityGroup `
    -Name $managementNsgName `
    -ResourceGroupName $rgNetwork `
    -ErrorAction SilentlyContinue

if ($managementNsg) {
    Write-Status -Message $managementNsgName -Status "Exists"
} else {
    $managementNsg = New-AzNetworkSecurityGroup `
        -Name $managementNsgName `
        -ResourceGroupName $rgNetwork `
        -Location $location `
        -Tag $tags
    Write-Status -Message $managementNsgName -Status "Created"
}

# -----------------------------------------------------------------------------
# STEG 6 — Opprett Hub VNET med subnett
# -----------------------------------------------------------------------------
# Hub-en inneholder to subnett:
#   - GatewaySubnet: reservert for VPN Gateway (opprettes i neste lab)
#   - ManagementSubnet: for administrasjonsressurser, med NSG

Write-Host "`n[4/8] Oppretter Hub VNET med subnett..." -ForegroundColor Cyan

$hubVnet = Get-AzVirtualNetwork `
    -Name $hubVnetName `
    -ResourceGroupName $rgNetwork `
    -ErrorAction SilentlyContinue

if ($hubVnet) {
    Write-Status -Message "$hubVnetName ($hubVnetPrefix)" -Status "Exists"

    # Sjekk at begge subnettene eksisterer selv om VNET-et finnes
    $existingGwSubnet   = $hubVnet.Subnets | Where-Object { $_.Name -eq $gatewaySubnetName }
    $existingMgmtSubnet = $hubVnet.Subnets | Where-Object { $_.Name -eq $managementSubnetName }

    if (-not $existingGwSubnet) {
        Add-AzVirtualNetworkSubnetConfig `
            -Name $gatewaySubnetName `
            -VirtualNetwork $hubVnet `
            -AddressPrefix $gatewaySubnetPrefix | Out-Null
        $hubVnet | Set-AzVirtualNetwork | Out-Null
        $hubVnet = Get-AzVirtualNetwork -Name $hubVnetName -ResourceGroupName $rgNetwork
        Write-Status -Message "Subnett $gatewaySubnetName lagt til i eksisterende VNET" -Status "Created"
    } else {
        Write-Status -Message "Subnett $gatewaySubnetName ($gatewaySubnetPrefix)" -Status "Exists"
    }

    if (-not $existingMgmtSubnet) {
        Add-AzVirtualNetworkSubnetConfig `
            -Name $managementSubnetName `
            -VirtualNetwork $hubVnet `
            -AddressPrefix $managementSubnetPrefix `
            -NetworkSecurityGroup $managementNsg | Out-Null
        $hubVnet | Set-AzVirtualNetwork | Out-Null
        $hubVnet = Get-AzVirtualNetwork -Name $hubVnetName -ResourceGroupName $rgNetwork
        Write-Status -Message "Subnett $managementSubnetName lagt til i eksisterende VNET" -Status "Created"
    } else {
        Write-Status -Message "Subnett $managementSubnetName ($managementSubnetPrefix)" -Status "Exists"
    }
} else {
    $gatewaySubnetConfig = New-AzVirtualNetworkSubnetConfig `
        -Name $gatewaySubnetName `
        -AddressPrefix $gatewaySubnetPrefix
    # Merk: Ingen NSG på GatewaySubnet - Azure tillater ikke dette

    $managementSubnetConfig = New-AzVirtualNetworkSubnetConfig `
        -Name $managementSubnetName `
        -AddressPrefix $managementSubnetPrefix `
        -NetworkSecurityGroup $managementNsg

    $hubVnet = New-AzVirtualNetwork `
        -Name $hubVnetName `
        -ResourceGroupName $rgNetwork `
        -Location $location `
        -AddressPrefix $hubVnetPrefix `
        -Subnet $gatewaySubnetConfig, $managementSubnetConfig `
        -Tag $tags

    Write-Status -Message "$hubVnetName ($hubVnetPrefix)" -Status "Created"
    Write-Host "    Subnett: $gatewaySubnetName ($gatewaySubnetPrefix) - ingen NSG (Azure-krav)" -ForegroundColor Gray
    Write-Host "    Subnett: $managementSubnetName ($managementSubnetPrefix) - med NSG" -ForegroundColor Gray
}

# -----------------------------------------------------------------------------
# STEG 7 — Opprett Spoke VNET med AKS-subnett
# -----------------------------------------------------------------------------
# Spoke-en inneholder ett subnett dimensjonert for AKS med kubenet-plugin.
# Ingen custom NSG på AKS-subnettet - AKS administrerer sine egne
# nettverksregler internt, og en custom NSG kan forstyrre cluster-kommunikasjon.

Write-Host "`n[5/8] Oppretter Spoke VNET med AKS-subnett..." -ForegroundColor Cyan

$spokeVnet = Get-AzVirtualNetwork `
    -Name $spokeVnetName `
    -ResourceGroupName $rgNetwork `
    -ErrorAction SilentlyContinue

if ($spokeVnet) {
    Write-Status -Message "$spokeVnetName ($spokeVnetPrefix)" -Status "Exists"

    $existingAksSubnet = $spokeVnet.Subnets | Where-Object { $_.Name -eq $aksSubnetName }
    if (-not $existingAksSubnet) {
        Add-AzVirtualNetworkSubnetConfig `
            -Name $aksSubnetName `
            -VirtualNetwork $spokeVnet `
            -AddressPrefix $aksSubnetPrefix | Out-Null
        $spokeVnet | Set-AzVirtualNetwork | Out-Null
        $spokeVnet = Get-AzVirtualNetwork -Name $spokeVnetName -ResourceGroupName $rgNetwork
        Write-Status -Message "Subnett $aksSubnetName lagt til i eksisterende VNET" -Status "Created"
    } else {
        Write-Status -Message "Subnett $aksSubnetName ($aksSubnetPrefix)" -Status "Exists"
    }
} else {
    $aksSubnetConfig = New-AzVirtualNetworkSubnetConfig `
        -Name $aksSubnetName `
        -AddressPrefix $aksSubnetPrefix
    # Merk: Ingen NSG på AKS-subnettet - se kommentar over

    $spokeVnet = New-AzVirtualNetwork `
        -Name $spokeVnetName `
        -ResourceGroupName $rgNetwork `
        -Location $location `
        -AddressPrefix $spokeVnetPrefix `
        -Subnet $aksSubnetConfig `
        -Tag $tags

    Write-Status -Message "$spokeVnetName ($spokeVnetPrefix)" -Status "Created"
    Write-Host "    Subnett: $aksSubnetName ($aksSubnetPrefix) - ingen NSG (AKS-krav)" -ForegroundColor Gray
}

# -----------------------------------------------------------------------------
# STEG 8 — Konfigurer VNET Peering
# -----------------------------------------------------------------------------
# Peering opprettes i begge retninger (Azure-krav).
#
# AllowGatewayTransit på hub-siden (switch-parameter, inkluderes = true):
#   Tillater at hub-en deler sin fremtidige VPN Gateway med spoke-ene.
#
# UseRemoteGateways utelates på spoke-siden (= false, midlertidig):
#   Settes til false nå fordi VPN Gateway ikke er deployet ennå.
#   VIKTIG: Dette må aktiveres i neste lab etter at VPN Gateway er
#   ferdig provisjonert, ellers vil VPN-klienter ikke nå ressurser i spoke-en.
#
# En peering med status "Initiated" betyr at kun én side er opprettet.
# Scriptet sletter og gjenskaper i så fall begge sider for å sikre "Connected".

Write-Host "`n[6/8] Konfigurerer VNET Peering (hub <-> spoke)..." -ForegroundColor Cyan

# Hent oppdaterte VNET-objekter med korrekte resource ID-er
$hubVnet   = Get-AzVirtualNetwork -Name $hubVnetName   -ResourceGroupName $rgNetwork
$spokeVnet = Get-AzVirtualNetwork -Name $spokeVnetName -ResourceGroupName $rgNetwork

$existingHubPeering   = Get-AzVirtualNetworkPeering `
    -VirtualNetworkName $hubVnetName `
    -ResourceGroupName $rgNetwork `
    -Name $peeringHubToSpoke `
    -ErrorAction SilentlyContinue

$existingSpokePeering = Get-AzVirtualNetworkPeering `
    -VirtualNetworkName $spokeVnetName `
    -ResourceGroupName $rgNetwork `
    -Name $peeringSpokeToHub `
    -ErrorAction SilentlyContinue

$hubState   = if ($existingHubPeering)   { $existingHubPeering.PeeringState }   else { $null }
$spokeState = if ($existingSpokePeering) { $existingSpokePeering.PeeringState } else { $null }

if ($hubState -eq "Connected" -and $spokeState -eq "Connected") {
    Write-Status -Message "$peeringHubToSpoke (Connected)" -Status "Exists"
    Write-Status -Message "$peeringSpokeToHub (Connected)" -Status "Exists"
} else {
    # Slett eventuelle halvferdige peeringer før ny oppretting
    if ($existingHubPeering) {
        Remove-AzVirtualNetworkPeering `
            -VirtualNetworkName $hubVnetName `
            -ResourceGroupName $rgNetwork `
            -Name $peeringHubToSpoke `
            -Force | Out-Null
        Write-Host "  Fjernet inkonsistent peering: $peeringHubToSpoke (status: $hubState)" -ForegroundColor Yellow
    }
    if ($existingSpokePeering) {
        Remove-AzVirtualNetworkPeering `
            -VirtualNetworkName $spokeVnetName `
            -ResourceGroupName $rgNetwork `
            -Name $peeringSpokeToHub `
            -Force | Out-Null
        Write-Host "  Fjernet inkonsistent peering: $peeringSpokeToHub (status: $spokeState)" -ForegroundColor Yellow
    }

    # Hub -> Spoke peering
    # -AllowGatewayTransit er et switch-parameter: inkluderes = true, utelates = false
    Add-AzVirtualNetworkPeering `
        -Name $peeringHubToSpoke `
        -VirtualNetwork $hubVnet `
        -RemoteVirtualNetworkId $spokeVnet.Id `
        -AllowGatewayTransit | Out-Null
    Write-Status -Message "$peeringHubToSpoke (AllowGatewayTransit = true)" -Status "Created"

    # Spoke -> Hub peering
    # -AllowGatewayTransit og -UseRemoteGateways utelates = begge false
    # UseRemoteGateways aktiveres i neste lab etter at VPN Gateway er deployet
    Add-AzVirtualNetworkPeering `
        -Name $peeringSpokeToHub `
        -VirtualNetwork $spokeVnet `
        -RemoteVirtualNetworkId $hubVnet.Id | Out-Null
    Write-Status -Message "$peeringSpokeToHub (UseRemoteGateways = false, oppdateres i neste lab)" -Status "Created"
}

# -----------------------------------------------------------------------------
# STEG 9 — Verifisering og oppsummering
# -----------------------------------------------------------------------------

Write-Host "`n[7/8] Verifiserer opprettede ressurser..." -ForegroundColor Cyan

$hubPeering   = Get-AzVirtualNetworkPeering `
    -VirtualNetworkName $hubVnetName `
    -ResourceGroupName $rgNetwork `
    -Name $peeringHubToSpoke `
    -ErrorAction SilentlyContinue

$spokePeering = Get-AzVirtualNetworkPeering `
    -VirtualNetworkName $spokeVnetName `
    -ResourceGroupName $rgNetwork `
    -Name $peeringSpokeToHub `
    -ErrorAction SilentlyContinue

$hubPeeringStatus   = if ($hubPeering)   { $hubPeering.PeeringState }   else { "Ikke funnet" }
$spokePeeringStatus = if ($spokePeering) { $spokePeering.PeeringState } else { "Ikke funnet" }

Write-Host "`n[8/8] Deployment fullført." -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " OPPSUMMERING - $prefix" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " Resource Groups:" -ForegroundColor White
Write-Host "   $rgNetwork" -ForegroundColor Gray
Write-Host "   $rgCompute" -ForegroundColor Gray
Write-Host " Hub VNET: $hubVnetName ($hubVnetPrefix)" -ForegroundColor White
Write-Host "   $gatewaySubnetName : $gatewaySubnetPrefix (ingen NSG - Azure-krav)" -ForegroundColor Gray
Write-Host "   $managementSubnetName : $managementSubnetPrefix (med NSG)" -ForegroundColor Gray
Write-Host " Spoke VNET: $spokeVnetName ($spokeVnetPrefix)" -ForegroundColor White
Write-Host "   $aksSubnetName : $aksSubnetPrefix (ingen NSG - AKS-krav)" -ForegroundColor Gray
Write-Host " Peering status:" -ForegroundColor White
Write-PeeringStatus -Name $peeringHubToSpoke -State $hubPeeringStatus
Write-PeeringStatus -Name $peeringSpokeToHub -State $spokePeeringStatus
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " NESTE STEG: Kjør 'az aks create' i Azure Cloud Shell" -ForegroundColor Yellow
Write-Host " for å starte AKS-provisjonering parallelt med VPN Gateway." -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan