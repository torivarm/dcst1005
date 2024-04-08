# This script will create four VNETs with subnets in Azure using the Az module.
# The VNETs and subnets are defined in an array of hash tables, where each hash table represents a VNET configuration.
# It ResourceGroup must be created first before running this script.
# 00-CreatResourceGroup.ps1 script can be used to create the Resource Group.
# The script contains a function New-VNetWithSubnets that creates a VNET with the specified subnets.
# It iterates over each subnet configuration and adds it to the VNET.

function New-VNetWithSubnets {
    param (
        [string]$resourceGroupName,
        [string]$location,
        [string]$vnetName,
        [string]$vnetAddressSpace,
        [array]$subnets
    )
    # Check if the Resource Group exists
    $resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue

    if (-not $resourceGroup) {
        Write-Error "Resource Group $resourceGroupName does not exist. Creates the Resource Group first."
        Write-Host "Run the 00-CreateResourceGroup.ps1 script to create the Resource Group."
    }
    else {
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
}

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

# Variables
$prefix = 'tim'
# Resource group:
$resourceGroupName = $prefix + '-rg-network-001'
$location = 'uksouth'

# Execution - Create the VNETs with subnets
foreach ($vnetConfig in $vnetConfigs) {
    New-VNetWithSubnets -resourceGroupName $resourceGroupName -location $location -vnetName $vnetConfig.Name -vnetAddressSpace $vnetConfig.AddressSpace -subnets $vnetConfig.Subnets
}