# In this PowerShell script, we will create one Network Security Group and attach it to 
# appropriate subnets in the virtual networks.
# This is the following subnets from the previous script:
# Subnets: 
# - $prefix-snet-mgmt-prod-we-001
# - $prefix-snet-web-prod-we-001
# - $prefix-snet-hrweb-prod-we-001
# - $prefix-snet-hrweb-dev-we-001
# Then the script will create a rule that allows for inbound traffic on port 80 and 22.

$prefix = "tim"
$nsgName = "$prefix-nsg-port80-22"
$resourceGroupName = "$prefix-rg-network-001"
$location = "uksouth"

$newNSG = New-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroupName -Location $location




# Retrieve all VNETs within the specified Resource Group
# Use this to determine the VNETs and their subnets
# Spesify the vnet and subnet in the variables under the foreach loop

<#
$vNets = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName

# Iterate over each VNET to list its subnets
foreach ($vNet in $vNets) {
    Write-Output "VNET: $($vNet.Name), Address Space: $($vNet.AddressSpace.AddressPrefixes -join ', ')"
    foreach ($subnet in $vNet.Subnets) {
        Write-Output "`tSubnet: $($subnet.Name), Address Prefix: $($subnet.AddressPrefix)"
    }
}
#>

$hubVnetName = "$prefix-vnet-hub-shared-we"
$hubVnetSubnet = "$prefix-snet-mgmt-prod-we-001"

$spoke1vnetName = "$prefix-vnet-web-shared-we-001"
$spoke1vnetSubnet = "$prefix-snet-web-prod-we-001"

$spoke2vnetName = "$prefix-vnet-hr-prod-we-001"
$spoke2vnetSubnet = "$prefix-snet-hrweb-prod-we-001"

$spoke3vnetName = "$prefix-vnet-hrdev-dev-we-001"
$spoke3vnetSubnet = "$prefix-snet-hrweb-dev-we-001"

