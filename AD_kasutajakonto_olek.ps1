# Impordi Active Directory moodul.
Import-Module ActiveDirectory

# Kui puudub siis loo kaust aruannete salvestamiseks.
$folderPath = "C:\RAPORTID\AD_RAPORTID"
if (!(Test-Path -Path $folderPath)) {
    New-Item -ItemType Directory -Path $folderPath | Out-Null
}

# Hankige kõik AD kasutajad koos vajalike parameetritega.
$allUsers = Get-ADUser -Filter * -Properties LastLogonDate, Enabled, LockedOut

# Filtreeri kasutajad kolme kategooriasse.
# 1. Pole kunagi sisse loginud
$neverLoggedIn = $allUsers | Where-Object { -not $_.LastLogonDate }

# 2. Keelatud kasutajakontod.
$disabledAccounts = $allUsers | Where-Object { $_.Enabled -eq $false }

# 3. Lukustatud kontod.
$lockedAccounts = $allUsers | Where-Object { $_.LockedOut -eq $true }

# Salvesta tulemused CSV-Failidesse.
$neverLoggedIn | Select-Object Name, SamAccountName, Enabled, LastLogonDate |
    Export-Csv -Path "$folderPath\NeverLoggedInUsers.csv" -NoTypeInformation -Encoding UTF8

$disabledAccounts | Select-Object Name, SamAccountName, Enabled, LastLogonDate |
    Export-Csv -Path "$folderPath\DisabledAccounts.csv" -NoTypeInformation -Encoding UTF8

$lockedAccounts | Select-Object Name, SamAccountName, Enabled, LockedOut, LastLogonDate |
    Export-Csv -Path "$folderPath\LockedAccounts.csv" -NoTypeInformation -Encoding UTF8

# Kuva teade kui failid on salvestatud.
Write-Host "`CSV failid salvestati kausta: $folderPath"
