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
        $sessionuser = ($username -split "am\\")[-1] #removes domain name from username and ensures it's a string
        $jcuser = $matchedRow.jcuser
        Write-Output "Assigned username: $username"
        Write-Output "Assigned jcuser: $jcuser"
    
        #logout user if they are logged in
        Write-Output "Checking for active user sessions..."
        $sessions = quser | Select-String $sessionuser #gets the users session
        $sessionId = ($sessions -split '\s+')[2] #extracts the session ID from the output
        if ($sessionId) {
            Write-Output "Logging out user $sessionuser with session ID $sessionId"
            logoff $sessionId
            #wait for the user to be logged out
            Start-Sleep -Seconds 40
            msg * "user $sessionuser has been logged out to complete the migration process. Please do not log in again until after the computer reboots."

        } else {
            Write-Output "No active session found for user $sessionuser continuing with the migration." 
        }
     
        #allow user to run scripts
        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
        #Install the JumpCloud module and dependencies
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        if (-not (Get-Module -ListAvailable -Name JumpCloud.ADMU)) {
            Install-Module -Name JumpCloud.ADMU -Confirm:$False -Force
        }
        Import-Module JumpCloud.ADMU;
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
    $OEMKey = (Get-CimInstance -ClassName SoftwareLicensingService).OA3xOriginalProductKey
    # Get the OEM product key from the BIOS
    $OEMKey = (Get-WmiObject -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey
    
    # Check if a key was found
    if ($OEMKey) {
        Write-Host "OEM key found: $OEMKey"
    
        # Attempt to activate Windows using the retrieved key
            slmgr /ipk $OEMKey
            slmgr /ato
            Write-Host "Windows activation process completed."
            
    } else {
        Write-Host "No OEM key found in the BIOS."
    
    }
}

function MakeAdmin {
    
    # Add the migrated user to the local Administrators group
    try {
        Add-LocalGroupMember -Group "Administrators" -Member $jcuser -ErrorAction Stop
        Write-Host "User $jcuser has been added to the Administrators group."
    } catch {
        Write-Host "Failed to add user $jcuser to the Administrators group. Error: $_"
    }
}

function Reboot-ComputerToCompleteMigration {
    if($global:migrated){# Reboot the computer to complete the migration
    Write-Output "Rebooting the computer to complete the migration..."
    msg * "The computer will reboot in 30 seconds to complete the migration process."
    # Wait for 30 seconds before rebooting
    Start-Sleep -Seconds 30; Restart-Computer -Force
} else {
        Write-Output "Migration did not complete successfully. No reboot will occur."
    }
}
ActivateWindows
Migration
MakeAdmin
Reboot-ComputerToCompleteMigration
Write-Output "Migration script completed. Please check the output for any errors or messages."
# End of script

    