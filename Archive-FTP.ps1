# Archive-FTP.ps1

# AUTHOR: Jonathan Lutz (jonlutz@gmail.com)
# UPDATED: 9/7/2018
# PURPOSE: Connect to FTP site & move old files to archive folder.

# SETUP

# This script depends on the PowerShell FTP Client Module (PSFPT).

# 1) Download PSFTP.zip from here:
# https://gallery.technet.microsoft.com/scriptcenter/PowerShell-FTP-Client-db6fe0cb

# 2) Extract in two places on client machine:
# %USERPROFILE%\Documents\WindowsPowerShell\Modules
# %WINDIR%\System32\WindowsPowerShell\v1.0\Modules

Import-Module PSFTP

$DEBUG = $false

# PARAMS
$server = "192.168.1.7"
$user = "user"
$pw = "password"
$scanDirPath = "/SCAN"
$archiveDirPath = "/ARCHIVE"
$maxDaysToKeep = 2

# FUNCTIONS

function Log-Debug {
    param($output)
    if ($debug) { $output }
}

$ftp = "ftp://" + $server

# Secure password
$pwSecure = ConvertTo-SecureString $pw -AsPlainText -Force
$credentials = New-Object System.Management.Automation.PSCredential ($user, $pwSecure)

# Open FTP session
write-host ("Connecting to '" + $ftp + "'...")
try {
    Set-FTPConnection -Server $server -Credentials $credentials -Session MyTestSession -UseBinary -KeepAlive -UsePassive > $null
    $session = Get-FTPConnection -Session MyTestSession
    write-host "Done!"
}
catch {
    write-error ("Failed to connect!")
    return
}

# Get child items at path
$items = Get-FTPChildItem -Session $session -Path $scanDirPath

write-host ("Archiving files older than " + $maxDaysToKeep + " days...")

# Loop through items in scan directory
foreach ($item in $items) {
    # Process files only
    if ($item.Dir -ne 'd') {
        Log-Debug $item

        $modifiedDate = $item.ModifiedDate
        Log-Debug ("modifiedDate=" + $modifiedDate)

        $maxDateToArchive = (Get-Date).Date.adddays(-$maxDaysToKeep)
        Log-Debug ("maxDateToArchive=" + $maxDateToArchive)

        if ($modifiedDate -lt $maxDateToArchive) {
            Log-Debug "Archive!"
            write-host $item.Name

            Rename-FTPItem -Session $session -Path ($scanDirPath + "/" + $item.Name) -NewName ($archiveDirPath + "/" + $item.Name)
            continue
        }

        Log-Debug "Keep!"
    }
}

write-host "All done!"