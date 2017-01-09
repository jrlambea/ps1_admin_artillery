<#
.SYNOPSIS
Script for Nagios that test the response speed of Sql server queries for a instance.
.DESCRIPTION
Script for Nagios that test the response speed of Sql server queries for a instance.
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
  Creation Date:  20160109
  Purpose/Change: Initial script development
#>

[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
Param (
  [Parameter(Mandatory=$True, HelpMessage='SQL instance to Test:')]
  [Alias('i')]
  [String]$Instance
)

# Build connection string
$sqlConnection = New-Object System.Data.SqlClient.SqlConnection "Server=.\${Instance};Integrated Security=sspi"

try {
    $date1 = Get-Date
    $sqlConnection.Open()
    $sqlCommand = $sqlConnection.CreateCommand()
    $sqlCommand.CommandText = "SELECT * FROM sys.databases WHERE owner_sid <> 1 AND state_desc = 'ONLINE'"
    $sqlReader = $sqlCommand.ExecuteReader()
    $Databases = While ($sqlReader.Read()) {$sqlReader.GetSqlString(0).Value}
    $sqlReader.Close()
    ForEach ($Database in $Databases) {
        $sqlCommand.CommandText = "SELECT TABLE_NAME FROM ${Database}.INFORMATION_SCHEMA.Tables WHERE TABLE_TYPE = 'BASE TABLE'"
        $sqlReader = $sqlCommand.ExecuteReader()
        $sqlReader.Close()    
    }
    $sqlConnection.Close()
    $date2 = Get-Date
}
catch {
    Write-Host "Cannot query the SQL Service."
    Exit 2
}
$ResultTime = $date2 - $date1
If ($ResultTime.Millisecond -gt 2) {
    Write-Host "SQL Server response very slow!"
    Exit 2
}

Write-Host "SQL Server Queried in $($ResultTime.Seconds)s $($ResultTime.Millisecond)ms"
