# Enshrouded Dedicated Server installation script for Windows Server Core
# Written by TripodGG

# Make sure all Windows updates have been applied - This can be done from sconfig under option 6
Install-Module -Name PSWindowsUpdate -Force
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll

# Set the execution policy
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Scoop
iex "& {$(irm get.scoop.sh)} -RunAsAdmin"

# Install git
scoop install git

# Install Scoop extras bucket
scoop bucket add extras

# Add Nano for Windows bucket
scoop bucket add .oki https://github.com/okibcn/Bucket

# Install Nano text editor and SteamCMD
scoop install nano
scoop install steamcmd

# Check the version of Windows Server and add the correct Windows desktop application compatibility files
$osVersion = (Get-CimInstance Win32_OperatingSystem).Version

# Check if the OS is Windows Server 2016/2019
if ($osVersion -match '10\.0\.(14393|17763)') {
    Write-Host "Windows Server 2016/2019 detected."
    # Run the command for Server 2016 or 2019
    Add-WindowsCapability -Online -Name ServerCore.AppCompatibility
}
# Check if the OS Windows Server 2022
elseif ($osVersion -match '10\.0\.(20348)') {
    Write-Host "Windows Server 2022 detected."
    # Run the command for Server 2022
    Add-WindowsCapability -Online -Name ServerCore.AppCompatibility~~~~0.0.1.0
}
else {
    Write-Host "Unsupported Windows Server version."
	exit
}

# Install the OpenSSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Start the sshd service
Start-Service sshd

# Set the SSH service to automatic startup
Set-Service -Name sshd -StartupType 'Automatic'

# Create a firewall rule allowing SSH access
if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
    Write-Output "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
} else {
    Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists."
}

# Create the directory for the Enshrouded server to be installed to
mkdir "c:\Enshrouded\"

# Install Enshrouded dedicated server 
steamcmd +force_install_dir c:\Enshrouded\ +login anonymous +app_update 2278520 validate +quit

# Create the Enshrouded config file and write the contents of the file
New-Item c:\Enshrouded\enshrouded_server.json
Set-Content c:\Enshrouded\enshrouded_server.json '{

    "name": "ENSHROUDED_SERVER_NAME",

    "password": "ENSHROUDED_SERVER_PASSWORD",

    "saveDirectory": "./savegame",

    "logDirectory": "./logs",

    "ip": "0.0.0.0",

    "gamePort": 15636,

    "queryPort": 15637,

    "slotCount": ENSHROUDED_SERVER_MAXPLAYERS

}'

# Create firewall rules to allow external access to the Enshrouded server
if (!(Get-NetFirewallRule -Name "Enshrouded-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
    Write-Output "Firewall Rule 'Enshrouded-TCP' does not exist, creating it..."
    New-NetFirewallRule -Name 'Enshrouded-TCP' -DisplayName 'Enshrouded-TCP' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 15636-15637
} else {
    Write-Output "Firewall rule 'Enshrouded-TCP' has been created and exists."
}


if (!(Get-NetFirewallRule -Name "Enshrouded-UDP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
    Write-Output "Firewall Rule 'Enshrouded-UDP' does not exist, creating it..."
    New-NetFirewallRule -Name 'Enshrouded-UDP' -DisplayName 'Enshrouded-UDP' -Enabled True -Direction Inbound -Protocol UDP -Action Allow -LocalPort 15636-15637
} else {
    Write-Output "Firewall rule 'Enshrouded-UDP' has been created and exists."
}

# Create a shortcut link to the Enshrouded server application in the home directory. This will allow you to run the server at logon by typing '.\enserver.lnk' 
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$Home\enserver.lnk")
$Shortcut.TargetPath = "C:\enshrouded\enshrouded_server.exe"
$Shortcut.Save()

# Echo the completion of the script and provide the command to start the server app.
Write-Output "Enshrouded dedicated server has successfully been installed. Use '.\enserver.lnk' to start the game server app."