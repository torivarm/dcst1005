# In this script, I will install NGINX on a VM (demo-vm-web-prod-uk-001) in the spoke VNET named demo-vnet-web-shared-uk-001.

# Variables
$prefix = 'demo'
$resourceGroupName = $prefix + '-rg-vm-001'
$location = 'uksouth'
$vmName = "$prefix-vm-web-prod-uk-001"

# Get the VM
"Getting the VM..."
try {
    $vm = Get-AzVM -Name $vmName -ResourceGroupName $resourceGroupName
    $vm.Name
}
catch {
    Write-Error "VM '$vmName' not found. Please create the VM or check the name."
    exit
}

# Install NGINX
"Installing NGINX on the VM..."
$script = "sudo apt-get update -y && sudo apt-get install -y nginx"

try {
    $installNGINX = Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -Name $vmName -CommandId 'RunShellScript' -ScriptString $script
    $installNGINX.Value.Message
}
catch {
    Write-Error "Failed to install NGINX on the VM."
    exit
}