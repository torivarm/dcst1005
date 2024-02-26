## Monitoring DC1 Active Directory Services
<# 

Invoke-Command -ComputerName DC1 -ScriptBlock {
    Get-Service | Select-Object DisplayName, ServiceName, Status | Format-Table -AutoSize
}
#> 
# Use the abouve command to get the list of services running on the DC1 server

$scriptBlock = {
    # Define the service name for Active Directory Domain Services
    $serviceName = "NTDS"

    # Retrieve the current status of the NTDS service
    $serviceStatus = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

    # Check if the service is running
    if ($serviceStatus.Status -ne 'Running') {
        # Attempt to start the service if it is not running
        try {
            Start-Service -Name $serviceName
            Write-Output "The NTDS service was not running and has been started."
        } catch {
            # If an error occurs while starting the service, output the error
            Write-Output "Failed to start the NTDS service. Error: $_"
        }
    } else {
        # If the service is already running, output its status
        Write-Output "The NTDS service is running."
    }
}

Invoke-Command -ComputerName DC1 -ScriptBlock $scriptBlock


