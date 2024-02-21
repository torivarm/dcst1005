Get-EventLog Security -InstanceId 4625 -Newest 50
Get-EventLog Security | Where-Object {$_.EventID -eq 4720 -or $_.EventID -eq 4726 -or $_.EventID -eq 4738}
Get-Counter '\Processor(_Total)\% Processor Time', '\Memory\Available MBytes'
Get-PSDrive C | Select-Object Used, Free
Get-Counter '\Network Interface(*)\Bytes Total/sec'
Get-EventLog -LogName System -EntryType Error, Warning -Newest 50
Get-WindowsUpdateLog

