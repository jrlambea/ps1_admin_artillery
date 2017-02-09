<#
.SYNOPSIS
Script for verify the certificate expiration date issued by a Certificate Authority. It uses the binary certutil to retrieve the certificate list.
.DESCRIPTION
Script for verify the certificate expiration date issued by a Certificate Authority. It uses the binary certutil to retrieve the certificate list.
.EXAMPLE
Test-CertExpirationDate.ps1 -Days 30
Show the certificates that expires in the next 30 days.
.EXAMPLE
Test-CertExpirationDate.ps1 -Days 45 -MailAdresses "sysadmins@contoso.com, devs@contoso.com"
Get the certificates that expires in the next 30 days and send a table by mail.
.PARAMETER Days
Restrict the certificates to retrieve to the certificates that expires in the next specified number of days.
.PARAMETER MailAddress
Mail addresses to send the expiring certificate list, one string and addresses separated with comma.
.INPUTS
None
.OUTPUTS
None
.LINK
.NOTES
  Version:        1.1
  Author:         Jose Ramón Lambea <jr_lambea@protonmail.com>
  Creation Date:  2014/01/31
  Purpose/Change: Initial script development

  170205 Fix: Filter the certificates by date with the certutil execution.
         Fix: Set "Days" parameter as uint32 instead of string.
         Add: Get-Help information.
         Add: Set mail body as html.
#>
Param(
    [Parameter(Mandatory=$true)]
    [Alias("d")]
    [UInt32]$Days,
    [Parameter(Mandatory=$False)]
    [Alias("m")]
    [String]$MailAddresses = "no")

[String]$MaxDate = (Get-Date).addDays($Days).ToString("dd/MM/yyyy")

# Mail configuration
[String]$EmailFrom 	= "certreport@contoso.com"
[String]$Subject = "Certificate control that expires in less than ${Days} days."
[String]$SMTPServer = "mailserver.contoso.com"

# Create an object with the list of certificates, each column is a property of the object.
$CertList = certutil -view -restrict "Disposition=20,notafter<=${MaxDate},notafter>=$((Get-Date).ToString("dd/MM/yyyy"))" -out "RequestID,CommonName,NotAfter,Disposition" csv | Select-Object -Skip 1 | ConvertFrom-Csv -Header RequestID,CommonName,NotAfter,Disposition

If ( $MailAddresses -ne "no" -And $CertList -ne $Null )
{
	$Message = New-Object System.Net.Mail.MailMessage("${EmailFrom}", "${MailAddresses}")
	$Message.Subject = "${Subject}"
	$Message.IsBodyHtml = $True
	$Message.Body = $CertList | ConvertTo-HTML
	$Message.BodyEncoding = [System.Text.Encoding]::UTF8
	$SMTP = New-Object Net.Mail.SmtpClient("$SMTPServer")
	$SMTP.Send($Message)
}

$CertList
