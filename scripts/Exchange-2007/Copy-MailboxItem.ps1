<# 
    .Synopsis
    CMDLET para copiar un correo electrónico de un buzón a otro.
    .Description
    CMDLET para copiar un correo electrónico de un buzón a otro.
    .Parameter FromMailbox
    .Parameter ToMailbox
    .Example
        Copy-MailboxItem -FromMailbox OrigMailbox -ToMailbox DestMailbox
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

$Options = [System.Management.Automation.Host.ChoiceDescription[]]("&Contactos", "&E-mail", "&Mensajeria instantanea", "C&itas", "&Tareas", "&Notas")
$Select = $host.ui.PromptForChoice("Tipo de seleccion", "Que tipo de elemento buscas?", $Options, 1)

Switch( $Select )
{
    0 { $Kind = "kind:contacts" }
    1 { $Kind = "kind:email"
       
        $Value = Read-Host "Subject"
        If ( $Value ) { $Properties += " Subject:`"$Value`"" ; $Value = "" }

        $Value = Read-Host "From"
        If ( $Value ) { $Properties += " From:`"$Value`"" ; $Value = "" }

        $Value = Read-Host "To"
        If ( $Value ) { $Properties += " To:`"$Value`"" ; $Value = "" }

        $Value = Read-Host "Date"
        If ( $Value ) { $Properties += " Date:`"$Value`"" ; $Value = "" }
    }
    2 { $Kind = "kind:im" }
    3 { $Kind = "kind:meetings" }
    4 { $Kind = "kind:tasks" }
    5 { $Kind = "kind:notes" }
}

$Query = $Kind+$Properties
$Result = Search-Mailbox -Identity $FromMailbox -SearchQuery $Query -EstimateResultOnly

if ($Result.ResultItemscount -gt 0 ) {

    $Options = [System.Management.Automation.Host.ChoiceDescription[]]("&Si", "&No")
    $Select = $host.ui.PromptForChoice("Confirmar recuperacion", "Se han encontrado "+$Result.ResultItemscount+" coincidencias. Quieres recuperar estos correos?" , $Options, 0)

    Switch( $Select )
    {
        0 { Search-Mailbox -Identity $FromMailbox -SearchQuery $Query -TargetMailbox "$ToMailbox" -TargetFolder "AllMailboxes-Election" -LogLevel Full }
    }        

} else { "Se han encontrado "+$Result.ResultItemscount+" coincidencias." }
