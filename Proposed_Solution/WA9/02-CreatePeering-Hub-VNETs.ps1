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


# Variables
$prefix = 'tim'
# Resource group:
$resourceGroupName = $prefix + '-rg-network-001'
$location = 'uksouth'

# Create Peering between VNETs - NOTE! Hardcoded VNET names. These are the same as in the previous scripts.
# Define the hub and spoke VNET names. Names found in 01-CreateVNET-and-subnet.ps1 under $vnetConfigs hashtable.
$hubVnetName = "$prefix-vnet-hub-shared-we"
$spokeVnetNames = @("$prefix-vnet-web-shared-we-001", "$prefix-vnet-hr-prod-we-001", "$prefix-vnet-hrdev-dev-we-001")

# Loop through each spoke VNET and create peering with the hub
foreach ($spokeVnetName in $spokeVnetNames) {
    New-VNetPeering -resourceGroupName $resourceGroupName -hubVnetName $hubVnetName -spokeVnetName $spokeVnetName
}