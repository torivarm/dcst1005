# Define the prefix to search for VMs
$prefix = "tim"

# Retrieve all VMs in the subscription
$vms = Get-AzVM | Where-Object { $_.Name -like "$prefix*" }

# Loop through each VM found
foreach ($vm in $vms) {
    # Get the primary NIC of the VM
    $nic = Get-AzNetworkInterface -ResourceId $vm.NetworkProfile.NetworkInterfaces[0].Id

    # Attempt to retrieve the public IP address associated with the NIC
    $publicIP = $null
    if ($nic.IpConfigurations[0].PublicIpAddress) {
        $publicIpId = $nic.IpConfigurations[0].PublicIpAddress.Id
        $publicIP = Get-AzPublicIpAddress -Name ($publicIpId.Split('/')[-1]) -ResourceGroupName $nic.ResourceGroupName
    }

    # Output VM name, Public IP Address, and Subnet
    $output = @{
        VMName = $vm.Name
        PublicIPAddress = if ($publicIP) { $publicIP.IpAddress } else { "None" }
        Subnet = $nic.IpConfigurations[0].Subnet.Id.Split('/')[-1] # Extract the subnet name
    }

    # Display the information
    $outputObj = New-Object -TypeName PSObject -Property $output
    Write-Output $outputObj
}
