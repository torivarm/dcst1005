# COPY THIS TO SRV1 AND RUN IN POWERSHELL 7.x AS ADMINISTRATOR

$departments = @("HR", "Consultant", "Finance", "IT", "Sales", "Shared")

foreach ($department in $departments) {
    New-DfsReplicationGroup -GroupName "RepGrp$department-Share" 
    Add-DfsrMember -GroupName "RepGrp$department-Share" -ComputerName "srv1","dc1" 
    Add-DfsrConnection -GroupName "RepGrp$department-Share" `
                        -SourceComputerName "srv1" `
                        -DestinationComputerName "dc1" 

    New-DfsReplicatedFolder -GroupName "RepGrp$department-Share" -FolderName "Replica$department-SharedFolder" 

    Set-DfsrMembership -GroupName "RepGrp$department-Share" `
                        -FolderName "Replica$department-SharedFolder" `
                        -ContentPath "C:\shares\$department" `
                        -ComputerName "srv1" `
                        -PrimaryMember $True 

    Set-DfsrMembership -GroupName "RepGrp$department-Share" `
                        -FolderName "Replica$department-SharedFolder" `
                        -ContentPath "c:\dfsreplication\$department" `
                        -ComputerName "dc1" 
}


