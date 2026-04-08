`InvalidImage` betyr at Kubernetes ikke finner eller ikke kan hente container-imaget fra ACR. Det er to vanlige årsaker.

**Steg 1 — Se hva Kubernetes faktisk rapporterer**

```bash
kubectl describe pod -l app=infraitsec-employee-app
```

Se under `Events:` nederst. Der vil det stå en konkret feilmelding — typisk en av disse:

- `Failed to pull image ... not found` → imaget eksisterer ikke i ACR
- `Failed to pull image ... unauthorized` → AKS mangler tillatelse til å hente fra ACR
- `invalid reference format` → feil i image-navnet i manifestet

**Steg 2 — Sjekk at imaget faktisk ble bygget og ligger i ACR**

```bash
az acr repository list --name $ACR_NAME --output table

az acr repository show-tags \
    --name $ACR_NAME \
    --repository infraitsec-employee-app \
    --output table
```

Hvis repository-en er tom eller ikke finnes, betyr det at `az acr build` feilet eller ikke ble kjørt. Da må studenten kjøre build-steget på nytt fra `~/infraitsec-app`-katalogen.

**Steg 3 — Sjekk at AKS har pull-tillatelse til ACR**

```bash
az aks check-acr \
    --resource-group $RG_COMPUTE \
    --name $AKS_CLUSTER \
    --acr $ACR_NAME
```

Hvis dette feiler, mangler `--attach-acr`-koblingen. Fiks det med:

```bash
az aks update \
    --resource-group $RG_COMPUTE \
    --name $AKS_CLUSTER \
    --attach-acr $ACR_NAME
```

**Steg 4 — Sjekk at image-referansen i manifestet stemmer**

```bash
echo $ACR_LOGIN_SERVER
```

Hvis variabelen er tom (fordi Cloud Shell-sesjonen ble avbrutt), vil manifestet inneholde en ufullstendig image-referanse som `/infraitsec-employee-app:latest` istedenfor `<prefix>acrinfraisec.azurecr.io/infraitsec-employee-app:latest`. Da må variablene settes på nytt og manifestet re-applies:

```bash
ACR_LOGIN_SERVER=$(az acr show \
    --name $ACR_NAME \
    --query loginServer \
    --output tsv)

# Regenerer og apply manifestet på nytt
```

Den vanligste årsaken i praksis er at Cloud Shell-sesjonen har vært inaktiv og variablene er borte — da inneholder `$ACR_LOGIN_SERVER` ingenting når manifestet genereres. Det er verdt å legge til en `echo $ACR_LOGIN_SERVER`-sjekk i walkthrough-en før Steg 8.8 som en liten sikkerhetsventil.