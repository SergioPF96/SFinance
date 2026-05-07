$bytes = [System.IO.File]::ReadAllBytes('C:\Users\Sergio\Documents\sfinance.sqlite')
$header = [System.Text.Encoding]::ASCII.GetString($bytes, 0, 16)
Write-Host "Header (ASCII): $header"
Write-Host "Hex: $($bytes[0..15] | ForEach-Object { $_.ToString('x2') } | Join-String -Separator ' ')"
if ($header -eq "SQLite format 3`0") {
    Write-Host "RESULT: PLAIN SQLite (NOT encrypted)"
} else {
    Write-Host "RESULT: ENCRYPTED (first bytes are not SQLite header)"
}
