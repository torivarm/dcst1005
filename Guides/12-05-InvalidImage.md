# Lab 12-05: Feilsøking og gjenoppretting

Denne guiden dekker to vanlige situasjoner i Lab 12-02: gjenoppretting av Cloud Shell-variabler etter en ny sesjon, og feilsøking av `InvalidImage`-feil ved deployment av applikasjonen.

---

## Del 1 — Ny Cloud Shell-sesjon

Alle shell-variabler forsvinner når Cloud Shell-sesjonen avsluttes eller timeout oppstår. Filer i hjemmekatalogen (`~/`) overlever derimot, slik at `~/infraitsec-app/` med applikasjonsfilene og `kubernetes-manifest.yaml` er intakte.

Kjør følgende blokk ved starten av en ny sesjon for å gjenopprette alle nødvendige variabler:

### Steg 1.1 — Gjenopprett variabler

```bash
PREFIX="<prefix>"   # <-- ENDRE TIL DITT EGET PREFIKS
LOCATION="norwayeast"
RG_NETWORK="${PREFIX}-rg-infraitsec-network"
RG_COMPUTE="${PREFIX}-rg-infraitsec-compute"
AKS_CLUSTER="${PREFIX}-aks-infraitsec"
ACR_NAME="${PREFIX}acrinfraisec"
VNET_NAME="${PREFIX}-vnet-spoke"
SUBNET_NAME="${PREFIX}-snet-aks"
STORAGE_ACCOUNT="${PREFIX}stginfraisec"
TABLE_NAME="employees"
PEERING_NAME="${PREFIX}-peer-spoke-to-hub"

ACR_LOGIN_SERVER=$(az acr show \
    --name $ACR_NAME \
    --query loginServer \
    --output tsv)

STORAGE_KEY=$(az storage account keys list \
    --account-name $STORAGE_ACCOUNT \
    --query "[0].value" \
    --output tsv)

AKS_SUBNET_ID=$(az network vnet subnet show \
    --resource-group $RG_NETWORK \
    --vnet-name $VNET_NAME \
    --name $SUBNET_NAME \
    --query id \
    --output tsv)

AKS_CONTROL_PLANE_IDENTITY=$(az aks show \
    --resource-group $RG_COMPUTE \
    --name $AKS_CLUSTER \
    --query identity.principalId \
    --output tsv)

az aks get-credentials \
    --resource-group $RG_COMPUTE \
    --name $AKS_CLUSTER

echo "ACR Login Server : $ACR_LOGIN_SERVER"
echo "Storage Account  : $STORAGE_ACCOUNT"
echo "AKS Subnet ID    : $AKS_SUBNET_ID"
echo "Control Plane ID : $AKS_CONTROL_PLANE_IDENTITY"
```

Verifiser at alle fire echo-linjene viser gyldige verdier. En tom linje betyr at ressursen ikke finnes eller ikke er opprettet ennå.

### Steg 1.2 — Verifiser Network Contributor-tilgang

Sjekk at AKS-clusteret har Network Contributor på spoke-subnettet. Hvis denne tildelingen mangler vil den interne load balanceren feile.

```bash
az role assignment list \
    --assignee $AKS_CONTROL_PLANE_IDENTITY \
    --scope $AKS_SUBNET_ID \
    --query "[?roleDefinitionName=='Network Contributor'].{Role:roleDefinitionName, Scope:scope}" \
    --output table
```

Hvis tabellen er tom, er ikke rollen tildelt. Kjør da Steg 2.6 fra Lab 12-02 på nytt:

```bash
az role assignment create \
    --assignee $AKS_CONTROL_PLANE_IDENTITY \
    --role "Network Contributor" \
    --scope $AKS_SUBNET_ID
```

---

## Del 2 — Feilsøking av InvalidImage

`InvalidImage` i `kubectl get pods` betyr at Kubernetes ikke finner eller ikke kan hente container-imaget fra ACR. Status `0/1` i READY-kolonnen bekrefter at containeren ikke er oppe.

```
NAME                                       READY   STATUS         RESTARTS   AGE
infraitsec-employee-app-84cfb6848b-98ws7   0/1     InvalidImage   0          46s
```

### Steg 2.1 — Hent den eksakte feilmeldingen

```bash
kubectl describe pod -l app=infraitsec-employee-app
```

Se under `Events:` nederst i output. Feilmeldingen der avgjør hvilke av de påfølgende stegene som er relevante.

---

### Feilårsak A — Tom image-referanse i manifestet

**Symptom i Events:**
```
Failed to pull image "/infraitsec-employee-app:latest"
```

Image-referansen starter med `/` istedenfor et registry-navn, noe som betyr at `$ACR_LOGIN_SERVER` var tom da manifestet ble generert — typisk fordi Cloud Shell-sesjonen ble avbrutt mellom Steg 2.4 og Steg 8.8.

**Løsning:** Verifiser variabelen, regenerer manifestet og apply på nytt:

```bash
echo $ACR_LOGIN_SERVER
```

Hvis output er tomt, kjør Steg 1.1 i denne guiden for å gjenopprette variablene. Deretter:

```bash
cd ~/infraitsec-app

kubectl delete deployment infraitsec-employee-app

cat > kubernetes-manifest.yaml << EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: infraitsec-employee-app
  labels:
    app: infraitsec-employee-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: infraitsec-employee-app
  template:
    metadata:
      labels:
        app: infraitsec-employee-app
    spec:
      containers:
      - name: infraitsec-employee-app
        image: ${ACR_LOGIN_SERVER}/infraitsec-employee-app:latest
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
  name: infraitsec-employee-app
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 3000
  selector:
    app: infraitsec-employee-app
EOF

kubectl apply -f kubernetes-manifest.yaml
```

---

### Feilårsak B — Imaget eksisterer ikke i ACR

**Symptom i Events:**
```
Failed to pull image "...azurecr.io/infraitsec-employee-app:latest": not found
```

`az acr build` ble ikke kjørt, eller build-steget feilet.

**Løsning:** Verifiser at imaget eksisterer i ACR:

```bash
az acr repository list --name $ACR_NAME --output table

az acr repository show-tags \
    --name $ACR_NAME \
    --repository infraitsec-employee-app \
    --output table
```

Hvis repository-listen er tom eller `infraitsec-employee-app` ikke finnes, kjør build-steget på nytt fra applikasjonskatalogen:

```bash
cd ~/infraitsec-app

az acr build \
    --registry $ACR_NAME \
    --image infraitsec-employee-app:latest \
    .
```

Etter vellykket build, slett eksisterende deployment og apply på nytt:

```bash
kubectl delete deployment infraitsec-employee-app
kubectl apply -f kubernetes-manifest.yaml
```

---

### Feilårsak C — AKS mangler pull-tillatelse til ACR

**Symptom i Events:**
```
Failed to pull image "...azurecr.io/infraitsec-employee-app:latest": unauthorized
```

`--attach-acr`-koblingen mellom AKS og ACR mangler eller ble ikke satt opp korrekt.

**Løsning:** Verifiser og reparer koblingen:

```bash
az aks check-acr \
    --resource-group $RG_COMPUTE \
    --name $AKS_CLUSTER \
    --acr $ACR_NAME
```

Hvis sjekken feiler, koble ACR til AKS på nytt:

```bash
az aks update \
    --resource-group $RG_COMPUTE \
    --name $AKS_CLUSTER \
    --attach-acr $ACR_NAME
```

Restart deretter podene slik at Kubernetes gjør et nytt pull-forsøk:

```bash
kubectl rollout restart deployment infraitsec-employee-app
```

---

## Verifisering etter feilretting

Uavhengig av hvilken feilårsak som ble rettet, verifiser at applikasjonen er oppe:

```bash
kubectl get pods
kubectl get service infraitsec-employee-app
```

`STATUS` skal vise `Running` og `EXTERNAL-IP` skal vise en adresse i `10.1.x.x`-området. Er begge disse på plass, er applikasjonen tilgjengelig via VPN som forventet.