#region USB
Write-Log "`n-- USB --"
$usbDevices = Get-WmiObject Win32_USBControllerDevice

if ($usbDevices.Count -eq 0) {
    Write-Host "No USB devices found."
} else {
    foreach ($device in $usbDevices) {
        $deviceInfo = [Wmi]$device.Dependent
        
        $properties = @(
            @{ Name = "Name"; Value = $deviceInfo.Description },
            @{ Name = "ID"; Value = $deviceInfo.DeviceID },
            @{ Name = "Serial"; Value = ($deviceInfo.DeviceID -split '\\')[-1] }
        )
        
        Write-Props $properties
        Write-Host ""
    }
}
#endregion

#region HV detections
Write-Log "`n-- Hypervisor --"

$thermals = Get-CimInstance MSAcpi_ThermalZoneTemperature -Namespace "root/wmi"
$kelvin = 10
$celsius = 273.15

$properties = @(
    @{Name = "CPU Active Trip-point"; Value = "$($thermals.ActiveTripPoint[0] / $kelvin - $celsius) C" }
    @{Name = "CPU Active Trip-point count"; Value = $($thermals.ActiveTripPointCount[0]) }
    @{Name = "CPU Critical Trip-point"; Value = "$($thermals.CriticalTripPoint[0] / $kelvin - $celsius) C" }
    @{Name = "CPU Current"; Value = "$($thermals.CurrentTemperature[0] / $kelvin - $celsius) C" }
)

Write-Props $properties

$portConnector = Get-CimInstance -Class Win32_PortConnector
if (-not ([string]::IsNullOrEmpty($portConnector))) {
    Write-Log "Port Connectors: detected, not a hypervisor."
}
else {
    Write-Log "Port Connectors: none, a sign of a hypervisor."
}
#endregion

#region BIOS
$bios = Get-CimInstance Win32_BIOS
$properties = @(
    @{Name = "Vendor"; Value = $($bios.Manufacturer) }
    @{Name = "Version"; Value = $($bios.SMBIOSBIOSVersion) }
    @{Name = "Release Date"; Value = $($bios.ReleaseDate) }
    @{Name = "Revision"; Value = $($bios.BIOSVersion) }
)

Write-Log "`n-- BIOS --"
Write-Props $properties
#endregion

#region Motherboard
$system = Get-CimInstance Win32_ComputerSystem
$properties = @(
    @{Name = "Manufacturer"; Value = $($system.Manufacturer) }
    @{Name = "Product Name"; Value = $($system.Model) }
    @{Name = "Version"; Value = $($system.SystemFamily) }
    @{Name = "Serial"; Value = $($system.SerialNumber) }
    @{Name = "UUID"; Value = $((Get-CimInstance Win32_ComputerSystemProduct).UUID) }
)

Write-Log "`n-- Motherboard --"
Write-Props $properties
#endregion

#region RAM
$bankCount = 1
$memoryModules = Get-CimInstance -Class Win32_PhysicalMemory

foreach ($module in $memoryModules) {
    $sizeGB = [math]::Round($module.Capacity / 1GB, 2)
    $properties = @(
        @{Name = "Size"; Value = "$sizeGB GB" },
        @{Name = "Type"; Value = $module.MemoryType },
        @{Name = "Speed"; Value = "$($module.Speed) MHz" },
        @{Name = "Manufacturer"; Value = $module.Manufacturer },
        @{Name = "Part Number"; Value = $module.PartNumber },
        @{Name = "Serial"; Value = $module.SerialNumber },
        @{Name = "Bank/Slot"; Value = $module.BankLabel }
    )
    
    foreach ($prop in $properties) {
        if ($prop.Name.Length -gt $maxLength) {
            $maxLength = $prop.Name.Length
        }
    }
}

foreach ($module in $memoryModules) {
    Write-Log "`n-- RAM Stick $bankCount --"

    foreach ($prop in $properties) {
        $paddedName = $prop.Name.PadRight($maxLength)
        Write-Log "${paddedName}: $($prop.Value)"
    }
    
    $bankCount++
}

$totalMemory = (Get-CimInstance -Class Win32_ComputerSystem).TotalPhysicalMemory
$totalMemoryGB = [math]::Round($totalMemory / 1GB, 2)

Write-Log "`nTotal RAM Size: $totalMemoryGB GB"
#endregion

#region Networking
$netAdapter = Get-NetAdapter

Write-Log "`n-- Networking --"
foreach ($interface in $netAdapter) {
    $properties = @(
        @{Name = "Name"; Value = $interface.InterFaceDescription }
        @{Name = "MAC Address"; Value = $interface.MacAddress.Replace("-", ":") }
    )
    Write-Props $properties
    Write-Log ""
}
#endregion

#region Disks
$disks = Get-Disk
Write-Log "`n-- Disks --"

if (([string]::IsNullOrEmpty($disks))) {
    Write-Log "No disks were found. Your spoofer is bad."
}
else {
    foreach ($obj in $disks) {
        $properties = @(
            @{Name = "Order"; Value = $obj.Number }
            @{Name = "Name"; Value = $obj.FriendlyName }
            @{Name = "Serial"; Value = $obj.SerialNumber.Replace(" ", "") }
        )
        Write-Props $properties
        Write-Log ""
    }
}
#endregion

# Untested, I don't have a NVIDIA GPU.
if (Get-Command nvidia-smi -errorAction SilentlyContinue) {
    Write-Log "`n-- NVIDIA --"
    nvidia-smi -L
}
else {
    Write-Log "`n-- NVIDIA --`nNo NVIDIA GPU detected. Note that spoofing AMD GPUs is unnecessary."
}

#region Windows
$properties = @(
    @{Name = "Serial Number"; Value = (Get-CimInstance -ClassName Win32_OperatingSystem).SerialNumber }
)

Write-Log "`n-- Windows --"
Write-Props $properties
#endregion

#region Displays
$monitors = Get-CimInstance -Namespace root\wmi -Class WmiMonitorID

Write-Log "`n-- Displays --"
foreach ($obj in $monitors) {
    $properties = @(
        @{Name = "Name"; Value = [System.Text.Encoding]::ASCII.GetString($obj.UserFriendlyName -ne 0) }
        @{Name = "Serial"; Value = [System.Text.Encoding]::ASCII.GetString($obj.SerialNumberID -ne 0) }
    )
    Write-Props $properties
}
#endregion

#region TPM
$tpm = Get-Tpm

Write-Log "`n-- TPM --"
if (-not $tpm.TpmPresent -or -not $tpm.TpmReady) {
    Write-Log "There is no Trusted Platform Module available."
}
else {
    $tpmMC = Get-TpmEndorsementKeyInfo
    Write-Log $tpmMC.ManufacturerCertificates
}
#endregion
