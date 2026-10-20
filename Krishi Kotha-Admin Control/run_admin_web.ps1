# Krishi Kotha - Admin Control Web Launcher
param (
    [int]$Port = 5000
)

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  কৃষি কথা – Krishi Kotha Admin Control (Port: $Port)" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

# Check if flutter exists
$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue

if ($flutterCmd) {
    Write-Host "Launching Flutter Web on http://localhost:$Port ..." -ForegroundColor Cyan
    flutter run -d chrome --web-port=$Port
} else {
    Write-Host "Flutter CLI PATH এ পাওয়া যায়নি।" -ForegroundColor Yellow
    Write-Host "বিকল্প হিসেবে সরাসরি Standalone Admin Preview সার্ভার পোর্ট $Port এ চালু করা হচ্ছে..." -ForegroundColor Cyan
    
    $previewServer = Join-Path $PSScriptRoot "web_preview\server.ps1"
    if (Test-Path $previewServer) {
        & powershell -ExecutionPolicy Bypass -File $previewServer -Port $Port
    } else {
        Write-Host "Flutter ইন্সটল করা থাকলে রান করুন: flutter run -d chrome --web-port=$Port" -ForegroundColor Yellow
    }
}
