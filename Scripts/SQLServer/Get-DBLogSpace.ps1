$Instances = (Get-ChildItem sqlserver:/SQL/$($env:computername)/).Where({$_.InstanceName}).InstanceName

ForEach ( $Instance in $Instances ) {
    $Databases = (Get-ChildItem sqlserver:/SQL/$($env:computername)/${Instance}/Databases/).Where({$_.RecoveryModel -eq "Full"}).Name
    (Invoke-sqlcmd -Query "dbcc sqlperf (logspace)" -ServerInstance "localhost\${Instance}").Where({$_."Database Name" -in $Databases})
}
