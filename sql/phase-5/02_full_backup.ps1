$script = @'
# =============================================================================
# Project:  MySQL DBA
# Author:   Naseer Aryobee
# Script:   02_full_backup.ps1
# Phase:    5 - Backup and Recovery
# Purpose:  Perform a full logical backup of cancer_environment_db using
#           mysqldump. Includes timestamp in filename and verification.
# =============================================================================

$mysqlBin   = "C:\Program Files\MySQL\MySQL Server 8.0\bin"
$backupDir  = "C:\Users\User\Desktop\mysql-dba-project\backups"
$database   = "cancer_environment_db"
$user       = "root"
$timestamp  = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = "$backupDir\${database}_full_$timestamp.sql"

if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
    Write-Host "Created backup directory: $backupDir"
} else {
    Write-Host "Backup directory confirmed: $backupDir"
}

Write-Host ""
Write-Host "Starting full backup of $database..."
Write-Host "Backup file: $backupFile"
Write-Host "Start time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

$startTime = Get-Date

& "$mysqlBin\mysqldump.exe" `
    --user=$user `
    --password `
    --single-transaction `
    --routines `
    --triggers `
    --events `
    --flush-logs `
    --source-data=2 `
    --databases $database `
    --result-file="$backupFile"

$endTime  = Get-Date
$duration = $endTime - $startTime

if (Test-Path $backupFile) {
    $fileSizeMB = [math]::Round((Get-Item $backupFile).Length / 1MB, 2)
    $fileSizeGB = [math]::Round((Get-Item $backupFile).Length / 1GB, 2)
    Write-Host "Backup completed successfully."
    Write-Host "Duration: $($duration.ToString('hh\:mm\:ss'))"
    Write-Host "File:     $backupFile"
    Write-Host "Size:     $fileSizeMB MB ($fileSizeGB GB)"
} else {
    Write-Host "ERROR: Backup file was not created."
}

Write-Host ""
Write-Host "Backup process complete."
'@

[System.IO.File]::WriteAllText("C:\Users\User\Desktop\mysql-dba-project\sql\phase-5\02_full_backup.ps1", $script, [System.Text.Encoding]::ASCII)