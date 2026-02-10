
<#
.SYNOPSIS
    Copies disk contents to a destination disk, organizing backups
    into date-labeled folders.

.DESCRIPTION
    Each execution creates (or uses) a destination subfolder named
    with the current date (e.g. 20-12-2025).
    Supports Complete, Incremental, Differential, and Dry-Run modes.

.NOTES
    Folder names cannot contain '/' on Windows.
    Date format used: dd-MM-yyyy (customizable below).
#>


param (
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,

    [Parameter(Mandatory = $true)]
    [string]$DestinationRoot,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Complete", "Incremental", "Differential", "DryRun")]
    [string]$Mode,

    [string]$LogRoot = "$env:USERPROFILE\BackupTools\logs"
)

$DateLabel = Get-Date -Format "dd-MM-yyyy"

$DestinationPath = Join-Path $DestinationRoot $DateLabel

# Baseline marker (used for Differential)
$BaselineFile = Join-Path $DestinationPath ".last_full_backup"

$LogPath = Join-Path $LogRoot "DiskCopy_$DateLabel.log"

try {
    if (-not (Test-Path $DestinationPath)) {
        Write-Host "Creating dated destination folder: $DestinationPath" -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
    }

    if (-not (Test-Path $LogPath)) {
        Write-Host "Creating log file: $LogPath" -ForegroundColor Yellow
        New-Item -ItemType File -Path $LogPath -Force | Out-Null
    }

    # Convert all paths to absolute paths
    $SourcePath = (Resolve-Path $SourcePath).Path
    $DestinationPath = (Resolve-Path $DestinationPath).Path
    $LogPath = (Resolve-Path $LogPath).Path

}
catch {
    Write-Error "Validation failed: $_"
    exit 1
}

$RoboCopyBaseArgs = @(
    $SourcePath,
    $DestinationPath,
    "/E",              # Copy all subfolders
    "/COPY:DAT",       # Data, Attributes, Timestamps
    "/DCOPY:T",        # Preserve directory timestamps
    "/MT:16", 
    "/R:2",
    "/W:2",
    "/TEE",
    "/LOG+:$LogPath"
)

Write-Host "----------------------------------------"
Write-Host "Disk Copy Operation Started" -ForegroundColor Cyan
Write-Host "Date Label      : $DateLabel"
Write-Host "Mode            : $Mode"
Write-Host "Source          : $SourcePath"
Write-Host "Destination     : $DestinationPath"
Write-Host "Log File        : $LogPath"
Write-Host "----------------------------------------"

try {
    switch ($Mode) {

        "Complete" {
            Write-Host "Performing COMPLETE backup (mirror)..." -ForegroundColor Green
            Write-Host "Source: $SourcePath"
            Write-Host "Destination: $DestinationPath"
            Write-Host "Log: $LogPath"


            $argsRobo = $RoboCopyBaseArgs + "/MIR"
            robocopy @argsRobo

            Get-Date | Out-File $BaselineFile -Force
        }

        "Incremental" {
            Write-Host "Performing INCREMENTAL backup (newer files only)..." -ForegroundColor Green

            $argsRobo = $RoboCopyBaseArgs + "/XO"
            robocopy @argsRobo
        }

        "Differential" {
            Write-Host "Performing DIFFERENTIAL backup..." -ForegroundColor Green

            if (-not (Test-Path $BaselineFile)) {
                throw "Differential baseline not found in $DestinationPath. Run a Complete backup first."
            }

            $BaselineDate = Get-Content $BaselineFile
            Write-Host "Baseline date: $BaselineDate"

            $argsRobo = $RoboCopyBaseArgs + "/MAXAGE:$BaselineDate"
            robocopy @argsRobo
        }

        "DryRun" {
            Write-Host "Performing DRY-RUN (no data will be copied)..." -ForegroundColor Yellow

            $argsRobo = $RoboCopyBaseArgs + "/L"
            robocopy @argsRobo
        }
    }
}
catch {
    Write-Error "Backup operation failed: $_"
    exit 2
}

Write-Host "----------------------------------------"
Write-Host "Backup completed successfully." -ForegroundColor Cyan
Write-Host "Backup folder: $DestinationPath"
Write-Host "----------------------------------------"

