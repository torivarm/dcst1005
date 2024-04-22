# In this script we will create VMs in the different subnets in the VNET named $prefix-vnet-web-shared-uk-001.
# The VMs will be placed in the resource group $prefix-rg-vm-001.
# The VMs will be named the same as the subnet they are placed in.
# The VMs will only gave private IP address.

# Variables
# Variables
$prefix = "demo"
$resourceGroupName = "$prefix-rg-vm-001"
$location = "uksouth"
$resourceGroupNameVNET = "$prefix-rg-network-001"

function New-AzureVMNICs {
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable[]]$nicConfigurations
    )

    foreach ($config in $nicConfigurations) {
        try {
            # Attempt to retrieve the VNet that contains the target subnet
            $subnet = $null
            $vNets = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupNameVNET
            foreach ($vNet in $vNets) {
                $subnet = $vNet.Subnets | Where-Object { $_.Name -eq $config.Subnet }
                if ($subnet) {
                    break
                }
            }

            if (-not $subnet) {
                Write-Error "Subnet $($config.Subnet) not found."
                continue
            }

            # Create the NIC and attach to Subnet
            $nic = New-AzNetworkInterface -Name $config.Name `
                                          -ResourceGroupName $config.ResourceGroupName `
                                          -Location $config.Location `
                                          -SubnetId $subnet.Id `
                                          -ErrorAction Stop
            Write-Output "Successfully created NIC: $($nic.Name) in $($nic.Location)"
        }
        catch {
            Write-Error "Failed to create NIC: $($config.Name). Error: $_"
        }
    }
}

function New-AzureVMs {
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable[]]$vmConfigurations
    )

    foreach ($config in $vmConfigurations) {
        # Retrieve the NIC for the VM
        $nic = Get-AzNetworkInterface -Name $config.NicName -ResourceGroupName $config.ResourceGroupName
        if (-not $nic) {
            Write-Error "NIC $($config.NicName) not found."
            continue
        }

        # Define the VM configuration
        try {
            # Create VM configuration
            $vmConfig = New-AzVMConfig -VMName $config.VMName -VMSize $config.VMSize
            $vmConfig = Set-AzVMOperatingSystem -VM $vmConfig -Linux -ComputerName $config.VMName -Credential $config.Credential
            $vmConfig = Set-AzVMSourceImage -VM $vmConfig -PublisherName $config.ImagePublisher -Offer $config.ImageOffer -Skus $config.ImageSku -Version $config.ImageVersion
            $vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id

            # Create the VM
            New-AzVM -ResourceGroupName $config.ResourceGroupName -Location $config.Location -VM $vmConfig -AsJob -Verbose
            Write-Output "Successfully created VM: $($config.VMName)"
        }
        catch {
            Write-Error "Failed to create VM: $($config.VMName). Error: $_"
        }
    }
}

# Variables for VMs
$vmName1 = "$prefix-vm-web-prod-uk-001"
$vmName2 = "$prefix-vm-app-prod-uk-001"
$vmName3 = "$prefix-vm-db-prod-uk-001"



# VM configurations - Change username and password
$vmSize = 'Standard_B1s'
$adminUsername = 'tim'
$adminPassword = 'SDfsgl!_DFahS24!fsdf'
$secureAdminPassword = ConvertTo-SecureString -String $adminPassword -AsPlainText -Force
$image = 'debian-11'


# Subnet names
$subnetName1 = "$prefix-snet-web-prod-uk-001"
$subnetName2 = "$prefix-snet-app-prod-uk-001"
$subnetName3 = "$prefix-snet-db-prod-uk-001"


# NIC configurations
$nicConfigurations = @(
    @{
        Name = $vmName1 + '-nic'
        ResourceGroupName = $resourceGroupName
        Location = $location
        Subnet = $subnetName1
    },
    @{
        Name = $vmName2 + '-nic'
        ResourceGroupName = $resourceGroupName
        Location = $location
        Subnet = $subnetName2
    },
    @{
        Name = $vmName3 + '-nic'
        ResourceGroupName = $resourceGroupName
        Location = $location
        Subnet = $subnetName3
    }
)
