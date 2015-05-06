<#
Author Jose Ramón Lambea

140205 Nuevo script.
150505 Revisión.

Usage:
get-SizefromTSM.ps1 -p path [ -s $true/$false ]

#>

[CmdletBinding()]
Param(
    [parameter(Mandatory=$true)]
    [alias("p")]
    [string]$Path,
    [parameter(Mandatory=$false)]
    [alias("s")]
    [switch]$Subdir,
    [parameter(Mandatory=$false)]
    [alias("x")]
    [Int32]$Scale=1MB
)

$TSMDir = "C:\Program Files\Tivoli\TSM\baclient\"
function get-DirectorySize( $path )
{

    if ( $path.Substring(0,2) -eq "\\" -And $path.IndexOf("$") -ne 0 )
    {
        Write-Verbose "Querying to TSM service... `'$TSMDir\dsmc.exe query backup `"$path\*`" -subdir=yes`'."

        $p = Start-Process "$TSMDir\dsmc.exe" -ArgumentList "query backup `"$path\*`" -subdir=yes " -Wait -NoNewWindow -RedirectStandardOutput $tmpFile
        $p.HasExited

        $blank_line = 0
        $totalBytes = 0
        $regex      = new-object System.Text.RegularExpressions.Regex( "[0-9]  B" )

        Write-Verbose "Reading server answer..."

        Get-Content $tmpFile | % {

            if ( $regex.IsMatch( $_ )  )
            {
                $curLineBytes   = $_.Trim().replace(",","").Split(" ")[0]
                $totalBytes    += $curLineBytes

            }

        }

        "" | Select-Object -Property @{n="Size";e={(${totalBytes}/$Scale).ToString("0.00")}},@{n="Path";e={$path}}

    }
}


$tsmFiles   = "dsm.opt","dsmc.exe"
$tmpFile    = "$($env:temp)\tsmquery.txt"

ForEach ( $File in $tsmFiles )
{
    if ( -not ( get-Item "$TSMDir$File" ) )
    {
        Write-Error "The file $File doesn't exist."
        Exit

    }
}

if ( $subdir ) {
    $subdirs = Get-ChildItem "$path" | ?{ $_.attributes -like "*Directory*" }
    $subdirs | % { get-DirectorySize $_.FullName }

} else {
    get-DirectorySize $path

}
