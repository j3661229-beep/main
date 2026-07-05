#!/bin/bash
# Run this in Google Cloud Shell (Console → Activate Cloud Shell)
# Usage: bash gcp/cloud-shell-deploy.sh YOUR_PROJECT_ID

set -euo pipefail

PROJECT_ID="${1:-}"
REGION="${REGION:-asia-south1}"
SERVICE="agrimart-api"
REPO="agrimart"

if [ -z "$PROJECT_ID" ]; then
  echo "Usage: bash gcp/cloud-shell-deploy.sh YOUR_GCP_PROJECT_ID"
  echo "Find project ID: Console top bar → project dropdown → Project ID"
  exit 1
fi

gcloud config set project "$PROJECT_ID"

echo "==> Enabling APIs..."
gcloud services enable run.googleapis.com cloudbuild.googleapis.com \
  artifactregistry.googleapis.com secretmanager.googleapis.com \
  generativelanguage.googleapis.com --quiet

echo "==> Artifact Registry..."
gcloud artifacts repositories describe "$REPO" --location="$REGION" 2>/dev/null || \
  gcloud artifacts repositories create "$REPO" \
    --repository-format=docker --location="$REGION" \
    --description="AgriMart backend"

echo "==> Build & deploy (Cloud Build)..."
gcloud builds submit --config cloudbuild.yaml \
  --substitutions="_REGION=$REGION,_SERVICE=$SERVICE"

URL=$(gcloud run services describe "$SERVICE" --region="$REGION" --format='value(status.url)')
echo ""
echo "Deployed: $URL"
echo "Health:   $URL/health"
echo "API:      $URL/api"
echo ""
echo "Next: Cloud Run → $SERVICE → Edit → Environment variables"
echo "  Add DATABASE_URL, GEMINI_API_KEY, JWT_SECRET, etc. from your .env"
echo "  Set NODE_ENV=production, STATIC_OTP=false, PUBLIC_URL=$URL"
