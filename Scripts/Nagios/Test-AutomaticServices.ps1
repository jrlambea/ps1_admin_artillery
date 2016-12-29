<#
.SYNOPSIS
Script for Nagios that control if the services with automatic start are started or not.
.DESCRIPTION
Script for Nagios that control if the services with automatic start are started or not.
.EXAMPLE
--
.EXAMPLE
--
.PARAMETER computername
--
.PARAMETER logname
--
.INPUTS
--
.OUTPUTS
--
.LINK
.NOTES
  Version:        1.0
  Author:         JR. Lambea
  Creation Date:  20161229
  Purpose/Change: Initial script development
#>

$BlackList = "blacklist.txt"

# Get all services configured as automatic startup, and the status is "Stopped"
$StopedAutoSvc = Get-Service | Where-Object { $_.StartType -eq "Automatic" -And $_.Status -ne "Running" -And $_.Name -notin (Get-Content $BlackList) }

If ($StopedAutoSvc -ne "")
{
    $Outstr = "Service down: "
    
    ForEach ($Service in $StopedAutoSvc)
    {
        $Outstr += "$($Service.Name) "
    }

    Write-Host $Outstr
    Exit 2
}

Write-Host "All services ok."
Exit 0
