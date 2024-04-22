# In this script we will create two NSGs and attach them to the subnets in the VNET 
# $prefix-vnet-web-shared-uk-001. The NSGs will be named $prefix-NSG-App and $prefix-NSG-DB.

# Variables
$prefix = "demo"
$resourceGroupName = "$prefix-rg-network-001"
$location = "uksouth"
$vnetName = "$prefix-vnet-web-shared-uk-001"

$subnet1Name = "$prefix-snet-app-prod-uk-001"
$subnet2Name = "$prefix-snet-db-prod-uk-001"

$nsg1 = "$prefix-NSG-App"
$nsg2 = "$prefix-NSG-DB"

# Create NSG1
# Check if NSG exists, if not, create it
$nsgcheck = Get-AzNetworkSecurityGroup -Name $nsg1 -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue

if (-not $nsgcheck) {
    Write-Host "Creating NSG $nsg1..." -ForegroundColor Green
    $nsg1 = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $nsg1
}
else {
    Write-Host "NSG $nsg1 already exists."
}

# Create NSG2
# Check if NSG exists, if not, create it

$nsgcheck = Get-AzNetworkSecurityGroup -Name $nsg2 -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue

if (-not $nsgcheck) {
    Write-Host "Creating NSG $nsg2..." -ForegroundColor Green
    $nsg2 = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $nsg2
}
else {
    Write-Host "NSG $nsg2 already exists."
}


# Get the subnets
$subnet1 = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName |
           Get-AzVirtualNetworkSubnetConfig -Name $subnet1Name
$subnet2 = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName |
           Get-AzVirtualNetworkSubnetConfig -Name $subnet2Name

# Attach NSG1 to Subnet1
Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $subnet1.VirtualNetwork -Name $subnet1.Name -NetworkSecurityGroup $nsg1 |
    Set-AzVirtualNetwork

# Attach NSG2 to Subnet2
Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $subnet2.VirtualNetwork -Name $subnet2.Name -NetworkSecurityGroup $nsg2 |
    Set-AzVirtualNetwork

# Output the configuration for verification
Get-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName
