<#
.Synopsis
Obtiene el tamaño de los directorios realizando consultas al servidor de backup TSM.
.Description
Obtiene el tamaño de los directorios realizando consultas al servidor de backup TSM, para ello en la máquina donde se ejecute debe estar instalado el TSM BAClient y debe estar configurado como nodo. Hay que tener en cuenta que el resultado de este comando se basa en los datos de la última cópia realizada.
.Parameter Path
El directorio del cual se quiere averiguar el tamaño, en formato UNC.
.Parameter Subdir
Especifica que se debe realizar la consulta de los subdirectorios dentro del directorio del parámetro Path.
.Parameter Scale
La escala de los resultados basados en bytes (p.e. 1MB, 1GB, 1TB...)
.Parameter TSMDir
Ubicación de la instalación de TSM Backup/Archive Client.
.Example
.\Get-SizefromTSM.ps1 '\\server1\f$\' -Scale 1GB -Subdir -Verbose
Muestra la ocupación en GB de todos los subdirectorios dentro de la unidad f del server1, además, muestra información adicional.
.Example
.\Get-SizefromTSM.ps1 '\\server1\e$\dir1\' -Scale 1MB
Muestra la ocupación en MB del directorio dir1 dentro de la unidad e del server1.
.Links
http://spageek.net
#>

[CmdletBinding()]
Param(
    [parameter(Mandatory=$true, Position = 0)]
    [alias("p")]
    [string[]]$Path,
    [parameter(Mandatory=$false)]
    [alias("t")]
    [string]$TSMDir = "C:\Program Files\Tivoli\TSM\baclient\",
    [parameter(Mandatory=$false)]
    [alias("s")]
    [switch]$Subdir,
    [parameter(Mandatory=$false)]
    [alias("x")]
    [Int32]$Scale=1MB
)

function get-DirectorySize( $Path )
{

    if ( $path.Substring(0,2) -eq "\\" -And $path.IndexOf("$") -ne 0 )
    {
        Write-Verbose "Querying to TSM service... `'${TSMDir}dsmc.exe query backup `"$path\*`" -subdir=yes`'."

        $p = Start-Process "${TSMDir}dsmc.exe" -ArgumentList "query backup `"$path\*`" -subdir=yes" -Wait -NoNewWindow -RedirectStandardOutput $tmpFile -WorkingDirectory "$TSMDir"
        $p.HasExited

        $blank_line = 0
        $totalBytes = 0
        $regex      = new-object System.Text.RegularExpressions.Regex( "[0-9]  B" )

        Write-Verbose "Reading server answer..."

        ForEach ($Line in (Get-Content $tmpFile))
        {
            if ( $regex.IsMatch( $Line ) )
            {
                $curLineBytes   = $Line.Trim().Replace(",","").Split(" ")[0]
                $totalBytes    += $curLineBytes
            }

        }

        Write-Verbose ("" | Select-Object -Property @{n="Size";e={(${totalBytes}/$Scale).ToString("0.00")}},@{n="Path";e={$path}})

        "" | Select-Object -Property @{n="Size";e={(${totalBytes}/$Scale).ToString("0.00")}},@{n="Path";e={$path}}

    }
}


$tsmFiles   = "dsm.opt","dsmc.exe"
$tmpFile    = "$($env:temp)\tsmquery.txt"
$errFile    = "$($env:temp)\tsmerror.txt"

ForEach ( $File in $tsmFiles )
{
    if ( -not ( get-Item "$TSMDir$File" ) )
    {
        Write-Error "The file $File doesn't exist."
        Exit

    }
}

ForEach ( $dir in $Path ) {
    if ( $subdir ) {
        $subdirs = Get-ChildItem "$dir" -Force | ?{ $_.attributes -like "*Directory*" }
        $subdirs | % { get-DirectorySize $_.FullName }

    } else {
        get-DirectorySize $dir

    }
}
