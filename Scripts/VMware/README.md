## Oneline scripts
### CPU Commitment
```
Get-VMHost | %{$Name=$_.Name;$HostCPU=$_.NumCPU;$CPU=$_ | Get-VM | Measure-Object -Sum NumCPU; "" | Select @{n="Name";e={$Name}}, @{n="HostCPU";e={$HostCPU}}, @{n="Commited";e={$CPU.Sum/$HostCPU}}}
```

### VM and ip relationship
```
Get-VM * | %{$vm = $_.Name;$ip = $_.Guest.Nics.IPAddress;"" | Select-Object -Property @{n="VMName";e={$vm}}, @{n="IPAddresses";e={$ip}}}
```
