#download csv file
$url = "https://urldefense.com/v3/__https://github.com/AngrySaveFile/Migration/archive/refs/heads/main.zip__;!!D68HAeWseNw0ZHM!vJSLUesvUWjnfTal_Xt90S92gViwCbAPForgqEHfOtjGFTMMVkgfwwkflrmFS5qzmLT2TZ6rcFsSmd549qgEooVlWwEllvs$"
$output = "computer.zip"
$destination = "C:\"

Invoke-WebRequest -Uri $url -OutFile $output
Expand-Archive -Path $output -DestinationPath $destination -Force

#Define the path to the CSV file
$csvPath = "C:\Migration-main\computers.csv"

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
    <#MIGRATION script!! Do not uncomment
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser

    nstall-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Install-Module -Name JumpCloud.ADMU -Confirm:$False -Force
    Import-Module JumpCloud.ADMU;

    Start-Migration -SelectedUserName "$username" -JumpCloudUserName "$jcuser" -TempPassword 'Temp123!Temp123!' -LeaveDomain $true -ForceReboot $true
#>
} 
else {
    Write-Output "No match found for computer name '$currentComputerName'"
}
