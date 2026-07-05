# AgriMart — Deploy backend to Google Cloud Run
# Prerequisites: Google Cloud SDK installed, logged in (gcloud auth login)
#
# Usage:
#   .\scripts\deploy-gcp.ps1 -ProjectId "your-gcp-project-id"
#   .\scripts\deploy-gcp.ps1 -ProjectId "your-gcp-project-id" -SetEnvFromDotEnv

param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectId,

    [string]$Region = "asia-south1",
    [string]$ServiceName = "agrimart-api",
    [switch]$SetEnvFromDotEnv,
    [switch]$SkipApis
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

function Require-Gcloud {
    if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
        Write-Host ""
        Write-Host "Google Cloud SDK not found. Install it:" -ForegroundColor Yellow
        Write-Host "  winget install Google.CloudSDK" -ForegroundColor Cyan
        Write-Host "  OR: https://cloud.google.com/sdk/docs/install" -ForegroundColor Cyan
        exit 1
    }
}

Require-Gcloud

Write-Host "==> Setting project: $ProjectId" -ForegroundColor Green
gcloud config set project $ProjectId

if (-not $SkipApis) {
    Write-Host "==> Enabling required APIs..." -ForegroundColor Green
    $apis = @(
        "run.googleapis.com",
        "cloudbuild.googleapis.com",
        "artifactregistry.googleapis.com",
        "secretmanager.googleapis.com",
        "generativelanguage.googleapis.com",
        "aiplatform.googleapis.com"
    )
    foreach ($api in $apis) {
        gcloud services enable $api --quiet
    }
}

$repo = "agrimart"
$image = "$Region-docker.pkg.dev/$ProjectId/$repo/$ServiceName"

Write-Host "==> Creating Artifact Registry repo (if missing)..." -ForegroundColor Green
gcloud artifacts repositories describe $repo --location=$Region 2>$null
if ($LASTEXITCODE -ne 0) {
    gcloud artifacts repositories create $repo `
        --repository-format=docker `
        --location=$Region `
        --description="AgriMart backend images"
}

Write-Host "==> Building Docker image..." -ForegroundColor Green
gcloud auth configure-docker "$Region-docker.pkg.dev" --quiet
docker build -t "${image}:latest" .

Write-Host "==> Pushing image..." -ForegroundColor Green
docker push "${image}:latest"

$deployArgs = @(
    "run", "deploy", $ServiceName,
    "--image=${image}:latest",
    "--region=$Region",
    "--platform=managed",
    "--allow-unauthenticated",
    "--port=3000",
    "--memory=1Gi",
    "--cpu=1",
    "--min-instances=0",
    "--max-instances=10",
    "--timeout=300",
    "--set-env-vars=NODE_ENV=production,PORT=3000,GOOGLE_CLOUD_PROJECT=$ProjectId,GOOGLE_CLOUD_LOCATION=$Region"
)

if ($SetEnvFromDotEnv) {
    $envFile = Join-Path $Root ".env"
    if (-not (Test-Path $envFile)) {
        Write-Error ".env not found at $envFile"
    }
    Write-Host "==> Loading env vars from .env (production overrides)..." -ForegroundColor Green
    $pairs = @()
    Get-Content $envFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -match '^\s*#' -or $line -eq '') { return }
        if ($line -match '^([A-Z_][A-Z0-9_]*)=(.*)$') {
            $key = $matches[1]
            $val = $matches[2].Trim().Trim('"').Trim("'")
            # Skip local-only / deprecated vars
            if ($key -in @('PORT', 'GEMINI_API_KEY', 'GOOGLE_API_KEY')) { return }
            if ($key -eq 'GOOGLE_CLOUD_PROJECT') { $val = $ProjectId }
            if ($key -eq 'GCP_PROJECT_ID') { return }
            if ($key -eq 'NODE_ENV') { $val = 'production' }
            if ($key -eq 'STATIC_OTP') { $val = 'false' }
            if ($key -eq 'CORS_ORIGIN') { $val = '*' }
            $escaped = $val -replace ',', '\,'
            $pairs += "${key}=${escaped}"
        }
    }
    if ($pairs.Count -gt 0) {
        $deployArgs += "--set-env-vars=$($pairs -join ',')"
    }
}

Write-Host "==> Deploying to Cloud Run..." -ForegroundColor Green
gcloud @deployArgs

Write-Host "==> Granting Vertex AI access to Cloud Run service account..." -ForegroundColor Green
$projectNumber = gcloud projects describe $ProjectId --format="value(projectNumber)"
$runSa = "${projectNumber}-compute@developer.gserviceaccount.com"
gcloud projects add-iam-policy-binding $ProjectId `
    --member="serviceAccount:$runSa" `
    --role="roles/aiplatform.user" `
    --quiet 2>$null

$serviceUrl = gcloud run services describe $ServiceName --region=$Region --format="value(status.url)"
Write-Host ""
Write-Host "Deployed successfully!" -ForegroundColor Green
Write-Host "  Service URL: $serviceUrl"
Write-Host "  Health:      $serviceUrl/health"
Write-Host "  API base:    $serviceUrl/api"
Write-Host ""
Write-Host "Update Flutter app:" -ForegroundColor Yellow
Write-Host "  flutter run --dart-define=API_BASE_URL=$serviceUrl/api"
Write-Host ""
Write-Host "Set PUBLIC_URL on Cloud Run for keep-alive cron:" -ForegroundColor Yellow
Write-Host "  gcloud run services update $ServiceName --region=$Region --update-env-vars=PUBLIC_URL=$serviceUrl"
