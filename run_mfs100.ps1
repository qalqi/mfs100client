# MFS100 Local HTTP Bridge for Chrome
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $scriptDir) { $scriptDir = (Get-Location).Path }

$localDll = Join-Path $scriptDir "lib\MANTRA.MFS100.dll"
$fallbackDll = "C:\Program Files\Mantra\MFS100\Driver\MFS100Test\MANTRA.MFS100.dll"

if (Test-Path $localDll) {
    $dllPath = $localDll
} else {
    $dllPath = $fallbackDll
}

# Ensure DLL directory is in PATH for native dependency loading (iengine_ansi_iso.dll, MFS100Dll.dll)
$libDir = Split-Path -Parent $dllPath
$env:PATH = "$libDir;$env:PATH"

Add-Type -Path $dllPath
Add-Type -AssemblyName System.Drawing

$mfs = New-Object MANTRA.MFS100
$port = 8004
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/mfs100/")
$listener.Prefixes.Add("http://127.0.0.1:$port/mfs100/")

try {
    $listener.Start()
} catch {
    Write-Host "[-] Failed to start HTTP listener on port $port : $_"
    exit 1
}

Write-Host "=========================================================="
Write-Host "[OK] MFS100 Hardware Bridge listening on port $port"
Write-Host "[OK] Device: Mantra MFS100"
Write-Host "[OK] Loaded DLL from: $dllPath"
Write-Host "[OK] Ready for Chrome! Click Capture on your IGR page."
Write-Host "=========================================================="

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $response.AddHeader("Access-Control-Allow-Origin", "*")
        $response.AddHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        $response.AddHeader("Access-Control-Allow-Headers", "Content-Type, Origin, Accept, Key")
        $response.AddHeader("Access-Control-Allow-Private-Network", "true")

        if ($request.HttpMethod -eq "OPTIONS") {
            $response.StatusCode = 200
            $response.Close()
            continue
        }

        $rawUrl = $request.RawUrl

        if ($rawUrl -match "/mfs100/info") {
            Write-Host "[+] Received /mfs100/info from Chrome"
            $initRet = $mfs.Init()
            $dev = $mfs.GetDeviceInfo()
            $serial = "1510682"
            $w = 316
            $h = 354
            if ($dev) {
                $serial = $dev.SerialNo
                $w = $dev.Width
                $h = $dev.Height
            }
            $mfs.Uninit() | Out-Null

            $respObj = @{
                ErrorCode = "0"
                ErrorDescription = "Success"
                DeviceInfo = @{
                    Make = "Mantra"
                    Model = "MFS100"
                    SerialNo = "$serial"
                    Width = "$w"
                    Height = "$h"
                    Certificate = ""
                }
            }
            $jsonStr = $respObj | ConvertTo-Json -Compress
            $buf = [System.Text.Encoding]::UTF8.GetBytes($jsonStr)
            $response.ContentType = "application/json"
            $response.ContentLength64 = $buf.Length
            $response.OutputStream.Write($buf, 0, $buf.Length)
            $response.Close()
            Write-Host "[OK] Handshake answered with device Serial: $serial"
        }
        elseif ($rawUrl -match "/mfs100/capture") {
            Write-Host ""
            Write-Host "[+] Received /mfs100/capture from Chrome!"
            Write-Host "[*] Initializing sensor..."
            $initRet = $mfs.Init()
            if ($initRet -ne 0) {
                $errMsg = $mfs.GetErrorMsg($initRet)
                Write-Host "[-] MFS.Init error: $errMsg"
                $errObj = @{ ErrorCode = "$initRet"; ErrorDescription = $errMsg }
                $buf = [System.Text.Encoding]::UTF8.GetBytes(($errObj | ConvertTo-Json -Compress))
                $response.ContentType = "application/json"
                $response.ContentLength64 = $buf.Length
                $response.OutputStream.Write($buf, 0, $buf.Length)
                $response.Close()
                continue
            }

            Write-Host "[*] Sensor is ON. PLACE YOUR FINGER ON THE SCANNER NOW..."
            $fingerData = New-Object MANTRA.FingerData
            $captureRet = $mfs.AutoCapture([ref]$fingerData, 15000, $false, $true)

            if ($captureRet -eq 0 -and $fingerData.Quality -ge 30) {
                $q = $fingerData.Quality
                $n = $fingerData.Nfiq
                Write-Host "[OK] Finger successfully captured! Quality: $q, Nfiq: $n"

                $bmpBytes = $mfs.RawToBitmapBytes($fingerData.RawData)
                $bmpBase64 = [Convert]::ToBase64String($bmpBytes)
                $isoBase64 = [Convert]::ToBase64String($fingerData.ISOTemplate)

                $respObj = @{
                    ErrorCode = "0"
                    ErrorDescription = "Success"
                    BitmapData = $bmpBase64
                    IsoTemplate = $isoBase64
                    AnsiTemplate = ""
                    RawData = ""
                    Quality = $q
                    Nfiq = $n
                    WsqImage = ""
                }
            } else {
                $errMsg = $mfs.GetErrorMsg($captureRet)
                Write-Host "[-] Capture failed: $errMsg"
                $respObj = @{
                    ErrorCode = "-1"
                    ErrorDescription = "Capture timeout or quality low: $errMsg"
                }
            }

            $mfs.Uninit() | Out-Null

            $jsonStr = $respObj | ConvertTo-Json -Compress
            $buf = [System.Text.Encoding]::UTF8.GetBytes($jsonStr)
            $response.ContentType = "application/json"
            $response.ContentLength64 = $buf.Length
            $response.OutputStream.Write($buf, 0, $buf.Length)
            $response.Close()
            Write-Host "[OK] Real thumb data sent to Chrome."
        }
        else {
            $response.StatusCode = 404
            $response.Close()
        }
    } catch {
        Write-Host "[-] Handler error: $_"
    }
}
