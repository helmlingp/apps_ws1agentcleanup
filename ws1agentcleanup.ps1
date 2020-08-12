<#	
    .Synopsis
      Script to uninstall and cleanup WorkspaceONE Agent and residual items for testing/re-testing purposes
    .NOTES
	  Created:      September, 2019
	  Created by:   Phil Helmling, @philhelmling
	  Organization: VMware, Inc.
	  Filename:     ws1agentcleanup.ps1
	.DESCRIPTION
	  Script to uninstall and cleanup WorkspaceONE Agent and residual items for testing/re-testing purposes
    .EXAMPLE
      powershell.exe -executionpolicy bypass -file .\ws1agentcleanup.ps1
#>

#Uninstall Agent - requires manual delete of device object in console
$b = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -eq "Workspace ONE Intelligent Hub Installer"}
$b.Uninstall()

#uninstall WS1 App
Get-AppxPackage *AirWatchLLC* | Remove-AppxPackage
 
#Delte reg keys
Remove-Item -Path HKLM:\SOFTWARE\Airwatch\* -Recurse -Force
Remove-Item -Path HKLM:\SOFTWARE\AirwatchMDM\* -Recurse -Force
Remove-Item -Path HKLM:\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked\* -Recurse -Force
Remove-Item -Path HKLM:\SOFTWARE\Microsoft\Enrollments\* -Recurse -Force
Remove-Item -Path HKLM:\SOFTWARE\Microsoft\Provisioning\omadm\Accounts\* -Recurse -Force
# may not work ;)
Remove-Item -Path HKLM:\SOFTWARE\Microsoft\EnterpriseDesktopAppManagement\*\MSI\* -Recurse -Force
 
#Delete folders
$path = "$env:ProgramData\AirWatch\UnifiedAgent\Logs\"
Get-ChildItem $path -Recurse | Remove-Item -Recurse -Force
 
#Delete certificates
$Certs = get-childitem cert:"CurrentUser" -Recurse
$AirwatchCert = $certs | Where-Object {$_.Issuer -eq "CN=AirWatchCa"}
foreach ($Cert in $AirwatchCert) {
    $cert | Remove-Item -Force
}
 
$AirwatchCert = $certs | Where-Object {$_.Subject -like "*AwDeviceRoot*"}
foreach ($Cert in $AirwatchCert) {
    $cert | Remove-Item -Force
}
