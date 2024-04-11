# In this PowerShell script, we will create one Network Security Group
# The NSG will be attached to appropriate subnets in the virtual networks on 04-AttachNSGtoSubnet.ps1.
# Then the script will create a rule that allows for inbound traffic on port 80 and 22.

# Variables - REMEMBER to change $prefix to your own prefix
$prefix = 'demo'
# Resource group:
$resourceGroupName = $prefix + '-rg-network-001'
$location = 'uksouth'
# NSG:
$nsgName = "$prefix-nsg-web-subnet"

# Attempt to fetch an existing NSG
$nsg = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue

# If the NSG doesn't exist, create it
if (-not $nsg) {
    $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $nsgName
}
# Define subnet names to search for
$targetSubnets = @(
    "$prefix-snet-mgmt-prod-uk-001",
    "$prefix-snet-web-prod-uk-001",
    "$prefix-snet-hrweb-prod-uk-001",
    "$prefix-snet-hrweb-dev-uk-001"
)

# Fetch the NSG
$nsg = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroupName

# Retrieve all VNETs in the resource group
$vNets = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName

# Iterate over each VNET
foreach ($vNet in $vNets) {
    # Iterate over each subnet in the current VNET
    foreach ($subnet in $vNet.Subnets) {
        # Check if the current subnet is one of the target subnets
        if ($targetSubnets -contains $subnet.Name) {
            # If so, attach the NSG to this subnet

            # Update the subnet configuration to include the NSG
            $subnetConfig = Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vNet -Name $subnet.Name `
                            -AddressPrefix $subnet.AddressPrefix -NetworkSecurityGroup $nsg

            # Apply the updated configuration to the VNET
            $vNet | Set-AzVirtualNetwork
            
            Write-Output "Attached NSG $nsgName to subnet $($subnet.Name) in VNET $($vNet.Name)."
        }
    }
}
