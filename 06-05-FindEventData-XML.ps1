$faildLogon = Get-WinEvent -FilterHashtable @{
    LogName ='Security'
    ID = 4625
}


# Get the last 10 failed logon events and then parse the XML to get the data
$events = Get-WinEvent -FilterHashtable @{
    LogName='Security';
    ID=4625;
} -MaxEvents 10 | ForEach-Object { [xml]$_.ToXml() }


foreach ($event in $events) {
    $eventData = $event.Event.EventData.Data
    $output = New-Object PSObject
    foreach ($data in $eventData) {
        $name = $data.Name
        $value = $data.'#text'
        Add-Member -InputObject $output -MemberType NoteProperty -Name $name -Value $value
    }
    $output
}



# Find the user name of the failed logon
$faildLogon | ForEach-Object {
    $event = [xml]$_.ToXml()
    $event.Event.EventData.Data | ForEach-Object {
        if ($_.Name -eq 'TargetUserName') {
            $_.'#text'
        }
    }
}



