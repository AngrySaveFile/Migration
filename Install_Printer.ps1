#download Print Drivers file
$url = "https://support.ricoh.com/bb/pub_e/dr_ut_e/0001343/0001343373/V3000/z03777L16.exe"
$output = "C:\Windows\Temp\print.zip"
Invoke-WebRequest -Uri $url -OutFile $output 
#Unzip the driver pacakge 
Expand-Archive -Path $output -DestinationPath "C:\Windows\Temp" -Confirm:$false

#Define the path to the Inf file we downloaded 
$infPath = "C:\Windows\Temp\z03777L16\disk1\MPC3004_.inf"
# Replace with the correct values
$driver = "RICOH MP C3004 PCL 6"
$address = "10.9.68.70" # Printer IP address
$name = "4400_2nd_East"
$portname = "10.9.68.70_0"


# Install the printer driver
Invoke-Command {pnputil.exe -a $infPath} # Add the inf file to the driver store
Add-PrinterDriver -Name $driver
# Create the printer port
Add-PrinterPort -Name $portname -PrinterHostAddress $address
# Install the printer
Add-Printer -Name $name -DriverName $driver -PortName $portname