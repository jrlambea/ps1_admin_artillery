<#
    Author Jose Ramón Lambea

    140213 This script adds members to Active Directory Groups with the content
           of a CSV file.

    Usage:
        Add-BulkADGroupMember.ps1 -GroupColumn ColumnHeader
                                  -ObjectNameColumn ColumnHeader
                                  -File CSVFilePath
                         Optional -Computer $true         
                         Optional -Delimiter ";"
#>

Param(
    [parameter(Mandatory=$true)]
    [alias("g")]
    [string]
    $GroupColumn,
    [parameter(Mandatory=$true)]
    [alias("o")]
    [string]
    $ObjectNameColumn,
    [parameter(Mandatory=$true)]
    [alias("f")]
    [string]
    $File,
    [parameter(Mandatory=$false)]
    [alias("c")]
    [string]
    $Computer = $false,
    [parameter(Mandatory=$false)]
    [alias("d")]
    [string]
    $Delimiter = ",")

if ( -not ( Get-Module -listAvailable -All | ?{ $_.Name -eq "ActiveDirectory" } ) ) {
    "The ""ActiveDirectory"" module ins't available."
    Exit }
ElseIf ( -not ( Get-Module | ?{ $_.Name -eq "ActiveDirectory" } ) ) {
    Import-Module ActiveDirectory
}

$Data = Import-CSV $File -delimiter $Delimiter

$Data | % {

    $Group  = $_.$GroupColumn
    $Object = $_.$ObjectNameColumn

    if ( $Computer -eq $true ) { $Object = "$Object$" }

    "Adding ""$Object"" in ""$Group"""

    Add-ADGroupMember "$Group" "$Object"

}
