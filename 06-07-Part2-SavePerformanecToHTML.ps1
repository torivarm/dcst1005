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
$duration = 10 # 10 minutes 
$interval = 10 # 10 second intervals
$startTime = Get-Date

# Loop to collect data every interval for the duration of 24 hours
$results = while ((New-TimeSpan -Start $startTime).TotalMinutes -lt $duration) {
    Invoke-Command -ComputerName dc1 -ScriptBlock $scriptBlock
    Start-Sleep -Seconds ($interval)
}

<# Sample structure for $results to simulate the actual data collection
$results = @(
    # Processor Time samples
    @{Path='\Processor(_Total)\% Processor Time'; CookedValue=20; Timestamp=(Get-Date).AddSeconds(-90)},
    @{Path='\Memory\% Committed Bytes In Use'; CookedValue=30; Timestamp=(Get-Date).AddSeconds(-90)},
    @{Path='\Memory\Available MBytes'; CookedValue=8000; Timestamp=(Get-Date).AddSeconds(-90)},
)
#>


# Initialize strings to hold formatted data for each metric
$processorTimeDataJS = @()
$committedBytesDataJS = @()
$availableMBytesDataJS = @()

foreach ($sample in $results) {
    $timestamp = $sample.Timestamp.ToString("HH:mm:ss")
    switch -Wildcard ($sample.Path) {
        '*\Processor(_Total)\% Processor Time' {
            $processorTimeDataJS += "[`"$timestamp`", $($sample.CookedValue)]"
        }
        '*\Memory\% Committed Bytes In Use' {
            $committedBytesDataJS += "[`"$timestamp`", $($sample.CookedValue)]"
        }
        '*\Memory\Available MBytes' {
            $availableMBytesDataJS += "[`"$timestamp`", $($sample.CookedValue)]"
        }
    }
}

# Combine into JavaScript arrays
$jsProcessorTimeData = $processorTimeDataJS -join ", "
$jsCommittedBytesData = $committedBytesDataJS -join ", "
$jsAvailableMBytesData = $availableMBytesDataJS -join ", "

# Create the HTML content
$htmlTemplate = @"
<html>
<head>
    <title>Performance Report - DC1</title>
    <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
    <script type="text/javascript">
        google.charts.load('current', {'packages':['corechart']});
        google.charts.setOnLoadCallback(drawCharts);

        function drawCharts() {
            drawChart('processorTime_chart', '% Processor Time', [['Time', 'Processor Time'], PLACEHOLDER_PROCESSOR_TIME_DATA]);
            drawChart('committedBytes_chart', '% Committed Bytes In Use', [['Time', '% Committed Bytes'], PLACEHOLDER_COMMITTED_BYTES_DATA]);
            drawChart('availableMBytes_chart', 'Available MBytes', [['Time', 'Available MBytes'], PLACEHOLDER_AVAILABLE_MBYTES_DATA]);
        }

        function drawChart(elementId, title, dataRows) {
            var data = google.visualization.arrayToDataTable(dataRows);
            var options = {
                title: title,
                curveType: 'function',
                legend: { position: 'bottom' }
            };
            var chart = new google.visualization.LineChart(document.getElementById(elementId));
            chart.draw(data, options);
        }
    </script>
</head>
<body>
    <h2>Performance Report for DC1</h2>
    <div id="processorTime_chart" style="width: 900px; height: 500px"></div>
    <div id="committedBytes_chart" style="width: 900px; height: 500px"></div>
    <div id="availableMBytes_chart" style="width: 900px; height: 500px"></div>
</body>
</html>
"@

# Replace placeholders in the HTML template with the actual data
$htmlContent = $htmlTemplate -replace 'PLACEHOLDER_PROCESSOR_TIME_DATA', $jsProcessorTimeData `
                             -replace 'PLACEHOLDER_COMMITTED_BYTES_DATA', $jsCommittedBytesData `
                             -replace 'PLACEHOLDER_AVAILABLE_MBYTES_DATA', $jsAvailableMBytesData

# Save the modified HTML content to a file
$htmlContent | Out-File -FilePath "$rootpath\performanceReport.html" -Force
