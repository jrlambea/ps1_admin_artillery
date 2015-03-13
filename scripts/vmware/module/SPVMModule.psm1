<#
    alias SS
    function Get-SPCommand
    function Get-SPVMCPUOverlapping
    function Get-SPVMReplicatedVM
    function Get-SPVLANIDbyDatastore
#>

function Get-SPVMReplicatedVM() {
    <# 
        .Synopsis
            Muestra las maquinas virtuales ubicadas en un datastore replicado.

        .Description
            Este script busca las maquinas que tengan algun elemento ubicado en algun datastore con el nombre [*R_*], el cual es distintivo de replicacion.

        .Parameter NotReplicated
            Muestra las maquinas que no se replican.
          
        .Example
            # Muestra las maquinas virtuales que se replican.
            Get-SPVMReplicatedVM

        .Example
            # Muestra las maquinas virtuales que no se replican.
            Get-SPVMReplicatedVM -NotReplicated
    #>
    Param(
        [parameter( Mandatory = $false )]
        [alias( "N" )]
        [Switch]$NotReplicated
    )

    $datastores = Get-Datastore | ?{ $_.Name -like "*R_*" } | %{ $_.id }
    $VMs = Get-VM | Select Name,VMHost,DatastoreIdList,Notes
    $VMNotReplicated = @()
    $VMReplicated = @()

    ForEach ( $VM in $VMs ) {

        ForEach ( $VMdatastore in $VM.DatastoreIdList ){

            If ( $datastores -NotContains $VMdatastore ) {
                $VMNotReplicated += $VM
                Break
            }

        }

    }

    if ( $NotReplicated ) {

        $VMNotReplicated

    } else {

        ForEach ( $VM in $VMs ) {
            if ( $VMNotReplicated -NotContains $VM ) { $VMReplicated += $VM }
        }

        $VMReplicated

    } 
}

function Get-SPVMMappedCD() {
    <# 
        .Synopsis
            Muestra las imagenes (ISO) montadas en las maquinas virtuales.

        .Description
            Este script busca las maquinas que tengan algun como unidad de CD/DVD una imagen (ISO) montada.
          
        .Example
            # Muestra las maquinas virtuales con una imagen de CD/DVD montada.
            Get-SPVMMappedCD

    #>
    $VMs=Get-VM

    ForEach ( $VM in $VMs ) {

        If ( ( Get-CDDrive $VM ).IsoPath ) {
            $Drive = "" |Select-Object -Property Name, IsoPath
            $Drive.Name = $VM.Name
            $Drive.IsoPath = ( Get-CDDrive $VM ).IsoPath

            $Drive

        }

    }

}

function Get-SPVLANIDbyDatastore() {
    <# 
        .Synopsis
            Muestra las maquinas virtuales y sus VLANID en relación a los datastores.

        .Description
            Este script busca las maquinas ubicadas en los datastores y muestra las VLANID de todas las interfaces de red.
          
        .Example
            # Muestra todas las maquinas virtuales de todos los datastores con sus VLANID por interfaz.
            Get-SPVLANIDbyDatastore

    #>
    $Datastores = Get-Datastore
    $Lista = @()

    ForEach ( $Datastore in $Datastores ) {

        $Maquinas = $Datastore | Get-VM

        if ( ($Maquinas) ) {

            ForEach ( $Maquina in $Maquinas) {

                $VLanIds = Get-VirtualPortGroup -VM $Maquina | %{ $_.VLanId }

                ForEach ( $VLanId in $VLanIds ) {
                    $Entrada = "" | Select-Object -Property "Datastore", "Hostname", "VLANID"
                    $Entrada.Datastore = $Datastore
                    $Entrada.Hostname = $Maquina
                    $Entrada.VLanId = $VLanId

                    $Lista += $Entrada
                }
            }
        }
    }

    $Lista

}


function Get-SPCommand {Get-Command | ?{ $_.Name -Like "*-SP*" }}

function Get-SPVMCPUOverlapping() {
    Param(
        [parameter( Mandatory = $true )]
        [alias( "C" )]
        [String]$Cluster,
        [parameter( Mandatory = $true )]
        [alias( "S" )]
        [String]$Server   
    )

    <# Desconexión de la consola actual de todos los vCenters #>
    Disconnect-VIServer * -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

    Connect-VIServer $Server -ErrorAction SilentlyContinue | Out-Null

    $Hosts = Get-Cluster | ?{$_.name -eq $Cluster} | Get-VMHost

    $Hosts | % {
           
           $hst = $_.Name
           $hnum_CPU = $_.NumCpu

           $hres_CPU = (Get-VM | ?{ $_.VMHost.toString() -eq $hst } | ?{ $_.PowerState -eq "PoweredOn"} | Measure-Object -Sum NumCpu).Sum

           $object = "" | Select-Object -Property hostName, CPURatio, hostCPU, assCPU
           $object.assCPU = $hres_CPU
           [decimal]$hres_CPU = [Math]::Round($hres_CPU / $hnum_CPU, 2)

           $object.hostName = $hst
           $object.CPURatio = $hres_CPU
           $object.hostCPU = $hnum_CPU
           $object
    } | Sort-Object hostName
}

Set-Alias -Name SS -Value "Select-String"

Export-ModuleMember -function * -Alias SS
