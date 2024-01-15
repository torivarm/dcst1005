# REMEMER TO READ THE COMMENTS - THIS IS NOT A SCRIPT TO RUN FROM START TO END :) 
# This commands are used to find the commands that are related to Active Directory
Get-Command -Module ActiveDirectory | Where-Object {$_.name -like "*user*"}
Get-Command -Module ActiveDirectory | Where-Object {$_.name -like "*group*"}
Get-Command -Module ActiveDirectory | Where-Object {$_.name -like "*OrganizationalUnit*"}

#############################################################################
#                                                                           #
#     I denne gjennomgangen skal vi gjøre følgende fra MGR:                 #
#       1. Opprette OU-struktur i AD for brukere, maskiner og grupper       #
#       2. Opprette grupper som skal representere en eksempelbedrift        #
#       3. Opprette brukere som skal:                                       #
#             - Plasseres i ønsket OU                                       #
#             - Meldes inn i tiltenkt gruppe for tilganger                  #
#             - Sørge for at de for logget seg inn på ønsket maskin (cl1)   #
#                                                                           #
#                                                                           #
#                                                                           #
#                                                                           #
#############################################################################

New-ADOrganizationalUnit "TestOU" `
            -Description "TEst for å sjekk at cmdlet fungerer" `
            -ProtectedFromAccidentalDeletion:$false
Get-ADOrganizationalUnit -Filter * | Select-Object name
Get-Help Remove-ADOrganizationalUnit -Online
Get-ADOrganizationalUnit -Filter * | Where-Object {$_.name -eq "TestOU"} | Remove-ADOrganizationalUnit -Recursive -Confirm:$false

# Eksempelbedrift - LearnIT - MERK!!! Video brukt i 2023, navn vil variere fra tidligere gjennomgang
# HUSK Å TA STILLING TIL HVOR DU VIL LAGRE OU-ER, GRUPPER OG BRUKERE OG NAVN DERE BRUKER
$lit_users = "LearnIT_Users"
$lit_groups = "LearnIT_Groups"
$lit_computers = "LearnIT_Computers"

$topOUs = @($lit_users,$lit_groups,$lit_computers )
$departments = @('hr','it','dev','sale','finance')

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

# Opprette grupper
# ----Group Structure----- #

# Finne ut hvilke kommandoer som er tilgjengelig for å opprette grupper - ONLINE
Get-Help New-ADGroup -Online

New-ADGroup -Name "g_TestGruppe" `
            -SamAccountName g_TestGruppe `
            -GroupCategory Security `
            -GroupScope Global `
            -DisplayName "Test" `
            -Path "CN=Users,DC=core,DC=sec" `
            -Description "Test"

foreach ($department in $departments) {
    $path = Get-ADOrganizationalUnit -Filter * | 
            Where-Object {($_.name -eq "$department") `
            -and ($_.DistinguishedName -like "OU=$department,OU=$lit_groups,*")}
    New-ADGroup -Name "g_$department" `
                -SamAccountName "g_$department" `
                -GroupCategory Security `
                -GroupScope Global `
                -DisplayName "g_$department" `
                -Path $path.DistinguishedName `
                -Description "$department group"
}

New-ADGroup -name "g_all_employee" `
            -SamAccountName "g_all_employee" `
            -GroupCategory Security `
            -GroupScope Global `
            -DisplayName "g_all_employee" `
            -path "OU=LearnIT_Groups,DC=core,DC=sec" `
            -Description "all employee"


# ----Create Users ----- #
<#
The easy way or the "hard" way? (advanced - AD liker ikke æ,ø,å. Kanskje en også bør ha en navnestandard? 
Easy way - Brukere uten noen særnorske tegn og ingen vasking av input data
#>

Get-Help New-AdUSer -Online

$password = Read-Host -Prompt "EnterPassword" -AsSecureString
New-ADUser -Name "Hans Hansen" `
            -GivenName "Hans" `
            -Surname "Hansen" `
            -SamAccountName  "hhansen" `
            -UserPrincipalName  "hhansen@core.sec" `
            -Path "OU=IT,OU=LearnIT_Users,DC=core,DC=sec" `
            -AccountPassword $Password `
            -Enabled $true

# HUSK å vis til egen csv fil med brukere (-path viser her en type windows-path)
$users = Import-Csv -Path 'C:\WRITE-YOUR-OWN-PATH!!!!!\02-01-Users.csv' -Delimiter ";"

foreach ($user in $users) {
    New-ADUser -Name $user.DisplayName `
                -GivenName $user.GivenName `
                -Surname $user.Surname `
                -SamAccountName  $user.username `
                -UserPrincipalName  $user.UserPrincipalName `
                -Path $user.path `
                -AccountPassword (convertto-securestring $user.password -AsPlainText -Force) `
                -Department $user.department `
                -Enabled $true
            }

# Legger til brukere i grupper basert på avdeling (department)
$ADUsers = @()

foreach ($department in $departments) {
    $ADUsers = Get-ADUser -Filter {Department -eq $department} -Properties Department
    #Write-Host "$ADUsers som er funnet under $department"

    foreach ($aduser in $ADUsers) {
        Add-ADPrincipalGroupMembership -Identity $aduser.SamAccountName -MemberOf "g_$department"
    }

}


# ---- Move Computer to correct OU ---- #
Get-ADComputer -Filter * | ft
Move-ADObject -Identity "CN=mgr,CN=Computers,DC=core,DC=sec" `
            -TargetPath "OU=it,OU=LearnIT_Computers,DC=core,DC=sec"

New-ADOrganizationalUnit "Servers" `
                -Description "OU for Servers" `
                -Path "OU=LearnIT_Computers,DC=core,DC=sec" `
                -ProtectedFromAccidentalDeletion:$false
