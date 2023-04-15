#requires -version 2
<#
.SYNOPSIS
  Get the resource utilization of all IIS application pools in use.
.DESCRIPTION
  Get the resource utilization of all IIS application pools in use. This script needs the Web-Scripting-Tools to be installed
.PARAMETER CSVFile
  CSV file to write the obtained data
.NOTES
  Version:        1.0
  Author:         @jr_lambea
  Creation Date:  2023-04-15
  Purpose/Change: Initial script development
  
#>
param
(
    [ValidateNotNullOrEmpty()][string]$CSVFile
)
$datetime = (Get-Date).tostring("yyyy-MM-dd HH:mm:ss")

if (-not $CSVFile) {$CSVFile = "c:\Windows\temp\iis_apppool.csv"}

if ((gwmi -namespace Root -Class __Namespace).Name -notcontains "WebAdministration") {
	Write-Error "Yay! You should install Web-Scripting-Tools feature before you use this script."
	Exit
}

$app_pools = gwmi -Class Workerprocess -Namespace root/WebAdministration | Select AppPoolName, ProcessId

if (-not (Test-Path $CSVFile)) { "DateTime;pool_pid;PagedMemory;" | Out-File $CSVFile }

foreach ($app_pool in $app_pools) {
	$pool_pid = $app_pool.ProcessId
	$pool_proc = Get-Process -PID $pool_pid
	$pool_mem = $pool_proc.PM / 1MB
	$pool_cpu = $pool_proc.CPU
	"${datetime};$pool_pid;${pool_mem};${pool_cpu}" | Tee-Object -Append $CSVFile
}
