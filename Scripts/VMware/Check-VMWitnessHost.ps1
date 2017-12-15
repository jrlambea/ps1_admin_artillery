<#
    Script to ensure that the passive vCenter server and witness are running
    together in the same ESXi (therefore cluster).
#>
Import-Module VMWare.VimAutomation.Core

$nodeNames = "vcenter1-server", "vcenter2-server"
$witness = "witness-server"
$serviceIP = "xx.xx.xx.xx"

$hostsCluster1 = "^xplmvwes\d.vb.and.corp$"

Write-Host "Primary vCenter search."

# Search the active and passive server and determine the cluster on which are running
$activeServer = (Get-VM).where({
        $_.Name -in $nodeNames -and $_.Guest.IpAddress -contains $serviceIP
    })

Write-Host "The vCenter principal server is $($activeServer.Name)."
    
$passiveServer = (Get-VM).where({
        $_.Name -in $nodeNames -and $_.Guest.IpAddress -notcontains $serviceIP
    })

$clusterActive = $activeServer.VMHost.Name -match $hostsCluster1

If ($clusterActive) {
    Write-Host "The active server is on principal cluster."
}
Else {
    Write-Host "The active server is on secondary cluster."    
}

$clusterPassive = $passiveServer.VMHost.Name -match $hostsCluster1

If ($clusterPassive) {
    Write-Host "The passive server is on principal cluster."
}
Else {
    Write-Host "The passive server is on secondary cluster."    
}

If ( $clusterActive -eq $clusterPassive ) {
    Write-Host "Both active and passive servers are in the same cluster!" -ForegroundColor Red
}
Else {
    Write-Host "Active and passive are in different, that's ok." -ForegroundColor Green
}

Write-Host "No need to take action, locating witness."

# Search the witness server and move with passive if necessary.
$clusterWitness = (Get-VM $witness).VMHost.Name -match $hostsCluster1

If ( $clusterWitness -eq $clusterPassive ) {
    Write-Host "Both witness and passive servers are in the same cluster, that's fine." -ForegroundColor Green
    Exit 0
}

Write-Host "Witness and passive are in different cluster! MOVE THE WITHNESS || GTFO!" -ForegroundColor Red
Move-VM $witness -Destination $passiveServer.VMHost

If ($witness.VMHost -eq $passiveServer.VMHost) {
    Exit 0
}
Else {
    Throw "The witness $witness couldn't be moved."
}
