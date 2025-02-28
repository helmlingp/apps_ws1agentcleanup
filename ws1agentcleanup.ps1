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

# Things to remove
$apps2remove = @(
  "Workspace ONE"
  "*AirWatchLLC*"
)

$regpaths2remove = @(
  #delete Airwatch Agent keys
  "HKLM:\SOFTWARE\Airwatch"
  "HKLM:\SOFTWARE\AirwatchMDM"
  "HKLM:\SOFTWARE\VMware, Inc.\VMware Endpoint Telemetry"
  #"HKLM:\SOFTWARE\VMware, Inc.\VMware EUC"
  "HKLM:\SOFTWARE\VMware, Inc.\VMware EUC Telemetry"
  "HKLM:\SOFTWARE\WorkspaceONE"
  #Delete OMA-DM keys
  #"HKLM:\SOFTWARE\Microsoft\Enrollments"
  "HKLM:\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked"
  "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts"
  #Delete OMA-DM apps and SFD apps keys
  "HKLM:\SOFTWARE\Microsoft\EnterpriseDesktopAppManagement\*\MSI"
)

$filepaths2remove = @(
  "$env:ProgramData\AirWatch"
  "$env:ProgramData\AirWatchMDM"
  "$env:ProgramData\EUC"
  "$env:ProgramData\VMware\SfdAgent"
  "$env:ProgramData\VMware\vmwetlm"
  "$env:ProgramData\VMWOSQEXT"
  "$env:ProgramFiles\WorkspaceONE"
  "$env:LOCALAPPDATA\VMware\IntelligentHub"
  "$env:LOCALAPPDATA\WorkspaceONE"
  "$env:ProgramFiles(x86)\Airwatch"
)

$certs2remove = @(
  "*AirWatchCA*"
  "*AwDeviceRoot*"
)

function Remove-AndWaitForApp {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$AppName,
        
        [Parameter(Mandatory=$false)]
        [int]$PollingIntervalSeconds = 10,
        
        [Parameter(Mandatory=$false)]
        [int]$TimeoutMinutes = 10
    )
    
    begin {
        $startTime = Get-Date
        $timeoutTime = $startTime.AddMinutes($TimeoutMinutes)
        
        Write-Host "Starting to remove app containing '$AppName' at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Write-Host "Timeout set to $TimeoutMinutes minutes (will end at $($timeoutTime.ToString('yyyy-MM-dd HH:mm:ss')))"
    }
    
    process {
        $appRemoved = $false
        $iteration = 1
        $uninstallAttempted = $false
        
        do {
            Write-Host "Check #$iteration - Searching for app containing '$AppName'..."
            
            # Check for Win32 app
            $win32App = Get-WmiObject -Class Win32_Product -Filter "Name like ""%$AppName%"""
            
            # Check for AppX package
            $appxPackage = Get-AppxPackage | Where-Object {$_.Name -like "*$AppName*"}
            
            # Determine if app is present and what type
            if ($null -ne $win32App) {
                if ($uninstallAttempted) {
                    Write-Host "Win32 app '$($win32App.Name)' is still present. Waiting..." -ForegroundColor Yellow
                } else {
                    Write-Host "Found Win32 app: $($win32App.Name). Attempting to uninstall..." -ForegroundColor Yellow
                    try {
                        $result = $win32App.Uninstall()
                        if ($result.ReturnValue -eq 0) {
                            Write-Host "Uninstall command completed successfully." -ForegroundColor Green
                        } else {
                            Write-Warning "Uninstall command returned code $($result.ReturnValue)."
                        }
                        $uninstallAttempted = $true
                    } catch {
                        Write-Error "Error attempting to uninstall Win32 app: $_"
                        $uninstallAttempted = $true
                    }
                }
            }
            elseif ($null -ne $appxPackage) {
                if ($uninstallAttempted) {
                    Write-Host "AppX package '$($appxPackage.PackageFullName)' is still present. Waiting..." -ForegroundColor Yellow
                } else {
                    Write-Host "Found AppX package: $($appxPackage.PackageFullName). Attempting to remove..." -ForegroundColor Yellow
                    try {
                        Remove-AppxPackage -Package $appxPackage.PackageFullName -AllUsers -Force -ErrorAction Stop
                        Write-Host "AppX removal command completed." -ForegroundColor Green
                        $uninstallAttempted = $true
                    } catch {
                        Write-Error "Error attempting to remove AppX package: $_"
                        $uninstallAttempted = $true
                    }
                }
            }
            else {
                # No app found, so it's already removed
                Write-Host "No application found matching '$AppName'. Application has been removed." -ForegroundColor Green
                $appRemoved = $true
                break
            }
            
            # If we've made an uninstall attempt, wait before checking again
            if ($uninstallAttempted) {
                Write-Host "Waiting $PollingIntervalSeconds seconds before checking again..." -ForegroundColor Cyan
                Start-Sleep -Seconds $PollingIntervalSeconds
            }
            
            # Check timeout
            $currentTime = Get-Date
            $iteration++
            
            if ($currentTime -gt $timeoutTime) {
                Write-Warning "Timeout of $TimeoutMinutes minutes reached. Could not confirm app removal."
                return $false
            }
            
        } while (-not $appRemoved)
        
        if ($appRemoved) {
            $duration = New-TimeSpan -Start $startTime -End (Get-Date)
            Write-Host "App removal confirmed after $([math]::Round($duration.TotalMinutes, 2)) minutes." -ForegroundColor Green
            return $true
        }
    }
}

function Remove-Path {
  param (
    [string]$path
  )
  write-host "removing $path"
  if (Test-Path $path) {
    Remove-Item -Path $path -Recurse -Force -ErrorAction Continue | Out-Null
    if (Test-Path $path) {
        Start-Sleep 10
        Remove-Item -Path $path -Recurse -Force -ErrorAction Continue | Out-Null
    }
  }
}

function Remove-Cert {
  param (
    [string]$certname
  )
  write-host "removing cert $certname"
  $certs = Get-ChildItem cert: -Recurse | Where-Object {$_.Issuer -eq "$certname"}
  foreach ($cert in $certs) {
    Remove-Item -Path $cert -Force -ErrorAction Continue | Out-Null
  }
}

#Main
Write-Host "Removing Apps" -ForegroundColor Yellow
foreach ($app in $apps2remove) {
  Remove-AndWaitForApp -AppName $app -PollingIntervalSeconds 10 -TimeoutMinutes 10
}

Write-Host "Removing Registry Keys" -ForegroundColor Yellow
foreach ($path in $regpaths2remove) {
  Remove-Path $path
}

Write-Host "Removing Files and Folders" -ForegroundColor Yellow
foreach ($path in $filepaths2remove) {
  Remove-Path $path
}

Write-Host "Removing Certificates" -ForegroundColor Yellow
foreach ($cert in $certs2remove) {
  Remove-Cert $cert
}
