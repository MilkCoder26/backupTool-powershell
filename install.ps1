<#
.SYNOPSIS
    Installer for BackupTools (per-user)

.DESCRIPTION
    - Creates BackupTools folder in the current user's profile
    - Creates logs folder
    - Downloads required files from GitHub
    - Adds BackupTools to the USER PATH environment variable
#>

# -------------------------------
# CONFIGURATION (CHANGE THESE)
# -------------------------------

$GitHubBaseUrl = "https://raw.githubusercontent.com/MilkCoder26/backupTool-powershell/main"

$FilesToDownload = @(
    "Backup.exe",
    "BackupGUI.exe",
    "DiskCopy.ps1"
)

# -------------------------------
# Paths
# -------------------------------

$UserProfile = $env:USERPROFILE
$InstallRoot = Join-Path $UserProfile "BackupTools"
$LogFolder   = Join-Path $InstallRoot "logs"

# -------------------------------
# Create folders
# -------------------------------

Write-Host "Creating BackupTools folder..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null

Write-Host "Creating logs folder..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $LogFolder -Force | Out-Null

# -------------------------------
# Download files
# -------------------------------

foreach ($file in $FilesToDownload) {
    $destination = Join-Path $InstallRoot $file
    $url = "$GitHubBaseUrl/$file"

    Write-Host "Downloading $file..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $url -OutFile $destination -UseBasicParsing
    }
    catch {
        Write-Error "Failed to download $file from $url"
        exit 2
    }
}

# -------------------------------
# Add to USER PATH
# -------------------------------

Write-Host "Adding BackupTools to USER PATH..." -ForegroundColor Cyan

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")

if ($userPath -notlike "*$InstallRoot*") {
    if ([string]::IsNullOrWhiteSpace($userPath)) {
        $newPath = $InstallRoot
    } else {
        $newPath = "$userPath;$InstallRoot"
    }

    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "USER PATH updated successfully." -ForegroundColor Green
}
else {
    Write-Host "BackupTools already present in USER PATH." -ForegroundColor Green
}

# -------------------------------
# Final message
# -------------------------------

Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor Green
Write-Host "BackupTools installation completed!"
Write-Host "Install location : $InstallRoot"
Write-Host "Logs location    : $LogFolder"
Write-Host "Restart your terminal or log out/in to use PATH commands."
Write-Host "----------------------------------------" -ForegroundColor Green
