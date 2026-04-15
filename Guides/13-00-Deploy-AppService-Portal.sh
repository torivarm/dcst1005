#!/bin/bash
# =============================================================================
# Deploy-AppService-Portal.sh
# Deployer kundeportal-innhold til App Service
# DCST1005 — InfraIT.sec sikkerhetsvurderingslab
# =============================================================================
# Kjøres i Azure Cloud Shell (Bash) etter at PowerShell deployment-scriptet
# er fullført. Setter riktig Python-runtime og laster opp kundeportalen.
#
# Bruk: bash Deploy-AppService-Portal.sh
# =============================================================================

# --- Konfigurer prefiks ---
read -p "Skriv inn ditt prefiks (f.eks. on03): " PREFIX
PREFIX=$(echo "$PREFIX" | tr '[:upper:]' '[:lower:]' | tr -d ' ')

if [ ${#PREFIX} -lt 2 ]; then
  echo "Feil: Prefikset må være minst 2 tegn."
  exit 1
fi

RG_FRONTEND="${PREFIX}-rg-infraitsec-frontend"
APP="${PREFIX}-app-infraitsec"
APP_PLAN="${PREFIX}-plan-infraitsec"

echo ""
echo "--- Sjekker at App Service eksisterer ---"
APP_EXISTS=$(az webapp show \
  --resource-group $RG_FRONTEND \
  --name $APP \
  --query "name" \
  --output tsv 2>/dev/null)

if [ -z "$APP_EXISTS" ]; then
  echo "Feil: App Service '$APP' ble ikke funnet i '$RG_FRONTEND'."
  echo "      Kjør PowerShell deployment-scriptet først."
  exit 1
fi

echo "Funnet: $APP"

# --- Sett Python 3.11 runtime ---
echo ""
echo "--- Setter Python 3.11 runtime ---"
az webapp config set \
  --resource-group $RG_FRONTEND \
  --name $APP \
  --linux-fx-version "PYTHON|3.11" \
  --output none

echo "Python 3.11 konfigurert."

# --- Opprett applikasjonsfilene ---
echo ""
echo "--- Oppretter applikasjonsfiler ---"

TMPDIR=$(mktemp -d)
mkdir -p $TMPDIR/static

# app.py
cat > $TMPDIR/app.py << 'PYEOF'
from flask import Flask, send_from_directory
import os

app = Flask(__name__, static_folder='static')

@app.route('/')
def index():
    return send_from_directory('static', 'index.html')

@app.route('/<path:path>')
def static_files(path):
    return send_from_directory('static', path)

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8000))
    app.run(host='0.0.0.0', port=port)
PYEOF

# requirements.txt
cat > $TMPDIR/requirements.txt << 'EOF'
flask==3.0.0
gunicorn==21.2.0
EOF

# index.html
cat > $TMPDIR/static/index.html << 'EOF'
<!DOCTYPE html>
<html lang="no">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>InfraIT.sec AS — Kundeportal</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:system-ui,sans-serif;background:#0f1923;color:#e8e6e0;min-height:100vh}
header{background:#1a2a3a;border-bottom:3px solid #1a56a0;padding:16px 32px;display:flex;align-items:center;gap:16px}
.lm{width:38px;height:38px;background:#1a56a0;border-radius:8px;display:flex;align-items:center;justify-content:center;font-weight:900;font-size:20px;color:#fff;flex-shrink:0}
.lt{font-size:20px;font-weight:700}.lt span{color:#6ba3e8}
.tag{font-size:13px;color:#6b7a8d;margin-left:auto}
main{max-width:920px;margin:0 auto;padding:48px 32px}
.hero{text-align:center;margin-bottom:40px}
.hero h1{font-size:34px;font-weight:700;margin-bottom:12px}
.hero h1 span{color:#6ba3e8}
.hero p{font-size:16px;color:#9ba8b5;max-width:560px;margin:0 auto;line-height:1.7}
.notice{background:#1a2230;border:1px solid #1a56a0;border-radius:10px;padding:12px 18px;margin-bottom:32px;font-size:13px;color:#6ba3e8;display:flex;align-items:center;gap:10px}
.nd{width:8px;height:8px;border-radius:50%;background:#4caf50;flex-shrink:0}
.grid{display:grid;grid-template-columns:repeat(3,1fr);gap:16px;margin-bottom:40px}
.card{background:#1a2230;border:1px solid #2a3a4a;border-radius:10px;padding:22px}
.ci{font-size:26px;margin-bottom:10px}
.card h3{font-size:15px;font-weight:600;margin-bottom:6px}
.card p{font-size:13px;color:#6b7a8d;line-height:1.6}
.lbox{background:#1a2230;border:1px solid #2a3a4a;border-radius:12px;padding:28px;max-width:380px;margin:0 auto;text-align:center}
.lbox h2{font-size:19px;margin-bottom:6px}
.lbox p{font-size:13px;color:#6b7a8d;margin-bottom:18px}
input{display:block;width:100%;padding:10px 12px;background:#0f1923;border:1px solid #2a3a4a;border-radius:8px;color:#e8e6e0;font-size:14px;margin-bottom:10px;font-family:inherit}
.btn{display:block;width:100%;padding:10px;background:#1a56a0;color:#fff;border:none;border-radius:8px;font-size:14px;font-weight:600;cursor:pointer}
.btn:hover{opacity:.88}
footer{text-align:center;padding:20px;font-size:12px;color:#3a4a5a;border-top:1px solid #1a2230;margin-top:32px}
</style>
</head>
<body>
<header>
  <div class="lm">I</div>
  <span class="lt">InfraIT<span>.sec</span></span>
  <span class="tag">Sikker IT-drift for norske bedrifter</span>
</header>
<main>
  <div class="hero">
    <h1>Velkommen til <span>kundeportalen</span></h1>
    <p>Her finner du driftsrapporter, supportsaker og dokumentasjon for dine IT-tjenester levert av InfraIT.sec AS.</p>
  </div>
  <div class="notice">
    <div class="nd"></div>
    Alle systemer opererer normalt &mdash; sist oppdatert i dag kl. 08:00
  </div>
  <div class="grid">
    <div class="card"><div class="ci">📋</div><h3>Driftsrapporter</h3><p>Månedlige statusrapporter og SLA-oppfølging for din infrastruktur.</p></div>
    <div class="card"><div class="ci">🔧</div><h3>Supportsaker</h3><p>Opprett og følg opp supportsaker direkte i portalen.</p></div>
    <div class="card"><div class="ci">📁</div><h3>Dokumentasjon</h3><p>Teknisk dokumentasjon og brukerveiledninger for dine systemer.</p></div>
  </div>
  <div class="lbox">
    <h2>Logg inn</h2>
    <p>Bruk din InfraIT.sec-konto for å få tilgang til portalen.</p>
    <input type="text" placeholder="Brukernavn">
    <input type="password" placeholder="Passord">
    <button class="btn" onclick="alert('Autentisering er ikke konfigurert.')">Logg inn</button>
  </div>
</main>
<footer>InfraIT.sec AS &mdash; Org.nr. 123 456 789 &mdash; post@infraitsec.no &mdash; Tlf: 22 00 00 00</footer>
</body>
</html>
EOF

echo "Filer opprettet."

# --- Pakk og deploy ---
echo ""
echo "--- Pakker og deployer til App Service ---"

ZIP_PATH=$(mktemp).zip
cd $TMPDIR
zip -r $ZIP_PATH . -q

az webapp deploy \
  --resource-group $RG_FRONTEND \
  --name $APP \
  --src-path $ZIP_PATH \
  --type zip \
  --output none

# --- Sett startup command og restart ---
az webapp config set \
  --resource-group $RG_FRONTEND \
  --name $APP \
  --startup-file "gunicorn --bind=0.0.0.0:8000 app:app" \
  --output none

az webapp restart \
  --resource-group $RG_FRONTEND \
  --name $APP \
  --output none

# --- Rydding ---
rm -rf $TMPDIR $ZIP_PATH

# --- Verifisering ---
echo ""
echo "--- Verifiserer deployment ---"
sleep 5

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  "https://${APP}.azurewebsites.net" 2>/dev/null)

echo ""
echo "═══════════════════════════════════════════════════════"
echo " DEPLOYMENT FULLFORT — $PREFIX"
echo "═══════════════════════════════════════════════════════"
echo " App Service: https://${APP}.azurewebsites.net"
if [ "$HTTP_CODE" = "200" ]; then
  echo " Status:      HTTP $HTTP_CODE — kundeportalen er oppe"
else
  echo " Status:      HTTP $HTTP_CODE — vent 1-2 min og last inn på nytt"
fi
echo "═══════════════════════════════════════════════════════"