Param(
    [Parameter(Mandatory=$True, Position = 0)]
    [String]$TimeServer = $null,
    [Parameter(Mandatory=$True, Position = 1)]
    [Int]$OffsetInMilliseconds = 0
)

$Result = &"C:\windows\system32\w32tm.exe" "/monitor" "/computers:${TimeServer}" | ?{$_ -match "    NTP: ([+-]+)([0-9]+).([0-9]+)s offset.*"}
If (!($Result)) {
    $Err = &"C:\windows\system32\w32tm.exe" "/monitor" "/computers:${TimeServer}" | ?{$_ -Like "*ERROR_TIMEOUT*"}
    If ($Err) {
        "Server NTP $TimeServer unreachable."
        Exit 2
    }
    Write-Warning "The time cannot be read."
    Exit 3
}

$ResultInMilliseconds = [Int]([Float]([Regex]::Match($Result, "\d.\d{7}").Value) * 1000)
$Offset = [Regex]::Match($Result, "(\+|\-)\d.\d{7}s").Value

If ($ResultInMilliseconds -gt $OffsetInMilliseconds) {
    "Time not in sync ($Offset)"
    Exit 2
}

"Time synchronized correctly ($Offset)"
