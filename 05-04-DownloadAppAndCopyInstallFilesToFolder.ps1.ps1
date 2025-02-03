# Define the URL of the file to download
$fileURL = "https://www.7-zip.org/a/7z2409-x64.msi"

# Define the path to save the file
$destinationPath = "C:\shares\installfiles\7z2409-x64.msi"

# Define the remote server name
$remoteServerName = "srv1"

# Script block to download the file
$scriptBlock = {
    param($fileURL, $destinationPath)

    # Use invoke-webrequest to download the file
    Invoke-WebRequest -Uri $fileURL -OutFile $destinationPath
    Write-Host "File downloaded to $destinationPath"
}

# Execute the script block on the remote server
Invoke-Command -ComputerName $remoteServerName -ScriptBlock $scriptBlock -ArgumentList $fileURL, $destinationPath