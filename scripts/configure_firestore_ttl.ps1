Param(
  [Parameter(Mandatory=$true)][string]$ProjectId,
  [string]$CollectionGroup = 'request_nonces',
  [string]$Field = 'expireAt'
)

Write-Host "Configuring Firestore TTL policy for $CollectionGroup.$Field in project $ProjectId"

# Checks
$gcloud = Get-Command gcloud -ErrorAction SilentlyContinue
if (-not $gcloud) {
  Write-Error "gcloud CLI not found. Install from https://cloud.google.com/sdk/docs/install and ensure it's on PATH."
  exit 1
}

# Authenticate if needed
Write-Host "Ensuring gcloud is authenticated..."
gcloud auth list | Out-Null

# Enable APIs (idempotent)
Write-Host "Enabling required APIs (idempotent)..."
gcloud services enable firestore.googleapis.com --project $ProjectId | Out-Null

# Enable TTL using current gcloud syntax
$enableCmd = @(
  'firestore','fields','ttls','update',
  "--collection-group=$CollectionGroup",
  "--field=$Field",
  '--enable',
  "--project=$ProjectId"
)

& gcloud $enableCmd

Write-Host "Listing TTL configuration to verify..."
& gcloud firestore fields ttls list --collection-group=$CollectionGroup --project=$ProjectId | Out-String | Write-Host

Write-Host "Done. TTL should now be active; new consumed nonces will auto-expire after your server window."
