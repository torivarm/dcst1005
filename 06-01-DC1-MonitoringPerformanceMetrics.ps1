# Define the remote domain controller's name
$DC1 = "DC1"

# Define the list of performance counters to monitor
$PerformanceCounters = @(
    "\Processor(_Total)\% Processor Time", # CPU usage
    "\Memory\Available MBytes", # Available memory
    "\PhysicalDisk(_Total)\Disk Reads/sec", # Disk read operations per second
    "\PhysicalDisk(_Total)\Disk Writes/sec", # Disk write operations per second
    "\Network Interface(*)\Bytes Total/sec" # Network bandwidth usage
)

# Loop through each counter and retrieve the values
foreach ($Counter in $PerformanceCounters) {
    try {
        $CounterData = Get-Counter -Counter $Counter -ComputerName $DC1 -ErrorAction Stop
        foreach ($Value in $CounterData.CounterSamples) {
            Write-Output "$($Value.Path): $($Value.CookedValue)"
        }
    } catch {
        Write-Error "Failed to retrieve data for counter '$Counter' on $DC1. Error: $_"
    }
}
