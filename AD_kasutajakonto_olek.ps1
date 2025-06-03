# Impordi Active Directory moodul
Import-Module ActiveDirectory

# Loo sihtkaust, kui see puudub
$folderPath = "C:\AD_Raport"
if (!(Test-Path -Path $folderPath)) {
    New-Item -ItemType Directory -Path $folderPath | Out-Null
}

# Hankige kõik kasutajad koos vajalike omadustega
$allUsers = Get-ADUser -Filter * -Properties LastLogonDate, Enabled, LockedOut

# Filtreeri kategooriad
$neverLoggedIn = $allUsers | Where-Object { -not $_.LastLogonDate }
$disabledAccounts = $allUsers | Where-Object { $_.Enabled -eq $false }
$lockedAccounts = $allUsers | Where-Object { $_.LockedOut -eq $true }

# Salvesta .csv-failidesse
$neverLoggedIn | Select-Object Name, SamAccountName, Enabled, LastLogonDate |
    Export-Csv -Path "$folderPath\NeverLoggedInUsers.csv" -NoTypeInformation -Encoding UTF8

$disabledAccounts | Select-Object Name, SamAccountName, Enabled, LastLogonDate |
    Export-Csv -Path "$folderPath\DisabledAccounts.csv" -NoTypeInformation -Encoding UTF8

$lockedAccounts | Select-Object Name, SamAccountName, Enabled, LockedOut, LastLogonDate |
    Export-Csv -Path "$folderPath\LockedAccounts.csv" -NoTypeInformation -Encoding UTF8

# Lõpuks info
Write-Host "`nCSV failid salvestati kausta: $folderPath" -ForegroundColor Green
