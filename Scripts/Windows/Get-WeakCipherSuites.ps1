
$Protocols = @{
    "PCT 1.0" = "\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\PCT 1.0\Server"
    "SSL 2.0" = "\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client", "\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server"
    "SSL 3.0" = "\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client", "\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server"
}

$Ciphers = @{
    "DES 56/56" = "\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\DES 56/56"
    "Null" = "\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\NULL"
    "RC2 128/128" = "\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC2 128/128"
    "RC2 40/128" = "\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC2 40/128"
    "RC2 56/128" = "\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC2 56/128"
    "RC2 56/56" = "\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC2 56/56"
    "RC4 128/128" = "\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 128/128"
    "RC4 40/128" = "\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 40/128"
    "RC4 56/128" = "\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 56/128"
    "RC4 64/128" = "\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 64/128"
    "Triple DES 126" = "\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\Triple DES 168"
}

Write-Host "`nDiscovering Weak Protocols Status"
foreach ($protocol in $Protocols.Keys) {
    $rc = $false
    foreach ($registryKey in $Protocols[$protocol]) {
        try {
            $disabledByDefault = (Get-ItemProperty hklm:${registryKey} -ErrorAction Stop).DisabledByDefault
            $enabled = (Get-ItemProperty hklm:${registryKey}).Enabled

            If (![Bool]$disabledByDefault -Or [Bool]$enabled) {
                $rc = $true
            }
        }
        Catch [System.Management.Automation.ActionPreferenceStopException] {
            $rc = $true
        }
    }
    Write-Host "- Protocol ${protocol} Enabled: ${rc}"  -ForegroundColor $(If($rc){"Red"}Else{"Green"})
}

Write-Host "`nDiscovering Weak Ciphers Status"
foreach ($cipher in $Ciphers.Keys) {
    foreach ($registryKey in $Ciphers[$cipher]) {
        Try {
            $enabled = [Bool](Get-ItemProperty hklm:${registryKey} -ErrorAction Stop).Enabled
        }
        Catch [System.Management.Automation.ActionPreferenceStopException] {
            $enabled = $true
        }
        Write-Host "- Cipher ${cipher} Enabled: ${enabled}" -ForegroundColor $(If($enabled){"Red"}Else{"Green"})
    }
}
