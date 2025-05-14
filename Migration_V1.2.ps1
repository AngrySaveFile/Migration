#download csv file
$url = "https://docs.google.com/spreadsheets/d/e/2PACX-1vT1VcPm2l-BveQr8xi62N-VLrSBBmU-pkL1okA1mAxqUS8wSMrxEV4al5dfr-m9s9j82sXOArH-a24I/pub?output=csv"
$output = "C:\computers.csv"
Invoke-WebRequest -Uri $url -OutFile $output 

#Define the path to the CSV file we downloaded 
$csvPath = "C:\computers.csv"

# Get the current computer name
$currentComputerName = $env:COMPUTERNAME

# Import the CSV
$csvData = Import-Csv -Path $csvPath

# Search for the computer name
$matchedRow = $csvData | Where-Object { $_.ComputerName -eq $currentComputerName }

# Assign the username column to a variable if a match is found
if ($matchedRow) {    
    $username = $matchedRow.username
    $jcuser = $matchedRow.jcuser
    Write-Output "Assigned username: $username"
    Write-Output "Assigned jcuser: $jcuser"
    #allow user to run scripts
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
    #Install the JumpCloud module and dependencies
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Install-Module -Name JumpCloud.ADMU -Confirm:$False -Force
    Import-Module JumpCloud.ADMU;
    #start the migration process
    Start-Migration -SelectedUserName "$username" -JumpCloudUserName "$jcuser" -TempPassword 'Temp123!Temp123!' -LeaveDomain $true -ForceReboot $true
    Write-Output "Migration started for user: $username"
} 
else {
    Write-Output "No match found for computer name $currentComputerName"
}
