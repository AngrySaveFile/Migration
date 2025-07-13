# Define the new username and password
$Username = "Admin"
$Password = ConvertTo-SecureString "IamUnkonw4Now@" -AsPlainText -Force
$Groupname = "Administrators"

# Create the new local user account
New-LocalUser -Name $Username -Password $Password -AccountNeverExpires:$true -Description "Local Administrator Account"

# Add the new user to the local Administrators group
Add-LocalGroupMember -Group $Groupname -Member $Username

Write-Host "Local administrator account '$Username' created successfully and added to the Administrators group."
