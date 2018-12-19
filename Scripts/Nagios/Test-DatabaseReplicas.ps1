If (!(Get-Module -ListAvailable SQLPS)) {
    Write-Error "Seems that this is not a SQL Server."
    Exit 99
}

Import-Module SQLPS

$Server = (Get-Item Env:\Computername).Value
$Instances = (Get-ChildItem SQLServer:\SQL\${Server}\).where({$_.ServiceStartMode -eq "Auto"})

$FailedReplicas = ""

ForEach ($Instance in $Instances.InstanceName){
    $AvailabilityGroups = (Get-ChildItem SQLServer:\SQL\${Server}\${Instance}\AvailabilityGroups\).Name
    ForEach ($AvailabilityGroup in $AvailabilityGroups){
        $ReplicatedDatabases = (Get-ChildItem SQLServer:\SQL\${Server}\${Instance}\AvailabilityGroups\${AvailabilityGroup}\AvailabilityDatabases).Where({ $_.SynchronizationState -eq "Synchronized" }).Name
        $FailedReplicas += (Get-ChildItem SQLServer:\SQL\${Server}\${Instance}\Databases).Name.Where({$_ -notin $ReplicatedDatabases})
    }
}

If ($FailedReplicas -ne "" ) {
    "Failed replicas: " + $FailedReplicas
    Exit 2
}

Else {
    "All databases are replicated correctly"
    Exit 0
}
