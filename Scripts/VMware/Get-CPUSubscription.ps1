$VMHosts = Get-VMHost

ForEach ($VMHost in $VMHosts) {
    $CPUS = ($VMHost | Get-VM | ?{$_.PowerState -eq "PoweredOn"}| Measure-Object -Sum numcpu).Sum
    $Med = [Math]::Floor($CPUS / $VMHost.NumCPU)
    If ($Med -le 3) {
        Write-Host "There is no problem, ratio in $($VMHost.Name) ${Med}:1, $CPUS/$($VMHost.NumCPU)" -ForeGroundColor Green
    } ElseIf ($Med -le 6) {
        Write-Host "Attention, ratio in $($VMHost.Name) may begin to cause performance degradation ${Med}:1, $CPUS/$($VMHost.NumCPU)" -ForeGroundColor Yellow
    } ElseIf ($Med -gt 6) {
        Write-Host "Alert! Ratio in $($VMHost.Name) is often going to cause a problem ${Med}:1, $CPUS/$($VMHost.NumCPU)" -ForeGroundColor Red
    }
}
