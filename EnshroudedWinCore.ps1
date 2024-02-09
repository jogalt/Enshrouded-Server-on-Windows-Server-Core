# Enshrouded Dedicated Server installation script for Windows Server Core
# Written by TripodGG

# Check the version of Windows Server and add the correct Windows desktop application compatibility files
$osVersion = (Get-CimInstance Win32_OperatingSystem).Version

# Check if the OS is Windows Server 2016/2019
if ($osVersion -match '10\.0\.(14393|17763)') {
    Write-Host "Windows Server 2016/2019 detected."
}
# Check if the OS Windows Server 2022
elseif ($osVersion -match '10\.0\.(20348)') {
    Write-Host "Windows Server 2022 detected."
}
else {
    Write-Host "Unsupported Windows Server version. Please use a supported version of Windows Server."
	exit
}

# Check if NuGet is installed
if (-not (Get-Module -ListAvailable -Name NuGet)) {
    # NuGet is not installed, so install it silently
    Install-PackageProvider -Name NuGet -Force -ForceBootstrap -Scope CurrentUser -Confirm:$false
    Install-Module -Name NuGet -Force -Scope CurrentUser -Confirm:$false
}

# Make sure all Windows updates have been applied - This can also be done from sconfig under option 6
# Install the PSWindowsUpdate module
Install-Module -Name PSWindowsUpdate -Force

# Import the module
Import-Module PSWindowsUpdate

# Set the execution policy
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Check for and install updates
Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot

# Check the version of Windows Server and add the correct Windows desktop application compatibility files
$osVersion = (Get-CimInstance Win32_OperatingSystem).Version

# Check if the OS is Windows Server 2016/2019
if ($osVersion -match '10\.0\.(14393|17763)') {
    Write-Host "Installing App Compatibility Tools for Windows Server 2016/2019."
    # Run the command for Server 2016 or 2019
    Add-WindowsCapability -Online -Name ServerCore.AppCompatibility
}
# Check if the OS Windows Server 2022
elseif ($osVersion -match '10\.0\.(20348)') {
    Write-Host "Installing App Compatibility Tools for Windows Server 2022."
    # Run the command for Server 2022
    Add-WindowsCapability -Online -Name ServerCore.AppCompatibility~~~~0.0.1.0
}
else {
    Write-Host "Continuing with installation..."
}

# Check to see if apps are already installed and install them if they are not
# Function to check if a command is available
function CommandExists($command) {
    Get-Command $command -ErrorAction SilentlyContinue
}

# Check if Scoop is installed
if (-not (CommandExists 'scoop')) {
    # Scoop is not installed, so install it
    Write-Host "Scoop is not installed. Installing Scoop..."
    
    # Run the Scoop installation command with elevated privileges
    iex "& {$(irm get.scoop.sh)} -RunAsAdmin"

    # Check if Scoop installation was successful
    if (CommandExists 'scoop') {
        Write-Host "Scoop installed successfully."
    } else {
        Write-Host "Failed to install Scoop. Please check your internet connection and try again."
        exit 1
    }
} else {
    # Scoop is already installed
    Write-Host "Scoop is already installed. Skipping installation."
}

# Check if Chocolatey is installed
if (-not (CommandExists 'choco')) {
    # Chocolatey is not installed, so install it
    Write-Host "Chocolatey is not installed. Installing Chocolatey..."
    
    # Run the Chocolatey installation command with elevated privileges
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

    # Check if Chocolatey installation was successful
    if (CommandExists 'choco') {
        Write-Host "Chocolatey installed successfully."
    } else {
        Write-Host "Failed to install Chocolatey. Please check your internet connection and try again."
        exit 1
    }
} else {
    # Chocolatey is already installed
    Write-Host "Chocolatey is already installed. Skipping installation."
}

# Check if Git is installed
if (-not (CommandExists 'git')) {
    # Git is not installed, so install it using Chocolatey
    Write-Host "Git is not installed. Installing Git..."
    scoop install git

    # Check if Git installation was successful
    if (CommandExists 'git') {
        Write-Host "Git installed successfully."
    } else {
        Write-Host "Failed to install Git. Please check your internet connection and try again."
        exit 1
    }
} else {
    # Git is already installed
    Write-Host "Git is already installed. Skipping installation."
}

# Check if Scoop Extras bucket is added
if (-not (Test-Path "$env:USERPROFILE\scoop\buckets\extras")) {
    # Scoop Extras bucket is not added, so add it
    Write-Host "Scoop Extras bucket is not added. Adding Scoop Extras bucket..."
    
    # Run the Scoop command to add the Extras bucket
    scoop bucket add extras

    # Check if Scoop Extras bucket addition was successful
    if (Test-Path "$env:USERPROFILE\scoop\buckets\extras") {
        Write-Host "Scoop Extras bucket added successfully."
    } else {
        Write-Host "Failed to add Scoop Extras bucket. Please check your internet connection and try again."
        exit 1
    }
} else {
    # Scoop Extras bucket is already added
    Write-Host "Scoop Extras bucket is already added. Skipping addition."
}

# Check if Nano for Windows is installed
if (-not (CommandExists 'nano')) {
    # Nano for Windows is not installed, so install it using Scoop
    Write-Host "Nano for Windows is not installed. Installing Nano for Windows..."
    scoop install nano

    # Check if Nano for Windows installation was successful
    if (CommandExists 'nano') {
        Write-Host "Nano for Windows installed successfully."
    } else {
        Write-Host "Failed to install Nano for Windows. Please check your internet connection and try again."
        exit 1
    }
} else {
    # Nano for Windows is already installed
    Write-Host "Nano for Windows is already installed. Skipping installation."
}

# Check if SteamCMD is installed
if (-not (CommandExists 'steamcmd')) {
    # SteamCMD is not installed, so install it using Scoop
    Write-Host "SteamCMD is not installed. Installing SteamCMD..."
    scoop install steamcmd

    # Check if SteamCMD installation was successful
    if (CommandExists 'steamcmd') {
        Write-Host "SteamCMD installed successfully."
    } else {
        Write-Host "Failed to install SteamCMD. Please check your internet connection and try again."
        exit 1
    }
} else {
    # SteamCMD is already installed
    Write-Host "SteamCMD is already installed. Skipping installation."
}

# Install the OpenSSH Server (convenient for copying files)
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

# Function to prompt user for install path
function PromptForInstallPath {
    $installPath = Read-Host -Prompt "Enter the installation directory where you would like to install the dedicated server"

    # Validate and ensure the path is not empty
    while (-not $installPath -or -not (Test-Path $installPath -IsValid)) {
        Write-Host "Invalid directory or directory does not exist."
        $createPathChoice = Read-Host -Prompt "Do you want to create the directory? (Y/N)"
        
        if ($createPathChoice -eq 'Y' -or $createPathChoice -eq 'y') {
            # Attempt to create the path
            try {
                New-Item -Path $installPath -ItemType Directory -Force
                Write-Host "Directory created successfully."
            } catch {
                Write-Host "Error creating path. Please enter a valid installation path."
                $installPath = Read-Host -Prompt "Enter the installation path where you would like to install the dedicated server"
            }
        } else {
            # User does not want to create the path, prompt again for install path
            $installPath = Read-Host -Prompt "Enter the installation directory where you would like to install the dedicated server"
        }
    }

    return $installPath
}

# Prompt user for install path
$chosenPath = PromptForInstallPath

# Use the $chosenPath variable later in your script
Write-Host "Success! Installing to $chosenPath"

# Continue with your script...


# Install Enshrouded dedicated server 
steamcmd +force_install_dir $chosenPath +login anonymous +app_update 2278520 validate +quit

# Create the Enshrouded config file and write the contents of the file
# Prompt the user for server name
$serverName = Read-Host -Prompt "Enter the name you would like to use for your game server"

# Prompt the user for server password
$serverPassword = Read-Host -Prompt "Enter the password you would like to use for your game server"

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
$maxPlayers = Read-Host -Prompt "Enter the maximum number of players (up to 16)"
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
$filePath = "$chosenPath\enshrouded_server.json"

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
$Shortcut.TargetPath = "$chosenPath\enshrouded_server.exe"
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