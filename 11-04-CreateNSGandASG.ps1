# In this script we will create Application Security Groups (ASGs) and Network Security Groups (NSGs) 
# for the subnets in the VNET named demo-vnet-web-shared-uk-001.

# Variables
$prefix = "demo"
$resourceGroupName = "$prefix-rg-network-001"
$vnetName = "$prefix-vnet-web-shared-uk-001"
$location = "uksouth"

# Define the names of subnets
$subnets = @{
    "Web" = "$prefix-snet-web-prod-uk-001"
    "App" = "$prefix-snet-app-prod-uk-001"
    "Db" = "$prefix-snet-db-prod-uk-001"
}

# Define the names of VMs
$vms = @{
    "Web" = "$prefix-vm-web-prod-uk-001"
    "App" = "$prefix-vm-app-prod-uk-001"
    "Db" = "$prefix-vm-db-prod-uk-001"
}

# Function to create an ASG if it does not exist
function Create-ASGIfNotExists {
    param($asgName, $location)
    $asg = Get-AzApplicationSecurityGroup -Name $asgName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
    if (-not $asg) {
        try {
            $asg = New-AzApplicationSecurityGroup -Name $asgName -ResourceGroupName $resourceGroupName -Location $location
            Write-Host "Created ASG: $asgName"
        } catch {
            Write-Error "Failed to create ASG: $asgName. Error: $_"
        }
    } else {
        Write-Host "ASG already exists: $asgName"
    }
    return $asg.Id
}


# Function to create and configure NSG rules
function Create-AndConfigure-NSG {
    param($nsgName, $location, $allowSubnetName, $targetSubnet)
    $nsg = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
    if (-not $nsg) {
        try {
            $nsg = New-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroupName -Location $location
            $ruleName = "Allow" + $allowSubnetName + "To" + $targetSubnet
            $priority = 111
            Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $ruleName -Direction Inbound -Priority $priority `
                -SourceAddressPrefix $asgIds[$allowSubnetName] -SourcePortRange "*" -DestinationAddressPrefix $asgIds[$targetSubnet] `
                -DestinationPortRange "*" -Access Allow -Protocol Tcp -Description "Allow $allowSubnetName to $targetSubnet"
            Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsg
            Write-Host "Configured NSG: $nsgName with rule $ruleName"
        } catch {
            Write-Error "Failed to create or configure NSG: $nsgName. Error: $_"
        }
    } else {
        Write-Host "NSG already exists: $nsgName"
    }
}

# Main logic
$asgIds = @{}
foreach ($tier in $subnets.GetEnumerator()) {
    $asgName = $tier.Name + "ASG" + $prefix
    $asgIds[$tier.Name] = Create-ASGIfNotExists -asgName $asgName -location "UK South"
}

foreach ($tier in $subnets.GetEnumerator()) {
    $nsgName = $tier.Name + "NSG" + $prefix
    if ($tier.Name -eq "Web") {
        Create-AndConfigure-NSG -nsgName $nsgName -location "UK South" -allowSubnetName "Web" -targetSubnet "App"
    }
    elseif ($tier.Name -eq "App") {
        Create-AndConfigure-NSG -nsgName $nsgName -location "UK South" -allowSubnetName "App" -targetSubnet "Db"
    }
}
