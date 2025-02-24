# Installing WSUS on Windows Server 2025 - SRV1

## Prerequisites
- Windows Server 2025 (SRV1)
- Administrator access (administrator@<yourDomain.nn>)
- Minimum 10GB free disk space (40GB recommended)
- TIPS!! RESTART SRV1 to avoid other setups, configurations affecting the WSUS role install

## Step 1: Install Required Server Roles and Features (SRV1)

1. Remember to restart first, my setup got "stuck"
2. Open Server Manager
3. Click "Manage" → "Add Roles and Features"
![alt text](AddRoles.png)
1. Click "Next" until you reach "Server Roles"
2. Select the following roles:
![alt text](WSUSRole.png)
   - Windows Server Update Services - Select WSUS first, then it will automatically select the necessary roles for WSUS.
   - IIS (if not already installed)

1. Choose your installation location for WSUS updates
   - Create a new folder on D:\ -> D:\WSUS 
   - Recommended: Separate volume with sufficient space
![alt text](StoreWSUS.png)

1. Complete the installation wizard
2. Wait for the installation to finish
3. OBS! If it get "stuck", wait a bit longer..
4. Start the post install configuration..
![alt text](done.png)

## Step 2: Post install and Configure WSUS Post-Installation

1. Open Server Manager
![alt text](PostInstall.png)
2. Click on "Tools" → "Windows Server Update Services"
![alt text](WSUSstart.png)
3. The WSUS Configuration Wizard will start automatically
![alt text](WSUSConfiguration.png)

### Initial Configuration Steps:
1. Choose upstream server:
   - Synchronize from Microsoft Update

2. No proxy settings
3. Click "Start Connecting" to test connection
![alt text](StartConnection.png)

4. Choose languages:
   - Select "Download updates only in these languages"
   - Choose required languages: English

5. Choose products to update:
   - Windows Server 2025
   - Windows 11

6. Select update classifications:
   - Critical Updates
   - Security Updates
   - Service Packs
   - Update Rollups
   - Add others based on requirements

7. Configure sync schedule:
   - Recommended: Daily at off-peak hours
   - Initial sync may take several hours

## Step 3: Configure Client-Side Settings

1. Open Group Policy Management Console
2. Create new GPO or edit existing one
3. Navigate to:
   ```
   Computer Configuration\Administrative Templates\Windows Components\Windows Update
   ```

4. Configure these key settings:
   - "Configure Automatic Updates": Enabled
   - "Specify intranet Microsoft update service location": Enabled
     - Set URL to your WSUS server
     - Example: http://wsus-server:8530

5. Set update frequency and behavior:
   - "Auto download and notify for install"
   - Or "Auto download and schedule installation"

6. Link GPO to appropriate OU
7. Force policy update on clients:
   ```powershell
   gpupdate /force
   ```

## Step 4: Verify Installation

1. Check WSUS console:
   - Open WSUS Management Console
   - Verify synchronization status
   - Check for connected clients

2. Monitor client reporting:
   ```powershell
   # On client machine
   wuauclt /detectnow
   wuauclt /reportnow
   ```

3. Verify updates are being offered to clients
4. Check IIS logs for client connections

## Troubleshooting

### Common Issues:
1. Synchronization Failures
   - Check network connectivity
   - Verify proxy settings
   - Review WSUSContent folder permissions

2. Client Connection Issues
   - Verify GPO settings
   - Check client-side Windows Update logs
   - Ensure firewall allows WSUS traffic (Ports 8530/8531)

3. Database Issues
   - Run WSUS Server Cleanup Wizard
   - Check SQL Server connectivity
   - Monitor database growth

### Maintenance Tasks:
1. Regular cleanup:
   ```powershell
   # Run WSUS cleanup wizard monthly
   Get-WsusServer | Invoke-WsusServerCleanup -CleanupObsoleteUpdates
   ```

2. Monitor disk space usage
3. Review and decline superseded updates
4. Check for failed client installations

## Best Practices

1. Regular Maintenance:
   - Run Server Cleanup Wizard monthly
   - Monitor database size
   - Review and approve updates weekly

2. Security:
   - Use SSL for WSUS traffic
   - Implement role-based access control
   - Regular backup of WSUS database

3. Performance:
   - Store updates on separate volume
   - Configure IIS application pool recycling
   - Implement automatic cleanup procedures

## Additional Resources

- Microsoft WSUS Documentation
- Windows Server Update Services Best Practices
- Group Policy Settings Reference

## Support

For additional support:
1. Check Windows Server logs
2. Review IIS logs
3. Contact your system administrator
4. Reference Microsoft TechNet forums