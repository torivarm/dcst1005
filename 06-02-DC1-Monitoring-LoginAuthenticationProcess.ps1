# THIS POWERSHELL COMMAND MUST BE RUN ON THE DC1 SERVER
# Set-NetFirewallRule -Name "RemoteEventLogSvc-In-TCP" -Enabled True


# Define the remote domain controller's name
$DC1 = "DC1"

# Define the number of recent events to retrieve
$NumberOfEvents = 10

# Define event IDs for successful and failed logon attempts
$EventIDs = 4624, 4625

# Retrieve and display the specified number of recent logon events
foreach ($EventID in $EventIDs) {
    Write-Host "Retrieving the last $NumberOfEvents events for Event ID: $EventID" -ForegroundColor Cyan
    Get-WinEvent -ComputerName $DC1 -FilterHashtable @{LogName='Security'; ID=$EventID} -MaxEvents $NumberOfEvents | ForEach-Object {
        $Event = [PSCustomObject]@{
            TimeCreated = $_.TimeCreated
            EventID = $_.Id
            UserName = $_.Properties[5].Value
            LogonType = $_.Properties[8].Value
            IPAddress = $_.Properties[18].Value
            LogonProcess = $_.Properties[11].Value
        }
        Write-Output $Event
    }
    Write-Host "-------------------------------------------------------------" -ForegroundColor Green
}
