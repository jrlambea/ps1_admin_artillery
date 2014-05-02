<#
Author Jose Ramón Lambea

140502 Script to cipher files with BMC SDE dll libraries.

Usage:
sdencrypt.ps1 -i inputfile -o outputfile

Mandatory: Use in a 32 bit powershell, full path for i/o files.

#>

Param(
    [parameter(Mandatory=$true)]
    [alias("i")]
    [string]
    $inputfile,
    [parameter(Mandatory=$false)]
    [alias("o")]
    [string]
    $outputfile = "encrypted")

$LIB_DLL = "C:\Program Files (x86)\BMC\Service Desk Express\Application Server\bin"
[Reflection.Assembly]::LoadFile("$LIB_DLL\Interop.NAMATTACHMENTLib.DLL")
[Reflection.Assembly]::LoadFile("$LIB_DLL\Interop.NAMDATALib.dll")

[NAMATTACHMENTLib.IMAttachment] $AttachObj      = New-Object NAMATTACHMENTLib.MAttachmentClass
[NAMDATALib.IMData] $pdParamsAttach             = New-Object NAMDATALib.MDataClass

$pdParamsAttach.set_Item("FROMFILE", $inputfile)
$pdParamsAttach.set_Item("TOFILE", $outputfile)
$pdParamsAttach.set_Item("HEADERFILENAME", $inputfile)

$AttachObj.IEncodeFile($pdParamsAttach)

Get-Item $outputfile
