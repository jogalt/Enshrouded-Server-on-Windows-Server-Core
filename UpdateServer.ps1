# Enshrouded Dedicated Server update script for Windows Server Core
# Written by TripodGG

$attempts = 0

# Set the path for the error log
$errorLogPath = "C:\Windows\Logs\EnshroudedUpdate.log"

do {
    # Increment the attempt counter
    $attempts++

    # Prompt the user for the search path
    $searchPath = Read-Host "Enter the directory where you installed your Enshrouded server"

    # Start transcript to capture console output
    Start-Transcript -Path $errorLogPath -Append

    # Search for enshrouded_server.exe
    $fileToSearch = "enshrouded_server.exe"
    $foundFile = Get-ChildItem -Path $searchPath -Filter $fileToSearch -Recurse | Select-Object -First 1

    # Check if the file is found
    if ($foundFile -ne $null) {
        $installDirectory = $foundFile.Directory.FullName

        # Run the specified SteamCMD command
        $steamcmdCommand = "steamcmd +force_install_dir $installDirectory +login anonymous +app_update 2278520 validate +quit"
        Invoke-Expression -Command $steamcmdCommand
        Write-Host "Enshrouded Server update executed successfully!"
    } else {
        Write-Host "$fileToSearch not found in $searchPath or its subdirectories. Please try again."

        # Check if the maximum number of attempts is reached
        if ($attempts -eq 3) {
            Write-Host "Maximum number of attempts reached. Please verify the install directory and run the update script again."
            break
        }
    }

    # Stop transcript to close the log file
    Stop-Transcript
} while ($foundFile -eq $null)