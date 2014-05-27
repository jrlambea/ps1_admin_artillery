<#
	Hardening registry based W2008
#>

# Null sesion vuln

Param(
    [parameter(Mandatory=$false)]
    [alias("R")]
    [boolean]
    $Repair)

$FAIL = "[FAIL] "
$DONE = "[DONE] "
$PASS = "[PASS] "

$regRestrictAnon = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\"

if ((Get-ItemProperty $regRestrictAnon).RestrictAnonymous -ne 2 ) {
    Write-Host -NoNewLine "$FAIL" -foregroundcolor "red"
    Write-Host "Null Session Vulnerability"

    if ( $Repair ) {
        Set-ItemProperty -path $regRestrictAnon -name "RestrictAnonymous" -value 2
        Write-Host -NoNewLine "$DONE" -foregroundcolor "green"
        Write-Host "Null Session Vulnerability fixed."
    }

} else {

	Write-Host -NoNewLine "$PASS" -foregroundcolor "green"
    Write-Host "Null Session Vulnerability passed."
}
