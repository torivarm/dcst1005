$rootpath = "C:\git-projects\dcst1005\dcst1005"


$scriptBlock = {
    # Capturing performance data
    $data = @()
    $data += Get-Counter '\Processor(_Total)\% Processor Time' | ForEach-Object { $_.CounterSamples }
    $data += Get-Counter '\Memory\% Committed Bytes In Use' | ForEach-Object { $_.CounterSamples }
    $data += Get-Counter '\Memory\Available MBytes' | ForEach-Object { $_.CounterSamples }
    $data
}

# Duration and interval settings
$duration = 2 #24 * 60 # 24 hours in minutes
$interval = 1 # Interval in seconds
$startTime = Get-Date

# Loop to collect data every interval for the duration of 24 hours
$results = while ((New-TimeSpan -Start $startTime).TotalMinutes -lt $duration) {
    Invoke-Command -ComputerName dc1 -ScriptBlock $scriptBlock
    Start-Sleep -Seconds ($interval)
}

$html = @"
<html>
<head>
    <title>Performance Report</title>
</head>
<body>
    <h1>Performance Report</h1>
    <table border="1">
        <tr>
            <th>Time</th>
            <th>Counter</th>
            <th>Value</th>
        </tr>
"@

foreach ($result in $results) {
    foreach ($sample in $result) {
        $html += @"
        <tr>
            <td>$($sample.Timestamp)</td>
            <td>$($sample.Path)</td>
            <td>$($sample.CookedValue)</td>
        </tr>
"@
    }
}

$html += @"
    </table>
</body>
</html>
"@

# Save HTML to file
"performanceReport.html"
$html | Out-File -FilePath "$rootpath\performanceReport.html" -Force





