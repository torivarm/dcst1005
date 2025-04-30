# Azure Kubernetes and Table Storage Lab Guide

This comprehensive guide will walk you through creating a containerized web application that interacts with Azure Table Storage and deploying it to Azure Kubernetes Service (AKS), all using Azure Cloud Shell.

## Lab Overview

You will build a simple web application that displays and manages employee data stored in Azure Table Storage. The app will be containerized and deployed to Azure Kubernetes Service. This lab demonstrates several key cloud concepts:

- Azure Table Storage for NoSQL data storage
- Containerization using Azure Container Registry (ACR) Tasks
- Container orchestration with Azure Kubernetes Service (AKS)
- Kubernetes concepts: Deployments, Services, and Secrets

## Prerequisites

- Azure subscription with contributor access
- Basic familiarity with Azure portal
- Basic understanding of command-line interfaces

## Part 1: Setting Up Azure Resources

### Step 1: Open Azure Cloud Shell

1. Go to [Azure Portal](https://portal.azure.com)
2. Click the Cloud Shell icon in the top navigation bar
3. Choose Bash as your shell environment

### Step 2: Set Up Environment Variables

```bash
# Set variables for resource names
INITIALS="demo" # <-- PUT YOUR OWN INITIALS OR UNIQUE SUFFIX
RESOURCE_GROUP="rg-aks-lab-$INITIALS"
LOCATION="norwayeast"
ACR_NAME="studentsacr$RANDOM"  # Ensures unique name
AKS_CLUSTER="students-aks-$INITIALS"
STORAGE_ACCOUNT="studentstg$RANDOM"  # Ensures unique name
TABLE_NAME="employees"
```

### Step 3: Create Resource Group

```bash
# Create a resource group
az group create --name $RESOURCE_GROUP --location $LOCATION
```

### Step 4: Create Azure Container Registry

```bash
# Create container registry
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic

# Get ACR login server
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer --output tsv)
echo "Container registry created: $ACR_LOGIN_SERVER"
```

### Step 5: Create Azure Storage Account and Table

```bash
# Create storage account
az storage account create --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --location $LOCATION --sku Standard_LRS

# Get storage account key
STORAGE_KEY=$(az storage account keys list --account-name $STORAGE_ACCOUNT --query "[0].value" -o tsv)

# Create table
az storage table create --name $TABLE_NAME --account-name $STORAGE_ACCOUNT --account-key $STORAGE_KEY

echo "Storage account: $STORAGE_ACCOUNT"
echo "Table name: $TABLE_NAME"
```

### Step 6: Create AKS Cluster

```bash
# Create AKS cluster
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER \
    --node-count 1 \
    --enable-addons monitoring \
    --generate-ssh-keys \
    --attach-acr $ACR_NAME

# Get AKS credentials
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER

echo "AKS cluster created: $AKS_CLUSTER"
```

## Part 2: Creating the Application

### Step 1: Create Project Directory

```bash
# Create project directory
mkdir -p azure-table-frontend/views
cd azure-table-frontend
```

### Step 2: Create package.json

```bash
cat > package.json << 'EOF'
{
  "name": "azure-table-frontend",
  "version": "1.0.0",
  "description": "Frontend application for Azure Table Storage",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  },
  "dependencies": {
    "@azure/data-tables": "^13.2.1",
    "dotenv": "^16.0.3",
    "ejs": "^3.1.9",
    "express": "^4.18.2"
  }
}
EOF
```

### Step 3: Create app.js

```bash
cat > app.js << 'EOF'
// app.js - Express application to interact with Azure Table Storage
const express = require('express');
const { TableClient, AzureNamedKeyCredential } = require('@azure/data-tables');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static('public'));
app.set('view engine', 'ejs');

// Azure Table Storage configuration
const accountName = process.env.AZURE_STORAGE_ACCOUNT_NAME;
const accountKey = process.env.AZURE_STORAGE_ACCOUNT_KEY;
const tableName = process.env.AZURE_STORAGE_TABLE_NAME || 'employees';

const credential = new AzureNamedKeyCredential(accountName, accountKey);
const tableClient = new TableClient(
  `https://${accountName}.table.core.windows.net`,
  tableName,
  credential
);

// Routes
app.get('/', async (req, res) => {
  try {
    // Fetch entities from table storage
    const entities = [];
    const iterator = tableClient.listEntities();
    for await (const entity of iterator) {
      entities.push(entity);
    }
    
    res.render('index', { entities });
  } catch (error) {
    console.error('Error fetching entities:', error);
    res.status(500).send('Error fetching data');
  }
});

// Add new entity
app.post('/add', async (req, res) => {
  try {
    const { firstName, lastName, department, jobTitle, email, salary } = req.body;
    const entity = {
      partitionKey: department,
      rowKey: `${firstName.substr(0,1)}${lastName.substr(0,1)}${Date.now()}`,
      firstName,
      lastName,
      department,
      jobTitle,
      email,
      salary: parseInt(salary) || 0
    };
    
    await tableClient.createEntity(entity);
    res.redirect('/');
  } catch (error) {
    console.error('Error creating entity:', error);
    res.status(500).send('Error adding data');
  }
});

// Delete entity
app.post('/delete', async (req, res) => {
  try {
    const { partitionKey, rowKey } = req.body;
    await tableClient.deleteEntity(partitionKey, rowKey);
    res.redirect('/');
  } catch (error) {
    console.error('Error deleting entity:', error);
    res.status(500).send('Error deleting data');
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
EOF
```

### Step 4: Create views/index.ejs

```bash
mkdir -p views
cat > views/index.ejs << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Employee Management</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { padding-top: 2rem; }
        .container { max-width: 900px; }
        .header { margin-bottom: 2rem; text-align: center; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Employee Management</h1>
            <p class="lead">Azure Table Storage + Kubernetes Demo</p>
        </div>

        <div class="card mb-4">
            <div class="card-header">
                Add New Employee
            </div>
            <div class="card-body">
                <form action="/add" method="POST">
                    <div class="row mb-3">
                        <div class="col">
                            <label for="firstName" class="form-label">First Name</label>
                            <input type="text" class="form-control" id="firstName" name="firstName" required>
                        </div>
                        <div class="col">
                            <label for="lastName" class="form-label">Last Name</label>
                            <input type="text" class="form-control" id="lastName" name="lastName" required>
                        </div>
                    </div>
                    <div class="row mb-3">
                        <div class="col">
                            <label for="department" class="form-label">Department</label>
                            <input type="text" class="form-control" id="department" name="department" required>
                        </div>
                        <div class="col">
                            <label for="jobTitle" class="form-label">Job Title</label>
                            <input type="text" class="form-control" id="jobTitle" name="jobTitle" required>
                        </div>
                    </div>
                    <div class="row mb-3">
                        <div class="col">
                            <label for="email" class="form-label">Email</label>
                            <input type="email" class="form-control" id="email" name="email" required>
                        </div>
                        <div class="col">
                            <label for="salary" class="form-label">Salary</label>
                            <input type="number" class="form-control" id="salary" name="salary" required>
                        </div>
                    </div>
                    <button type="submit" class="btn btn-primary">Add Employee</button>
                </form>
            </div>
        </div>

        <div class="card">
            <div class="card-header">
                Employee List
            </div>
            <div class="card-body">
                <% if (entities && entities.length > 0) { %>
                    <table class="table table-striped">
                        <thead>
                            <tr>
                                <th>First Name</th>
                                <th>Last Name</th>
                                <th>Department</th>
                                <th>Job Title</th>
                                <th>Email</th>
                                <th>Salary</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% entities.forEach(entity => { %>
                                <tr>
                                    <td><%= entity.firstName %></td>
                                    <td><%= entity.lastName %></td>
                                    <td><%= entity.department %></td>
                                    <td><%= entity.jobTitle %></td>
                                    <td><%= entity.email %></td>
                                    <td><%= entity.salary %></td>
                                    <td>
                                        <form action="/delete" method="POST" style="display: inline;">
                                            <input type="hidden" name="partitionKey" value="<%= entity.partitionKey %>">
                                            <input type="hidden" name="rowKey" value="<%= entity.rowKey %>">
                                            <button type="submit" class="btn btn-sm btn-danger">Delete</button>
                                        </form>
                                    </td>
                                </tr>
                            <% }); %>
                        </tbody>
                    </table>
                <% } else { %>
                    <div class="alert alert-info">No employees found in the table.</div>
                <% } %>
            </div>
        </div>
    </div>
</body>
</html>
EOF
```

### Step 5: Create .env file

```bash
cat > .env << EOF
# Azure Storage Configuration
AZURE_STORAGE_ACCOUNT_NAME=$STORAGE_ACCOUNT
AZURE_STORAGE_ACCOUNT_KEY=$STORAGE_KEY
AZURE_STORAGE_TABLE_NAME=$TABLE_NAME

# App Configuration
PORT=3000
EOF
```

### Step 6: Create Dockerfile

```bash
cat > Dockerfile << 'EOF'
FROM node:16-alpine

WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy application files
COPY . .

# Expose the application port
EXPOSE 3000

# Command to run the application
CMD ["node", "app.js"]
EOF
```

## Part 3: Populating Sample Data

### Step 1: Create a Script to Add Sample Data

```bash
cat > populate-data.sh << 'EOF'
#!/bin/bash
# Set storage account info from environment variables
STORAGE_ACCOUNT=$1
TABLE_NAME=$2
STORAGE_KEY=$3

if [ -z "$STORAGE_ACCOUNT" ] || [ -z "$TABLE_NAME" ] || [ -z "$STORAGE_KEY" ]; then
  echo "Usage: $0 <storage-account-name> <table-name> <storage-account-key>"
  exit 1
fi

# Function to add an employee
add_employee() {
  local department=$1
  local emp_id=$2
  local first_name=$3
  local last_name=$4
  local email=$5
  local job_title=$6
  local salary=$7

  echo "Adding employee: $first_name $last_name..."
  
  az storage entity insert \
    --entity PartitionKey=$department RowKey=$emp_id \
    firstName=$first_name \
    lastName=$last_name \
    email=$email \
    department=$department \
    jobTitle="$job_title" \
    salary=$salary \
    --table-name $TABLE_NAME \
    --account-name $STORAGE_ACCOUNT \
    --account-key $STORAGE_KEY
}

# Add dummy employee data
echo "Adding sample employee data..."

# Employee 1
add_employee \
  "Engineering" \
  "E001" \
  "John" \
  "Smith" \
  "john.smith@example.com" \
  "Senior_Software_Engineer" \
  95000

# Employee 2
add_employee \
  "Marketing" \
  "M001" \
  "Emily" \
  "Davis" \
  "emily.davis@example.com" \
  "Marketing_Specialist" \
  78000

# Employee 3
add_employee \
  "HR" \
  "H001" \
  "Michael" \
  "Brown" \
  "michael.brown@example.com" \
  "HR_Director" \
  110000

# Employee 4
add_employee \
  "Engineering" \
  "E002" \
  "Sarah" \
  "Johnson" \
  "sarah.johnson@example.com" \
  "Engineering_Manager" \
  125000

# Employee 5
add_employee \
  "Finance" \
  "F001" \
  "David" \
  "Wilson" \
  "david.wilson@example.com" \
  "Financial_Analyst" \
  85000

echo "Successfully added sample employees to the '$TABLE_NAME' table."
EOF

chmod +x populate-data.sh
```

### Step 2: Run the Script to Add Sample Data

```bash
./populate-data.sh $STORAGE_ACCOUNT $TABLE_NAME $STORAGE_KEY
```

## Part 4: Building and Deploying the Application

### Step 1: Build the Container Image Using ACR Tasks

```bash
# Build the container image directly in Azure
az acr build --registry $ACR_NAME --image azure-table-frontend:latest .
```

### Step 2: Create Kubernetes Deployment Manifest

```bash
cat > kubernetes-manifests.yaml << EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: azure-table-frontend
  labels:
    app: azure-table-frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: azure-table-frontend
  template:
    metadata:
      labels:
        app: azure-table-frontend
    spec:
      containers:
      - name: azure-table-frontend
        image: ${ACR_LOGIN_SERVER}/azure-table-frontend:latest
        ports:
        - containerPort: 3000
        env:
        - name: AZURE_STORAGE_ACCOUNT_NAME
          valueFrom:
            secretKeyRef:
              name: azure-storage-credentials
              key: account-name
        - name: AZURE_STORAGE_ACCOUNT_KEY
          valueFrom:
            secretKeyRef:
              name: azure-storage-credentials
              key: account-key
        - name: AZURE_STORAGE_TABLE_NAME
          value: "${TABLE_NAME}"
---
apiVersion: v1
kind: Service
metadata:
  name: azure-table-frontend
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 3000
  selector:
    app: azure-table-frontend
EOF
```

### Step 3: Create Kubernetes Secret for Storage Credentials

```bash
# Create a Kubernetes secret for the storage credentials
kubectl create secret generic azure-storage-credentials \
  --from-literal=account-name=$STORAGE_ACCOUNT \
  --from-literal=account-key=$STORAGE_KEY
```

### Step 4: Deploy Application to Kubernetes

```bash
# Apply the Kubernetes configuration
kubectl apply -f kubernetes-manifests.yaml

# Check the deployment status
kubectl get deployments
kubectl get pods
```

### Step 5: Access the Application

```bash
# Get the service's external IP address
kubectl get service azure-table-frontend --watch
```

Wait until an external IP address is assigned. Once you have the IP address, you can access the application by navigating to `http://<EXTERNAL-IP>` in your web browser.

## Part 5: Exploring the Application

1. **View employees**: The application displays all employees from the Azure Table Storage
2. **Add new employees**: Fill out the form to add a new employee to the table
3. **Delete employees**: Use the delete button to remove employees from the table

## Part 6: Understanding the Architecture

This lab demonstrates several important cloud computing concepts:

1. **Serverless storage**: Azure Table Storage provides a scalable NoSQL datastore without managing servers
2. **Container builds in the cloud**: Using ACR Tasks to build containers without Docker installed locally
3. **Container orchestration**: Kubernetes manages container deployment, scaling, and networking
4. **Secret management**: Sensitive information (storage credentials) is securely stored in Kubernetes secrets
5. **Load balancing**: Kubernetes service exposes the application and load balances traffic across pods

## Part 7: Cleanup Resources

When you're done with the lab, clean up your resources to avoid unnecessary charges:

```bash
# Delete the lab resources
az group delete --name $RESOURCE_GROUP --yes --no-wait
```