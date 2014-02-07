<#
Author Jose Ramón Lambea

140205 Script for calculate the size of a folder from last
       TSM backup.

Usage:
get-SizefromTSM.ps1 -p path [ -s yes/no ]

#>

Param(
    [parameter(Mandatory=$true)]
    [alias("p")]
    [string]
    $path,
    [parameter(Mandatory=$false)]
    [alias("s")]
    [string]
    $subdir = "no",
    [parameter(Mandatory=$false)]
    [alias("v")]
    [string]
    $vvv = $false)

function get-DirectorySize( $path ) {
    if ( $path.Substring(0,2) -eq "\\" -And $path.IndexOf("$") -ne 0 )
    {
        if ( $vvv -eq $true ) { Write-Host "Querying to TSM service..." }

        $p = Start-Process ".\dsmc.exe" -ArgumentList "query backup ""$path\*"" -subdir=yes " -Wait -NoNewWindow -RedirectStandardOutput $tmpFile
        $p.HasExited

        $blank_line = 0
        $totalBytes = 0
        $regex      = new-object System.Text.RegularExpressions.Regex( "[0-9]  B" )

        if ( $vvv -eq $true ) { Write-Host "Reading server answer..." }

        Get-Content $tmpFile | % {

            if ( $regex.IsMatch( $_ )  )
            {
                $curLineBytes   = $_.Trim().replace(",","").Split(" ")[0]
                $totalBytes    += $curLineBytes

            }

        }

        $totalBytes = $(((${totalBytes}/1024)/1024)/1024).ToString("0.00")
        "$totalBytes,${path}"

    }

}


$tsmFiles   = "dsm.opt","dsmc.exe"
$tmpFile    = "$($env:temp)\tsmquery.txt"

$tsmFiles | % {

    if ( -not ( get-Item $_ ) )
    {
        if ( $vvv -eq $true ) { Write-Host "The file $_ doesn't exist." }
        Exit

    }

}

if ( $subdir ) {
    $subdirs = Get-ChildItem "$path" | ?{ $_.attributes -like "*Directory*" }
    $subdirs | % { get-DirectorySize $_.FullName }

} else {
    get-DirectorySize $path

}
