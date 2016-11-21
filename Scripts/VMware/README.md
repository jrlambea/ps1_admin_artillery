## Onelines scripts
### CPU Commitment
Get-VMHost | %{$CPU=$_ | Get-VM | Measure-Object -Sum NumCPU; "" | Select @"$($_.Name): Total:$($_.NumCPU) Commit:$($CPU.Sum/$_.NumCPU)"}
