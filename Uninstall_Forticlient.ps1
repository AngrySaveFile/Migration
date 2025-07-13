function Installed {
  param(
      [string]$appName
  )
  $installedApp = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq $appName}
  if ($installedApp) {
      Write-Host "$appName is installed."
      return $true
  } else {
      Write-Host "$appName is not installed."
      return $false
  }
}

$appName = "FortiClient" 
if (Installed -appName $appName) {
  # Perform actions if the app is installed
  Write-Host "Continuing process as $appName is installed."
  [string]$ApplicationName ='FortiClient'
    
  $InstalledApplications = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    foreach ($app in $InstalledApplications) {
      $appName = $app.GetValue("DisplayName")
      
      if ($appName -eq $ApplicationName) {
        $appVersion = $app.GetValue("DisplayVersion")
        $uninstallKey = $app.GetValue("UninstallString")
        
      }
    }
  $version = $appVersion
  $key = $uninstallKey
  $subkey = $key.Substring(14) # Extracts "This" (characters from index 0 to 3)
  
  Write-Host "The version of Forticlient is: $version and the unistall key is $subkey"
  C:\windows\system32\msiexec.exe /quiet /norestart /uninstall $subkey

} else {
  # Perform actions if the app is not installed
  Write-Host "Stopping process as $appName is not installed."
}
