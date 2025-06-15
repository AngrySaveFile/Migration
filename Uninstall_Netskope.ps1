$productCode = wmic product where "Name like 'Netskope Client'" get IdentifyingNumber /value
msiexec /uninstall {$productCode} PASSWORD="SecretAgentMan" /qn /l*v %PUBLIC%\nscuninstall.log
