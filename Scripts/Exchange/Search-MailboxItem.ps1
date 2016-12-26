<# 
    .Synopsis
    Cmdlet to locate, copy or drop items from a MS Exchange mailbox.
    .Description
    Cmdlet to locate, copy or drop items from a MS Exchange mailbox, it's a wizard for Search-Mailbox Exchange cmdlet.
    .Parameter TargetMailbox
    Mailbox which is target, the mailbox to poke around.
    .Parameter ReportMailbox
    Mailbox that has to receive the reports.
    .Example
        Search-MailboxItem.ps1 -TargetMailbox OrigMailbox -ReportMailbox DestMailbox
    .Link
	AQS: https://msdn.microsoft.com/en-us/library/aa965711%28v=vs.85%29.aspx
    Blog: inceptor.me
#>
Param(
    [Parameter( Position = 0, Mandatory = $True )]
    [Alias( "f" )]
    [String]$TargetMailbox,
    [Parameter( Position = 1, Mandatory = $True )]
    [Alias( "t" )]
    [String]$ReportMailbox
)

Function QueryForm {

    $Value = Read-Host "Subject"
    If ( $Value ) { $Query += " Subject:`"${Value}`""; $Value = "" }

    $Value = Read-Host "From"
    If ( $Value ) { $Query += " From:`"${Value}`""; $Value = "" }

    $Value = Read-Host "To"
    If ( $Value ) { $Query += " To:`"${Value}`""; $Value = "" }

    $Value = Read-Host "Date"
    If ( $Value ) { $Query += " Sent:${Value}"; $Value = "" }

    $Query

}

$Select = 0

While ( $Select -eq 0 ) {

    $Options = [System.Management.Automation.Host.ChoiceDescription[]]("&Contacts", "&E-mail", "&IM", "&Meetings", "&Tasks", "&Notes")
    $Select = $host.UI.PromptForChoice("Kind of item", "What kind of item are you searching?", $Options, 1)

    Switch( $Select )
    {
        0 { $Kind = "kind:contacts" }
        1 { $Kind = "kind:email"; $Kind += QueryForm }
        2 { $Kind = "kind:im" }
        3 { $Kind = "kind:meetings" }
        4 { $Kind = "kind:tasks" }
        5 { $Kind = "kind:notes" }
    }

    $Options = [System.Management.Automation.Host.ChoiceDescription[]]("&Yes", "&No")
    $Select = $host.UI.PromptForChoice("Send report", "Do you want send a report?" , $Options, 0)

    If ($Select -eq 0 )
    {
        $TemporalRprtMailbox = Read-Host "To whitch mailbox you want send the report?"
        $Report = @{
            TargetMailbox = "${TemporalRprtMailbox}"
            TargetFolder = "Item_Results"
            LogOnly = $True
            LogLevel = "Full"
        }

    }
    
    Else
    {
        $Report = @{ EstimateResultOnly = $True }
    }

    $Result = Search-Mailbox -Identity "${TargetMailbox}" -SearchQuery $Kind @Report

    $Select = $host.UI.PromptForChoice("$($Result.ResultItemscount) matches has been found.", "Do you want modify the search parameters?" , $Options, 1)

}

If ($Result.ResultItemscount -gt 0 ) {

    $Options = [System.Management.Automation.Host.ChoiceDescription[]]("&Nothing", "&Copy", "&Remove")
    $Select = $host.UI.PromptForChoice("Action to do", "What do you want to do with the selected items?" , $Options, 0)

    Switch( $Select )
    {
        1 { Search-Mailbox -Identity $TargetMailbox -SearchQuery $Kind -TargetMailbox "${ReportMailbox}" -TargetFolder "Item_Results" -LogLevel Full }
        2 { Search-Mailbox -Identity $TargetMailbox -SearchQuery $Kind -TargetMailbox "${ReportMailbox}" -TargetFolder "Item_Results" -LogLevel Full -DeleteContent }
    }        

}

Else 
{ 
    "$($Result.ResultItemscount) matches has been found."
}
