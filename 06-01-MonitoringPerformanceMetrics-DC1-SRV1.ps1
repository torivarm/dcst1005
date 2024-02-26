$scriptblock = { 
    # Processor Total
    Get-Counter '\Processor(_Total)\% Processor Time' | ForEach-Object { $_.CounterSamples }

    # Memory Total and Available (in MB)
    Get-Counter '\Memory\% Committed Bytes In Use' | ForEach-Object { $_.CounterSamples }
    Get-Counter '\Memory\Available MBytes' | ForEach-Object { $_.CounterSamples }
}

Invoke-Command -ComputerName dc1,srv1 -ScriptBlock $scriptblock | ForEach-Object {
    # Displaying the results
    Write-Host "Counter: $($_.Path)"
    Write-Host "Value: $($_.CookedValue)"
    Write-Host "---------------------------"
}
