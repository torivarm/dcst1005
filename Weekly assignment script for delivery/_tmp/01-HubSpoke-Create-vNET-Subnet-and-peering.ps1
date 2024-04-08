# This script is used to create a VNET with subnets in Azure using the Az module
# It contains of two functions:
# 1. Get-ResourceGroup: This function checks if a Resource Group exists and creates it if it does not
# 2. New-VNetWithSubnets: This function creates a VNET with the specified subnets
#   It iterates over each subnet configuration and adds it to the VNET

<# Variables - Remember to change these to your own TenantID and SubscriptionID found in the Azure Portal
$tenantID = "bd0944c8-c04e-466a-9729-d7086d13a653"
$subscrptionID = "41082359-57d6-4427-b5d9-21e269157652"

# Connect to Azure
Connect-AzAccount -Tenant $tenantID -Subscription $subscrptionID
#>

function Get-ResourceGroup {
    param (
        [string]$resourceGroupName,
        [string]$location
    )

    # Check if the Resource Group already exists
    $resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue

    if (-not $resourceGroup) {
        # Resource Group does not exist, so create it
        New-AzResourceGroup -Name $resourceGroupName -Location $location -ErrorAction Stop
        Write-Output "Created Resource Group: $resourceGroupName in $location"
    } else {
        Write-Output "Resource Group $resourceGroupName already exists."
    }
}


function New-VNetWithSubnets {
    param (
        [string]$resourceGroupName,
        [string]$location,
        [string]$vnetName,
        [string]$vnetAddressSpace,
        [array]$subnets
    )

    # Check if the VNET already exists
    $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue

    if (-not $vnet) {
        # VNET does not exist, create it
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressSpace -ErrorAction Stop
        Write-Output "Created VNET: $vnetName"
    } else {
        Write-Output "VNET $vnetName already exists."
    }

    # Iterate over each subnet configuration
    foreach ($subnet in $subnets) {
        # Check if the subnet already exists in the VNET
        $subnetConfig = $vnet.Subnets | Where-Object { $_.Name -eq $subnet.Name }

        if (-not $subnetConfig) {
            # Subnet does not exist, add it to the VNET
            $subnetConfig = Add-AzVirtualNetworkSubnetConfig -Name $subnet.Name -AddressPrefix $subnet.AddressPrefix -VirtualNetwork $vnet -ErrorAction Stop
            $vnet | Set-AzVirtualNetwork -ErrorAction Stop
            Write-Output "Added subnet $($subnet.Name) to $vnetName"
        } else {
            Write-Output "Subnet $($subnet.Name) already exists in $vnetName."
        }
    }
}


function New-VNetPeering {
    param (
        [Parameter(Mandatory=$true)]
        [string]$resourceGroupName,
        [Parameter(Mandatory=$true)]
        [string]$hubVnetName,
        [Parameter(Mandatory=$true)]
        [string]$spokeVnetName,
        [string]$hubToSpokePeeringName = "$hubVnetName-to-$spokeVnetName",
        [string]$spokeToHubPeeringName = "$spokeVnetName-to-$hubVnetName"
    )

    # Fetch the VNET objects
    $hubVnet = Get-AzVirtualNetwork -Name $hubVnetName -ResourceGroupName $resourceGroupName
    $spokeVnet = Get-AzVirtualNetwork -Name $spokeVnetName -ResourceGroupName $resourceGroupName

    # Check and create peering from Hub to Spoke
    $existingPeering = Get-AzVirtualNetworkPeering -VirtualNetworkName $hubVnetName -ResourceGroupName $resourceGroupName -Name $hubToSpokePeeringName -ErrorAction SilentlyContinue
    if (-not $existingPeering) {
        Add-AzVirtualNetworkPeering -Name $hubToSpokePeeringName -VirtualNetwork $hubVnet -RemoteVirtualNetworkId $spokeVnet.Id
        Write-Output "Created peering from $hubVnetName to $spokeVnetName."
    } else {
        Write-Output "Peering from $hubVnetName to $spokeVnetName already exists."
    }

    # Check and create peering from Spoke to Hub
    $existingPeering = Get-AzVirtualNetworkPeering -VirtualNetworkName $spokeVnetName -ResourceGroupName $resourceGroupName -Name $spokeToHubPeeringName -ErrorAction SilentlyContinue
    if (-not $existingPeering) {
        Add-AzVirtualNetworkPeering -Name $spokeToHubPeeringName -VirtualNetwork $spokeVnet -RemoteVirtualNetworkId $hubVnet.Id
        Write-Output "Created peering from $spokeVnetName to $hubVnetName."
    } else {
        Write-Output "Peering from $spokeVnetName to $hubVnetName already exists."
    }
}

# Define the VNET and subnet configurations
$vnetConfigs = @(
    @{
        Name = "$prefix-vnet-hub-shared-we"
        AddressSpace = "10.10.0.0/16"
        Subnets = @(
            @{Name = "$prefix-snet-mgmt-prod-we-001"; AddressPrefix = "10.10.0.0/24"}
        )
    },
    @{
        Name = "$prefix-vnet-web-shared-we-001"
        AddressSpace = "10.20.0.0/16"
        Subnets = @(
            @{Name = "$prefix-snet-web-prod-we-001"; AddressPrefix = "10.20.0.0/24"},
            @{Name = "$prefix-snet-app-prod-we-001"; AddressPrefix = "10.20.1.0/24"},
            @{Name = "$prefix-snet-db-prod-we-001"; AddressPrefix = "10.20.2.0/24"}
        )
    },
    @{
        Name = "$prefix-vnet-hr-prod-we-001"
        AddressSpace = "10.30.0.0/16"
        Subnets = @(
            @{Name = "$prefix-snet-hrweb-prod-we-001"; AddressPrefix = "10.30.0.0/24"},
            @{Name = "$prefix-snet-hrapp-prod-we-001"; AddressPrefix = "10.30.1.0/24"},
            @{Name = "$prefix-snet-hrdb-prod-we-001"; AddressPrefix = "10.30.2.0/24"}
        )
    },
    @{
        Name = "$prefix-vnet-hrdev-dev-we-001"
        AddressSpace = "10.40.0.0/16"
        Subnets = @(
            @{Name = "$prefix-snet-hrweb-dev-we-001"; AddressPrefix = "10.40.0.0/24"},
            @{Name = "$prefix-snet-hrapp-dev-we-001"; AddressPrefix = "10.40.1.0/24"},
            @{Name = "$prefix-snet-hrdb-dev-we-001"; AddressPrefix = "10.40.2.0/24"}
        )
    }
)

############################################################################################

# Variables
$prefix = 'tim'
# Resource group:
$resourceGroupName = $prefix + '-rg-network-001'
$location = 'uksouth'

# First, ensure the Resource Group exists or create it if it does not
Get-ResourceGroup -resourceGroupName $resourceGroupName -location $location

# Execution - Create the VNETs with subnets
foreach ($vnetConfig in $vnetConfigs) {
    New-VNetWithSubnets -resourceGroupName $rgName -location $location -vnetName $vnetConfig.Name -vnetAddressSpace $vnetConfig.AddressSpace -subnets $vnetConfig.Subnets
}

# Create Peering between VNETs
$hubVnetName = "$prefix-vnet-hub-shared-we"
$spokeVnetNames = @("$prefix-vnet-web-shared-we-001", "$prefix-vnet-hr-prod-we-001", "$prefix-vnet-hrdev-dev-we-001")

# Loop through each spoke VNET and create peering with the hub
foreach ($spokeVnetName in $spokeVnetNames) {
    New-VNetPeering -resourceGroupName $resourceGroupName -hubVnetName $hubVnetName -spokeVnetName $spokeVnetName
}











<# Variables
$prefix = 'tim'
# Resource group:
$rgName = $prefix + '-rg-network-001'
$location = 'uksouth'

# VNET1 hub:
$vnetName1 = $prefix + '-vnet-hub-shared-we'
$addressPrefix2 = '10.10.0.0/16'
$subnetVnet1Name1 = $prefix + '-snet-mgmt-prod-we-001'
$subnetVnet1AddressPrefix1 = '10.10.0.0/24'

# VNET2 spoke1:
$vnetName2 = $prefix + '-vnet-web-shared-we-001'
$addressPrefix2 = '10.20.0.0/16'
$subnetVnet2Name1 = $prefix + '-snet-web-prod-we-001'
$subnetVnet2AddressPrefix1 = '10.20.0.0/24'
$subnetVnet2Name2 = $prefix + '-snet-app-prod-we-001'
$subnetVnet2AddressPrefix2 = '10.20.1.0/24'
$subnetVnet2Name3 = $prefix + '-snet-db-prod-we-001'
$subnetVnet2AddressPrefix3 = '10.20.2.0/24'

# VNET3 spoke2:
$vnetName3 = $prefix + '-vnet-hr-prod-we-001'
$addressPrefix3 = '10.30.0.0/16'
$subnetVnet3Name1 = $prefix + '-snet-hrweb-prod-we-001'
$subnetVnet3AddressPrefix1 = '10.30.0.0/24'
$subnetVnet3Name2 = $prefix + '-snet-hrapp-prod-we-001'
$subnetVnet3AddressPrefix2 = '10.30.1.0/24'
$subnetVnet3Name3 = $prefix + '-snet-hrdb-prod-we-001'
$subnetVnet3AddressPrefix3 = '10.30.2.0/24'

# VNET4 spoke3:
$vnetName4 = $prefix + '-vnet-hrdev-dev-we-001'
$addressPrefix4 = '10.40.0.0/16'
$subnetVnet4Name1 = $prefix + '-snet-hrweb-dev-we-001'
$subnetVnet4AddressPrefix1 = '10.40.0.0/24'
$subnetVnet4Name2 = $prefix + '-snet-hrapp-dev-we-001'
$subnetVnet4AddressPrefix2 = '10.40.1.0/24'
$subnetVnet4Name3 = $prefix + '-snet-hrdb-dev-we-001'
$subnetVnet4AddressPrefix3 = '10.40.2.0/24'

#>