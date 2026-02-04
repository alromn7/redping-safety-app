param(
  [string]$DeviceId = "",
  [string]$DartDefines = ""
)

Set-Location "$PSScriptRoot"

$cmd = @(
  "flutter", "run",
  "--flavor", "sos",
  "-t", "lib/main_sos.dart"
)

if ($DeviceId -ne "") {
  $cmd += @("-d", $DeviceId)
}

if ($DartDefines -ne "") {
  # Example: -DartDefines "FOO=bar,BAZ=qux"
  $pairs = $DartDefines.Split(',') | Where-Object { $_.Trim() -ne "" }
  foreach ($p in $pairs) {
    $cmd += @("--dart-define", $p.Trim())
  }
}

Write-Host ("Running: " + ($cmd -join ' '))
& $cmd[0] $cmd[1..($cmd.Length-1)]
