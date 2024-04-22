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



