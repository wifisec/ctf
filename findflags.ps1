# Author: Adair John Collins
# Version: 1.1
# Description: PowerShell script to search for commonly known CTF flags within default and commonly readable directories on Windows systems, including patterns for variations.
# Date: 03/31/2025

# Define search paths
$searchPaths = @(
    "$env:SYSTEMDRIVE\Users",
    "$env:SYSTEMDRIVE\ProgramData",
    "$env:TEMP",
    "$env:PUBLIC",
    "$env:SYSTEMDRIVE\Program Files\Common Files"
)

# Define flag filenames
$flagFiles = @(
    "user.txt",
    "root.txt",
    "flag.txt",
    "proof.txt"
)

# Define flag patterns (using regex for variations)
$flagPatterns = @(
    "^.*user.*\.txt$",
    "^.*root.*\.txt$",
    "^.*flag.*\.txt$",
    "^.*proof.*\.txt$"
)

# Search for flags
foreach ($path in $searchPaths) {
    Write-Host "Searching in $path..."
    if (Test-Path $path) {
        Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue |
        Where-Object { -Not $_.PSIsContainer } |
        ForEach-Object {
            # Check exact filenames
            if ($flagFiles -contains $_.Name) {
                Write-Host "Flag found: $($_.FullName)"
            }
            
            # Check patterns for variations
            foreach ($pattern in $flagPatterns) {
                if ($_.Name -match $pattern) {
                    Write-Host "Flag (variation) found: $($_.FullName)"
                }
            }
        }
    } else {
        Write-Host "Path does not exist: $path"
    }
}
