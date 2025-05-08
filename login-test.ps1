# Define the variables required to connect
$tenantId = "f5d7ff48-e4cf-4114-ab5b-1a930c176f9d"
$spPassword = "OVs8Q~cM7h0rkB1_lYAXmQTCEP3wWWZ_P6YZ5bcR"
$servicePrincipalAppID = "b1b6e2c6-9de4-4ef6-bb3c-184bec578514" # This is the Application ID

# Convert the Service Principal secret to secure string
$password = ConvertTo-SecureString $spPassword -AsPlainText -Force

# Create a new credentials object containing the application ID and password that will be used to authenticate
$psCredentials = New-Object System.Management.Automation.PSCredential ($servicePrincipalAppID, $password)

# Authenticate with the credentials object
Connect-AzAccount -ServicePrincipal -Credential $psCredentials -Tenant $tenantId
