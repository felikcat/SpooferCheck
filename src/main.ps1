function Write-Log {
    param (
        [string]$Message,
        [string]$LogFilePath
    )
    Write-Host $Message
    $Message | Out-File -FilePath .\logs\ids-$timestamp.txt -Append
}

function Write-Props {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [array]$properties
    )
    # Update max length for padding
    foreach ($prop in $properties) {
        if ($prop.Name.Length -gt $maxLength) {
            $maxLength = $prop.Name.Length
        }
    }

    # Output each property
    foreach ($prop in $properties) {
        $paddedName = $prop.Name.PadRight($maxLength)
        Write-Log "${paddedName}: $($prop.Value)"
    }
}


$timestamp = (Get-Date).ToString("dd-MM-yyyy_HH-mm-ss")
if (-not (Test-Path ".\logs")) {
    New-Item ".\logs" -ItemType Directory
}
. ".\src\ids.ps1"

Read-Host -Prompt "`nPress enter to exit"