###############################################################################
# Deploy-HubSpoke-Complete.ps1
#
# Fullstendig deployment av hub-spoke-topologi for InfraIT.sec:
#   - Hub VNET med AzureFirewallSubnet, AzureFirewallManagementSubnet og subnet-management
#   - NSG for management-subnet
#   - To public IP-adresser (firewall + management)
#   - Firewall Policy (Basic)
#   - Spoke 2 og Spoke 3 med NSGer
#   - VNET Peering (hub <-> alle spokes)
#   - Azure Firewall Basic
#   - Route tables med UDR for alle spokes
#   - Firewall Policy nettverksregler (allow-inter-spoke)
#   - Tre Linux VM-er med nginx (én per spoke)
#   - NSG-regler for HTTP og SSH fra AzureFirewallSubnet
#   - DNAT-regler for HTTP (:8081-8083) og SSH (:2221-2223)
#
# Forutsetninger:
#   - Innlogget med Connect-AzAccount mot riktig tenant og subscription
#   - Az PowerShell-modulen installert
#   - Networking resource group eksisterer (<prefix>-rg-infraitsec-networking)
#
# Spoke 1 (<prefix>-vnet-infraitsec) opprettes automatisk hvis den ikke finnes.
#
# Scriptet er idempotent — trygt å kjøre flere ganger.
# Eksisterende ressurser hoppes over, manglende opprettes.
#
# DNAT-portmapping etter deployment:
#   HTTP:  <fw-public-ip>:8081  ->  Spoke 1 VM :80
#   HTTP:  <fw-public-ip>:8082  ->  Spoke 2 VM :80
#   HTTP:  <fw-public-ip>:8083  ->  Spoke 3 VM :80
#   SSH:   <fw-public-ip>:2221  ->  Spoke 1 VM :22
#   SSH:   <fw-public-ip>:2222  ->  Spoke 2 VM :22
#   SSH:   <fw-public-ip>:2223  ->  Spoke 3 VM :22
###############################################################################


###############################################################################
# VARIABLER — fyll inn dine egne verdier her
###############################################################################

$prefix   = 'eg06'           # Ditt tildelte prefix
$location = 'norwayeast'     # Azure-region — bruk samme som forrige øvelse

# Resource groups
$networkingRG = "$prefix-rg-infraitsec-networking"
$computeRG    = "$prefix-rg-infraitsec-compute"

# VM-innstillinger
$adminUsername = 'azureuser'
$adminPassword = 'InfraIT2025!'   # Min 12 tegn, store+små+tall+spesialtegn
$vmSize        = 'Standard_B1s'

# ---------------------------------------------------------------------------
# Hub
# ---------------------------------------------------------------------------
$hubVnetName      = "$prefix-vnet-hub"
$hubAddressSpace  = '10.100.0.0/16'
$mgmtSubnetName   = 'subnet-management'
$mgmtSubnetPrefix = '10.100.0.0/24'
$fwSubnetPrefix   = '10.100.1.0/26'   # AzureFirewallSubnet — reservert navn
$fwMgmtSubnetPrefix = '10.100.2.0/26' # AzureFirewallManagementSubnet — påkrevd for Basic
$mgmtNsgName      = "$prefix-nsg-management"
$pipFwName        = "$prefix-pip-fw"
$pipFwMgmtName    = "$prefix-pip-fw-mgmt"
$fwPolicyName     = "$prefix-fwpolicy-hub"
$firewallName     = "$prefix-fw-hub"

# SSH tillates fra NTNU-nettverket. Legg til din hjemme-IP om nødvendig.
$allowedSshSource     = '129.241.0.0/16'

# ---------------------------------------------------------------------------
# Spoke 1 — n-tier VNET (opprettes hvis det ikke finnes fra forrige øvelse)
# ---------------------------------------------------------------------------
$spoke1VnetName     = "$prefix-vnet-infraitsec"
$spoke1AddressSpace = '10.0.0.0/16'
$spoke1SubnetName   = 'subnet-frontend'
$spoke1VmName       = "$prefix-vm-web-spoke1"
$spoke1VmIp         = '10.0.1.10'
$spoke1NsgName      = "$prefix-nsg-frontend"
$spoke1NsgBackend   = "$prefix-nsg-backend"
$spoke1NsgData      = "$prefix-nsg-data"

# ---------------------------------------------------------------------------
# Spoke 2
# ---------------------------------------------------------------------------
$spoke2VnetName     = "$prefix-vnet-spoke2"
$spoke2AddressSpace = '10.1.0.0/16'
$spoke2SubnetName   = 'subnet-workload'
$spoke2SubnetPrefix = '10.1.0.0/24'
$spoke2VmName       = "$prefix-vm-web-spoke2"
$spoke2VmIp         = '10.1.0.10'
$spoke2NsgName      = "$prefix-nsg-spoke2"

# ---------------------------------------------------------------------------
# Spoke 3
# ---------------------------------------------------------------------------
$spoke3VnetName     = "$prefix-vnet-spoke3"
$spoke3AddressSpace = '10.2.0.0/16'
$spoke3SubnetName   = 'subnet-workload'
$spoke3SubnetPrefix = '10.2.0.0/24'
$spoke3VmName       = "$prefix-vm-web-spoke3"
$spoke3VmIp         = '10.2.0.10'
$spoke3NsgName      = "$prefix-nsg-spoke3"

# ---------------------------------------------------------------------------
# Firewall subnet og DNAT-porter
# ---------------------------------------------------------------------------
$fwSubnetCidr  = '10.100.1.0/26'   # Kilde i NSG-regler (SNAT-adresse)
$httpPortSpoke1 = '8081'
$httpPortSpoke2 = '8082'
$httpPortSpoke3 = '8083'
$sshPortSpoke1  = '2221'
$sshPortSpoke2  = '2222'
$sshPortSpoke3  = '2223'

# Tags som settes på alle ressurser
$tags = @{ Owner = $prefix; Environment = 'Lab'; Course = 'InfraIT-Cyber' }


###############################################################################
# HJELPEFUNKSJONER
###############################################################################

function Write-Step { param([string]$Text)
    Write-Host "`n$Text" -ForegroundColor Cyan }

function Write-Ok { param([string]$Text)
    Write-Host "  [OK]  $Text" -ForegroundColor Green }

function Write-Skip { param([string]$Text)
    Write-Host "  [--]  $Text" -ForegroundColor Gray }

function Write-Warn { param([string]$Text)
    Write-Host "  [!!]  $Text" -ForegroundColor Yellow }

function Write-Doing { param([string]$Text)
    Write-Host "        $Text" -ForegroundColor Gray }

# Legg til en NSG-regel hvis den ikke allerede finnes
function Add-NsgRuleIfMissing {
    param(
        [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup]$Nsg,
        [string]$Name,
        [string]$Description,
        [string]$Protocol,
        [string]$SourcePrefix,
        [string]$DestPort,
        [string]$Access,
        [int]$Priority,
        [string]$Direction = 'Inbound'
    )
    $existing = $Nsg.SecurityRules | Where-Object { $_.Name -eq $Name }
    if ($existing) {
        Write-Skip "NSG-regel '$Name' finnes allerede."
        return $Nsg
    }
    $Nsg | Add-AzNetworkSecurityRuleConfig `
        -Name $Name -Description $Description `
        -Protocol $Protocol `
        -SourceAddressPrefix $SourcePrefix -SourcePortRange '*' `
        -DestinationAddressPrefix '*' -DestinationPortRange $DestPort `
        -Access $Access -Priority $Priority -Direction $Direction | Out-Null
    Write-Ok "NSG-regel '$Name' lagt til."
    return $Nsg
}


###############################################################################
# STEG 1 — Spoke 1 (n-tier VNET) — opprett hvis den ikke finnes
###############################################################################

Write-Step "[1/12] Spoke 1 — n-tier VNET..."

# Sjekk/opprett networking resource group
$netRg = Get-AzResourceGroup -Name $networkingRG -ErrorAction SilentlyContinue
if (-not $netRg) {
    Write-Doing "Oppretter resource group $networkingRG..."
    New-AzResourceGroup -Name $networkingRG -Location $location -Tag $tags | Out-Null
    Write-Ok "$networkingRG opprettet."
} else {
    Write-Skip "$networkingRG eksisterer allerede."
}

$spoke1Vnet = Get-AzVirtualNetwork -Name $spoke1VnetName `
              -ResourceGroupName $networkingRG -ErrorAction SilentlyContinue

if ($spoke1Vnet) {
    Write-Skip "$spoke1VnetName eksisterer allerede."
} else {
    Write-Doing "$spoke1VnetName ikke funnet — oppretter n-tier VNET med NSGer..."

    # NSG frontend
    $nsgFe = Get-AzNetworkSecurityGroup -Name $spoke1NsgName `
             -ResourceGroupName $networkingRG -ErrorAction SilentlyContinue
    if (-not $nsgFe) {
        $nsgFe = New-AzNetworkSecurityGroup -Name $spoke1NsgName `
                 -ResourceGroupName $networkingRG -Location $location -Tag $tags
        Write-Ok "  NSG $spoke1NsgName opprettet."
    }

    # NSG backend
    $nsgBe = Get-AzNetworkSecurityGroup -Name $spoke1NsgBackend `
             -ResourceGroupName $networkingRG -ErrorAction SilentlyContinue
    if (-not $nsgBe) {
        $nsgBe = New-AzNetworkSecurityGroup -Name $spoke1NsgBackend `
                 -ResourceGroupName $networkingRG -Location $location -Tag $tags
        Write-Ok "  NSG $spoke1NsgBackend opprettet."
    }

    # NSG data
    $nsgDa = Get-AzNetworkSecurityGroup -Name $spoke1NsgData `
             -ResourceGroupName $networkingRG -ErrorAction SilentlyContinue
    if (-not $nsgDa) {
        $nsgDa = New-AzNetworkSecurityGroup -Name $spoke1NsgData `
                 -ResourceGroupName $networkingRG -Location $location -Tag $tags
        Write-Ok "  NSG $spoke1NsgData opprettet."
    }

    # Subnets med NSGer
    $subFe = New-AzVirtualNetworkSubnetConfig -Name 'subnet-frontend' `
             -AddressPrefix '10.0.1.0/24' -NetworkSecurityGroupId $nsgFe.Id
    $subBe = New-AzVirtualNetworkSubnetConfig -Name 'subnet-backend' `
             -AddressPrefix '10.0.2.0/24' -NetworkSecurityGroupId $nsgBe.Id
    $subDa = New-AzVirtualNetworkSubnetConfig -Name 'subnet-data' `
             -AddressPrefix '10.0.3.0/24' -NetworkSecurityGroupId $nsgDa.Id

    $spoke1Vnet = New-AzVirtualNetwork `
        -Name $spoke1VnetName `
        -ResourceGroupName $networkingRG `
        -Location $location `
        -AddressPrefix $spoke1AddressSpace `
        -Subnet @($subFe, $subBe, $subDa) `
        -Tag $tags
    Write-Ok "$spoke1VnetName opprettet med subnet-frontend, subnet-backend og subnet-data."
}


###############################################################################
# STEG 2 — Hub VNET
###############################################################################

Write-Step "[2/12] Hub VNET og subnets..."

$hubVnet = Get-AzVirtualNetwork -Name $hubVnetName `
           -ResourceGroupName $networkingRG -ErrorAction SilentlyContinue

if ($hubVnet) {
    Write-Skip "$hubVnetName eksisterer allerede."
} else {
    Write-Doing "Oppretter $hubVnetName..."

    $subMgmt   = New-AzVirtualNetworkSubnetConfig -Name $mgmtSubnetName -AddressPrefix $mgmtSubnetPrefix
    $subFw     = New-AzVirtualNetworkSubnetConfig -Name 'AzureFirewallSubnet' -AddressPrefix $fwSubnetPrefix
    $subFwMgmt = New-AzVirtualNetworkSubnetConfig -Name 'AzureFirewallManagementSubnet' -AddressPrefix $fwMgmtSubnetPrefix

    $hubVnet = New-AzVirtualNetwork `
        -Name $hubVnetName `
        -ResourceGroupName $networkingRG `
        -Location $location `
        -AddressPrefix $hubAddressSpace `
        -Subnet @($subMgmt, $subFw, $subFwMgmt) `
        -Tag $tags
    Write-Ok "$hubVnetName opprettet med AzureFirewallSubnet, AzureFirewallManagementSubnet og $mgmtSubnetName."
}


###############################################################################
# STEG 3 — NSG for management-subnet
###############################################################################

Write-Step "[3/12] NSG for management-subnet..."

$mgmtNsg = Get-AzNetworkSecurityGroup -Name $mgmtNsgName `
           -ResourceGroupName $networkingRG -ErrorAction SilentlyContinue

if (-not $mgmtNsg) {
    Write-Doing "Oppretter $mgmtNsgName..."
    $mgmtNsg = New-AzNetworkSecurityGroup `
        -Name $mgmtNsgName `
        -ResourceGroupName $networkingRG `
        -Location $location `
        -Tag $tags
    Write-Ok "$mgmtNsgName opprettet."
} else {
    Write-Skip "$mgmtNsgName eksisterer allerede."
}

$mgmtNsg = Add-NsgRuleIfMissing -Nsg $mgmtNsg `
    -Name 'allow-ssh-ntnu' -Description 'SSH fra NTNU-nettverket' `
    -Protocol 'Tcp' -SourcePrefix $allowedSshSource `
    -DestPort '22' -Access 'Allow' -Priority 1000

$mgmtNsg | Set-AzNetworkSecurityGroup | Out-Null

# Knytt NSG til subnet-management hvis ikke allerede tilknyttet
$hubVnet  = Get-AzVirtualNetwork -Name $hubVnetName -ResourceGroupName $networkingRG
$mgmtSub  = Get-AzVirtualNetworkSubnetConfig -Name $mgmtSubnetName -VirtualNetwork $hubVnet
if ($mgmtSub.NetworkSecurityGroup) {
    Write-Skip "NSG allerede tilknyttet $mgmtSubnetName."
} else {
    Write-Doing "Knytter $mgmtNsgName til $mgmtSubnetName..."
    Set-AzVirtualNetworkSubnetConfig `
        -Name $mgmtSubnetName `
        -VirtualNetwork $hubVnet `
        -AddressPrefix $mgmtSubnetPrefix `
        -NetworkSecurityGroupId $mgmtNsg.Id | Out-Null
    $hubVnet | Set-AzVirtualNetwork | Out-Null
    Write-Ok "NSG tilknyttet $mgmtSubnetName."
}


###############################################################################
# STEG 4 — Public IP-adresser
###############################################################################

Write-Step "[4/12] Public IP-adresser..."

foreach ($pipDef in @(
    @{ Name = $pipFwName;     DnsLabel = "$prefix-infrait-fw" },
    @{ Name = $pipFwMgmtName; DnsLabel = "$prefix-infrait-mgmt" }
)) {
    $pip = Get-AzPublicIpAddress -Name $pipDef.Name `
           -ResourceGroupName $networkingRG -ErrorAction SilentlyContinue
    if ($pip) {
        Write-Skip "$($pipDef.Name) eksisterer allerede ($($pip.IpAddress))."
    } else {
        Write-Doing "Oppretter $($pipDef.Name)..."
        New-AzPublicIpAddress `
            -Name $pipDef.Name `
            -ResourceGroupName $networkingRG `
            -Location $location `
            -Sku 'Standard' `
            -AllocationMethod 'Static' `
            -DomainNameLabel $pipDef.DnsLabel `
            -IdleTimeoutInMinutes 4 `
            -Tag $tags | Out-Null
        Write-Ok "$($pipDef.Name) opprettet."
    }
}


###############################################################################
# STEG 5 — Firewall Policy
###############################################################################

Write-Step "[5/12] Firewall Policy..."

$fwPolicy = Get-AzFirewallPolicy -Name $fwPolicyName `
            -ResourceGroupName $networkingRG -ErrorAction SilentlyContinue
if ($fwPolicy) {
    Write-Skip "$fwPolicyName eksisterer allerede."
} else {
    Write-Doing "Oppretter $fwPolicyName (Basic tier)..."
    $fwPolicy = New-AzFirewallPolicy `
        -Name $fwPolicyName `
        -ResourceGroupName $networkingRG `
        -Location $location `
        -SkuTier 'Basic' `
        -Tag $tags
    Write-Ok "$fwPolicyName opprettet."
}


###############################################################################
# STEG 6 — Spoke 2 og Spoke 3 med NSGer
###############################################################################

Write-Step "[6/12] Spoke-nettverk og NSGer..."

foreach ($spokeDef in @(
    @{
        VnetName     = $spoke2VnetName
        AddressSpace = $spoke2AddressSpace
        SubnetName   = $spoke2SubnetName
        SubnetPrefix = $spoke2SubnetPrefix
        NsgName      = $spoke2NsgName
    },
    @{
        VnetName     = $spoke3VnetName
        AddressSpace = $spoke3AddressSpace
        SubnetName   = $spoke3SubnetName
        SubnetPrefix = $spoke3SubnetPrefix
        NsgName      = $spoke3NsgName
    }
)) {
    # NSG
    $nsg = Get-AzNetworkSecurityGroup -Name $spokeDef.NsgName `
           -ResourceGroupName $networkingRG -ErrorAction SilentlyContinue
    if (-not $nsg) {
        Write-Doing "Oppretter NSG $($spokeDef.NsgName)..."
        $nsg = New-AzNetworkSecurityGroup `
            -Name $spokeDef.NsgName `
            -ResourceGroupName $networkingRG `
            -Location $location `
            -Tag $tags
        Write-Ok "NSG $($spokeDef.NsgName) opprettet."
    } else {
        Write-Skip "NSG $($spokeDef.NsgName) eksisterer allerede."
    }

    # VNET
    $vnet = Get-AzVirtualNetwork -Name $spokeDef.VnetName `
            -ResourceGroupName $networkingRG -ErrorAction SilentlyContinue
    if ($vnet) {
        Write-Skip "$($spokeDef.VnetName) eksisterer allerede."
    } else {
        Write-Doing "Oppretter $($spokeDef.VnetName)..."
        $subnet = New-AzVirtualNetworkSubnetConfig `
            -Name $spokeDef.SubnetName `
            -AddressPrefix $spokeDef.SubnetPrefix `
            -NetworkSecurityGroupId $nsg.Id
        New-AzVirtualNetwork `
            -Name $spokeDef.VnetName `
            -ResourceGroupName $networkingRG `
            -Location $location `
            -AddressPrefix $spokeDef.AddressSpace `
            -Subnet $subnet `
            -Tag $tags | Out-Null
        Write-Ok "$($spokeDef.VnetName) opprettet med $($spokeDef.SubnetName)."
    }
}


###############################################################################
# STEG 7 — VNET Peering (hub <-> alle tre spokes)
###############################################################################

Write-Step "[7/12] VNET Peering..."

$hubVnet = Get-AzVirtualNetwork -Name $hubVnetName -ResourceGroupName $networkingRG

foreach ($spokeDef in @(
    @{ VnetName = $spoke1VnetName; HubLink = 'hub-to-spoke1'; SpokeLink = 'spoke1-to-hub' },
    @{ VnetName = $spoke2VnetName; HubLink = 'hub-to-spoke2'; SpokeLink = 'spoke2-to-hub' },
    @{ VnetName = $spoke3VnetName; HubLink = 'hub-to-spoke3'; SpokeLink = 'spoke3-to-hub' }
)) {
    $spokeVnet   = Get-AzVirtualNetwork -Name $spokeDef.VnetName -ResourceGroupName $networkingRG
    $existingHub = Get-AzVirtualNetworkPeering `
        -VirtualNetworkName $hubVnetName `
        -ResourceGroupName $networkingRG `
        -Name $spokeDef.HubLink -ErrorAction SilentlyContinue

    if ($existingHub) {
        Write-Skip "Peering '$($spokeDef.HubLink)' eksisterer allerede (status: $($existingHub.PeeringState))."
    } else {
        Write-Doing "Oppretter peering $($spokeDef.HubLink) <-> $($spokeDef.SpokeLink)..."

        # Hub -> Spoke
        Add-AzVirtualNetworkPeering `
            -Name $spokeDef.HubLink `
            -VirtualNetwork $hubVnet `
            -RemoteVirtualNetworkId $spokeVnet.Id `
            -AllowForwardedTraffic | Out-Null

        # Spoke -> Hub
        Add-AzVirtualNetworkPeering `
            -Name $spokeDef.SpokeLink `
            -VirtualNetwork $spokeVnet `
            -RemoteVirtualNetworkId $hubVnet.Id `
            -AllowForwardedTraffic | Out-Null

        Write-Ok "Peering $($spokeDef.HubLink) <-> $($spokeDef.SpokeLink) opprettet."
    }
}


###############################################################################
# STEG 8 — Azure Firewall
###############################################################################

Write-Step "[8/12] Azure Firewall..."
Write-Warn "Billing starter ved opprettelse av firewallen."

$firewall = Get-AzFirewall -Name $firewallName `
            -ResourceGroupName $networkingRG -ErrorAction SilentlyContinue

if ($firewall) {
    Write-Skip "$firewallName eksisterer allerede."
} else {
    Write-Doing "Henter ressurser for firewall-deployment..."

    $fwPolicy     = Get-AzFirewallPolicy  -Name $fwPolicyName  -ResourceGroupName $networkingRG
    $pipFw        = Get-AzPublicIpAddress -Name $pipFwName     -ResourceGroupName $networkingRG
    $pipFwMgmt    = Get-AzPublicIpAddress -Name $pipFwMgmtName -ResourceGroupName $networkingRG
    $hubVnet      = Get-AzVirtualNetwork  -Name $hubVnetName   -ResourceGroupName $networkingRG
    $fwSubnet     = $hubVnet.Subnets | Where-Object { $_.Name -eq 'AzureFirewallSubnet' }
    $fwMgmtSubnet = $hubVnet.Subnets | Where-Object { $_.Name -eq 'AzureFirewallManagementSubnet' }
    $subId        = (Get-AzContext).Subscription.Id

    # New-AzFirewall er inkonsistent mellom Az-versjoner for Basic tier med
    # management-subnet. Vi bruker Invoke-AzRestMethod mot ARM REST API direkte
    # — dette er versjonsuavhengig og støttes i alle nyere Az-installasjoner.
    $body = @{
        location   = $location
        tags       = $tags
        properties = @{
            sku            = @{ name = 'AZFW_VNet'; tier = 'Basic' }
            firewallPolicy = @{ id = $fwPolicy.Id }
            ipConfigurations = @(
                @{
                    name       = 'fw-ipconfig'
                    properties = @{
                        subnet          = @{ id = $fwSubnet.Id }
                        publicIPAddress = @{ id = $pipFw.Id }
                    }
                }
            )
            managementIpConfiguration = @{
                name       = 'fw-mgmt-ipconfig'
                properties = @{
                    subnet          = @{ id = $fwMgmtSubnet.Id }
                    publicIPAddress = @{ id = $pipFwMgmt.Id }
                }
            }
        }
    } | ConvertTo-Json -Depth 10

    $apiVersion = '2024-01-01'
    $uri = "/subscriptions/$subId/resourceGroups/$networkingRG/providers/Microsoft.Network/azureFirewalls/${firewallName}?api-version=$apiVersion"

    Write-Doing "Deployer $firewallName via REST API — dette tar ca. 10 minutter..."
    $response = Invoke-AzRestMethod -Method PUT -Path $uri -Payload $body

    if ($response.StatusCode -notin @(200, 201)) {
        Write-Host "`n  FEIL: REST API svarte HTTP $($response.StatusCode)" -ForegroundColor Red
        Write-Host ($response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 5) -ForegroundColor Red
        exit 1
    }

    # Poll til deployment er ferdig
    Write-Doing "Venter på at firewallen er klar (oppdaterer hvert 30. sekund)..."
    $maxIterations = 40   # maks 20 minutter
    $iteration     = 0
    do {
        Start-Sleep -Seconds 30
        $iteration++
        $fw = Get-AzFirewall -Name $firewallName `
              -ResourceGroupName $networkingRG -ErrorAction SilentlyContinue
        $state = if ($fw) { $fw.ProvisioningState } else { 'Deploying' }
        Write-Doing "  [$($iteration * 30)s] ProvisioningState: $state"
    } while ($state -ne 'Succeeded' -and $iteration -lt $maxIterations)

    if ($state -ne 'Succeeded') {
        Write-Warn "Tidsavbrudd etter $($iteration * 30)s — sjekk portalen manuelt."
        Write-Warn "Kjør scriptet på nytt når firewallen viser 'Succeeded' i portalen."
        exit 1
    }

    Write-Ok "$firewallName deployet."
}

# Hent firewall private IP — brukes i rutetabeller og DNAT
$firewall = Get-AzFirewall -Name $firewallName -ResourceGroupName $networkingRG

if (-not $firewall) {
    Write-Host "`n  FEIL: Klarte ikke å hente $firewallName etter deployment." -ForegroundColor Red
    Write-Host "  Sjekk Azure Portal og kjør scriptet på nytt." -ForegroundColor Red
    exit 1
}

$fwPrivateIp    = $firewall.IpConfigurations[0].PrivateIPAddress
$fwPublicIpAddr = (Get-AzPublicIpAddress -Name $pipFwName -ResourceGroupName $networkingRG).IpAddress

if (-not $fwPrivateIp) {
    Write-Host "`n  FEIL: Firewall private IP er tom. Firewallen er kanskje ikke ferdig deployet." -ForegroundColor Red
    Write-Host "  Vent et minutt og kjør scriptet på nytt — det er trygt å gjøre." -ForegroundColor Red
    exit 1
}

Write-Ok "Firewall private IP : $fwPrivateIp"
Write-Ok "Firewall public IP  : $fwPublicIpAddr"


###############################################################################
# STEG 9 — Route tables (UDR)
###############################################################################

Write-Step "[9/12] Route tables (User Defined Routes)..."

function Set-RouteTable {
    param(
        [string]$RtName,
        [string]$ResourceGroup,
        [string]$Location,
        [hashtable]$Tags,
        [string]$FwPrivateIp,
        [array]$Routes,        # @( @{Name='...'; Prefix='...'}, ... )
        [array]$SubnetAssocs   # @( @{VnetName='...'; SubnetName='...'; SubnetPrefix='...'}, ... )
    )

    $rt = Get-AzRouteTable -Name $RtName -ResourceGroupName $ResourceGroup `
          -ErrorAction SilentlyContinue

    if (-not $rt) {
        Write-Doing "Oppretter $RtName..."
        $rt = New-AzRouteTable `
            -Name $RtName `
            -ResourceGroupName $ResourceGroup `
            -Location $Location `
            -DisableBgpRoutePropagation `
            -Tag $Tags
        Write-Ok "$RtName opprettet."
    } else {
        Write-Skip "$RtName eksisterer allerede."
    }

    # Legg til manglende ruter
    foreach ($route in $Routes) {
        $existing = $rt.Routes | Where-Object { $_.Name -eq $route.Name }
        if ($existing) {
            Write-Skip "  Rute '$($route.Name)' finnes allerede."
        } else {
            $rt | Add-AzRouteConfig `
                -Name $route.Name `
                -AddressPrefix $route.Prefix `
                -NextHopType 'VirtualAppliance' `
                -NextHopIpAddress $FwPrivateIp | Out-Null
            Write-Ok "  Rute '$($route.Name)' lagt til."
        }
    }
    $rt | Set-AzRouteTable | Out-Null

    # Knytt til subnets
    foreach ($assoc in $SubnetAssocs) {
        $vnet   = Get-AzVirtualNetwork -Name $assoc.VnetName -ResourceGroupName $ResourceGroup
        $subnet = Get-AzVirtualNetworkSubnetConfig -Name $assoc.SubnetName -VirtualNetwork $vnet
        if ($subnet.RouteTable) {
            Write-Skip "  Rutetabell allerede tilknyttet $($assoc.VnetName)/$($assoc.SubnetName)."
        } else {
            Write-Doing "  Knytter $RtName til $($assoc.VnetName)/$($assoc.SubnetName)..."
            Set-AzVirtualNetworkSubnetConfig `
                -Name $assoc.SubnetName `
                -VirtualNetwork $vnet `
                -AddressPrefix $assoc.SubnetPrefix `
                -RouteTableId (Get-AzRouteTable -Name $RtName -ResourceGroupName $ResourceGroup).Id | Out-Null
            $vnet | Set-AzVirtualNetwork | Out-Null
            Write-Ok "  Tilknyttet."
        }
    }
}

# Spoke 1 — knyttes til alle tre subnets
Set-RouteTable `
    -RtName "$prefix-rt-spoke1" `
    -ResourceGroup $networkingRG `
    -Location $location `
    -Tags $tags `
    -FwPrivateIp $fwPrivateIp `
    -Routes @(
        @{ Name = 'to-spoke2-via-fw'; Prefix = '10.1.0.0/16' },
        @{ Name = 'to-spoke3-via-fw'; Prefix = '10.2.0.0/16' }
    ) `
    -SubnetAssocs @(
        @{ VnetName = $spoke1VnetName; SubnetName = 'subnet-frontend'; SubnetPrefix = '10.0.1.0/24' },
        @{ VnetName = $spoke1VnetName; SubnetName = 'subnet-backend';  SubnetPrefix = '10.0.2.0/24' },
        @{ VnetName = $spoke1VnetName; SubnetName = 'subnet-data';     SubnetPrefix = '10.0.3.0/24' }
    )

# Spoke 2
Set-RouteTable `
    -RtName "$prefix-rt-spoke2" `
    -ResourceGroup $networkingRG `
    -Location $location `
    -Tags $tags `
    -FwPrivateIp $fwPrivateIp `
    -Routes @(
        @{ Name = 'to-spoke1-via-fw'; Prefix = '10.0.0.0/16' },
        @{ Name = 'to-spoke3-via-fw'; Prefix = '10.2.0.0/16' }
    ) `
    -SubnetAssocs @(
        @{ VnetName = $spoke2VnetName; SubnetName = $spoke2SubnetName; SubnetPrefix = $spoke2SubnetPrefix }
    )

# Spoke 3
Set-RouteTable `
    -RtName "$prefix-rt-spoke3" `
    -ResourceGroup $networkingRG `
    -Location $location `
    -Tags $tags `
    -FwPrivateIp $fwPrivateIp `
    -Routes @(
        @{ Name = 'to-spoke1-via-fw'; Prefix = '10.0.0.0/16' },
        @{ Name = 'to-spoke2-via-fw'; Prefix = '10.1.0.0/16' }
    ) `
    -SubnetAssocs @(
        @{ VnetName = $spoke3VnetName; SubnetName = $spoke3SubnetName; SubnetPrefix = $spoke3SubnetPrefix }
    )


###############################################################################
# STEG 10 — Firewall Policy: nettverksregler (allow-inter-spoke)
###############################################################################

Write-Step "[10/12] Firewall Policy nettverksregler..."

$fwPolicy = Get-AzFirewallPolicy -Name $fwPolicyName -ResourceGroupName $networkingRG
$subId    = (Get-AzContext).Subscription.Id
$apiVer   = '2024-01-01'

$netGroupUri  = "/subscriptions/$subId/resourceGroups/$networkingRG/providers/Microsoft.Network/firewallPolicies/$fwPolicyName/ruleCollectionGroups/DefaultNetworkRuleCollectionGroup?api-version=$apiVer"
$netGroupResp = Invoke-AzRestMethod -Method GET -Path $netGroupUri

if ($netGroupResp.StatusCode -eq 200) {
    $netGroupBody = $netGroupResp.Content | ConvertFrom-Json
    $networkRuleExists = $netGroupBody.properties.ruleCollections |
        Where-Object { $_.name -eq 'allow-inter-spoke' }
    if ($networkRuleExists) {
        Write-Skip "Nettverksregel 'allow-inter-spoke' finnes allerede."
    } else {
        Write-Skip "DefaultNetworkRuleCollectionGroup finnes, men uten allow-inter-spoke — legg til manuelt i portalen om nødvendig."
    }
} else {
    Write-Doing "Oppretter nettverksregel allow-inter-spoke..."

    $netRule = New-AzFirewallPolicyNetworkRule `
        -Name 'spoke-to-spoke' `
        -Protocol @('Any') `
        -SourceAddress @('10.0.0.0/16', '10.1.0.0/16', '10.2.0.0/16') `
        -DestinationAddress @('10.0.0.0/16', '10.1.0.0/16', '10.2.0.0/16') `
        -DestinationPort '*'

    $netCollection = New-AzFirewallPolicyFilterRuleCollection `
        -Name 'allow-inter-spoke' `
        -Priority 200 `
        -Rule $netRule `
        -ActionType 'Allow'

    New-AzFirewallPolicyRuleCollectionGroup `
        -Name 'DefaultNetworkRuleCollectionGroup' `
        -Priority 200 `
        -RuleCollection $netCollection `
        -FirewallPolicyObject $fwPolicy | Out-Null

    Write-Ok "Nettverksregel allow-inter-spoke konfigurert."
}


###############################################################################
# STEG 11 — VM-er med cloud-init (nginx)
###############################################################################

Write-Step "[11/12] VM-er med nginx..."

# Opprett compute RG om nødvendig
$rg = Get-AzResourceGroup -Name $computeRG -ErrorAction SilentlyContinue
if (-not $rg) {
    Write-Doing "Oppretter $computeRG..."
    New-AzResourceGroup -Name $computeRG -Location $location -Tag $tags | Out-Null
    Write-Ok "$computeRG opprettet."
} else {
    Write-Skip "$computeRG eksisterer allerede."
}

# Cloud-init per spoke
$cloudInitTemplate = @'
#cloud-config
package_update: true
packages:
  - nginx
write_files:
  - path: /var/www/html/index.html
    content: |
      <!DOCTYPE html>
      <html>
        <head><title>SPOKE_TITLE</title></head>
        <body style="font-family:sans-serif;padding:2em;background:BG_COLOR;">
          <h1>&#x2705; SPOKE_HEADING</h1>
          <p><strong>InfraIT.sec Hub-Spoke Demo</strong></p>
          <p>VM: VM_NAME</p>
          <p>Privat IP: VM_IP</p>
          <p>Nettverk: VNET_NAME</p>
        </body>
      </html>
runcmd:
  - systemctl enable nginx
  - systemctl restart nginx
'@

$vmDefs = @(
    @{
        VmName    = $spoke1VmName;  VnetName  = $spoke1VnetName
        Subnet    = $spoke1SubnetName; Ip = $spoke1VmIp
        NsgName   = $spoke1NsgName
        Title     = 'Spoke 1';  Heading = 'Spoke 1 — Frontend'
        BgColor   = '#e8f4f8'
    },
    @{
        VmName    = $spoke2VmName;  VnetName  = $spoke2VnetName
        Subnet    = $spoke2SubnetName; Ip = $spoke2VmIp
        NsgName   = $spoke2NsgName
        Title     = 'Spoke 2';  Heading = 'Spoke 2 — Workload'
        BgColor   = '#e8f8e8'
    },
    @{
        VmName    = $spoke3VmName;  VnetName  = $spoke3VnetName
        Subnet    = $spoke3SubnetName; Ip = $spoke3VmIp
        NsgName   = $spoke3NsgName
        Title     = 'Spoke 3';  Heading = 'Spoke 3 — Workload'
        BgColor   = '#f8f0e8'
    }
)

$credential = [PSCredential]::new(
    $adminUsername,
    (ConvertTo-SecureString $adminPassword -AsPlainText -Force)
)

foreach ($def in $vmDefs) {
    # --- VM ---
    $existingVm = Get-AzVM -Name $def.VmName -ResourceGroupName $computeRG -ErrorAction SilentlyContinue
    if ($existingVm) {
        Write-Skip "VM $($def.VmName) eksisterer allerede."
    } else {
        Write-Doing "Deployer $($def.VmName)..."

        $cloudInit = $cloudInitTemplate `
            -replace 'SPOKE_TITLE',   $def.Title `
            -replace 'BG_COLOR',      $def.BgColor `
            -replace 'SPOKE_HEADING', $def.Heading `
            -replace 'VM_NAME',       $def.VmName `
            -replace 'VM_IP',         $def.Ip `
            -replace 'VNET_NAME',     $def.VnetName

        $vnet   = Get-AzVirtualNetwork -Name $def.VnetName -ResourceGroupName $networkingRG
        $subnet = Get-AzVirtualNetworkSubnetConfig -Name $def.Subnet -VirtualNetwork $vnet

        $ipConfig = New-AzNetworkInterfaceIpConfig `
            -Name 'ipconfig1' `
            -SubnetId $subnet.Id `
            -PrivateIpAddress $def.Ip `
            -PrivateIpAddressVersion IPv4 `
            -Primary

        $nic = New-AzNetworkInterface `
            -Name "$($def.VmName)-nic" `
            -ResourceGroupName $computeRG `
            -Location $location `
            -IpConfiguration $ipConfig `
            -Tag $tags

        $vmConfig = New-AzVMConfig -VMName $def.VmName -VMSize $vmSize |
            Set-AzVMOperatingSystem `
                -Linux -ComputerName $def.VmName `
                -Credential $credential -CustomData $cloudInit |
            Set-AzVMSourceImage `
                -PublisherName 'Canonical' `
                -Offer 'ubuntu-24_04-lts' `
                -Skus 'server' -Version 'latest' |
            Add-AzVMNetworkInterface -Id $nic.Id |
            Set-AzVMOSDisk `
                -Name "$($def.VmName)-osdisk" `
                -CreateOption FromImage -StorageAccountType Standard_LRS |
            Set-AzVMBootDiagnostic -Disable

        New-AzVM `
            -ResourceGroupName $computeRG `
            -Location $location `
            -VM $vmConfig `
            -Tag $tags | Out-Null

        Write-Ok "$($def.VmName) deployet."
    }

    # --- NSG-regler for HTTP og SSH fra AzureFirewallSubnet ---
    $nsg = Get-AzNetworkSecurityGroup -Name $def.NsgName `
           -ResourceGroupName $networkingRG -ErrorAction SilentlyContinue
    if (-not $nsg) {
        Write-Warn "NSG '$($def.NsgName)' ikke funnet — hopper over regeloppsett."
        continue
    }

    $nsg = Add-NsgRuleIfMissing -Nsg $nsg `
        -Name 'allow-http-from-firewall' `
        -Description 'HTTP fra AzureFirewallSubnet (DNAT)' `
        -Protocol 'Tcp' -SourcePrefix $fwSubnetCidr `
        -DestPort '80' -Access 'Allow' -Priority 1100

    $nsg = Add-NsgRuleIfMissing -Nsg $nsg `
        -Name 'allow-ssh-from-firewall' `
        -Description 'SSH fra AzureFirewallSubnet (DNAT)' `
        -Protocol 'Tcp' -SourcePrefix $fwSubnetCidr `
        -DestPort '22' -Access 'Allow' -Priority 1110

    $nsg | Set-AzNetworkSecurityGroup | Out-Null
}


###############################################################################
# STEG 12 — DNAT-regler i Firewall Policy
###############################################################################

Write-Step "[12/12] DNAT-regler..."

$fwPolicy = Get-AzFirewallPolicy -Name $fwPolicyName -ResourceGroupName $networkingRG
$subId    = (Get-AzContext).Subscription.Id
$apiVer   = '2024-01-01'

$dnatGroupUri  = "/subscriptions/$subId/resourceGroups/$networkingRG/providers/Microsoft.Network/firewallPolicies/$fwPolicyName/ruleCollectionGroups/DnatRuleCollectionGroup?api-version=$apiVer"
$dnatGroupResp = Invoke-AzRestMethod -Method GET -Path $dnatGroupUri

if ($dnatGroupResp.StatusCode -eq 200) {
    Write-Skip "DnatRuleCollectionGroup eksisterer allerede — hopper over DNAT-konfigurasjon."
    Write-Warn "  Slett 'DnatRuleCollectionGroup' manuelt i portalen og kjør scriptet på nytt for å rekonfigurere."
} else {
    Write-Doing "Oppretter DNAT-regler..."

    # Reglene opprettes enkeltvis for å unngå at PowerShells array-komma
    # feiltolkes som del av -TranslatedPort-parameteren
    $r1 = New-AzFirewallPolicyNatRule -Name 'dnat-http-spoke1' -Protocol 'TCP' `
        -SourceAddress '*' -DestinationAddress $fwPublicIpAddr `
        -DestinationPort $httpPortSpoke1 -TranslatedAddress $spoke1VmIp -TranslatedPort '80'
    $r2 = New-AzFirewallPolicyNatRule -Name 'dnat-http-spoke2' -Protocol 'TCP' `
        -SourceAddress '*' -DestinationAddress $fwPublicIpAddr `
        -DestinationPort $httpPortSpoke2 -TranslatedAddress $spoke2VmIp -TranslatedPort '80'
    $r3 = New-AzFirewallPolicyNatRule -Name 'dnat-http-spoke3' -Protocol 'TCP' `
        -SourceAddress '*' -DestinationAddress $fwPublicIpAddr `
        -DestinationPort $httpPortSpoke3 -TranslatedAddress $spoke3VmIp -TranslatedPort '80'
    $r4 = New-AzFirewallPolicyNatRule -Name 'dnat-ssh-spoke1' -Protocol 'TCP' `
        -SourceAddress '*' -DestinationAddress $fwPublicIpAddr `
        -DestinationPort $sshPortSpoke1 -TranslatedAddress $spoke1VmIp -TranslatedPort '22'
    $r5 = New-AzFirewallPolicyNatRule -Name 'dnat-ssh-spoke2' -Protocol 'TCP' `
        -SourceAddress '*' -DestinationAddress $fwPublicIpAddr `
        -DestinationPort $sshPortSpoke2 -TranslatedAddress $spoke2VmIp -TranslatedPort '22'
    $r6 = New-AzFirewallPolicyNatRule -Name 'dnat-ssh-spoke3' -Protocol 'TCP' `
        -SourceAddress '*' -DestinationAddress $fwPublicIpAddr `
        -DestinationPort $sshPortSpoke3 -TranslatedAddress $spoke3VmIp -TranslatedPort '22'

    $dnatCollection = New-AzFirewallPolicyNatRuleCollection `
        -Name 'dnat-spoke-vms' `
        -Priority 100 `
        -Rule @($r1, $r2, $r3, $r4, $r5, $r6) `
        -ActionType 'Dnat'

    New-AzFirewallPolicyRuleCollectionGroup `
        -Name 'DnatRuleCollectionGroup' `
        -Priority 100 `
        -RuleCollection $dnatCollection `
        -FirewallPolicyObject $fwPolicy | Out-Null

    Write-Ok "DNAT-regler konfigurert."
}


###############################################################################
# OPPSUMMERING
###############################################################################

Write-Host "`n================================================" -ForegroundColor White
Write-Host " Deployment fullfort!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor White
Write-Host " Firewall public IP : $fwPublicIpAddr" -ForegroundColor White
Write-Host " Firewall private IP: $fwPrivateIp"    -ForegroundColor White
Write-Host ""
Write-Host " HTTP (aapnes i nettleser):" -ForegroundColor White
Write-Host "   Spoke 1:  http://$($fwPublicIpAddr):$httpPortSpoke1" -ForegroundColor Yellow
Write-Host "   Spoke 2:  http://$($fwPublicIpAddr):$httpPortSpoke2" -ForegroundColor Yellow
Write-Host "   Spoke 3:  http://$($fwPublicIpAddr):$httpPortSpoke3" -ForegroundColor Yellow
Write-Host ""
Write-Host " SSH:" -ForegroundColor White
Write-Host "   Spoke 1:  ssh $adminUsername@$fwPublicIpAddr -p $sshPortSpoke1" -ForegroundColor Yellow
Write-Host "   Spoke 2:  ssh $adminUsername@$fwPublicIpAddr -p $sshPortSpoke2" -ForegroundColor Yellow
Write-Host "   Spoke 3:  ssh $adminUsername@$fwPublicIpAddr -p $sshPortSpoke3" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor White
Write-Host ""
Write-Host " NB: Cloud-init installerer nginx etter VM-oppstart." -ForegroundColor Gray
Write-Host " Vent 2-3 minutter foer HTTP-tilgang fungerer."       -ForegroundColor Gray
Write-Host ""
Write-Host " HUSK: Slett $firewallName umiddelbart etter presentasjon!" -ForegroundColor Red