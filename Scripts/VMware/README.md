## Onelines scripts
### CPU Commitment
```
Get-VMHost | %{$Name=$_.Name;$HostCPU=$_.NumCPU;$CPU=$_ | Get-VM | Measure-Object -Sum NumCPU; "" | Select @{n="Name";e={$Name}}, @{n="HostCPU";e={$HostCPU}}, @{n="Commited";e={$CPU.Sum/$HostCPU}}}
```
