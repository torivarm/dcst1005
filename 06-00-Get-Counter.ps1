Get-Counter -ListSet *
Get-Counter -ListSet * | Select-Object -ExpandProperty CounterSetName

Get-Counter -ListSet * | Where-Object {$_.CounterSetName -like "*Processor*"} | Select-Object -ExpandProperty CounterSetName
Get-Counter -ListSet * | Where-Object {$_.CounterSetName -like "*Memory*"} | Select-Object -ExpandProperty CounterSetName

# Gets all the counters for the Processor object
Get-Counter -ListSet Processor | Select-Object -ExpandProperty Counter
Get-Counter -Counter "\Processor(*)\% Processor Time" -SampleInterval 2 -MaxSamples 10


Get-Counter -ListSet * | Where-Object {$_.CounterSetName -like "*Disk*"} | Select-Object -ExpandProperty CounterSetName
Get-Counter -ListSet PhysicalDisk | Select-Object -ExpandProperty Counter

