# Upload .env values to Google Secret Manager (recommended for production)
# Usage: .\scripts\setup-gcp-secrets.ps1 -ProjectId "your-project-id"

param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectId
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$envFile = Join-Path $Root ".env"

if (-not (Test-Path $envFile)) {
    Write-Error ".env not found"
}

gcloud config set project $ProjectId
gcloud services enable secretmanager.googleapis.com --quiet

$secretKeys = @(
    "DATABASE_URL",
    "DIRECT_URL",
    "SUPABASE_URL",
    "SUPABASE_SERVICE_KEY",
    "SUPABASE_ANON_KEY",
    "JWT_SECRET",
    "ADMIN_PASSWORD",
    "GEMINI_MODEL",
    "GOOGLE_CLOUD_PROJECT",
    "GOOGLE_CLOUD_LOCATION",
    "GROQ_API_KEY",
    "OPENWEATHER_API_KEY",
    "AGMARKNET_API_KEY",
    "UPSTASH_REDIS_REST_URL",
    "UPSTASH_REDIS_REST_TOKEN",
    "TWILIO_ACCOUNT_SID",
    "TWILIO_AUTH_TOKEN",
    "ONESIGNAL_APP_ID",
    "ONESIGNAL_REST_API_KEY"
)

$envMap = @{}
Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -match '^([A-Z_][A-Z0-9_]*)=(.*)$') {
        $envMap[$matches[1]] = $matches[2].Trim().Trim('"').Trim("'")
    }
}

foreach ($key in $secretKeys) {
    if (-not $envMap.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($envMap[$key])) {
        Write-Host "Skip $key (empty)" -ForegroundColor DarkGray
        continue
    }
    $secretName = "agrimart-$($key.ToLower().Replace('_','-'))"
    $val = $envMap[$key]

    gcloud secrets describe $secretName 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Create secret: $secretName" -ForegroundColor Cyan
        $val | gcloud secrets create $secretName --data-file=-
    } else {
        Write-Host "Update secret: $secretName" -ForegroundColor Cyan
        $val | gcloud secrets versions add $secretName --data-file=-
    }

    $projectNumber = gcloud projects describe $ProjectId --format="value(projectNumber)"
    gcloud secrets add-iam-policy-binding $secretName `
        --member="serviceAccount:${projectNumber}-compute@developer.gserviceaccount.com" `
        --role="roles/secretmanager.secretAccessor" `
        --quiet 2>$null
}

Write-Host ""
Write-Host "Secrets created. Mount them on Cloud Run via Console:" -ForegroundColor Green
Write-Host "  Cloud Run > agrimart-api > Edit > Variables & Secrets > Reference a secret"
