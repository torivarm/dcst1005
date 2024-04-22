# Variables
$prefix = 'demo'
$resourceGroupName = $prefix + '-rg-network-001'
$resourceGroupNameVM = $prefix + '-rg-vm-001'
$location = 'uksouth'

# Gets all resources in two resources groups based on its $prefix
$resources = Get-AzResource -ResourceGroupName $resourceGroupName
$resourcesVM = Get-AzResource -ResourceGroupName $resourceGroupNameVM

# List all resources in the network resource group
# Gets the name of all VNETs, its subnets and the address prefix
# Gets the name of all NSGs and its rules and which subnets they are associated with
# Gets the name of all ASGs and associated nics


# Gets all resources in two resources groups based on its $prefix
$resources = Get-AzResource -ResourceGroupName $resourceGroupName
$resourcesVM = Get-AzResource -ResourceGroupName $resourceGroupNameVM

# List all resources in the network resource group
# Gets the name of all VNETs, its subnets, and the address prefix
$vnetDetails = $resources | Where-Object ResourceType -EQ "Microsoft.Network/virtualNetworks" | ForEach-Object {
    $vnet = Get-AzVirtualNetwork -Name $_.Name -ResourceGroupName $_.ResourceGroupName
    $subnets = $vnet.Subnets | ForEach-Object {
        @{
            SubnetName = $_.Name
            AddressPrefix = $_.AddressPrefix
        }
    }
    @{
        VNETName = $vnet.Name
        Subnets = $subnets
    }
}

# Gets the name of all NSGs and its rules and which subnets they are associated with
$nsgDetails = $resources | Where-Object ResourceType -EQ "Microsoft.Network/networkSecurityGroups" | ForEach-Object {
    $nsg = Get-AzNetworkSecurityGroup -Name $_.Name -ResourceGroupName $_.ResourceGroupName
    $rules = $nsg.SecurityRules | ForEach-Object {
        @{
            RuleName = $_.Name
            Access = $_.Access
            Direction = $_.Direction
            Priority = $_.Priority
            SourceAddressPrefix = $_.SourceAddressPrefix
            DestinationAddressPrefix = $_.DestinationAddressPrefix
            SourcePortRange = $_.SourcePortRange
            DestinationPortRange = $_.DestinationPortRange
            Protocol = $_.Protocol
        }
    }
    @{
        NSGName = $nsg.Name
        Rules = $rules
    }
}


# Gets the name of all ASGs and associated NICs
# Gets the name of all ASGs and associated NICs
$asgDetails = $resources | Where-Object ResourceType -EQ "Microsoft.Network/applicationSecurityGroups" | ForEach-Object {
    $asg = Get-AzApplicationSecurityGroup -Name $_.Name -ResourceGroupName $_.ResourceGroupName

    # Get all network interfaces in the same resource group as ASG
    $allNics = Get-AzNetworkInterface -ResourceGroupName $_.ResourceGroupName

    # Filter NICs associated with the current ASG
    $associatedNics = $allNics | Where-Object {
        $_.IpConfigurations.ApplicationSecurityGroups.Id -contains $asg.Id
    } | ForEach-Object {
        @{
            NicName = $_.Name
        }
    }

    @{
        ASGName = $asg.Name
        AssociatedNICs = $associatedNics
    }
}

# Output the details
$vnetDetails
$nsgDetails
$asgDetails
