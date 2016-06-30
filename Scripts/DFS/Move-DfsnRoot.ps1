<#
.SYNOPSIS
    Move or rename a DFS Root.
.DESCRIPTION
    Change the namespaces servers of a DFS root, and optionally change their name.
.PARAMETER DFSRootPath
    DFS root target, example: \\acme.com\rootname
.PARAMETER ServersFQDN
    List of servers in fqdn format
.PARAMETER NewDFSRootPath
    New name to set in the new DFSRoot
.EXAMPLE
    ./Move-DfsnRoot.ps1 -DFSRootPath \\domain.com\files -ServersFQDN svrdfs01.domain.com, svrdfs02.domain.com
.EXAMPLE
    ./Move-DfsnRoot.ps1 -DFSRootPath \\domain.com\files -ServersFQDN svrdfs01.domain.com, svrdfs02.domain.com -NewDFSRootPath \\domain.com\newfiles
#>

[CmdletBinding()]
Param(
    [Parameter( Mandatory = $True, Position = 0)][Alias( "p" )][String]$DFSRootPath,
    [Parameter( Mandatory = $True, Position = 1)][Alias( "s" )][String[]]$ServersFQDN,
    [Parameter( Mandatory = $False, Position = 2)][Alias("n")][String]$NewDFSRootPath = ""
)

function Exist-DFSRoot([String]$DFSRootPath, [String]$OutputFile)
{
    Return ((Get-DfsnRoot | ?{$_.Path -eq $DFSRootPath}) -ne $Null)
}

function Update-DFSXML([String]$XMLFileInput, [String]$XMLFileOutput,  [String[]]$ServersFQDN, [String]$NewDFSRootPath,[String]$RootName)
{
    [XML]$XMLData = Get-Content $XMLFileInput
    
    # Change the root path
    $XMLData.Root.Name = $NewDFSRootPath

    # Remove all existing nodes
    ForEach ($XMLDummy in $XMLData.SelectNodes("/Root/Target"))
    {
        $XMLDummy.ParentNode.RemoveChild($XMLDummy)
    }

    ForEach ($Server in $ServersFQDN)
    {
        # Define new Target node
        [System.Xml.XmlNode]$XMLNode = $XMLData.CreateNode([System.Xml.XmlNodeType]::Element, "Target", "")
        [System.Xml.XmlAttribute]$XMLAttServer = $XMLData.CreateAttribute("Server")
        [System.Xml.XmlAttribute]$XMLAttFolder = $XMLData.CreateAttribute("Folder")
        [System.Xml.XmlAttribute]$XMLAttState = $XMLData.CreateAttribute("State")

        # Assing values
        $XMLAttServer.Value = "${Server}"
        $XMLAttFolder.Value = "${RootName}"
        $XMLAttState.Value = "2"

        # Assign attributes to Node
        $XmlNode.Attributes.Append($XMLAttServer)
        $XmlNode.Attributes.Append($XMLAttFolder)
        $XmlNode.Attributes.Append($XMLAttState)

        # Insert the new node
        $XMLData.GetElementsByTagName("Root").PrependChild($XmlNode)
    }

    $XMLData.Save($XMLFileOutput)
}

function Set-DFSACLs([String]$XMLFileInput, [String]$DFSRootPath)
{
    [XML]$ACLs = Get-Content $XMLFileInput -Encoding UTF8

    ForEach ($ACL in $ACLs.Objects.Object)
    {
        $Path = ($ACL.Property | ?{$_.Name -eq "Path"})."#text"
        $AccountName = ($ACL.Property | ?{$_.Name -eq "AccountName"})."#text"

        &dfsutil property sd grant $Path ${AccountName}:RX protect
        
        # Grant-DfsnAccess cannot set explicit view permissions :(
        # Grant-DfsnAccess -Path $Path -AccountName $AccountName
    }
}

# (https://gallery.technet.microsoft.com/scriptcenter/Create-a-Share-and-Set-eb177a79)
function Create-WMITrustee([string]$NTAccount)
{ 
 
    $user = New-Object System.Security.Principal.NTAccount($NTAccount) 
    $strSID = $user.Translate([System.Security.Principal.SecurityIdentifier]) 
    $sid = New-Object security.principal.securityidentifier($strSID)  
    [byte[]]$ba = ,0 * $sid.BinaryLength      
    [void]$sid.GetBinaryForm($ba,0)  
     
    $Trustee = ([WMIClass] "Win32_Trustee").CreateInstance()  
    $Trustee.SID = $ba 
    $Trustee 
} 

# Create ACEs (https://gallery.technet.microsoft.com/scriptcenter/Create-a-Share-and-Set-eb177a79)
function Create-WMIAce([string]$account, [System.Security.AccessControl.FileSystemRights]$rights)
{     
    $trustee = Create-WMITrustee $account 
    $ace = ([WMIClass] "Win32_ace").CreateInstance()  
    $ace.AccessMask = $rights  
    $ace.AceFlags = 0 # set inheritances and propagation flags 
    $ace.AceType = 0 # set SystemAudit  
    $ace.Trustee = $trustee  
    $ace 
} 

function New-Share([String]$ShareName, [String]$PhysicalLocalPath, [String]$Server)
{
    [WMIClass]$WMIShare = "\\${Server}\Root\Cimv2:Win32_Share"
    
    # Set permissions (https://gallery.technet.microsoft.com/scriptcenter/Create-a-Share-and-Set-eb177a79)
    $SecurityDescriptor = ([WMIClass] "Win32_SecurityDescriptor").CreateInstance()
    $ACE = Create-WMIAce "Everyone" "FullControl"
    $SecurityDescriptor.DACL += @($ACE.psobject.baseobject) # append 
    $SecurityDescriptor.ControlFlags = "0x4" # set SE_DACL_PRESENT flag 
    $RC = $WMIShare.Create($PhysicalLocalPath, $ShareName, 0, 16777216, "", $False, $SecurityDescriptor)

    If (($RC.ReturnValue -eq 0) -Or ($RC.ReturnValue -eq 22)) { Return 0 }
    Else { Return $RC.ReturnValue }
}

# Variables
$TimeStamp = (Get-Date).ToString("%yMMddHmss")

# Output files
$TempDir = (get-item env:/TEMP).Value
$TempFile = "${TempDir}\mvdfsnroot_${TimeStamp}.xml"
$ACLTempFile = "${TempDir}\mvdfsnroot_acl_${TimeStamp}.xml"
$LogFile = "${TempDir}\mvdfsnroot_log_${TimeStamp}.txt"
$RootName = $DFSRootPath.Split("\")[3]

# New values
$NewTempFile = "${TempDir}\mvdfsnroot_new_${TimeStamp}.xml"

If (!($NewDFSRootPath))
{
    $NewDFSRootPath = $DFSRootPath;
    $NewRootName = $RootName
}

Else
{
    $NewRootName = $NewDFSRootPath.Split("\")[3]
}

$PrimaryServer = $ServersFQDN[0]
$NewTargetDir = "\\${PrimaryServer}\${NewRootName}"
$NewPhysicalTargetDir = "\\${PrimaryServer}\c$\DFSRoots\${NewRootName}"

<#
    1. If the physical target folder does not exist, create
#>
If (!(Test-Path $NewPhysicalTargetDir)) { New-Item $NewPhysicalTargetDir -ItemType Directory | Out-File -Append $LogFile }

$RC = $LASTEXITCODE
If (($RC -gt 0) -Or (!(Test-Path $NewPhysicalTargetDir))) { Write-Error "The destination folder has not been created."; Return $RC }

<#
    2. If the shared folder does not exist, create
#>
If (!(Test-Path $NewTargetDir)) { New-Share -ShareName $NewRootName -PhysicalLocalPath "c:\DFSRoots\${NewRootName}" -Server $PrimaryServer | Out-File -Append $LogFile }

$RC = $LASTEXITCODE
If (($RC -gt 0) -Or !(Test-Path $NewTargetDir)) { Write-Error "The shared folder has not been created."; Return $RC }

<#
    3. If the specified root exist, make an export (DFSRootPath)
#>
If (!(Exist-DFSRoot -DFSRootPath $DFSRootPath)) { Write-Error "The specified DFSRootPath does not exist."; Return 16 }

Write-Host "Export of root ${DFSRootPath} to ${TempFile}"
&dfsutil /root:${DFSRootPath} /export:${TempFile} /verbose | Out-File -Append $LogFile

$RC = $LASTEXITCODE
If (($RC -gt 0) -Or (!(Test-Path $TempFile))) { Write-Error "Export process failed. More details in ${LogFile}"; Return $RC }

<#
    4. Generate the ACL file
#>
Write-Host "Export ACL"
(Get-DfsnFolder -Path ${DFSRootPath}\* | Get-DfsnAccess | ConvertTo-XML).Save($ACLTempFile)
Write-Host "Modify the original XML file with the new namespace servers"
(Get-Content $ACLTempFile -Encoding UTF8).Replace($DFSRootPath, $NewDFSRootPath) | Out-File  $ACLTempFile
Update-DFSXML -XMLFileInput $TempFile -XMLFileOutput $NewTempFile -ServersFQDN $ServersFQDN -RootName $NewRootName -NewDFSRootPath $NewDFSRootPath | Out-File -Append $LogFile

If (!(Test-Path $TempFile)) { Write-Error "The file ${NewTempFile} has not been generated correctly"; Return 4 }

<#
    5. Remove
#>
Write-Host "[Not Operational!] Remove DFSRoot ${DFSRootPath}"
# {...}

<#
    6. Force synchronization between DC
#>
Write-Warning "Please, go to the DC $((Get-Item Env:\LogonServer).Value) and force a replication executing 'repadmin /syncall', after this, press intro to continue."
Read-Host | Out-Null

<#
    7. Create new DFS root
#>
Write-Host "Create new DFSRoot ${NewDFSRootPath}"
New-DfsnRoot -Path $NewDFSRootPath -TargetPath "\\${PrimaryServer}\${NewRootName}" -Type DomainV2 | Out-File -Append $LogFile

<#
    8. Load the folders exported in step 3
#>
Write-Host "Configure new DFSRoot ${NewDFSRootPath}"
&dfsutil /root:${NewDFSRootPath} /import:${NewTempFile} /set /verbose | Out-File -Append $LogFile

$RC = $LASTEXITCODE

If ($RC -gt 0) { Write-Error "Import process failed. More details in $LogFile, backup files: ${TempFile}, ${NewTempFile}, ${ACLTempFile}"; Return $RC }

<#
    9. Load the permissions exported in step 4
#>
Write-Host "Import ACLs"
Set-DFSACLs -XMLFileInput $ACLTempFile -DFSRootPath $NewDFSRootPath | Out-File -Append $LogFile

Write-Host "Process completed successfully"
