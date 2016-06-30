<# 
    .Synopsis
        Recicla ficheros anteriores a una fecha.

    .Description
        Este script busca ficheros con fecha de modificacion anterior a una fecha especificada, por defecto, busca ficheros con extension log.

    .Parameter -Extension
        Especifica la extension de los ficheros a buscar.

    .Parameter -AnteriorA
        Especifica la fecha de referencia.
      
    .Example
        # Elimina los ficheros con extension log con fecha de modificacion anterior a 30 dias
        Rotate-Logs -AnteriorA 30

    .Example
        # Elimina los ficheros con extension txt con fecha de modificacion anterior a una semana
        Rotate-Logs -AnteriorA 7 -Extension txt
#>
Param(
    [parameter( Mandatory = $true )]
    [Int32]$AnteriorA,
    [parameter( Mandatory = $false )]
    [String]$Extension = "log"
)

$logDir = "C:\inetpub\logs\LogFiles\"

if ($AnteriorA -gt 0 ) { $AnteriorA = $AnteriorA * -1 }

[datetime]$fecharef = (Get-Date).AddDays($AnteriorA)

$ficheros = Get-ChildItem $logDir -Recurse | ?{ ($_.Name -like "*.${Extension}") -And ( $_.LastWriteTime -lt $fecharef) }
$i=0
$c=0

ForEach ($fichero in $ficheros) {
    
    "Eliminando " + $fichero.FullName + " con fecha de modificacion " + $fichero.LastWritetime
    $c += $fichero.Length
    Remove-Item $fichero.FullName -Force:$True
    $i++

}

"`nSe han eliminado $i ficheros, un total de " + [math]::round(( $c / [math]::pow(1024,2) ),2) + " Mbytes."
