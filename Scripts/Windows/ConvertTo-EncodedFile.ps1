<#
.SYNOPSIS
Cmdlet to out the input data with the selected encoding.
.DESCRIPTION
This cmdlet uses the code pages specified here: https://msdn.microsoft.com/en-us/library/windows/desktop/dd317756(v=vs.85).aspx.
.EXAMPLE
Give an example of how to use it
.PARAMETER Encoding
This parameter can be any of the .NET Names specified here: https://msdn.microsoft.com/en-us/library/windows/desktop/dd317756(v=vs.85).aspx
.INPUTS
None
.OUTPUTS
None
.LINK
https://msdn.microsoft.com/en-us/library/windows/desktop/dd317756(v=vs.85).aspx
.NOTES
  Version:        1.0
  Author:         JR. Lambea
  Creation Date:  070101
  Purpose/Change: Initial script development
#>

[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
Param (
  [Parameter(Mandatory=$True, HelpMessage='What file you want to encode?')]
  [Alias('i')]
  [ValidateScript({Test-Path $_ })]
  [String]$InputFile,
  [Parameter(Mandatory=$False, HelpMessage='What encode you want should to use?')]
  [Alias('oe')]
  [ValidateScript({[System.Text.Encoding]::GetEncoding($_)})]
  [String]$OriginalEncoding="$($OutputEncoding.BodyName)",
  [Parameter(Mandatory=$True, HelpMessage='To what file you want dump the data?')]
  [Alias('o')]
  [String]$OutputFile,
  [Parameter(Mandatory=$True, HelpMessage='What encode you want should to use?')]
  [Alias('de')]
  [ValidateScript({[System.Text.Encoding]::GetEncoding($_)})]
  [String]$DestinationEncoding,
  [Parameter(Mandatory=$False, HelpMessage='What encode you want should to use?')]
  [Alias('b')]
  [Switch]$BOM=$False
)

Try {

  If ($BOM -and $DestinationEncoding -ne "utf-8") {
    Write-Host "The parameter BOM is only valid for UTF-8! Avoiding parameter..."
    $BOM = $False
  }

  Write-Host "`nInput: $InputFile`nOutput: $OutputFile`nEncoding: $DestinationEncoding $(If($BOM){"`nBOM: True"})"


  # Obtain data with the specified encoding. 
  If ($DestinationEncoding -eq "default") {
    $DataToEncode = Get-Content $InputFile -Encoding $OutputEncoding
  }

  Else {
    $InputEncoding = [System.Text.Encoding]::GetEncoding($OriginalEncoding)
    $DataToEncode = [System.IO.File]::ReadAllLines($InputFile, $InputEncoding)
  }

  # Dump data encoded with the selected charset
  If (!($BOM) -And ($DestinationEncoding -eq "utf-8")) { 
    $OutEncoding = New-Object System.Text.UTF8Encoding($False)
  }
  
  Else {
    $OutEncoding = [System.Text.Encoding]::GetEncoding($DestinationEncoding)
  }

  [System.IO.File]::WriteAllLines($OutputFile, $DataToEncode, $OutEncoding)
}

Catch {
  Write-Error $_.Exception.ToString()
}