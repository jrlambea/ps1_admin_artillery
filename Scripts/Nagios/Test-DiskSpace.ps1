<#
.SYNOPSIS
Plugin Nagios that evaluate the disk space status depending their total size.
.DESCRIPTION
Plugin Nagios that evaluate the disk space status depending their total size.
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
  Creation Date:  20161227
  Purpose/Change: Initial script development
#>

$GBList =  (1100*1GB), (800*1GB), (600*1GB), (450*1GB), (250*1GB), (100*1GB)
$CritList = 1, 2, 3, 4, 5, 10
$WarnSmall = 10
$CritSmall = 5


# Get all local disks from WMI
$Disks = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType = 3 and VolumeName <> 'SWAP'"
$Output = ""
$max = $GBList.Length - 1
$RC = 0

ForEach ($Disk in $Disks)
{
    $SizeGB = [Math]::Round($Disk.Size/1GB, 2)
    ForEach ($i in (0..$max))
    {
        If ($Disk.Size -gt $GBList[$i])
        {
            If ($Disk.FreeSpace -lt (( $Disk.Size/100) * $CritList[$i] ))
            {
                $FreeGB = [Math]::Round($Disk.FreeSpace/1GB, 2)
                If(!($RC)){ $RC = 2 }
                $Output += "$($Disk.DeviceId) ${FreeGB}/${SizeGB}GB Critical!"
            }
            
            ElseIf ($Disk.FreeSpace -lt (($Disk.Size/100) * ($CritList[$i] * 2)))
            {
                $FreeGB = [Math]::Round($Disk.FreeSpace/1GB, 2)
                If(!($RC)){ $RC = 1 }
                $Output += "$($Disk.DeviceId) ${FreeGB}/${SizeGB}GB Warning!"
            }
            break

            # If the disk is smaller than smallest SizeGB length should meet the if condition
            If ($i -eq $max) {
                If ($Disk.FreeSpace -lt ($CritSmall * 1GB))
                {
                    $FreeGB = [Math]::Round($Disk.FreeSpace/1GB, 2)
                    If(!($RC)){ $RC = 2 }
                    $Output += "$($Disk.DeviceId) ${FreeGB}/${SizeGB}GB Critical!"
                }
                
                ElseIf ($Disk.FreeSpace -lt ($WarnSmall * 1GB))
                {
                    $FreeGB = [Math]::Round($Disk.FreeSpace/1GB, 2)
                    If(!($RC)){ $RC = 1 }
                    $Output += "$($Disk.DeviceId) ${FreeGB}/${SizeGB}GB Warning!"
                }
            }
        }
    }
}

If (!($RC)) {$RC = 0}

Write-Host $Output
Exit $RC
