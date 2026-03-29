# Creates a PRIVATE GitHub repo under j3661229-beep and pushes current branch.
# Prerequisites:
#   1) GitHub classic PAT with "repo" scope: https://github.com/settings/tokens
#   2) In this shell:  $env:GITHUB_TOKEN = "ghp_xxxxxxxx"
#
# Usage (from repo root):
#   powershell -ExecutionPolicy Bypass -File .\tools\publish-private-repo.ps1
# Optional:
#   -RepoName "agrobee"

param(
    [string]$Owner = "j3661229-beep",
    [string]$RepoName = "agrobee",
    [string]$Description = "AgriMart platform: backend, Flutter, admin (private)"
)

$ErrorActionPreference = "Stop"
$token = $env:GITHUB_TOKEN
if (-not $token) {
    Write-Host "Set your token first, then re-run:" -ForegroundColor Yellow
    Write-Host '  $env:GITHUB_TOKEN = "ghp_xxxxxxxx"' -ForegroundColor Cyan
    Write-Host "Create token: https://github.com/settings/tokens (classic, scope: repo)" -ForegroundColor Gray
    exit 1
}

$headers = @{
    "Accept"               = "application/vnd.github+json"
    "Authorization"        = "Bearer $token"
    "X-GitHub-Api-Version" = "2022-11-28"
}
$bodyObj = @{
    name        = $RepoName
    description = $Description
    private     = $true
    auto_init   = $false
}
$body = $bodyObj | ConvertTo-Json

Write-Host "Creating private repo $Owner/$RepoName ..." -ForegroundColor Cyan
try {
    Invoke-RestMethod -Uri "https://api.github.com/user/repos" -Method Post -Headers $headers -Body $body -ContentType "application/json; charset=utf-8" | Out-Null
    Write-Host "Repository created." -ForegroundColor Green
}
catch {
    $resp = $_.Exception.Response
    if ($resp -and [int]$resp.StatusCode -eq 422) {
        Write-Host "Repo may already exist (422). Continuing to push." -ForegroundColor Yellow
    }
    else {
        throw
    }
}

$cleanRemote = "https://github.com/$Owner/$RepoName.git"
$repoRoot = Split-Path $PSScriptRoot -Parent
Set-Location $repoRoot

$hasOrigin = git remote get-url origin 2>$null
if ($LASTEXITCODE -eq 0) {
    git remote set-url origin $cleanRemote
} else {
    git remote add origin $cleanRemote
}

Write-Host "Pushing to origin (main) ..." -ForegroundColor Cyan
git push -u origin main
if ($LASTEXITCODE -ne 0) {
    Write-Host "HTTPS push failed; retrying with token (remote URL not left on disk with token)." -ForegroundColor Yellow
    $pushUrl = "https://x-access-token:${token}@github.com/${Owner}/${RepoName}.git"
    git push -u $pushUrl main
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    git remote set-url origin $cleanRemote
}

Write-Host "Done. Private repo: https://github.com/$Owner/$RepoName" -ForegroundColor Green
