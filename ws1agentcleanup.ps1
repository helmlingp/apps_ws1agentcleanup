<#	
  .Synopsis
    Script to uninstall and cleanup WorkspaceONE Agent and residual items for testing/re-testing purposes
  .NOTES
    Created:      September, 2019
    Updated:      Februrary, 2025
	  Created by:   Phil Helmling, @philhelmling
	  Organization: Omnissa, LLC.
	  Filename:     ws1agentcleanup.ps1
	.DESCRIPTION
	  Script to uninstall and cleanup WorkspaceONE Agent and residual items for testing/re-testing purposes
  .EXAMPLE
    powershell.exe -executionpolicy bypass -file .\ws1agentcleanup.ps1
#>

#Uninstall Agent - requires manual delete of device object in console
$b = Get-WmiObject -Class win32_product -Filter "Name like '%Workspace ONE%'"
$b.Uninstall()

#uninstall WS1 App
Get-AppxPackage *AirWatchLLC* | Remove-AppxPackage

function Remove-RegPath {
  param (
    [string]$path
  )
  if (Get-Item $path) {
    Remove-Item -Path $path -Recurse -Force -ErrorAction Continue | Out-Null
  }
}

$regpaths2remove = @(
  #delete Airwatch Agent keys
  "HKLM:\SOFTWARE\Airwatch\*"
  "HKLM:\SOFTWARE\AirwatchMDM\*"
  "HKLM\SOFTWARE\WorkspaceONE\*"
  #Delete OMA-DM keys
  "HKLM:\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked\*"
  "HKLM:\SOFTWARE\Microsoft\Enrollments\*"
  "HKLM:\SOFTWARE\Microsoft\Provisioning\omadm\Accounts\*"
  #Delete OMA-DM apps and SFD apps keys
  "HKLM:\SOFTWARE\Microsoft\EnterpriseDesktopAppManagement\*\MSI\*"
)

function Remove-FilePath {
  param (
    [string]$path
  )
  if (Get-Item $path) {
    Get-ChildItem $path -Recurse | Remove-Item -Recurse -Force -ErrorAction Continue | Out-Null
  }
}

$filepaths2remove = @(
  "$env:ProgramData\AirWatch"
  "$env:ProgramData\VMWOSQEXT"
  "$env:ProgramData\AirWatchMDM"
  "$env:ProgramFiles\WorkspaceONE"
  "$env:LOCALAPPDATA\WorkspaceONE"
  "$env:ProgramFiles(x86)\Airwatch"
)

function Remove-Cert {
  param (
    [string]$certname
  )
 
  $certs = Get-ChildItem cert: -Recurse | Where-Object {$_.Issuer -eq "$certname"}
  foreach ($cert in $certs) {
      #$cert | Remove-Item -Force -ErrorAction Continue | Out-Null
      Write-Host $c
  }
}

$certs2remove = @(
  "*AirWatchCA*"
  "*AwDeviceRoot*"
)

#Main
foreach ($path in $regpaths2remove) {
  Remove-RegPath $path
}

foreach ($path in $filepaths2remove) {
  Remove-FilePath $path
}

foreach ($cert in $certs2remove) {
  Remove-Cert $cert
}

<# #Delte reg keys
Remove-Item -Path HKLM:\SOFTWARE\Airwatch\* -Recurse -Force
Remove-Item -Path HKLM:\SOFTWARE\AirwatchMDM\* -Recurse -Force
Remove-Item -Path HKLM:\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked\* -Recurse -Force

#get enrolment SID in Airwatch key and find that in the enrollments key - do we need to?
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
} #>
