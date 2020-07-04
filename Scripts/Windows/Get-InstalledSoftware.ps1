<#
    .SYNOPSIS
        Get all local/remote installed software based on registry.

    .DESCRIPTION
        Get all local and remote installed software based on registry, this may be useful when a remote PS or Invoke-Command is not possible. In order to query the registry remotely, the service 'Remote Registry' must be enabled on the target computer.
#>

<#
    Author:     J.R. Lambea
    Version:    1.0
    Date:       Jul. 2020
#>

[CmdletBinding()]
param (
    # Select if need to get all local installed software.
    [Parameter()]
    [Switch]
    $Local = $False,

    # Select one or more comma separated machines in order to get the installed software remotely.
    [Parameter()]
    [String[]]
    $ComputerName = $null,

    # Use a regular expression in order to filter the results.
    [Parameter()]
    [String[]]
    $Filter = $null
)

Function Get-InstalledSoftwareFromReg() {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Microsoft.Win32.RegistryKey]
        $Reg,
        [Parameter()]
        [String]
        $ComputerName
    )

    $Results = @()

    ForEach ($RegistryKeyPath in $RegistryKeyPaths) {
        Write-Verbose "Analyzing `"${RegistryKeyPath}`" from ${ComputerName}"
        
        $key = $reg.OpenSubKey($RegistryKeyPath, $False)
        $Subkeys = $key.GetSubKeyNames()

        ForEach ($Subkey in $Subkeys) {
            $Key = $reg.OpenSubKey("${RegistryKeyPath}\${Subkey}", $False)
            $ProductName = $Key.GetValue("DisplayName")

            If ($null -ne $ProductName) {
                $ProductVersion = ""

                If ("DisplayVersion" -in $Key.GetValueNames()) {
                    $ProductVersion = $Key.GetValue("DisplayVersion")
                }

                $Results += "" | Select-Object `
                @{n = "ComputerName"; e = { $ComputerName } }, `
                @{n = "Product"; e = { $ProductName } }, `
                @{n = "Version"; e = { $ProductVersion } }
            }
        }
    }
    Return $Results
}

$RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
$RegistryKeyPaths = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", `
    "SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" 

If ([Environment]::Is64BitOperatingSystem) {
    $View = [Microsoft.Win32.RegistryView]::Registry64
}
Else {
    $View = [Microsoft.Win32.RegistryView]::Registry32
}

If ($Local) {
    Write-Verbose "Obtaining installed software from local (${Env:COMPUTERNAME})"

    $Reg = [Microsoft.Win32.RegistryKey]::OpenBaseKey($RegistryHive, $View)

    $Results = Get-InstalledSoftwareFromReg $Reg $Env:COMPUTERNAME
}

If ($ComputerName) {
    ForEach ($Computer in $ComputerName) {
        Write-Verbose "Obtaining installed software from Remote ($Computer)"

        $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $Computer)
        $Results = Get-InstalledSoftwareFromReg $Reg $Computer
    }
}

If ($Filter) {
    Try {
        Return $Results.Where( { $_ -match "${filter}" })
    }
    Catch {
        Write-Error "The filter has to be a regular expresion, like `"^.*Awsome.*$`"."
        Exit 5
    }
}

Return $Results