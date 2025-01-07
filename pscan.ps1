<#
.SYNOPSIS
    Simple port scanner with banner grabbing using TCP and UDP sockets.

.DESCRIPTION
    This script scans specified ports on a given target IP address,
    grabs banners using TCP and UDP sockets, and logs the results with error checking.
    Allows specifying single ports and port ranges, and enables TCP or UDP scanning using flags.

.USAGE
    ./bscan.ps1 -TargetIP <target_ip> -Ports <ports> -Timeout <timeout> -ScanType <TCP | UDP>

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
    1.0
#>

param (
    [string]$TargetIP,
    [string]$Ports,
    [int]$Timeout,
    [ValidateSet("TCP", "UDP")] [string]$ScanType
)

# Variables
$LogFile = "port_scan_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

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
            $banner = [Text.Encoding]::ASCII.GetString($buffer)
            if ($banner) {
                Log-Message "Banner for TCP port $Port:`n$banner"
            } else {
                Log-Message "No banner received for TCP port $Port."
            }

            $networkStream.Close()
            $tcpClient.Close()
        } else {
            Log-Message "TCP port $Port is closed or filtered."
        }
    } catch {
        Log-Message "Error scanning TCP port $Port: $_"
    }
}

# Function to scan a single UDP port and grab banner
function Scan-UDPPort {
    param (
        [int]$Port
    )
    Log-Message "`nScanning UDP port $Port..."

    try {
        $udpClient = New-Object Net.Sockets.UdpClient
        $udpClient.Connect($TargetIP, $Port)

        $sendBytes = [Text.Encoding]::ASCII.GetBytes("Hello")
        $udpClient.Send($sendBytes, $sendBytes.Length)

        Start-Sleep -Seconds $Timeout

        if ($udpClient.Available -gt 0) {
            $receivedBytes = $udpClient.Receive([ref]$remoteEndPoint)
            $banner = [Text.Encoding]::ASCII.GetString($receivedBytes)
            if ($banner) {
                Log-Message "Banner for UDP port $Port:`n$banner"
            } else {
                Log-Message "No banner received for UDP port $Port."
            }
        } else {
            Log-Message "UDP port $Port is open but no banner received."
        }

        $udpClient.Close()
    } catch {
        Log-Message "Error scanning UDP port $Port: $_"
    }
}

# Function to process the ports argument and scan ports
function Process-Ports {
    param (
        [string]$PortsArg
    )
    $PortsArray = $PortsArg -split ','

    foreach ($PortSpec in $PortsArray) {
        if ($PortSpec -contains '-') {
            $Range = $PortSpec -split '-'
            for ($Port = [int]$Range[0]; $Port -le [int]$Range[1]; $Port++) {
                if ($ScanType -eq "TCP") {
                    Scan-TCPPort -Port $Port
                } elseif ($ScanType -eq "UDP") {
                    Scan-UDPPort -Port $Port
                }
            }
        } else {
            if ($ScanType -eq "TCP") {
                Scan-TCPPort -Port [int]$PortSpec
            } elseif ($ScanType -eq "UDP") {
                Scan-UDPPort -Port [int]$PortSpec
            }
        }
    }
}

# Main function to start the port scanning
function Main {
    Log-Message "Starting port scanning on $TargetIP for ports: $Ports"
    Process-Ports -PortsArg $Ports
    Log-Message "`nPort scanning completed. Results saved in $LogFile."
}

# Run the main function
Main
