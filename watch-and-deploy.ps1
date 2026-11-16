# Text Studio Watch - نظارت خودکار روی تغییرات
# این اسکریپت باید always در حال اجرا باشه
# استفاده: .\watch-and-deploy.ps1

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# کپی اسکریپت auto-deploy به پوشه اکستنشن نصب شده
$Installed = "C:\Program Files (x86)\Common Files\Adobe\CEP\extensions\TextStudio"
if (Test-Path $Installed) {
    Write-Host "Copying auto-deploy script to installed extension..." -ForegroundColor Cyan
    Copy-Item -Path (Join-Path $ScriptDir "auto-deploy.ps1") -Destination $Installed -Force
    Copy-Item -Path (Join-Path $ScriptDir "auto-deploy.ps1") -Destination (Join-Path $Installed "deploy.ps1") -Force
}

Write-Host "Starting auto-deploy watcher..." -ForegroundColor Green
Write-Host "This window will stay open and watch for file changes." -ForegroundColor Yellow
Write-Host "Every change you make in the source folder will be auto-pushed to GitHub." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop." -ForegroundColor DarkGray
Write-Host ""

& (Join-Path $ScriptDir "auto-deploy.ps1") -Watch