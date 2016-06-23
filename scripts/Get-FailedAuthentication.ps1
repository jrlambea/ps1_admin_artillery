<#
.SYNOPSIS
    Get all the failed authentication events from remote computer eventlogs. ALERT!!, this script was made to work with spanish version of Windows.
.DESCRIPTION
    Get all the failed authentication events from remote computer eventlogs. ALERT!!, this script was made to work with spanish version of Windows.
.PARAMETER DomainControllers
    Name of the remote computer, commonly a Domain Controller
.PARAMETER FromHoursAgo
    Hours from we get all data.
#>
[CmdletBinding()]
Param(
    [Parameter( Mandatory = $True, Position = 0)][Alias("s")][String[]]$DomainControllers,
    [Parameter( Mandatory = $True, Position = 0)][Alias("h")][Int]$FromHoursAgo
)

# Avoid all errors
$ErrorActionPreference = "SilentlyContinue"

# If the FromHoursAgo parameter isn't negative, do the conversion.
If ($FromHoursAgo -gt 0) { $FromHoursAgo *= -1 }

# EventId that means like "Error in authentication"
# $EventId = 529, 672, 675

# Get all events with the EventId above
$Events = Get-EventLog -LogName Security -ComputerName $DomainControllers -After (Get-Date).AddHours($FromHoursAgo) -EntryType "FailureAudit" -InstanceId 529, 672, 675

# Parse all events and generate a custom object
$Data = ForEach ($Event in $Events)
{
	$Splittered = $Event.Message.Split("`r")
	$UsrName = ($Splittered | Select-String "Nombre de usuario:").Line.Split(":")[1].Trim()
	$HstName = ($Splittered | Select-String "Dirección de cliente:").Line.Split(":")[1].Trim()
	"" | Select-Object @{n="TimeGenerated";e={$Event.TimeGenerated}}, @{n="UserName";e={$UsrName}}, @{n="HostName";e={$HstName}}, @{n="Message";e={$Event.Message.Replace("`r", "")}}
}

# Sort by time
$Data | Sort-Object Time
