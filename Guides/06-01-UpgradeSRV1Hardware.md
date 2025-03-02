# Changing VM Flavor in OpenStack SkyHigh

## Overview
In this guide, you will learn how to change the flavor of a Virtual Machine (srv1) in OpenStack - SkyHigh. This is necessary to ensure adequate resources for installing VEEAM Backup and Replication.

### Current Configuration
- Virtual Machine: srv1
- Current Flavor: gx1.2c4r (2 CPU, 4GB RAM)
- Target Flavor: gx3.4c8r (4 CPU, 8GB RAM)

## Prerequisites
- Access to OpenStack SkyHigh dashboard
- The virtual machine (srv1) must be shut down before changing the flavor

## Step-by-Step Instructions

### 1. Prepare the Virtual Machine
1. Log in to OpenStack SkyHigh dashboard
2. Locate srv1 in your list of instances
3. If the VM is running, perform a graceful shutdown (or shutdown from Remote Desktop):
   - Select srv1
   - Click on the "Shut Off Instance" option
   - Wait for the status to show as "Shutoff"

![alt text](shutdown.png)

### 2. Change the Flavor
1. With srv1 shut down (NB! You need to wait for the OS to shut down, refresh page to verify that it is off):
   - From the dropdown menu of "srv1", select "Resize Instance"
2. In the Resize Instance dialog:
   - Select the new flavor "gx3.4c8r" from the flavor list
   - Verify the new specifications (4 CPU, 8GB RAM)
   - Click "Resize"

![alt text](resize-vm.png)

### 3. Confirm the Resize
1. Once the resize operation completes:
   - The status will change to "Verify Resize/Migrate"
   - Click "Confirm Resize/Migrate"
2. Wait for the operation to complete
   - Status should return to "Shutoff"


### 4. Start the Virtual Machine
1. Start srv1:
   - Select the instance
   - Click "Start Instance"
2. Verify the new configuration:
   - Check the instance details
   - Confirm new flavor shows as gx3.4c8r


## Next Steps
With the proper resources now allocated, you can proceed with the installation of VEEAM Backup and Replication.
