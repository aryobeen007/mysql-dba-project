# =============================================================================
# Project:  MySQL DBA
# Author:   Naseer Aryobee
# Script:   02_full_backup.ps1
# Phase:    5 — Backup and Recovery
# Purpose:  Perform a full logical backup of cancer_environment_db using
#           mysqldump. Includes timestamp in filename, compression, and
#           verification of output file size after backup completes.
# =============================================================================

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

$mysqlBin     = "C:\Program Files\MySQL\MySQL Server 8.0\bin"
$backupDir    = "C:\Users\User\Desktop\mysql-dba-project\backups"
$database     = "cancer_environment_db"
$user         = "root"
$timestamp    = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile   = "$backupDir\${database}_full_$timestamp.sql"
$compressedFile = "$backupDir\${database}_full_$timestamp.sql.gz"

# -----------------------------------------------------------------------------
# Step 1 — Confirm backup directory exists
# -----------------------------------------------------------------------------

if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
    Write-Host "Created backup directory: $backupDir"
} else {
    Write-Host "Backup directory confirmed: $backupDir"
}

# -----------------------------------------------------------------------------
# Step 2 — Run mysqldump
# -----------------------------------------------------------------------------
# --single-transaction: uses a consistent snapshot for InnoDB tables without
#   locking the database during the backup.
# --routines: includes stored procedures and functions.
# --triggers: includes triggers.
# --events: includes scheduled events.
# --flush-logs: flushes binary logs before backup so we have a clean binlog
#   position recorded in the dump file for point-in-time recovery.
# --master-data=2: records the binary log position as a comment in the dump
#   file, enabling point-in-time recovery from this backup.
# -----------------------------------------------------------------------------

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
    --master-data=2 `
    --databases $database `
    --result-file="$backupFile"

$endTime = Get-Date
$duration = $endTime - $startTime

# -----------------------------------------------------------------------------
# Step 3 — Verify backup file was created and check size
# -----------------------------------------------------------------------------

if (Test-Path $backupFile) {
    $fileSize = (Get-Item $backupFile).Length
    $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
    $fileSizeGB = [math]::Round($fileSize / 1GB, 2)
    Write-Host "Backup completed successfully."
    Write-Host "Duration:  $($duration.ToString('hh\:mm\:ss'))"
    Write-Host "File:      $backupFile"
    Write-Host "Size:      $fileSizeMB MB ($fileSizeGB GB)"
} else {
    Write-Host "ERROR: Backup file was not created. Check mysqldump output above."
}

# -----------------------------------------------------------------------------
# Step 4 — Compress the backup using gzip
# -----------------------------------------------------------------------------
# Compression typically reduces SQL dump size by 70-80%.
# Requires gzip available via Git Bash or Windows Subsystem for Linux.
# If gzip is not available, the uncompressed .sql file is retained.
# -----------------------------------------------------------------------------

Write-Host ""
Write-Host "Attempting compression..."

$gzip = Get-Command gzip -ErrorAction SilentlyContinue
if ($gzip) {
    & gzip -k "$backupFile"
    if (Test-Path $compressedFile) {
        $compressedSize = [math]::Round((Get-Item $compressedFile).Length / 1MB, 2)
        Write-Host "Compressed file: $compressedFile"
        Write-Host "Compressed size: $compressedSize MB"
    }
} else {
    Write-Host "gzip not found on PATH — skipping compression. Uncompressed backup retained."
}

Write-Host ""
Write-Host "Backup process complete: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"