# THIS POWERSHELL COMMAND MUST BE RUN ON THE DC1 SERVER
# Set-NetFirewallRule -Name "RemoteEventLogSvc-In-TCP" -Enabled True


$ClientMachines = "Cl1", "DC1", "SRV1", "mgr" # Add your client machine names here
$ScriptBlock = {
    # This is the same script block you'd use for a single machine, focusing on Event ID 4625
    Get-WinEvent -FilterHashtable @{
        LogName='Security';
        ID=4625;
    } -MaxEvents 10 | ForEach-Object {
        [PSCustomObject]@{
            TimeCreated = $_.TimeCreated
            EventID = $_.Id
            UserName = $_.Properties[5].Value
            LogonType = $_.Properties[8].Value
            IPAddress = $_.Properties[19].Value
            LogonProcess = $_.Properties[11].Value
        }
    }
}

foreach ($Client in $ClientMachines) {
    Write-Host "Querying $Client for non-successful logon events..."
    Invoke-Command -ComputerName $Client -ScriptBlock $ScriptBlock -ErrorAction SilentlyContinue | Format-Table -AutoSize
    Write-Host "-------------------------------------------------------------"
}

