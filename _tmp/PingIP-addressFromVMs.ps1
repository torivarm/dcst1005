# Variables
$prefix = 'demo'
$resourceGroupName = $prefix + '-rg-vm-001'

$targetIP = "129.241.160.102"    # IP address to ping

# VM names array
$vmNames = @(
    #"${prefix}-vm-hr-prod-uk-001",
    #"${prefix}-vm-hrdev-dev-uk-001",
    "${prefix}-vm-web-prod-uk-001",
    "${prefix}-vm-mgmt-prod-uk-001"
)

# Loop through each VM and perform a ping test
foreach ($vmName in $vmNames) {
    Write-Host "Pinging from $vmName"
    $pingResults = Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName `
                                        -Name $vmName `
                                        -CommandId 'RunShellScript' `
                                        -ScriptString "ping -c 4 $targetIP"
    
    # Output the results
    $pingResults.Value.Message
}
