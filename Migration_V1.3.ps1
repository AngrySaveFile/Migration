#download csv file
$url = "https://docs.google.com/spreadsheets/d/e/2PACX-1vT1VcPm2l-BveQr8xi62N-VLrSBBmU-pkL1okA1mAxqUS8wSMrxEV4al5dfr-m9s9j82sXOArH-a24I/pub?output=csv"
$output = "C:\Windows\Temp\computers.csv"
Invoke-WebRequest -Uri $url -OutFile $output 

#Define the path to the CSV file we downloaded 
$csvPath = "C:\Windows\Temp\computers.csv"

# Get the current computer name
$currentComputerName = $env:COMPUTERNAME

# Import the CSV
$csvData = Import-Csv -Path $csvPath

# Search for the computer name and assign the username column and jcuser column to a variable if a match is found
$matchedRow = $csvData | Where-Object { $_.ComputerName -eq $currentComputerName }
$username = $matchedRow.username
$jcuser = $matchedRow.jcuser
#set migrated variable to false
$global:migrated = $false

function Migration {
    if ($matchedRow) {    
        $username = $matchedRow.username
        # Remove the "am\" domain prefix from the username if present; if not present, the entire username is used.
        $sessionuser = ($username -split "am\\")[-1]
        $jcuser = $matchedRow.jcuser
        Write-Output "Assigned username: $username"
        Write-Output "Assigned jcuser: $jcuser"
    
        #logout user if they are logged in
        Write-Output "Checking for active user sessions..."
        $sessions = quser | Select-String $sessionuser #gets the users session
        $sessionId = ($sessions -split '\s+')[2] #extracts the session ID from the output
        if ($sessionId) {
            Write-Output "Logging out user $sessionuser with session ID $sessionId"
            msg * "User $sessionuser will be logged out to complete the migration process. Please do not log in again until after the computer reboots."
            start-sleep -Seconds 60
            logoff $sessionId

        } else {
            Write-Output "No active session found for user $sessionuser continuing with the migration." 
        }
        Start-Sleep -Seconds 40
        #allow user to run scripts
        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
        #Install the JumpCloud module and dependencies
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        # Check if the JumpCloud module is installed, if not, install it
        if (-not (Get-Module -ListAvailable -Name JumpCloud.ADMU)) {
            Install-Module -Name JumpCloud.ADMU -Confirm:$False -Force
        }
        Import-Module JumpCloud.ADMU
        #start the migration process
        Start-Migration -SelectedUserName "$username" -JumpCloudUserName "$jcuser" -TempPassword 'Temp123!Temp123!' -LeaveDomain $true -ForceReboot $false
        Write-Output "Migration completed for user: $username to user: $jcuser"
        $global:migrated = $true
    } 
    else {
        Write-Output "No match found for computer name $currentComputerName"
    }
}

function ActivateWindows {
    # Get the OEM product key from the BIOS
    $OEMKey = (Get-CimInstance -ClassName SoftwareLicensingService).OA3xOriginalProductKey    
    # Check if a key was found
    if ($OEMKey) {
        Write-Host "OEM key found: $OEMKey"
    
        # Attempt to activate Windows using the retrieved key
            slmgr /ipk $OEMKey
            slmgr /ato
            Write-Output "Windows activation process completed."
            
    } else {
        # If no key was found, output a message
        Write-Output "Windows activation failed. No OEM key found."
    }
}

function MakeAdmin {
    
    # Add the migrated user to the local Administrators group
    if (![string]::IsNullOrWhiteSpace($jcuser)) {
        try {
            Add-LocalGroupMember -Group "Administrators" -Member $jcuser -ErrorAction Stop
            Write-Host "User $jcuser has been added to the Administrators group."
        } catch {
            Write-Host "Failed to add user $jcuser to the Administrators group. Error: $_"
        }
    } else {
        Write-Host "No valid JumpCloud user found to add to the Administrators group."
    }
}

function RestartIfSuccess {
    if($global:migrated){# Reboot the computer to complete the migration
    Write-Output "Rebooting the computer to complete the migration..."
    msg * "The computer will reboot in 30 seconds to complete the migration process."
    # Wait for 30 seconds before rebooting
    Write-Output "Migration script completed. Please check the output for any errors or messages."
    # Wait for 30 seconds before rebooting
    Start-Sleep -Seconds 30; Restart-Computer -Force
    Write-Output "Reboot started"
    } else {
        Write-Output "Migration was not successful, skipping reboot."
    }
}
# Main script execution
Migration
ActivateWindows
MakeAdmin
RestartIfSuccess
# End of script

    