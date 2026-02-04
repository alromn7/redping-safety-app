Param(
  [string]$projectId = ''
)

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
$envTest = Join-Path $root ".env.test.local"
$envExample = Join-Path $root ".env.test.example"
$envFile = Join-Path $root ".env"

if (-not (Test-Path $envTest)) {
  Write-Warning ".env.test.local not found. Creating from .env.test.example. Fill in real test keys and price IDs."
  Copy-Item $envExample $envTest -Force
}

Copy-Item $envTest $envFile -Force
Write-Host "Copied .env.test.local to .env for TEST mode."

if ($projectId -ne '') {
  Write-Host "Setting default Firebase project: $projectId"
  firebase use $projectId | Out-Null
}

Write-Host "Deploying functions with TEST env..."
firebase deploy --only functions
