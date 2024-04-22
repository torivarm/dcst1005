# In this script we will create two ASGs and assume they could be attached to VMs or NICs in the future.
# $prefix-vnet-web-shared-uk-001. The ASGs will be named $prefix-ASG-App and $prefix-ASG-DB.

# Variables
$prefix = "demo"
$resourceGroupName = "$prefix-rg-network-001"
$location = "uksouth"

$asg1Name = "$prefix-ASG-App"
$asg2Name = "$prefix-ASG-DB"
$asg3Name = "$prefix-ASG-Web"

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

# Create ASG3
# Check if ASG exists, if not, create it
$asgcheck = Get-AzApplicationSecurityGroup -Name $asg3Name -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
if (-not $asgcheck) {
    Write-Host "Creating ASG $asg3Name..." -ForegroundColor Green
    $asg3 = New-AzApplicationSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $asg3Name
}
else {
    Write-Host "ASG $asg3Name already exists."
}
