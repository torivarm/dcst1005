$rootpath = "C:\git-projects\dcst1005\dcst1005"
$DC1 = "DC1"
$services = @("NTDS", "DNS", "Kdc", "DFSR", "Netlogon")

# Script block to check and start services
$scriptBlock = {
    param($services)
    $result = foreach ($service in $services) {
        try {
            $svc = Get-Service -Name $service -ErrorAction Stop
            if ($svc.Status -ne 'Running') {
                Start-Service $service
                Start-Sleep -Seconds 2 # Wait a bit to check the status again
                $svc.Refresh()
                if ($svc.Status -ne 'Running') {
                    throw "Failed to start."
                } else {
                    "$service started successfully."
                }
            } else {
                "$service is running."
            }
        } catch {
            "$service could not be started. Error: $_"
        }
    }
    $result
}

# Invoke the command on the domain controller
$results = Invoke-Command -ComputerName $DC1 -ScriptBlock $scriptBlock -ArgumentList (,$services)

# Generate HTML content
$html = "<html><body><h1>Service Status Report for $DC1</h1><table border='1'><tr><th>Service</th><th>Status</th></tr>"
foreach ($result in $results) {
    # Split the result to separate the service name from its status message
    $serviceName = $result.Split(' ')[0]
    $statusMessage = $result -replace $serviceName, '' # Remove the service name from the status message
    
    if ($result -match "successfully|running") {
        $html += "<tr><td>$serviceName</td><td><font color='green'>$statusMessage</font></td></tr>"
    } else {
        $html += "<tr><td>$serviceName</td><td><font color='red'>$statusMessage</font></td></tr>"
    }
}
$html += "</table></body></html>"

# Specify the path where the HTML file will be saved
$filePath = "$rootpath\serviceStatusReport.html"

# Save the HTML content to a file
$html | Out-File -FilePath $filePath

# Output the path to the HTML report
Write-Host "Service status report saved to: $filePath"


$session = New-PSSession -ComputerName srv1
Copy-Item -Path "C:\git-projects\dcst1005\dcst1005\serviceStatusReport.html" -Destination "C:\inetpub\wwwroot" -ToSession $session
Invoke-Command -Session $session -ScriptBlock {
}
Invoke-Command -Session $session -ScriptBlock { $PSVersionTable }