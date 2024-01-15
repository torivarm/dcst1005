New-ADOrganizationalUnit "TestOU" `
            -Description "TEst for å sjekk at cmdlet fungerer" `
            -ProtectedFromAccidentalDeletion:$false

Get-ADOrganizationalUnit -Filter * | ft

Get-ADOrganizationalUnit -Filter * | Where-Object {$_.name -eq "TestOU"} | ft







$testtall = @("1","2","3")

foreach ($tall in $testtall)
    {
        Write-Host $tall
    }







$infrait_users = "InfraIT_Users"
$infrait_groups = "InfraIT_Groups"
$infrait_computers = "InfraIT_Computers"

$topOUs = @($infrait_users,$infrait_groups,$infrait_computers )
$departments = @('hr','it','consultat','sale','finance')

foreach ($ou in $topOUs) {
    New-ADOrganizationalUnit $ou -Description "Top OU for LearnIT" -ProtectedFromAccidentalDeletion:$false
    $topOU = Get-ADOrganizationalUnit -Filter * | Where-Object {$_.name -eq "$ou"}
    #Get-ADOrganizationalUnit -Filter * | Where-Object {$_.name -eq $ou} | Remove-ADOrganizationalUnit -Recursive -Confirm:$false
        foreach ($department in $departments) {
            New-ADOrganizationalUnit $department `
                        -Path $topOU.DistinguishedName `
                        -Description "Deparment OU for $department in topOU $topOU" `
                        -ProtectedFromAccidentalDeletion:$false
        }
}