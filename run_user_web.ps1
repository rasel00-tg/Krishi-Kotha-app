# কৃষি কথা – Krishi Kotha User App Launcher
param (
    [int]$Port = 3000
)

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  কৃষি কথা – Krishi Kotha User App (Port: $Port)" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

# Check if flutter exists in system PATH
$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue

if ($flutterCmd) {
    Write-Host "Launching Flutter Web on http://localhost:$Port ..." -ForegroundColor Cyan
    flutter run -d chrome --web-port=$Port
} else {
    # Check if python exists
    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    $previewServer = Join-Path $PSScriptRoot "web_preview\server.ps1"
    
    if (Test-Path $previewServer) {
        Write-Host "Flutter CLI টার্মিনালে সরাসরি না থাকায় встроенный HTTP লোকাল সার্ভার চালু করা হচ্ছে..." -ForegroundColor Cyan
        Write-Host "ব্রাউজারে ওপেন করুন: http://localhost:$Port/" -ForegroundColor Yellow
        Start-Process "http://localhost:$Port/"
        & powershell -ExecutionPolicy Bypass -File $previewServer -Port $Port
    } elseif ($pythonCmd) {
        Write-Host "Python লোকাল HTTP সার্ভার চালু করা হচ্ছে (Port: $Port)..." -ForegroundColor Cyan
        Start-Process "http://localhost:$Port/"
        python -m http.server $Port --directory web_preview
    } else {
        Write-Host "লোকাল সার্ভার চালু করার জন্য টার্মিনালে লিখুন:" -ForegroundColor Yellow
        Write-Host "  flutter run -d chrome --web-port=$Port" -ForegroundColor Cyan
    }
}
