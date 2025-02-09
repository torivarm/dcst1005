Get-WinEvent -ListLog *



Get-WinEvent -LogName Application
Get-WinEvent -LogName Security

Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4625}

