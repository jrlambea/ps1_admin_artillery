Add-pssnapin VMWare.VimAutomation.Core

$VCENTER           = "vcenter1.contoso.com","vcenter2.contoso.com","vcenter3.contoso.com","vcenter4.contoso.com","vcenter5.contoso.com"
[Array]$snaps       = New-Object PSObject -Property @{ VM=""; Size=""; Date=""; vCenter="" }
$i                  = 0

# Mail configuration
[String]$emailFrom      = "controlsnaps@contoso.com"
[String]$subject        = "VMWare Snapshots Control."
[String]$smtpserver     = "smtp.contoso.com"
[String]$mailAddresses  = "bofh@contoso.com"
<#
    Function to connect to a vCenter server, it returns a boolean value:
    - $true if the function has completed succesfully.
    - false if the function hasn't completed succesfully.
#>
Function Connect( $VCENTER ){
   
   [String]$server = ""

    Try {
        $VCENTER | % { $server="$_" ; Connect-VIServer $VCENTER | Out-Null }
    
        Return $true

    } Catch {
        Write-Host "[X] Couldn't connect to vCenter Server: $server"
        Return $false

    }
}

<#    Main    #>
if ( Connect( $VCENTER ) ) {
    $VCENTER | % {
        $vcen = $_
        Get-Snapshot * -Server $vcen | %{
            $snaps += New-Object PSObject -Property @{ VM=$_.VM; Size=[System.Math]::Round($_.SizeGB, 2); Date=$_.Created.ToString("d"); vCenter=$vcen.split(".")[0] }
        }
    }

otes    [String]$body = $snaps | Out-String
    $smtp = new-object Net.Mail.SmtpClient("$smtpServer")
    $smtp.Send("$emailFrom", "$mailAddresses", "$subject", $body)

}
