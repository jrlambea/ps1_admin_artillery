<#
Author Jose Ramón Lambea

140206 little gptgen.exe wrapper, list local disks and convert to gpt.
       can get gptgen.exe from http://sourceforge.net/projects/gptgen/
Usage:
set-DiskToGPT.ps1

#>

$Drives = Get-WmiObject -Class Win32_DiskDrive

Write-Host "Available disks:"
$Drives | ft Index,DeviceID,TotalSectors,Size

[Int]$Index = Read-Host "Which disk want to convert? "

if ( $Index -eq $null -Or $Index -ge ( $Index | measure-Object ).count ) { 
    "Invalid number or out of range."
    Exit 
} else {
    $targetDrive = ( $Drives | ?{ $_.Index -eq $Index } ).DeviceID
    "& gptgen.exe -w $targetDrive"
}
