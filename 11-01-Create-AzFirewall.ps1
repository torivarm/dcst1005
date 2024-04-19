# In this script we will create an Azure Firewall in the virtual network created in earlier Weekly assignments.
# The firewall will have a public IP address and will be associated with the Azure Firewall subnet.
# It is placed in the same resource group as the virtual network, but we will delete it after testing.

# Variables
$prefix = 'demo'
$resourceGroupName = $prefix + '-rg-network-001'
$location = 'uksouth'
$vnetNameHUB = "$prefix-vnet-hub-shared-uk"
$fwName = "$prefix-Azfw"


# Create public IP for the Azure Firewall
# Check if the public IP already exists, if not, create it
"Creating public IP for the Azure Firewall..."
$publicIp = Get-AzPublicIpAddress -Name ($fwName + '-pip') -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
if (-not $publicIp) {
    $publicIp = New-AzPublicIpAddress -Name ($fwName + '-pip') `
                                      -ResourceGroupName $resourceGroupName `
                                      -Location $location `
                                      -AllocationMethod Static `
                                      -Sku Standard
}
else {
    Write-Host "Public IP for the Azure Firewall already exists."
}

# Check if the resource group exists
"Getting resource group '$resourceGroupName'..."
$resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if (-not $resourceGroup) {
    Write-Error "Resource group '$resourceGroupName' does not exist. Please create the resource group or check the name."
    exit
}
else {
    Write-Host "Resource group '$resourceGroupName' found."
}


# Check if the VNET exists
"Getting VNET '$vnetNameHUB'..."
$vnet = Get-AzVirtualNetwork -Name $vnetNameHUB -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
if (-not $vnet) {
    Write-Error "VNET '$vnetNameHUB' does not exist. Please create the VNET or check the name."
    exit
}
else {
    Write-Host "VNET '$vnetNameHUB' found."
}

# Check if the subnet for Azure Firewall exists, if not, create it
"Checking if the subnet for Azure Firewall exists..."
$subnetName = 'AzureFirewallSubnet' # This is the default name for the Azure Firewall subnet

$firewallSubnet = $vnet.Subnets | Where-Object { $_.Name -eq $subnetName }
if (-not $firewallSubnet) {
    $firewallSubnet = Add-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet -AddressPrefix '10.10.3.0/24'
    $vnet | Set-AzVirtualNetwork
}
else {
    Write-Host "Subnet '$subnetName' already exists."
}

# Getting the updated VNET with the new subnet
$vnet = Get-AzVirtualNetwork -Name $vnetNameHUB -ResourceGroupName $resourceGroupName

# Create the Azure Firewall
$azFirewall = New-AzFirewall -Name $fwName `
                            -ResourceGroupName $resourceGroupName `
                            -Location $location `
                            -VirtualNetwork $vnet `
                            -PublicIpAddress $publicIp `
                            -AsJob


# Output the configuration
# Get-AzFirewall -Name $fwName -ResourceGroupName $resourceGroupName

# Delete the Azure Firewall
# $azFirewall | Remove-AzFirewall -Force