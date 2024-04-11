# This script creates four VMs in Azure using the Az module.
# The script defines three functions: New-AzurePublicIPs, New-AzureVMNICs, and New-AzureVMs.
# The New-AzurePublicIPs function creates public IP addresses.
# The New-AzureVMNICs function creates network interfaces (NICs) with associated public IP addresses and subnets.
# The New-AzureVMs function creates VMs with the specified NICs.

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
$vmName1 = "$prefix-vm-mgmt-prod-uk-001"
$vmName2 = "$prefix-vm-web-prod-uk-001"
$vmName3 = "$prefix-vm-hr-prod-uk-001"
$vmName4 = "$prefix-vm-hrdev-dev-uk-001"

# VM configurations - Change username and password
$vmSize = 'Standard_B1s'
$adminUsername = 'tim'
$adminPassword = 'SDfsgl!_DFahS24!fsdf'
$secureAdminPassword = ConvertTo-SecureString -String $adminPassword -AsPlainText -Force
$image = 'debian-11'

# pip names
$publicIPName1 = "$prefix-pip-mgmt-prod-uk-001"
$publicIPName2 = "$prefix-pip-web-prod-uk-001"
$publicIPName3 = "$prefix-pip-hr-prod-uk-001"
$publicIPName4 = "$prefix-pip-hrdev-dev-uk-001"

# Subnet names
$subnetName1 = "$prefix-snet-mgmt-prod-uk-001"
$subnetName2 = "$prefix-snet-web-prod-uk-001"
$subnetName3 = "$prefix-snet-hrweb-prod-uk-001"
$subnetName4 = "$prefix-snet-hrweb-dev-uk-001"


    
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
    },
    @{
        Name = $vmName4 + '-nic'
        ResourceGroupName = $resourceGroupName
        Location = $location
        Subnet = $subnetName4
    }
)

# Example VM configuration
$vmConfigurations = @(
    @{
        VMName = $vmName1
        NicName = "$vmName1-nic"
        ResourceGroupName = $resourceGroupName
        Location = $location
        VMSize = $vmSize
        Credential = (New-Object System.Management.Automation.PSCredential ($adminUsername, $secureAdminPassword))
        ImagePublisher = "debian"
        ImageOffer = $image
        ImageSku = "11"
        ImageVersion = "latest"
    },
    @{
        VMName = $vmName2
        NicName = "$vmName2-nic"
        ResourceGroupName = $resourceGroupName
        Location = $location
        VMSize = $vmSize
        Credential = (New-Object System.Management.Automation.PSCredential ($adminUsername, $secureAdminPassword))
        ImagePublisher = "debian"
        ImageOffer = $image
        ImageSku = "11"
        ImageVersion = "latest"
    },
    @{
        VMName = $vmName3
        NicName = "$vmName3-nic"
        ResourceGroupName = $resourceGroupName
        Location = $location
        VMSize = $vmSize
        Credential = (New-Object System.Management.Automation.PSCredential ($adminUsername, $secureAdminPassword))
        ImagePublisher = "debian"
        ImageOffer = $image
        ImageSku = "11"
        ImageVersion = "latest"
    },
    @{
        VMName = $vmName4
        NicName = "$vmName4-nic"
        ResourceGroupName = $resourceGroupName
        Location = $location
        VMSize = $vmSize
        Credential = (New-Object System.Management.Automation.PSCredential ($adminUsername, $secureAdminPassword))
        ImagePublisher = "debian"
        ImageOffer = $image
        ImageSku = "11"
        ImageVersion = "latest"
    }
)


# Call the funtion to create the NICs
New-AzureVMNICs -nicConfigurations $nicConfigurations
Start-Sleep -Seconds 30

# Call the function to create the VM(s)
New-AzureVMs -vmConfigurations $vmConfigurations
Start-Sleep -Seconds 480

