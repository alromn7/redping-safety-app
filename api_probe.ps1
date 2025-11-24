<#!
api_probe.ps1
Simple API connectivity and latency probe.
Requires API_BASE_URL (env or -BaseUrl) pointing at backend root (e.g. https://api.example.com)
Outputs api_probe.json with endpoint status/latency and overall success flag.
Exit code 0 on success, 1 if critical endpoint (/health) fails.
#>
param(
    [string] $BaseUrl = $env:API_BASE_URL,
    [int] $TimeoutSeconds = 10,
    [string] $Endpoints = $env:API_ENDPOINTS  # Comma-separated override
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $BaseUrl) { Write-Host 'BaseUrl not provided; nothing to probe.'; exit 0 }
if ($BaseUrl.EndsWith('/')) { $BaseUrl = $BaseUrl.TrimEnd('/') }

$results = @()
$endpointList = @('/', '/health', '/status', '/version', '/ping')
if ($Endpoints) {
    $endpointList = $Endpoints.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
}

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

foreach ($ep in $endpointList) {
    if ($ep -eq '/health') { Probe $ep -Critical } else { Probe $ep }
}

$criticalFailure = $results | Where-Object { $_.critical -and -not $_.ok }
$latencies = $results | Where-Object { $_.ok } | Select-Object -ExpandProperty ms
$stats = $null
if ($latencies.Count -gt 0) {
    $avg = [Math]::Round(($latencies | Measure-Object -Average).Average,2)
    $p95 = ($latencies | Sort-Object | Select-Object -Last ([Math]::Ceiling($latencies.Count*0.95)))[-1]
    $max = ($latencies | Sort-Object -Descending | Select-Object -First 1)
    $stats = [pscustomobject]@{ averageMs=$avg; p95Ms=$p95; maxMs=$max }
}

$summary = [pscustomobject]@{
    baseUrl = $BaseUrl
    timestampUtc = [DateTime]::UtcNow.ToString('o')
    endpoints = $results
    latencyStats = $stats
    success = -not $criticalFailure
}

$summary | ConvertTo-Json -Depth 4 | Set-Content -Path api_probe.json -Encoding UTF8
Write-Host "API probe written to api_probe.json"
if ($criticalFailure) { Write-Error 'Critical endpoint failed.'; exit 1 } else { Write-Host 'All critical endpoints healthy.' }
