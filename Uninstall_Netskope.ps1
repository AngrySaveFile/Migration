# Replace <SecretAgentMan> with the actual password set in your Netskope configuration.
$password = "PuPasswordHere"

# Get the product code for Netskope Client
$productCode = (wmic product where "Name like 'Netskope Client'" get IdentifyingNumber /value | Select-String -Pattern "=").ToString().Split("=")[1]

# Check if Netskope Client is installed (before uninstall)
Write-Host "Checking Netskope Client installation status before uninstall..."
if (Get-Package -Name "Netskope Client" -IncludeWindowsInstaller) {
    Write-Host "Netskope Client is installed."
} else {
    Write-Host "Netskope Client is not installed."
}

# Uninstall Netskope Client with password (replace with your password)
if ($productCode) {
    msiexec /uninstall $productCode PASSWORD="$password" /qn /l*v $env:PUBLIC\nscuninstall.log
} else {
    Write-Host "Did not find product code for Netskope Client"
}
Start-Sleep 280
# Check Netskope Client installation status after uninstall
Write-Host "Checking Netskope Client installation status after uninstall..."
if (Get-Package -Name "Netskope Client" -IncludeWindowsInstaller) {
    Write-Host "Netskope Client is still installed."
} else {
    Write-Host "Netskope Client has been successfully uninstalled."
}
