# Impordi DHCP moodul
Import-Module DHCPServer

# Määra serveri nimi
$dhcpServer = "localhost"

# Loo kaust
$folderPath = "C:\DHCP_Raport"
if (!(Test-Path -Path $folderPath)) {
    New-Item -ItemType Directory -Path $folderPath | Out-Null
}

# Teenuse olek
$serviceStatus = Get-Service -Name DHCPServer | Select-Object Status, Name
$serviceStatus | Export-Csv -Path "$folderPath\DHCP_ServiceStatus.csv" -NoTypeInformation -Encoding UTF8

# Skoobid
$scopes = Get-DhcpServerv4Scope -ComputerName $dhcpServer
$scopes | Select-Object ScopeId, Name, State, StartRange, EndRange, SubnetMask |
    Export-Csv -Path "$folderPath\DHCP_Scopes.csv" -NoTypeInformation -Encoding UTF8

# IP-aadresside vahemiku genereerimise funktsioon
function Get-IPRange {
    param (
        [string]$startIP,
        [string]$endIP
    )

    $start = [System.Net.IPAddress]::Parse($startIP).GetAddressBytes()
    $end = [System.Net.IPAddress]::Parse($endIP).GetAddressBytes()
    [Array]::Reverse($start)
    [Array]::Reverse($end)
    $startInt = [BitConverter]::ToUInt32($start, 0)
    $endInt = [BitConverter]::ToUInt32($end, 0)

    $ipList = @()
    for ($i = $startInt; $i -le $endInt; $i++) {
        $bytes = [BitConverter]::GetBytes($i)
        [Array]::Reverse($bytes)
        $ip = [System.Net.IPAddress]::new($bytes)
        $ipList += $ip.IPAddressToString
    }
    return $ipList
}

# IP-de kogumine
$freeIPs = @()

foreach ($scope in $scopes) {
    # Aktiivsed ühendused
    $leases = Get-DhcpServerv4Lease -ScopeId $scope.ScopeId -ComputerName $dhcpServer
    $leases | Select-Object IPAddress, ClientId, HostName, AddressState |
        Export-Csv -Path "$folderPath\Leases_$($scope.ScopeId).csv" -NoTypeInformation -Encoding UTF8

    $used = $leases.IPAddress
    $range = Get-IPRange -startIP $scope.StartRange -endIP $scope.EndRange

    $available = $range | Where-Object { $used -notcontains $_ }

    foreach ($ip in $available) {
        $freeIPs += [PSCustomObject]@{
            ScopeId = $scope.ScopeId
            FreeIPAddress = $ip
        }
    }
}

# Salvesta vabad IP-aadressid
$freeIPs | Export-Csv -Path "$folderPath\FreeIPAddresses.csv" -NoTypeInformation -Encoding UTF8

# Lõpuks info
Write-Host "`nRaport loodud: $folderPath" -ForegroundColor Green
