$rootfolder = "C:\git-projects\dcst1005\dcst1005"

# Define the counters you want to measure
$counters = @(
    "\Processor(_Total)\% Processor Time",
    "\Memory\% Committed Bytes In Use",
    "\Memory\Available MBytes"

)

# Collect the counter data
$counterData = Get-Counter -Counter $counters

# Export the counter data to a CSV file
$counterData.CounterSamples | Select-Object Path, CookedValue, Timestamp | Export-Csv -Path "$rootfolder\output.csv" -NoTypeInformation
