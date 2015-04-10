<# 
    .Synopsis
    CMDLET para items de un buzón de Exchange a otro.
    .Description
    CMDLET para items de un buzón de Exchange a otro.
    .Parameter FromMailbox
    .Parameter ToMailbox
    .Example
        Search-MailboxItem.ps1 -FromMailbox OrigMailbox -ToMailbox DestMailbox
#>
<# AQS: https://msdn.microsoft.com/en-us/library/aa965711%28v=vs.85%29.aspx #>
Param(
    [parameter( Position = 0, Mandatory = $true )]
    [alias( "f" )]
    [String]$FromMailbox,
    [parameter( Position = 1, Mandatory = $true )]
    [alias( "t" )]
    [String]$ToMailbox
)

Function QueryForm {

    $Value = Read-Host "Subject"
    If ( $Value ) { $Query += " Subject:`"$Value`""; $Value = "" }

    $Value = Read-Host "From"
    If ( $Value ) { $Query += " From:`"$Value`""; $Value = "" }

    $Value = Read-Host "To"
    If ( $Value ) { $Query += " To:`"$Value`""; $Value = "" }

    $Value = Read-Host "Date"
    If ( $Value ) { $Query += " Date:`"$Value`""; $Value = "" }

    $Query

}

$Select = 0

While ( $Select -eq 0 ) {

    $Options = [System.Management.Automation.Host.ChoiceDescription[]]("&Contactos", "&E-mail", "&Mensajeria instantanea", "C&itas", "&Tareas", "&Notas")
    $Select = $host.ui.PromptForChoice("Tipo de seleccion", "Que tipo de elemento buscas?", $Options, 1)

    Switch( $Select )
    {
        0 { $Kind = "kind:contacts" }
        1 { $Kind = "kind:email"; $Kind += QueryForm }
        2 { $Kind = "kind:im" }
        3 { $Kind = "kind:meetings" }
        4 { $Kind = "kind:tasks" }
        5 { $Kind = "kind:notes" }
    }

    $Options = [System.Management.Automation.Host.ChoiceDescription[]]("&Si", "&No")
    $Select = $host.ui.PromptForChoice("Envio de informe", "Quieres recibir un informe?" , $Options, 0)

    if ($Select -eq 0 )
    {

        $targetMailbox = Read-Host "A que buzon quieres recibir el informe?"
        $Report = @{
            TargetMailbox = "$targetMailbox"
            TargetFolder = "Item_Results"
            LogOnly = $True
            LogLevel = "Full"
        }

    } else { $Report = @{ EstimateResultOnly = $True } }

    $Result = Search-Mailbox -Identity $FromMailbox -SearchQuery $Kind @Report

    $Select = $host.ui.PromptForChoice("Se han encontrado " + $Result.ResultItemscount + " coincidencias. Modificar la busqueda", "Quieres modificar la busqueda?" , $Options, 1)

}

if ($Result.ResultItemscount -gt 0 ) {

    $Options = [System.Management.Automation.Host.ChoiceDescription[]]("&Ninguna", "&Copiar", "&Eliminar")
    $Select = $host.ui.PromptForChoice("Accion a realizar", "Que accion quieres realizar con el/los item/s?" , $Options, 0)

    Switch( $Select )
    {
        1 { Search-Mailbox -Identity $FromMailbox -SearchQuery $Kind -TargetMailbox "$ToMailbox" -TargetFolder "Item_Results" -LogLevel Full }
        2 { Search-Mailbox -Identity $FromMailbox -SearchQuery $Kind -TargetMailbox "$ToMailbox" -TargetFolder "Item_Results" -LogLevel Full -DeleteContent }
    }        

} else { "Se han encontrado "+$Result.ResultItemscount+" coincidencias." }
