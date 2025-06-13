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
        $sessionuser = $username -split "am\\" #removes domain name from username
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
            Start-Sleep -Seconds 60
        } else {
            Write-Output "No active session found for user $username continuing with the migration." 
        }
     
        #allow user to run scripts
        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
        #Install the JumpCloud module and dependencies
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        Install-Module -Name JumpCloud.ADMU -Confirm:$False -Force
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
ActivateWindows
Migration
MakeAdmin
if($migrated){# Reboot the computer to complete the migration
Write-Output "Rebooting the computer to complete the migration..."
msg * "Computer will restart in 10 seconds."
Start-Sleep -Seconds 10; Restart-Computer -Force} else {
    Write-Output "Migration did not complete successfully. No reboot will occur."
}
# End of script
