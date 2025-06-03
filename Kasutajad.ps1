# CSV-faili asukoht
$csvFail = "C:\tee\kasutajad.csv"

# Domeeni DN
$domainDN = (Get-ADDomain).DistinguishedName

# Laeb CSV sisu
$kasutajad = Import-Csv -Path $csvFail -Delimiter ','  # Vajadusel muuda ; kui CSVs on semikoolon

foreach ($rida in $kasutajad) {
    # Lahuta ees- ja perenimi (toetab mitmiksõnalisi nimesid)
    $nimed = $rida.Nimi -split " "
    $eesnimi = $nimed[0]
    $perenimi = ($nimed[1..($nimed.Length - 1)] -join "").Trim()
    $kasutajanimi = ($eesnimi + "." + $perenimi).ToLower()

    # Osakonnast OU
    $ouNimi = ($rida.Osakond).Trim()
    $ouPath = "OU=$ouNimi,$domainDN"

    # Loob OU, kui seda ei ole
    if (-not (Get-ADOrganizationalUnit -LDAPFilter "(name=$ouNimi)" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $ouNimi -Path $domainDN
        Write-Host "Loodud OU: $ouNimi"
    }

    # Loob kasutaja, kui ei eksisteeri
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$kasutajanimi'" -ErrorAction SilentlyContinue)) {
        New-ADUser `
            -Name "$eesnimi $perenimi" `
            -GivenName $eesnimi `
            -Surname $perenimi `
            -SamAccountName $kasutajanimi `
            -UserPrincipalName "$kasutajanimi@$(Get-ADDomain).DNSRoot" `
            -AccountPassword (ConvertTo-SecureString "passw0rd" -AsPlainText -Force) `
            -Enabled $true `
            -ChangePasswordAtLogon $true `
            -Path $ouPath
        Write-Host "✅ Loodud kasutaja: $kasutajanimi → $ouNimi"
    } else {
        Write-Host "⚠️ Kasutaja juba olemas: $kasutajanimi"
   }
}

