# Windows DFS Installation and Configuration Guide

## Installing Windows Features Remotely

To install the required Windows Features on SRV1 from MGR, use the following PowerShell command:

```powershell
Invoke-Command -ComputerName srv1 -ScriptBlock {
    Install-WindowsFeature -Name FS-DFS-Namespace, FS-DFS-Replication, RSAT-DFS-Mgmt-Con
}
```

## Verify Installation

To verify the features are installed correctly, run:

```powershell
Invoke-Command -ComputerName srv1 -ScriptBlock {
    Get-WindowsFeature | Where-Object {$_.Name -in ('FS-DFS-Namespace','FS-DFS-Replication','RSAT-DFS-Mgmt-Con')}
}
```

## Creating Required Folders and New DFSN Root 

Create the main directories:

```powershell
Invoke-Command -ComputerName srv1 -ScriptBlock {
    New-Item -Path "C:\dfsroots" -ItemType Directory -Force
    New-Item -Path "C:\shares" -ItemType Directory -Force
    
    # Create department folders
    $departments = @('Finance','Sales','IT','Consultants','HR')
    foreach ($dept in $departments) {
        New-Item -Path "C:\shares\$dept" -ItemType Directory -Force
    }
    
    # Create files folder under dfsroots
    New-Item -Path "C:\dfsroots\files" -ItemType Directory -Force
}
```

# Creating DFS Namespace Structure

## Create DFS Namespace Root

First, create the DFS Namespace root: (make sure to edit the domain name, if you don't have the same name)

```powershell
Invoke-Command -ComputerName srv1 -ScriptBlock {
    # Create new DFS namespace
    New-DfsnRoot -TargetPath "\\srv1\files" `
                 -Path "\\InfraIT.sec\files" `
                 -Type DomainV2 `
                 -GrantAdminAccounts "infrait\Domain Admins"
}
```

## Create DFS Folders (Links)

Then create the department folders in the namespace:

```powershell
Invoke-Command -ComputerName srv1 -ScriptBlock {
    # Create DFS folders for each department
    $departments = @('Finance','Sales','IT','Consultants','HR')
    foreach ($dept in $departments) {
        New-DfsnFolder -Path "\\domain.com\files\$dept" `
                      -TargetPath "\\srv1\$dept" `
                      -EnableTargetFailback $true
    }
}
```

## Verify DFS Namespace Configuration

To verify the DFS namespace configuration:

```powershell
Invoke-Command -ComputerName srv1 -ScriptBlock {
    # Verify DFS root
    Get-DfsnRoot -Path "\\domain.com\files"

    # Verify DFS folders
    Get-DfsnFolder -Path "\\domain.com\files\*" | 
    Format-Table Path,TargetPath,State -AutoSize
}
```

Important Notes:
1. Replace "domain.com" with your actual domain name
2. The MGR machine must have the RSAT-DFS-Mgmt-Con feature installed to manage DFS remotely
3. The account running these commands needs appropriate permissions (Domain Admin or delegated DFS admin rights)
4. The DFS namespace server (srv1) must be a domain member
5. DNS must be properly configured in your domain for DFS to work

To verify access, users can now access their department shares through either:
- Direct path: `\\srv1\department`
- DFS path: `\\domain.com\files\department`


## Creating SMB Shares

Create SMB shares for all folders with Everyone having Full Access:

```powershell
Invoke-Command -ComputerName srv1 -ScriptBlock {
    # Share department folders
    $departments = @('Finance','Sales','IT','Consultants','HR')
    foreach ($dept in $departments) {
        New-SmbShare -Name $dept -Path "C:\shares\$dept" -FullAccess "Everyone"
    }
    
    # Share DFS root folder
    New-SmbShare -Name "files" -Path "C:\dfsroots\files" -FullAccess "Everyone"
}
```

## Required Active Directory Groups

The following local groups should be created in Active Directory:

- l_fullAccess-hr-share
- l_fullAccess-it-share
- l_fullAccess-sales-share
- l_fullAccess-finance-share
- l_fullAccess-consultants-share

Important Note: Each department's global group (containing all users from that department) should be made a member of their respective local full access group. For example, the global group "g__all_hr" should be a member of "l_fullAccess-hr-share".

After creating these groups, you should configure the appropriate NTFS permissions on each share to restrict access to only the relevant local group, replacing the initial "Everyone" Full Access permissions used during setup.

Would you like me to provide additional information about configuring the NTFS permissions or setting up the DFS namespaces?