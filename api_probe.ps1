<#!
api_probe.ps1
Simple API connectivity and latency probe.
Requires API_BASE_URL (env or -BaseUrl) pointing at backend root (e.g. https://api.example.com)
Outputs api_probe.json with endpoint status/latency and overall success flag.
Exit code 0 on success, 1 if critical endpoint (/health) fails.
#>
param(
    [string] $BaseUrl = $env:API_BASE_URL,
    [int] $TimeoutSeconds = 10
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $BaseUrl) { Write-Host 'BaseUrl not provided; nothing to probe.'; exit 0 }
if ($BaseUrl.EndsWith('/')) { $BaseUrl = $BaseUrl.TrimEnd('/') }

$results = @()
function Probe($path, [switch]$Critical) {
    $url = "$BaseUrl$path"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $status = 0
    $ok = $false
    $bodyExcerpt = $null
    try {
        $resp = Invoke-WebRequest -Uri $url -Method GET -TimeoutSec $TimeoutSeconds -UseBasicParsing
        $status = [int]$resp.StatusCode
        $ok = ($status -ge 200 -and $status -lt 300)
        $raw = $resp.Content
        if ($raw) { $bodyExcerpt = ($raw.Substring(0, [Math]::Min(120, $raw.Length))).Replace("`r"," ").Replace("`n"," ").Trim() }
    } catch {
        $status = -1
        $bodyExcerpt = $_.Exception.Message
        $ok = $false
    }
    $stopwatch.Stop()
    $obj = [pscustomobject]@{
        path = $path
        url = $url
        status = $status
        ms = $stopwatch.ElapsedMilliseconds
        ok = $ok
        critical = [bool]$Critical
        bodyExcerpt = $bodyExcerpt
    }
    $results += $obj
}

Probe '/'              # root
Probe '/health' -Critical  # expected health endpoint
Probe '/status'          # optional status endpoint

$criticalFailure = $results | Where-Object { $_.critical -and -not $_.ok }
$summary = [pscustomobject]@{
    baseUrl = $BaseUrl
    timestampUtc = [DateTime]::UtcNow.ToString('o')
    endpoints = $results
    success = -not $criticalFailure
}

$summary | ConvertTo-Json -Depth 4 | Set-Content -Path api_probe.json -Encoding UTF8
Write-Host "API probe written to api_probe.json"
if ($criticalFailure) { Write-Error 'Critical endpoint failed.'; exit 1 } else { Write-Host 'All critical endpoints healthy.' }
