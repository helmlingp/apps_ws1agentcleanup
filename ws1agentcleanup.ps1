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


function Remove-App {
  param (
    [string] $appname
  )
  $app = (Get-AppxPackage | Where-Object {$_.Name -like $appname}).PackageFullName
  if ($app -ne $null) {
    Remove-AppxPackage -Package $app -AllUsers -Force
  } else {
    $app = Get-WmiObject -Class Win32_Product -Filter "Name like ""$appname"""
    if ($app -ne $null) {
      $app.Uninstall()
    }
  }
}


function Remove-Path {
  param (
    [string]$path
  )
  if (Get-Item $path) {
    Remove-Item -Path $path -Recurse -Force -ErrorAction Continue | Out-Null
  }
}

function Remove-Cert {
  param (
    [string]$certname
  )
 
  $certs = Get-ChildItem cert: -Recurse | Where-Object {$_.Issuer -eq "$certname"}
  foreach ($cert in $certs) {
      Remove-Item -Path $cert -Force -ErrorAction Continue | Out-Null
  }
}

$apps2remove = @(
  "%Workspace ONE%"
  "*AirWatchLLC*"
)

$regpaths2remove = @(
  #delete Airwatch Agent keys
  "HKLM:\SOFTWARE\Airwatch"
  "HKLM:\SOFTWARE\AirwatchMDM"
  "HKLM\SOFTWARE\WorkspaceONE"
  #Delete OMA-DM keys
  "HKLM:\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked"
  "HKLM:\SOFTWARE\Microsoft\Enrollments"
  "HKLM:\SOFTWARE\Microsoft\Provisioning\omadm\Accounts"
  #Delete OMA-DM apps and SFD apps keys
  "HKLM:\SOFTWARE\Microsoft\EnterpriseDesktopAppManagement\*\MSI"
)

$filepaths2remove = @(
  "$env:ProgramData\AirWatch"
  "$env:ProgramData\VMWOSQEXT"
  "$env:ProgramData\AirWatchMDM"
  "$env:ProgramFiles\WorkspaceONE"
  "$env:LOCALAPPDATA\WorkspaceONE"
  "$env:ProgramFiles(x86)\Airwatch"
)

$certs2remove = @(
  "*AirWatchCA*"
  "*AwDeviceRoot*"
)

#Main
foreach ($app in $apps2remove) {
  Remove-App $appname
}

foreach ($path in $regpaths2remove) {
  Remove-Path $path
}

foreach ($path in $filepaths2remove) {
  Remove-Path $path
}

foreach ($cert in $certs2remove) {
  Remove-Cert $cert
}
