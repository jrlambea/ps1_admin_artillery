<#
.SYNOPSIS
Describe the function here
.DESCRIPTION
Describe the function in more detail
.EXAMPLE
Give an example of how to use it
.EXAMPLE
Give another example of how to use it
.PARAMETER computername
The computer name to query. Just one.
.PARAMETER logname
The name of a file to write failed computer names to. Defaults to errors.txt.
.INPUTS
Inputs if any, otherwise state None
.OUTPUTS
Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log
.LINK
.NOTES
  Version:        1.0
  Author:         <Name>
  Creation Date:  <Date>
  Purpose/Change: Initial script development
#>

#OPTIONAL: Set Error Action to Silently Continue
#$ErrorActionPreference = "SilentlyContinue"

[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
Param
(
  [Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, HelpMessage='What computer name would you like to target?')]
  [Alias('host')]
  [ValidateLength(3,30)]
  [string]$logname = 'errors.txt'
)

Begin
{
  Write-Verbose "Deleting $logname"
  Remove-Item $logname -ErrorActionSilentlyContinue
}

Process
{

  Write-Verbose "Beginning process loop"

  ForEach ($computer In $computername)
  {
    Write-Verbose "Processing $computer"
    If ($pscmdlet.ShouldProcess($computer)) { <# use $computer here #> }
  }
  
}
