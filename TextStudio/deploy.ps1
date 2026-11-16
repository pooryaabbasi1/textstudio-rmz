# Text Studio Auto-Deploy
# این اسکریپت تغییرات رو خودکار به GitHub push می‌کنه
# استفاده: این فایل رو در پوشه TextStudio قرار بدید و اجرا کنید

param(
    [string]$RepoUrl = "https://github.com/pooryaabbasi1/textstudio-rmz.git",
    [string]$Branch = "main",
    [string]$Username = "pooryaabbasi1"
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

#.check git
try {
    git --version | Out-Null
} catch {
    Write-Host "Git نصب نیست. از https://git-scm.com دانلود و نصب کنید." -ForegroundColor Red
    Read-Host "اینتر برای خروج"
    exit 1
}

#初始化 git if needed
if (-not (Test-Path ".git")) {
    Write-Host "در حال راه‌اندازی git..." -ForegroundColor Cyan
    git init
    git remote add origin $RepoUrl
    git config user.email "game.club.onix@gmail.com"
    git config user.name $Username
}

# تابع بروزرسانی نسخه
function Update-Version {
    $vPath = Join-Path $scriptDir "version.json"
    if (Test-Path $vPath) {
        $v = Get-Content $vPath -Raw | ConvertFrom-Json
        $parts = $v.version.Split('.')
        $patch = [int]$parts[-1] + 1
        $newVer = ($parts[0..($parts.Length-2)] -join '.') + "." + $patch
        $v.version = $newVer
        $v | ConvertTo-Json -Compress | Set-Content $vPath -Encoding UTF8
        return $newVer
    }
    return "1.0.1"
}

# تابع push
function Push-Changes {
    $newVer = Update-Version
    Write-Host "نسخه جدید: $newVer" -ForegroundColor Green

    git add -A
    git commit -m "Auto-deploy: version $newVer ($(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))"
    git push origin $Branch

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ با موفقیت به GitHub ارسال شد" -ForegroundColor Green
    } else {
        Write-Host "خطا در push. آیا username/password درست وارد شده؟" -ForegroundColor Red
    }
}

# حالت دستی: با آرگومان --watch تماشای خودکار
if ($args -contains "--watch") {
    Write-Host "حالت خودکار فعال شد. تغییرات هر ۵ ثانیه بررسی می‌شه..." -ForegroundColor Cyan
    Write-Host "برای توقف Ctrl+C بزنید" -ForegroundColor Yellow

    $lastHash = ""
    while ($true) {
        Start-Sleep -Seconds 5
        $currentHash = (git status --porcelain | Out-String)
        if ($currentHash -ne $lastHash -and $currentHash.Trim() -ne "") {
            Push-Changes
            $lastHash = $currentHash
        }
    }
} else {
    # یک بار push کن
    Push-Changes
    Write-Host "برای تماشای خودکار: .\deploy.ps1 --watch" -ForegroundColor Yellow
}

Read-Host "اینتر برای خروج"