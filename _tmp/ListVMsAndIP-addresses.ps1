# This script lists all VMs with a prefix and shows their IP addresses.

$prefix = 'demo'
$resourceGroupName = $prefix + '-rg-vm-001'

$vms = Get-AzVM -ResourceGroupName $resourceGroupName

foreach ($vm in $vms) {
    $nic = Get-AzNetworkInterface -ResourceId $vm.NetworkProfile.NetworkInterfaces[0].Id
    $ipConfig = $nic.IpConfigurations[0]
    $ipAddress = $ipConfig.PrivateIpAddress
    Write-Output "VM: $($vm.Name), IP Address: $ipAddress"
}

