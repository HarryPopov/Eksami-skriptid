# Impordib DHCP serveri haldamise mooduli
Import-Module DHCPServer

# Määrab kasutatava DHCP serveri nime (siin kasutatakse lokaalset masinat)
$dhcpServer = "localhost"

# Loob kausta raportite salvestamiseks, kui seda veel ei eksisteeri
$folderPath = "C:\DHCP_Raport"
if (!(Test-Path -Path $folderPath)) {
    New-Item -ItemType Directory -Path $folderPath | Out-Null
}

# Kogub DHCP teenuse oleku ja salvestab CSV faili
$serviceStatus = Get-Service -Name DHCPServer | Select-Object Status, Name
$serviceStatus | Export-Csv -Path "$folderPath\DHCP_ServiceStatus.csv" -NoTypeInformation -Encoding UTF8

# Kogub DHCP v4 skoopide info ja salvestab CSV faili
$scopes = Get-DhcpServerv4Scope -ComputerName $dhcpServer
$scopes | Select-Object ScopeId, Name, State, StartRange, EndRange, SubnetMask |
    Export-Csv -Path "$folderPath\DHCP_Scopes.csv" -NoTypeInformation -Encoding UTF8

# Funktsioon IP-aadresside vahemiku genereerimiseks (algus- ja lõppaadressi põhjal)
function Get-IPRange {
    param (
        [string]$startIP,
        [string]$endIP
    )

    # Teisendab IP-aadressid täisarvudeks, et neid järjest läbi käia
    $start = [System.Net.IPAddress]::Parse($startIP).GetAddressBytes()
    $end = [System.Net.IPAddress]::Parse($endIP).GetAddressBytes()
    [Array]::Reverse($start)
    [Array]::Reverse($end)
    $startInt = [BitConverter]::ToUInt32($start, 0)
    $endInt = [BitConverter]::ToUInt32($end, 0)

    # Loob IP-aadresside nimekirja
    $ipList = @()
    for ($i = $startInt; $i -le $endInt; $i++) {
        $bytes = [BitConverter]::GetBytes($i)
        [Array]::Reverse($bytes)
        $ip = [System.Net.IPAddress]::new($bytes)
        $ipList += $ip.IPAddressToString
    }
    return $ipList
}

# Algatab nimekirja vabade IP-aadresside kogumiseks
$freeIPs = @()

# Läbib iga DHCP skoopi
foreach ($scope in $scopes) {
    # Kogub kõik aktiivsed rendid (leases) ja salvestab need faili
    $leases = Get-DhcpServerv4Lease -ScopeId $scope.ScopeId -ComputerName $dhcpServer
    $leases | Select-Object IPAddress, ClientId, HostName, AddressState |
        Export-Csv -Path "$folderPath\Leases_$($scope.ScopeId).csv" -NoTypeInformation -Encoding UTF8

    # Koostab kasutuses olevate IP-aadresside nimekirja
    $used = $leases.IPAddress

    # Genereerib kogu IP-aadresside vahemiku skoopi ulatuses
    $range = Get-IPRange -startIP $scope.StartRange -endIP $scope.EndRange

    # Leiab kõik vabad aadressid (ehk need, mida ei ole kasutuses)
    $available = $range | Where-Object { $used -notcontains $_ }

    # Lisab iga vaba IP-aadressi objekti kujul nimekirja
    foreach ($ip in $available) {
        $freeIPs += [PSCustomObject]@{
            ScopeId = $scope.ScopeId
            FreeIPAddress = $ip
        }
    }
}

# Salvestab kõik vabad IP-aadressid CSV faili
$freeIPs | Export-Csv -Path "$folderPath\FreeIPAddresses.csv" -NoTypeInformation -Encoding UTF8

# Kuvab lõpus teate, et raport on loodud
Write-Host "Raport loodud: $folderPath"
