# In this script we will create two ASGs and assume they could be attached to VMs or NICs in the future.
# $prefix-vnet-web-shared-uk-001. The ASGs will be named $prefix-ASG-App and $prefix-ASG-DB.

# Variables
$prefix = "demo"
$resourceGroupName = "$prefix-rg-network-001"
$location = "uksouth"

$asg1Name = "$prefix-ASG-App"
$asg2Name = "$prefix-ASG-DB"

# Create ASG1
# Check if ASG exists, if not, create it
$asgcheck = Get-AzApplicationSecurityGroup -Name $asg1Name -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
if (-not $asgcheck) {
    Write-Host "Creating ASG $asg1Name..." -ForegroundColor Green
    $asg1 = New-AzApplicationSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $asg1Name
}
else {
    Write-Host "ASG $asg1Name already exists."
}

# Create ASG2
# Check if ASG exists, if not, create it
$asgcheck = Get-AzApplicationSecurityGroup -Name $asg2Name -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
if (-not $asgcheck) {
    Write-Host "Creating ASG $asg2Name..." -ForegroundColor Green
    $asg2 = New-AzApplicationSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $asg2Name
}
else {
    Write-Host "ASG $asg2Name already exists."
}

# Adding VMs to the ASGs
# Variables
$resourceGroupNameVM = $prefix + '-rg-vm-001'
$vmName1 = "$prefix-vm-app-prod-uk-001"
$vmName2 = "$prefix-vm-db-prod-uk-001"

# Get the VMs
"Getting the VMs..."
try {
    $vm1 = Get-AzVM -Name $vmName1 -ResourceGroupName $resourceGroupNameVM
    $vm1.Name
}
catch {
    Write-Error "VM '$vmName1' not found. Please create the VM or check the name."
    exit
}

try {
    $vm2 = Get-AzVM -Name $vmName2 -ResourceGroupName $resourceGroupNameVM
    $vm2.Name
}
catch {
    Write-Error "VM '$vmName2' not found. Please create the VM or check the name."
    exit
}

# Add the VMs to the ASGs
"Adding the VMs to the ASGs..."
$vm1 = Add-AzVMApplicationSecurityGroup -VM $vm1 -ApplicationSecurityGroup $asg1
$vm2 = Add-AzVMApplicationSecurityGroup -VM $vm2 -ApplicationSecurityGroup $asg2


# Output the configuration for verification
Get-AzApplicationSecurityGroup -ResourceGroupName $resourceGroupName

