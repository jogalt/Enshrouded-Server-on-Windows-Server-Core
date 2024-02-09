# Enshrouded Dedicated Server installation script for Windows Server Core
# Written by TripodGG

# Make sure all Windows updates have been applied - This can be done from sconfig under option 6
Install-Module -Name PSWindowsUpdate -Force
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot

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
# Prompt the user for server name
$serverName = Read-Host -Prompt "Enter the name you would like to use for your game server:"

# Prompt the user for server password
$serverPassword = Read-Host -Prompt "Enter the password you would like to use for your game server:"

# Prompt the user for the game port with default value 15636
$defaultGamePort = 15636
$gamePort = Read-Host -Prompt "Enter the game port to be used (press enter to use default port: $defaultGamePort)"
if (-not $gamePort) {
    $gamePort = $defaultGamePort
}

# Prompt the user for the query port with default value 15637
$defaultQueryPort = 15637
$queryPort = Read-Host -Prompt "Enter the query port to be used (press enter to use default port: $defaultQueryPort)"
if (-not $queryPort) {
    $queryPort = $defaultQueryPort
}

# Ensure that the query port is not more than 1 higher than the game port
while ($queryPort -gt ($gamePort + 1)) {
    Write-Host "Error: The query cannot be more than one port number higher than the game port."
    $gamePort = Read-Host -Prompt "Enter the game port (press enter to use default port: $defaultGamePort)"
    if (-not $gamePort) {
        $gamePort = $defaultGamePort
    }
    $queryPort = Read-Host -Prompt "Enter the query port (press enter to use default port: $defaultQueryPort)"
    if (-not $queryPort) {
        $queryPort = $defaultQueryPort
    }
}

# Prompt the user for the number of players allowed (with a maximum of 16)
$maxPlayers = Read-Host -Prompt "Enter the maximum number of players (up to 16):"
$maxPlayers = [math]::Min(16, [math]::Max(1, [int]$maxPlayers)) # Ensure the value is between 1 and 16

# Define the JSON object
$jsonObject = @{
    "name"          = $serverName
    "password"      = $serverPassword
    "saveDirectory" = "./savegame"
    "logDirectory"  = "./logs"
    "ip"            = "0.0.0.0"
    "gamePort"      = $gamePort
    "queryPort"     = $queryPort
    "slotCount"     = $maxPlayers
}

# Convert the JSON object to a JSON string
$jsonString = $jsonObject | ConvertTo-Json

# Set the file path
$filePath = "C:\enshrouded\enshrouded_server.json"

# Save the JSON string to the file
$jsonString | Set-Content -Path $filePath

Write-Host "Configuration saved to $filePath"

# Function to check and create firewall rules
function CheckAndCreateFirewallRule($port, $protocol, $ruleName) {
    $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue

    if (-not $existingRule) {
        New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol $protocol -LocalPort $port
        Write-Host "Firewall rule for $protocol port $port created."
    } else {
        Write-Host "Firewall rule for $protocol port $port already exists. Skipping creation."
    }
}

# Check and create firewall rules
CheckAndCreateFirewallRule $gamePort "TCP" "EnshroudedGamePort"
CheckAndCreateFirewallRule $queryPort "UDP" "EnshroudedQueryPort"

# Create a shortcut link to the Enshrouded server application in the home directory. This will allow you to run the server at logon by typing '.\enserver.lnk' 
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$Home\enserver.lnk")
$Shortcut.TargetPath = "C:\enshrouded\enshrouded_server.exe"
$Shortcut.Save()

# Echo the completion of the script and provide the command to start the server app.
Write-Output "Enshrouded dedicated server has successfully been installed. Use '.\enserver.lnk' to start the game server app."

# Check if there are pending reboots due to Windows updates
$pendingReboots = Get-PendingReboot
if ($pendingReboots.Count -gt 0) {
    # Prompt the user to reboot if there are pending reboots
    $rebootChoice = Read-Host -Prompt "There are pending reboots due to Windows updates. Do you want to reboot now? (Y/N)"
    if ($rebootChoice -eq 'Y' -or $rebootChoice -eq 'y') {
        Write-Host "Rebooting the server..."
        Restart-Computer -Force
    } else {
        Write-Host "Please remember to reboot the server later to apply the updates."
    }
} else {
    Write-Host "No pending reboots. The server is up to date."
}