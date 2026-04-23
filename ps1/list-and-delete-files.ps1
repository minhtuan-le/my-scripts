$Path = Read-Host "Enter a directory path"

while (-not (Test-Path $Path -PathType Container)) {

    $Path = Read-Host "Not a correct path. Enter a valid directory path"
}

$Extension = Read-Host "Enter file extension (without dot)"

$Days = 0

while ($Days -le 29) {
    $Days = Read-Host "Enter number of days (must be > 30)"
    
    # Try convert to integer safely
    if (-not [int]::TryParse($Days, [ref]$null)) {
        Write-Host "Please enter a valid number."
        $Days = 0
        continue
    }

    $Days = [int]$Days

    if ($Days -le 30) {
        Write-Host "Value must be greater than 30. Try again."
    }
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

$confirm = Read-Host "Confirm DELETE all the files LISTED above? (Y/N)"

if ($confirm -in @("Y","y")) {
    Get-ChildItem -Path $Path -Recurse -File -Filter "*.$Extension" |
        Where-Object { $_.LastWriteTime -lt $cutoff } |
        ForEach-Object {
            # Log before deleting
            Write-Output "$($_.FullName)"
            Remove-Item $_.FullName -Force
    }
    Write-Host "Remaining Files:"
    Get-ChildItem -Path $Path -Recurse -File -Filter "*.$Extension"

    Write-Host ""
    Write-Host "Done."
}
