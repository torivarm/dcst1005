# Define the URL of the file to download
$fileUrl = "https://www.7-zip.org/a/7z2401-x64.msi"

# Define the destination path on the remote server
$destinationPath = "C:\shares\installfiles\7z2401-x64.msi"

# Define the remote server name
$remoteServerName = "srv1"

# Script block to download the file
$scriptBlock = {
    param($fileUrl, $destinationPath)
    
    # Use Invoke-WebRequest to download the file
    Invoke-WebRequest -Uri $fileUrl -OutFile $destinationPath
    Write-Host "File downloaded to $destinationPath"
}

# Execute the script block on the remote server
Invoke-Command -ComputerName $remoteServerName -ScriptBlock $scriptBlock -ArgumentList $fileUrl, $destinationPath
