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

## Creating Required Folders

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

Important Note: Each department's global group (containing all users from that department) should be made a member of their respective local full access group. For example, the global group "g_hr_users" should be a member of "l_fullAccess-hr-share".

After creating these groups, you should configure the appropriate NTFS permissions on each share to restrict access to only the relevant local group, replacing the initial "Everyone" Full Access permissions used during setup.

Would you like me to provide additional information about configuring the NTFS permissions or setting up the DFS namespaces?