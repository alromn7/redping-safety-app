# Copies shared branding image into both app asset folders
param(
  [string]$ImagePath = "C:\flutterapps\redping_14v\packages\branding_assets\assets\REDP!NG.png"
)

$emergencyIcon = "C:\flutterapps\redping_emergency_app\assets\icon\REDP!NG.png"
$emergencySplash = "C:\flutterapps\redping_emergency_app\assets\splash\REDP!NG.png"
$sarIcon = "C:\flutterapps\redping_sar_app\assets\icon\REDP!NG.png"
$sarSplash = "C:\flutterapps\redping_sar_app\assets\splash\REDP!NG.png"

if (!(Test-Path $ImagePath)) {
  Write-Error "Shared image not found: $ImagePath"
  exit 1
}

Copy-Item -Path $ImagePath -Destination $emergencyIcon -Force
Copy-Item -Path $ImagePath -Destination $emergencySplash -Force
Copy-Item -Path $ImagePath -Destination $sarIcon -Force
Copy-Item -Path $ImagePath -Destination $sarSplash -Force

Write-Host "Branding image synced to both apps."