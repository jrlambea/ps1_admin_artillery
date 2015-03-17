<#
    alias xxx
    function Get-SPxxx
    function Get-SPxxx
    function Set-SPxxx
    function Get-SPxxx
#>

function Get-SPxxx() {
    <# 
        .Synopsis
        .Description
        .Parameter NotReplicated
        .Example
            # Use_1
        .Example
            # Use_2
    #>
    Param(
        [parameter( Mandatory = $false )]
        [alias( "x" )]
        [Switch]$xxx
    )

    $datastores = Get-Datastore | ?{ $_.Name -like "*R_*" } | %{ $_.id }
    $VMs = Get-VM | Select Name,VMHost,DatastoreIdList,Notes
    $VMNotReplicated = @()
    $VMReplicated = @()

}

function Get-SPxxx() {
    <# 
        .Synopsis
        .Description
        .Parameter NotReplicated
        .Example
            # Use_1
        .Example
            # Use_2
    #>

}

function Set-SPxxx() {
    <# 
        .Synopsis
        .Description
        .Parameter NotReplicated
        .Example
            # Use_1
        .Example
            # Use_2
    #>

}


function Get-SPCommand {Get-Command | ?{ $_.Name -Like "*-SP*" }}

function Get-SPxxx() {
    <# 
        .Synopsis
        .Description
        .Parameter NotReplicated
        .Example
            # Use_1
        .Example
            # Use_2
    #>

}

Set-Alias -Name xxx -Value "{Instruction}"

Export-ModuleMember -function * -Alias xxx
