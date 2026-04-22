$Path = Read-Host "Enter directory path"
$Extension = Read-Host "Enter file extension (without dot)"
$Days = Read-Host "Enter number of days"

if (-not $Path) {
    $Path = "."
}

# Validate path
if (-not (Test-Path $Path)) {
    Write-Host "Directory does not exist: $Path" -ForegroundColor Red
    exit 1
}

# Calculate cutoff date
$cutoff = (Get-Date).AddDays(-[int]$Days)
echo $cutoff
Write-Host ""
Write-Host "Listing *.$Extension files in '$Path' older than $Days days..." -ForegroundColor Cyan
Write-Host ""

# Get files
$files = Get-ChildItem -Path $Path -Recurse -File -Filter "*.$Extension" |
    Where-Object { $_.LastWriteTime -lt $cutoff }

if ($files.Count -eq 0) {
    Write-Host "No matching files found." -ForegroundColor Green
    exit 0
}

# Display with size
$fileList = $files | Select-Object `
    LastWriteTime,
    FullName,
    @{Name="SizeMB"; Expression = { "{0:N2}" -f ($_.Length / 1MB) }}

$fileList | Sort-Object LastWriteTime | Format-Table -AutoSize

# Total size
$totalBytes = ($files | Measure-Object -Property Length -Sum).Sum
$totalMB = "{0:N2}" -f ($totalBytes / 1MB)
$totalGB = "{0:N2}" -f ($totalBytes / 1GB)

Write-Host ""
Write-Host "Total files: $($files.Count)" -ForegroundColor Yellow
Write-Host "Total size: $totalMB MB ($totalGB GB)" -ForegroundColor Yellow

$confirm = Read-Host "Continue? (Y/N)"

if ($confirm -in @("Y","y")) {
    Write-Host "Deleting..."
    Get-ChildItem -Path $Path -Recurse -File -Filter "*.$Extension" |
        Where-Object { $_.LastWriteTime -lt $cutoff } |
        ForEach-Object {
            # Log before deleting
            # Write-Output "$($_.FullName)"
            Remove-Item $_.FullName -Force
    }
    Write-Host ""
    Write-Host "Done."
}
