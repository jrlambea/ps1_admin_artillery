Add-pssnapin VMWare.VimAutomation.Core

Get-VM | Get-CDDrive | Set-CDDrive -NoMedia -Connected:$false -StartConnected:$false -Confirm:$false
