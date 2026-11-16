# Text Studio Auto-Deploy to GitHub
# این اسکریپت تغییرات رو خودکار به GitHub push می‌کنه
# استفاده: .\auto-deploy.ps1
# حالت تماشای خودکار: .\auto-deploy.ps1 -Watch

param(
    [string]$RepoUrl = "https://github.com/pooryaabbasi1/textstudio-rmz.git",
    [string]$Branch = "main",
    [string]$UserEmail = "game.club.onix@gmail.com",
    [string]$UserName = "pooryaabbasi1",
    [switch]$Watch
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$GitPath = "C:\Program Files\Git\bin\git.exe"
if (-not (Test-Path $GitPath)) { $GitPath = "C:\Program Files\Git\cmd\git.exe" }
if (-not (Test-Path $GitPath)) {
    $g = Get-Command git -ErrorAction SilentlyContinue
    if ($g) { $GitPath = $g.Source }
}
if (-not (Test-Path $GitPath)) {
    Write-Host "Git not found. Please install Git first." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

function Git-Run { & $GitPath @args 2>&1 | Out-String }

Set-Location $ScriptDir

# --- init git repo if needed ---
if (-not (Test-Path (Join-Path $ScriptDir ".git"))) {
    Write-Host "Initializing git repository..." -ForegroundColor Cyan
    [void](Git-Run init)
    [void](Git-Run config user.email $UserEmail)
    [void](Git-Run config user.name $UserName)
    [void](Git-Run remote add origin $RepoUrl)
    Write-Host "Git initialized. First push will ask for GitHub credentials." -ForegroundColor Yellow
}

# --- version bump ---
function Update-Version {
    $vPath = Join-Path $ScriptDir "version.json"
    if (-not (Test-Path $vPath)) {
        return "1.0.1"
    }
    $v = Get-Content $vPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $parts = $v.version.Split('.')
    $patch = [int]$parts[$parts.Length - 1] + 1
    $parts[$parts.Length - 1] = $patch
    $newVer = $parts -join '.'
    $v.version = $newVer
    $json = $v | ConvertTo-Json -Compress
    [System.IO.File]::WriteAllText($vPath, $json, [System.Text.UTF8Encoding]::new($false))
    return $newVer
}

# --- deploy once ---
function Deploy-Once {
    $newVer = Update-Version
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Deploying version $newVer ..." -ForegroundColor Cyan

    $status = Git-Run status --porcelain
    if ($status.Trim() -eq "") {
        Write-Host "  No changes to deploy." -ForegroundColor DarkGray
        return $false
    }

    [void](Git-Run add -A)
    $msg = "Auto-deploy v$newVer $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    [void](Git-Run commit -m $msg)
    $pushResult = Git-Run push origin $Branch
    Write-Host $pushResult
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Pushed to GitHub successfully." -ForegroundColor Green
        return $true
    } else {
        Write-Host "  Push failed. Run once manually to authenticate (GitHub username + Personal Access Token)." -ForegroundColor Red
        return $false
    }
}

# --- watch mode ---
if ($Watch) {
    Write-Host "Watching for changes (every 3 seconds)..." -ForegroundColor Green
    Write-Host "Press Ctrl+C to stop." -ForegroundColor Yellow
    $lastHash = (Git-Run status --porcelain)
    while ($true) {
        Start-Sleep -Seconds 3
        $currentHash = (Git-Run status --porcelain)
        if ($currentHash -ne $lastHash -and $currentHash.Trim() -ne "") {
            [void](Deploy-Once)
            $lastHash = $currentHash
        }
    }
} else {
    $ok = Deploy-Once
    if ($ok) {
        Write-Host "Done. Installed extensions can now click update." -ForegroundColor Green
    }
}

Read-Host "Press Enter to exit"