Param(
    [parameter( Mandatory = $true )]
    [String]$Domain,
    [Parameter( Mandatory = $true )]
    [String]$UserName
)

Import-Module ActiveDirectory

Function Get-DomainControllers() {
    Param(
        [parameter( Mandatory = $true )]
        [String]$Domain
    )
    
    $DCs = @()

    ForEach ($DC in (Get-ADDomain $Domain).ReplicaDirectoryServers) {
        $item = "" | Select-Object -Property "DC Name","Site"
        $item."DC Name" = $DC
        $item.Site = (Get-ADDomainController $DC).Site
        
        $DCs += $item

    }

    Return $DCs
    
}

Function Get-UserExists() {
    Param(
        [parameter( Mandatory = $true )]
        [String]$Domain,
        [parameter( Mandatory = $true )]
        [String]$UserName
    )
    
    $User = Get-ADUser -Server $Domain $UserName -ErrorAction SilentlyContinue

    If ($User){Return $True}
    
    Return $False
    
}

Function Get-LockStatus() {
    Param(
        [parameter( Mandatory = $true )]
        [String]$Server,
        [parameter( Mandatory = $true )]
        [String]$UserName
    )

    If ((Get-ADUser -Server $Server $UserName -Property "LockedOut").LockedOut) { Return "Locked" }
    
    Return "Not Locked"
}

$DCs = Get-DomainControllers -Domain $Domain

If ( -not (Get-UserExists -Domain $Domain -UserName $UserName) ) { Exit 5 }

$Status = @()

ForEach ($DC in $DCs) {
    
    $Stat = "" | Select-Object -Property "DC Name", "Site", "User State", "Bad Pwd Count", "Last Bad Pwd", "Pwd Last Set", "Lockout Time"
    $Stat."DC Name" = $DC."DC Name"
    $Stat.Site = $DC.Site
    $Stat."User State" = Get-LockStatus -Server $DC."DC Name" -UserName $UserName
    $Stat."Bad Pwd Count" = (Get-ADUser -Server $DC."DC Name" $UserName -Property "badPwdCount").badPwdCount
    $Stat."Last Bad Pwd" = (Get-ADUser -Server $DC."DC Name" $UserName -Property "LastBadPasswordAttempt").LastBadPasswordAttempt
    $Stat."Pwd Last Set" = [datetime]::FromFileTime((Get-ADUser -Server $DC."DC Name" $UserName -Property "pwdLastSet").pwdLastSet)
    $Stat."Lockout Time" = [datetime]::FromFileTime((Get-ADUser -Server $DC."DC Name" $UserName -Property "lockoutTime").lockoutTime)
    
    $Status += $Stat
}

$Status
