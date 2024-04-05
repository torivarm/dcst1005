# In this script, we will create Virtual Machines in different subnets in the same VNET, 
# and different VNETs in the same Resource Group. Then we are going to see how the trafic
# flows between the VMs in the same VNET and different VNETs.
# We need the Az module to create the resources in Azure.
# Install-Module -Name Az -AllowClobber -Scope CurrentUser

# Import the Az module
# Import-Module Az



# Variables
$tenantID = "bd0944c8-c04e-466a-9729-d7086d13a653" # Remember to change this to your own TenantID
$subscrptionID = "41082359-57d6-4427-b5d9-21e269157652" # Remember to change this to your own SubscriptionID

# Connect to Azure
Connect-AzAccount -Tenant $tenantID -Subscription $subscrptionID


<# Check the available VM images for a specific location and publisher
$location="uksouth"
$pubName="Debian"
Get-AzVMImageOffer -Location $location -PublisherName $pubName | Select-Object Offer
$offerName="debian-11"
Get-AzVMImageSku -Location $locName -PublisherName $pubName -Offer $offerName | Select-Object Skus
$skuName="11"
Get-AzVMImage -Location $locName -PublisherName $pubName -Offer $offerName -Sku $skuName | Select-Object Version
#>




# Variables for VMs
$prefix = 'tim'
$rgName = $prefix + '-rg-powershelldemo-001'
$location = 'uksouth'
$vnetName1 = $prefix + '-vnet-powershelldemo-001'
$vnetName2 = $prefix + '-vnet-powershelldemo-002'
$subnetName1 = $prefix + '-snet-powershelldemo-001'
$subnetName2 = $prefix + '-snet-powershelldemo-002'
$vmName1 = $prefix + '-vm-powershelldemo-001'
$publicIPName1 = $prefix + '-pip-powershelldemo-001'
$publicIPName2 = $prefix + '-pip-powershelldemo-002'
$vmName2 = $prefix + '-vm-powershelldemo-002'
$vmSize = 'Standard_B1s'
$adminUsername = 'tim'
$adminPassword = 'SDfsgl!_DFahS24!fsdf'
$secureAdminPassword = ConvertTo-SecureString -String $adminPassword -AsPlainText -Force
$image = 'debian-11'



# Check if Resource Group, VNETs and Subnets exists
$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
$vnet1 = Get-AzVirtualNetwork -Name $vnetName1 -ResourceGroupName $rgName -ErrorAction SilentlyContinue
$vnet2 = Get-AzVirtualNetwork -Name $vnetName2 -ResourceGroupName $rgName -ErrorAction SilentlyContinue
# If vnet is null, drop subnet check
if (!$vnet1 -eq $null -or !$vnet2 -eq $null) {
    $subnet1 = Get-AzVirtualNetworkSubnetConfig -Name $subnetName1 -VirtualNetwork $vnet1 -ErrorAction SilentlyContinue
    $subnet2 = Get-AzVirtualNetworkSubnetConfig -Name $subnetName2 -VirtualNetwork $vnet2 -ErrorAction SilentlyContinue
}

# If $rg is null then create the Resource Group
if ($rg -eq $null) {
    New-AzResourceGroup -Name $rgName -Location $location
}
    

# Create Public IPs
$publicIP1 = @{
    Name = $publicIPName1
    ResourceGroupName = $rgName
    Location = $location
    AllocationMethod = 'Static'
}

$publicIP2 = @{
    Name = $publicIPName2
    ResourceGroupName = $rgName
    Location = $location
    AllocationMethod = 'Static'
}

$pip1 = New-AzPublicIpAddress @publicIP1
$pip2 = New-AzPublicIpAddress @publicIP2

# Create NICs
$nic1 = @{
    Name = $vmName1 + '-nic'
    ResourceGroupName = $rgName
    Location = $location
    PublicIpAddress = $pip1
    Subnet = $subnet1
}

$nic2 = @{
    Name = $vmName2 + '-nic'
    ResourceGroupName = $rgName
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

New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig1 -asJob
New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig2 -asJob

Invoke-AzVMRunCommand `
   -ResourceGroupName $rgName `
   -Name $vmName1 `
   -CommandId 'RunShellScript' `
   -ScriptString 'sudo apt-get update && sudo apt-get install -y nginx'

Get-AzPublicIpAddress -Name $publicIPName1 -ResourceGroupName $rgName | Select-Object "IpAddress"