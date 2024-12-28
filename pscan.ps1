<#
.SYNOPSIS
    Simple port scanner with banner grabbing using TCP and UDP sockets.

.DESCRIPTION
    This script scans specified ports on a given target IP address,
    grabs banners using TCP and UDP sockets, and logs the results with error checking.
    Allows specifying single ports and port ranges, and enables TCP or UDP scanning using flags.

.USAGE
    ./psscaner.ps1 -TargetIP <target_ip> -Ports <ports> -Timeout <timeout> -ScanType <TCP | UDP>

.PARAMETER TargetIP
    The target IP address to scan.

.PARAMETER Ports
    The ports to scan (e.g., "22,80,1000-1010").

.PARAMETER Timeout
    Connection timeout in seconds.

.PARAMETER ScanType
    Enable TCP or UDP scanning.

.AUTHOR
    Adair John Collins

.VERSION
    1.1
#>

param (
    [string]$TargetIP,
    [string]$Ports,
    [int]$Timeout,
    [ValidateSet("TCP", "UDP")] [string]$ScanType
)

# Variables
$LogFile = "port_scan_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$SummaryTable = @()

# Initialize log file
New-Item -Path $LogFile -ItemType File -Force

# Log message function
function Log-Message {
    param (
        [string]$Message
    )
    $Message | Tee-Object -FilePath $LogFile -Append
}

# Function to scan a single TCP port and grab banner
function Scan-TCPPort {
    param (
        [int]$Port
    )
    Log-Message "`nScanning TCP port $Port..."

    try {
        $tcpClient = New-Object Net.Sockets.TcpClient
        $tcpClient.Connect($TargetIP, $Port)
        if ($tcpClient.Connected) {
            Log-Message "TCP port $Port is open."

            $networkStream = $tcpClient.GetStream()
            $networkStream.WriteTimeout = $Timeout * 1000
            $networkStream.ReadTimeout = $Timeout * 1000

            $buffer = New-Object Byte[] 1024
            $networkStream.Read($buffer, 0, $buffer.Length)
            $banner = [Text.Encoding]::ASCII.GetString($buffer).Trim([char]0)
            if ($banner) {
                Log-Message "Banner for TCP port $Port:`n$banner"
                $SummaryTable += "$TargetIP|TCP|
