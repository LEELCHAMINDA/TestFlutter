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

# 2. Run Flutter Android app on the tablet emulator (foreground)
$androidId = "emulator-5554"
$emuId = "Pixel_Tablet"

# Start the emulator only if the device is not already available
$devicesOut = flutter devices 2>$null
$androidLine = $devicesOut | Where-Object { $_ -match [regex]::Escape($androidId) } | Select-Object -First 1
if ($null -eq $androidLine) {
    Write-Step "Starting Android tablet emulator ($emuId)..."
    flutter emulators --launch $emuId 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "WARNING: Emulator launch returned exit code $LASTEXITCODE. If it is already running, this is expected." -ForegroundColor Yellow
    }

    # Wait for the device to come online (up to ~2 minutes)
    $tries = 0
    while ($tries -lt 60) {
        $devicesOut = flutter devices 2>$null
        $androidLine = $devicesOut | Where-Object { $_ -match [regex]::Escape($androidId) } | Select-Object -First 1
        if ($null -ne $androidLine) {
            Write-Step "Android device detected ($androidId), waiting for it to finish booting..."
            Start-Sleep -Seconds 10
            break
        }
        Start-Sleep -Seconds 2
        $tries++
    }
}

if ($null -eq $androidLine) {
    Write-Host "ERROR: Android device '$androidId' not available. Start the emulator manually, then re-run." -ForegroundColor Red
    exit 1
}
Write-Step "Android device is ready ($androidId)"

Write-Step "Launching Flutter Android app..."
Set-Location $flutterDir
flutter run -d $androidId
