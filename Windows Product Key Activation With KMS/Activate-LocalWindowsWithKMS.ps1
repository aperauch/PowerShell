# Must run as admin

# KMS Client Keys
$W10_SAC_KEY = "NPPR9-FWDCX-D2C8J-H872K-2YT43" # Windows 10 Semi-Annual Channel Enterprise edition
$W10_KEY = "M7XTQ-FN8P6-TTKYV-9D4CC-J462D" # Windows 10 LTSC 2019 Enterprise edition
$W16_KEY = "CB7KF-BWN84-R7R2Y-793K2-8XDDG" # Windows Server 2016 LTSC Datacenter edition
$W19_KEY = "WMDGN-G9PQG-XVVXX-R3X43-63DFG" # Windows Server 2019 LTSC Datacenter edition

# Windows Build Versions
$W10_1809_BUILD = 17763
$W10_ENT_2004_BUILD = 19041
$W16_BUILD = 14393
$W19_BUILD = 17763

# Target KMS Server
$KMS_SERVER = "vmc-c-kms01.vmwarepso.org:1688"

# Get Windows Server OS version build number
$OSVersion = [System.Environment]::OSVersion.Version

# Select KMS client activation key based on reported OS version build number
$kmsKey = $null
switch ($OSVersion.Build) {
    $W10_1809_BUILD { $kmsKey = $W10_KEY ; break }
    $W10_ENT_2004_BUILD { $kmsKey = $W10_KEY ; break }
    $W16_BUILD { $kmsKey = $W16_KEY ; break }
    $W19_BUILD { $kmsKey = $W19_KEY ; break }

    default { 
        Write-Host "Unknown Windows Version for $(hostname):  $($OSVersion)"
        Write-Host "Defaulting to Windows 10 Enterprise Semi-Annual Channel Build."
        $kmsKey = $W10_SAC_KEY
        break 
    }
}

# If the OS version build number was known, attempt to activate with the specified KMS client key
if ($kmsKey) {
    Write-Host "Activating $(hostname) with OS version build $($OSVersion.Build) using KMS client key $($kmsKey)."
    cscript c:\windows\system32\slmgr.vbs /skms $KMS_SERVER
    cscript c:\windows\system32\slmgr.vbs /ipk $kmsKey
    cscript c:\windows\system32\slmgr.vbs /ato
}