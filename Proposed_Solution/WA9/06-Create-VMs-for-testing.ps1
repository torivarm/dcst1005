


function New-AzurePublicIPs {
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable[]]$publicIPconfigs
    )

    foreach ($config in $publicIPconfigs) {
        try {
            # Attempt to create the Public IP Address
            $publicIP = New-AzPublicIpAddress -Name $config.Name `
                                              -ResourceGroupName $config.ResourceGroupName `
                                              -Location $config.Location `
                                              -AllocationMethod $config.AllocationMethod `
                                              -ErrorAction Stop
            Write-Output "Successfully created Public IP Address: $($publicIP.Name) in $($publicIP.Location)"
        }
        catch {
            Write-Error "Failed to create Public IP Address: $($config.Name). Error: $_"
        }
    }
}


# Variables
$prefix = "tim"
$resourceGroupName = "$prefix-rg-vm-001"
$location = "uksouth"

# Create Resource Group for VMs


# Variables for VMs
$vmName1 = "$prefix-vm-mgmt-prod-uk-001"
$vmName2 = "$prefix-vm-web-prod-uk-001"
$vmName3 = "$prefix-vm-hr-prod-uk-001"
$vmName4 = "$prefix-vm-hrdev-dev-uk-001"

$vmSize = 'Standard_B1s'
$adminUsername = 'tim'
$adminPassword = 'SDfsgl!_DFahS24!fsdf'
$secureAdminPassword = ConvertTo-SecureString -String $adminPassword -AsPlainText -Force
$image = 'debian-11'

$publicIPName1 = "$prefix-pip-mgmt-prod-uk-001"
$publicIPName2 = "$prefix-pip-web-prod-uk-001"
$publicIPName3 = "$prefix-pip-hr-prod-uk-001"
$publicIPName4 = "$prefix-pip-hrdev-dev-uk-001"


    

# Public IP configurations
$publicIPconfigs = @( 
    @{
        Name = $publicIPName1
        ResourceGroupName = $resourceGroupName
        Location = $location
        AllocationMethod = 'Static'
    }, 
    @{
        Name = $publicIPName2
        ResourceGroupName = $resourceGroupName
        Location = $location
        AllocationMethod = 'Static'
    }, 
    @{
        Name = $publicIPName3
        ResourceGroupName = $resourceGroupName
        Location = $location
        AllocationMethod = 'Static'
    }, 
    @{
        Name = $publicIPName4
        ResourceGroupName = $resourceGroupName
        Location = $location
        AllocationMethod = 'Static'
    }
)

# Call the function to create the Public IPs
New-AzurePublicIPs -publicIPconfigs $publicIPconfigs

# Create NICs
$nic1 = @{
    Name = $vmName1 + '-nic'
    ResourceGroupName = $resourceGroupName
    Location = $location
    PublicIpAddress = $pip1
    Subnet = $subnet1
}

$nic2 = @{
    Name = $vmName2 + '-nic'
    ResourceGroupName = $resourceGroupName
    Location = $location
    PublicIpAddress = $pip2
    Subnet = $subnet2
}

$nic1 = New-AzNetworkInterface @nic1
$nic2 = New-AzNetworkInterface @nic2


# Create VMs configuration
$vmConfig1 = New-AzVMConfig -VMName $vmName1 -VMSize $vmSize |
            Set-AzVMOperatingSystem -Linux `
            -ComputerName $vmName1 `
            -Credential (New-Object System.Management.Automation.PSCredential ($adminUsername, $secureAdminPassword)) |
            Set-AzVMSourceImage -PublisherName "Debian" -Offer "debian-11" -Skus "11" -Version "latest" |
            Add-AzVMNetworkInterface -Id $nic1.Id

$vmConfig2 = New-AzVMConfig -VMName $vmName2 -VMSize $vmSize |
            Set-AzVMOperatingSystem -Linux `
            -ComputerName $vmName2 `
            -Credential (New-Object System.Management.Automation.PSCredential ($adminUsername, $secureAdminPassword)) |
            Set-AzVMSourceImage -PublisherName "Debian" -Offer $image -Skus "11" -Version "latest" |
            Add-AzVMNetworkInterface -Id $nic2.Id


# Create VMs

New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig1 -asJob
New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig2 -asJob

Invoke-AzVMRunCommand `
   -ResourceGroupName $resourceGroupName `
   -Name $vmName1 `
   -CommandId 'RunShellScript' `
   -ScriptString 'sudo apt-get update && sudo apt-get install -y nginx'

Get-AzPublicIpAddress -Name $publicIPName1 -ResourceGroupName $resourceGroupName | Select-Object "IpAddress"