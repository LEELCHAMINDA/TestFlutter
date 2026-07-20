$ErrorActionPreference = "Stop"

$workspace = "D:\TestFlutter"
$apiDir = Join-Path $workspace "TestAPI"
$flutterDir = Join-Path $workspace "Test"
$logDir = Join-Path $env:TEMP "opencode"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
$apiLog = Join-Path $logDir "api.log"
$apiErr = Join-Path $logDir "api_err.log"

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }

# 1. Start API in background if not already running
$apiUrl = "http://localhost:5148/api/products"

function Test-PortListening($port) {
    try {
        $out = netstat -ano 2>$null | Select-String ":$port\s"
        foreach ($line in $out) {
            if ($line -match "LISTENING") { return $true }
        }
    } catch { }
    return $false
}

function Test-ApiUp {
    try {
        $r = Invoke-WebRequest -Uri $apiUrl -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue
        if ($null -ne $r -and $r.StatusCode -eq 200) { return $true }
    } catch { }
    # Fallback: if the port is listening, treat API as up even if the probe is flaky
    return (Test-PortListening 5148)
}

if (Test-ApiUp) {
    Write-Step "API already running on :5148"
} else {
    Write-Step "Starting API (TestAPI)..."
    Start-Process -FilePath "dotnet" -ArgumentList "run","--project",$apiDir `
        -RedirectStandardOutput $apiLog -RedirectStandardError $apiErr -WindowStyle Hidden

    $tries = 0
    while ($tries -lt 40) {
        if (Test-ApiUp) { Write-Step "API is up on :5148"; break }
        Start-Sleep -Seconds 2
        $tries++
    }
    if (-not (Test-ApiUp)) {
        Write-Host "ERROR: API failed to start. Check $apiErr" -ForegroundColor Red
        exit 1
    }
}

# 2. Run Flutter Chrome app (foreground)
Write-Step "Launching Flutter Chrome app..."
Set-Location $flutterDir
flutter run -d chrome
