<#
.SYNOPSIS
    Interface graphique pour l'outil de backup avec affichage des logs en temps réel
#>

# Load WinForms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing


$form = New-Object System.Windows.Forms.Form
$form.Text = "Disk Backup Tool"
$form.Size = New-Object System.Drawing.Size(700, 600)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false


$lblSource = New-Object System.Windows.Forms.Label
$lblSource.Text = "Source Path:"
$lblSource.Location = '10,20'
$lblSource.AutoSize = $true

$txtSource = New-Object System.Windows.Forms.TextBox
$txtSource.Location = '120,18'
$txtSource.Width = 450

$btnBrowseSource = New-Object System.Windows.Forms.Button
$btnBrowseSource.Text = "..."
$btnBrowseSource.Location = '575,17'
$btnBrowseSource.Size = '30,22'
$btnBrowseSource.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select Source Folder"
    if ($folderBrowser.ShowDialog() -eq 'OK') {
        $txtSource.Text = $folderBrowser.SelectedPath
    }
})

$lblDest = New-Object System.Windows.Forms.Label
$lblDest.Text = "Destination Path:"
$lblDest.Location = '10,55'
$lblDest.AutoSize = $true

$txtDest = New-Object System.Windows.Forms.TextBox
$txtDest.Location = '120,53'
$txtDest.Width = 450

$btnBrowseDest = New-Object System.Windows.Forms.Button
$btnBrowseDest.Text = "..."
$btnBrowseDest.Location = '575,52'
$btnBrowseDest.Size = '30,22'
$btnBrowseDest.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select Destination Folder"
    if ($folderBrowser.ShowDialog() -eq 'OK') {
        $txtDest.Text = $folderBrowser.SelectedPath
    }
})


$grpMode = New-Object System.Windows.Forms.GroupBox
$grpMode.Text = "Backup Type"
$grpMode.Location = '10,90'
$grpMode.Size = '660,70'

$modes = @("Complete","Incremental","Differential","DryRun")
$radioButtons = @()
$x = 15

foreach ($mode in $modes) {
    $rb = New-Object System.Windows.Forms.RadioButton
    $rb.Text = $mode
    $rb.Location = "$x,25"
    $rb.AutoSize = $true
    $rb.Checked = ($mode -eq "Complete")
    $grpMode.Controls.Add($rb)
    $radioButtons += $rb
    $x += 150
}


$lblLog = New-Object System.Windows.Forms.Label
$lblLog.Text = "Log Output:"
$lblLog.Location = '10,170'
$lblLog.AutoSize = $true

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Location = '10,195'
$txtLog.Size = '660,300'
$txtLog.Multiline = $true
$txtLog.ScrollBars = 'Vertical'
$txtLog.ReadOnly = $true
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtLog.BackColor = [System.Drawing.Color]::Black
$txtLog.ForeColor = [System.Drawing.Color]::LimeGreen


$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready."
$statusLabel.Location = '10,505'
$statusLabel.Width = 460
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$statusLabel.ForeColor = [System.Drawing.Color]::DarkBlue


$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "Start Backup"
$btnStart.Location = '250,535'
$btnStart.Size = '100,30'
$btnStart.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)


$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 500 
$script:currentLogFile = $null
$script:lastLogPosition = 0
$script:backupProcess = $null

function Get-LogFileContent {
    if($script:currentLogFile -and (Test-Path $script:currentLogFile)) {
        try {
            $fileStream = [System.IO.File]::Open($script:currentLogFile, 'Open', 'Read', 'ReadWrite')
            $fileStream.Position = $script:lastLogPosition
            $reader = New-Object System.IO.StreamReader($fileStream)
            $newContent = $reader.ReadToEnd()
            
            if ($newContent) {
                $txtLog.AppendText($newContent)
                $txtLog.SelectionStart = $txtLog.Text.Length
                $txtLog.ScrollToCaret()
            }
            
            $script:lastLogPosition = $fileStream.Position
            $reader.Close()
            $fileStream.Close()
        }
        catch {}
    }
}

$timer.Add_Tick({
    Get-LogFileContent   
    # Check if backup process is still running
    if ($script:backupProcess -ne $null) {
        if ($script:backupProcess.HasExited) {
            $timer.Stop()
            $statusLabel.Text = "Done"
            $statusLabel.ForeColor = [System.Drawing.Color]::Green
            $btnStart.Enabled = $true
            
       
            Start-Sleep -Milliseconds 500
            Get-LogFileContent
            
            $txtLog.AppendText("`r`n`r`n=== Backup completed ===`r`n")
            $txtLog.SelectionStart = $txtLog.Text.Length
            $txtLog.ScrollToCaret()
            
            $script:backupProcess = $null
        }
    }
})


$btnStart.Add_Click({
    $source = $txtSource.Text.Trim()
    $dest   = $txtDest.Text.Trim()
    $mode   = ($radioButtons | Where-Object { $_.Checked }).Text

    if ([string]::IsNullOrWhiteSpace($source)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a Source Path.", "Validation Error", 'OK', 'Warning')
        return
    }

    if (-not (Test-Path $source)) {
        [System.Windows.Forms.MessageBox]::Show("Invalid source path: $source", "Validation Error", 'OK', 'Error')
        return
    }

    if ([string]::IsNullOrWhiteSpace($dest)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a Destination Path.", "Validation Error", 'OK', 'Warning')
        return
    }

    if (-not (Test-Path $dest)) {
        $result = [System.Windows.Forms.MessageBox]::Show(
            "Destination path does not exist: $dest`n`nDo you want to create it?", 
            "Create Destination?", 
            'YesNo', 
            'Question'
        )
        if ($result -eq 'Yes') {
            try {
                New-Item -ItemType Directory -Path $dest -Force | Out-Null
            }
            catch {
                [System.Windows.Forms.MessageBox]::Show("Failed to create destination: $_", "Error", 'OK', 'Error')
                return
            }
        }
        else {
            return
        }
    }

    $txtLog.Clear()
    
    $DateLabel = Get-Date -Format "dd-MM-yyyy"
    $LogRoot = "$env:USERPROFILE\BackupTools\logs"
    
    if (-not (Test-Path $LogRoot)) {
        New-Item -ItemType Directory -Path $LogRoot -Force | Out-Null
    }
    
    $script:currentLogFile = Join-Path $LogRoot "DiskCopy_$DateLabel.log"
    $script:lastLogPosition = 0
    

    $statusLabel.Text = "Running $mode backup..."
    $statusLabel.ForeColor = [System.Drawing.Color]::DarkOrange
    $btnStart.Enabled = $false
    
    $txtLog.AppendText("=== Backup Started ===`r`n")
    $txtLog.AppendText("Mode: $mode`r`n")
    $txtLog.AppendText("Source: $source`r`n")
    $txtLog.AppendText("Destination: $dest`r`n")
    $txtLog.AppendText("Log File: $script:currentLogFile`r`n")
    $txtLog.AppendText("`r`n")

    # Get script location
    $exeFolder = Split-Path -Parent $MyInvocation.MyCommand.Path
    if ([string]::IsNullOrWhiteSpace($exeFolder)) {
        $exeFolder = [System.AppDomain]::CurrentDomain.BaseDirectory
    }
    
    $diskCopyScript = Join-Path $exeFolder "DiskCopy.ps1"
    
    if (-not (Test-Path $diskCopyScript)) {
        [System.Windows.Forms.MessageBox]::Show(
            "DiskCopy.ps1 not found at: $diskCopyScript", 
            "Script Not Found", 
            'OK', 
            'Error'
        )
        $statusLabel.Text = "Error: Script not found"
        $statusLabel.ForeColor = [System.Drawing.Color]::Red
        $btnStart.Enabled = $true
        return
    }

    $scriptBlock = "& '$diskCopyScript' -SourcePath '$source' -DestinationRoot '$dest' -Mode '$mode'"
    
    $argumentList = "-NoProfile -ExecutionPolicy Bypass -Command `"$scriptBlock`""
    
    $txtLog.AppendText("Command Line:`r`n$argumentList`r`n`r`n")

    # Start the backup process
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = $argumentList
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    $psi.RedirectStandardOutput = $false
    $psi.RedirectStandardError = $false
    
    try {
        $script:backupProcess = New-Object System.Diagnostics.Process
        $script:backupProcess.StartInfo = $psi
        
        if (-not $script:backupProcess.Start()) {
            throw "Failed to start backup process"
        }
        
        $txtLog.AppendText("Process started successfully (PID: $($script:backupProcess.Id))`r`n`r`n")
        
        $timer.Start()
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Failed to start backup process: $_", 
            "Process Error", 
            'OK', 
            'Error'
        )
        $statusLabel.Text = "Error: Failed to start"
        $statusLabel.ForeColor = [System.Drawing.Color]::Red
        $btnStart.Enabled = $true
        $txtLog.AppendText("ERROR: $_`r`n")
    }
})

$form.Controls.AddRange(@(
    $lblSource, $txtSource, $btnBrowseSource,
    $lblDest, $txtDest, $btnBrowseDest,
    $grpMode,
    $lblLog, $txtLog,
    $btnStart,
    $statusLabel
))

$form.Add_FormClosing({
    if ($timer) {
        $timer.Stop()
        $timer.Dispose()
    }
})

[void]$form.ShowDialog()