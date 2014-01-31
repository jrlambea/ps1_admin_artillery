<#
    Author Jose Ramón Lambea

    140131 Script for verify the certificate expiration date issued by a
           Certificate Authority. It uses the binary certutil to retrieve
           the certificate list.

    Usage:
        Test-CertExpirationDate.ps1 -d days [ -m mailaddresses ]
#>

Param(
    [parameter(Mandatory=$true)]
    [alias("d")]
    [string]
    $days,
    [parameter(Mandatory=$false)]
    [alias("m")]
    [string]
    $mailAddresses = "no")

[Datetime]$refDate  = (Get-Date).addDays($days)
[Datetime]$nowDate  = Get-Date
[String]$tempDir    = (Get-ChildItem Env:TEMP).Value
[String]$tempFile   = "$tempDir\Test-CertExpirationDate.tmp"

# Mail configuration
[String]$emailFrom 	= "controlcerts@domain"
[String]$subject 	= "Certificate control that expires in less than $days days."
[String]$smtpserver = "smtp.server.domain"

# Retrieve the certificate list
certutil -view -out "RequestID,CommonName,NotAfter,Disposition" csv | Out-File $tempFile

# Create an object with the list retrieved before, each column is a property of the object.
$certList       = Import-CSV $tempFile -Header RequestID,CommonName,NotAfter,Disposition
$certstoExpire  = $certlist | ? { $_.Disposition                   -eq "20 -- Issued" -And `
                                  [datetime]::Parse($_.NotAfter)   -le $refDate       -And `
                                  [datetime]::Parse($_.NotAfter)   -gt $nowDate       }

if ( $mailAddresses -ne "no" )
{

	[String]$body = $certstoExpire | Out-String
	$smtp = new-object Net.Mail.SmtpClient("$smtpServer")
	$smtp.Send("$emailFrom", "$mailAddresses", "$subject", $body)
	
} else {

	$certstoExpire    

}
