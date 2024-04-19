# In this script, we will configure the Azure Firewall created in 11-01-Create-AzFirewall.ps1 to allow from VMs in the spoke VNETs to the internet.
# This is done by creating a network default route for the spoke VNETs to the Azure Firewall.
# We will also configure the firewall to allow traffic from Internet to a VM with a web server in the spoke VNET: $PREFIX-vnet-web-shared-uk-001

# Variables
$prefix = 'demo'
$resourceGroupName = $prefix + '-rg-network-001'
$location = 'uksouth'
$vnetNameHUB = "$prefix-vnet-hub-shared-uk"
$fwName = "$prefix-Azfw"
$spokeVNET1 = "$prefix-vnet-web-shared-uk-001"

# VM
$resourceGroupNameVM = $prefix + '-rg-vm-001'
$vmName = "$prefix-vm-web-prod-uk-001"

# Get the Azure Firewall
"Getting the Azure Firewall..."
try {
    $fw = Get-AzFirewall -Name $fwName -ResourceGroupName $resourceGroupName
    $fw.Name
}
catch {
    Write-Error "Azure Firewall '$fwName' not found. Please create the Azure Firewall or check the name."
    exit
}

# Get the spoke VNETs
"Getting the spoke VNETs..."
try {
    $vnet1 = Get-AzVirtualNetwork -Name $spokeVNET1 -ResourceGroupName $resourceGroupName
    $vnet1.Name
}
catch {
    Write-Error "VNET '$spokeVNET1' not found. Please create the VNET or check the name."
    exit
}

# Get the VM
"Getting the VM..."
try {
    $vm = Get-AzVM -Name $vmName -ResourceGroupName $resourceGroupNameVM
    $vm.Name
}
catch {
    Write-Error "VM '$vmName' not found. Please create the VM or check the name."
    exit
}

# Create a network rule collection
