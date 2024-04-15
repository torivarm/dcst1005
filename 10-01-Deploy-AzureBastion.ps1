# In this script, we will create an Azure Bastion 
# service in the virtual network created in 10-00-CreateVNET-HUB-Shared-UK.ps1.


#Variables
$prefix = 'demo'
$resourceGroupName = $prefix + '-rg-network-001'
$location = 'uksouth'
$vnetNameHUB = "$prefix-vnet-hub-shared-uk"

# Get HUB VNET
$vnet = Get-AzVirtualNetwork -Name $vnetNameHUB -ResourceGroupName $resourceGroupName

# Create Azure Bastion Subnet
Add-AzVirtualNetworkSubnetConfig `
                    -Name "AzureBastionSubnet" `
                    -VirtualNetwork $vnet `
                    -AddressPrefix "10.1.1.0/26" |
                    Set-AzVirtualNetwork


# Create Public IP for Azure Bastion
$publicIp = New-AzPublicIpAddress `
                    -Name ($prefix + '-pip-azbastion-001') `
                    -ResourceGroupName $resourceGroupName `
                    -Location $location `
                    -AllocationMethod Static `
                    -Sku Standard


# Create Azure Bastion
$bastion = New-AzBastion `
                    -Name ($prefix + '-bastion-001') `
                    -ResourceGroupName $resourceGroupName `
                    -PublicIpAddressId $publicIp.Id `
                    -VirtualNetworkId $vnet.Id
