# This script attaches a NSG to appropriate subnets in the virtual networks created in 01-CreateVNET-and-subnet.ps1.
# This is the following subnets from the previous script:
# Subnets: 
# - $prefix-snet-mgmt-prod-uk-001
# - $prefix-snet-web-prod-uk-001
# - $prefix-snet-hrweb-prod-uk-001
# - $prefix-snet-hrweb-dev-uk-001

# Variables
$prefix = "tim"
$nsgName = "$prefix-nsg-port80-22"
$resourceGroupName = "$prefix-rg-network-001"
$location = "uksouth"

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
