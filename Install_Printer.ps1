#download Print Drivers file
$url = "https://support.ricoh.com/bb/pub_e/dr_ut_e/0001343/0001343703/V3000/z04169L16.exe"
$output = "C:\Windows\Temp\print1.zip"
Invoke-WebRequest -Uri $url -OutFile $output
#Unzip the driver pacakge
Expand-Archive -LiteralPath $output -DestinationPath "C:\Windows\Temp" -Force -Confirm:$false
#Define the path to the Inf file we downloaded
$infPath = "C:\Windows\Temp\z04169L16\disk1\MPC3003_.inf"
$folderPath = "C:\Windows\Temp\z04169L16"
if (Test-Path -Path $folderPath -PathType Container) {
    Write-Host "Driver Folder exists."
    # Replace with the correct values
    $driver = "RICOH MP C3003 PCL 6"
    $address = "10.9.66.4" # Printer IP address
    $name = "4400_1st"
    $portname = "10.9.66.4_0"
    # Install the printer driver
    Invoke-Command {pnputil.exe -a $infPath} # Add the inf file to the driver store
    Add-PrinterDriver -Name $driver
    # Create the printer port
    Add-PrinterPort -Name $portname -PrinterHostAddress $address
    # Install the printer
    Add-Printer -Name $name -DriverName $driver -PortName $portname
} else {
    Write-Host "Folder does not exist."
}
# Remove the downloaded files
Remove-Item -Path $output -Force
# Remove the driver from the driver store
$driverPath = "C:\Windows\Temp\z04169L16\disk1"
$driverInf = "MPC3003_.inf"
$driverInfPath = Join-Path -Path $driverPath -ChildPath $driverInf
$driverInfPath = $driverInfPath.Replace("\", "\\")
$driverInfPath = $driverInfPath.Replace(" ", "` ")
$driverInfPath = $driverInfPath.Replace("(", "`(")
$driverInfPath = $driverInfPath.Replace(")", "`)")
$driverInfPath = $driverInfPath.Replace("&", "`&")











