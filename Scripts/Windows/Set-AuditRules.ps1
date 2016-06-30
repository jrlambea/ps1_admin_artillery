Import-Module ActiveDirectory

<# Configuración del script #>
$ROOT = "X:\UsrProfile"
$AuditedGroup = "SG_Audit_PersonalFiles"
$AuditedUsers = Get-ADGroupMember $AuditedGroup | %{ $_.Name }
$Domain = "DOMAIN"
$MyDocs = @()

ForEach ($User in $AuditedUsers) {
    $MyDocs += Get-Item "$ROOT\$User\Documents"
}

<# Plantilla de AuditRules que se deben comprobar/aplicar #>
$AuditRules = @()
$AuditRule = New-Object System.Security.AccessControl.FileSystemAuditRule("BM\SG_BM_Audit_PersonalFiles", "Write, Read", "ContainerInherit, ObjectInherit", "None", "Success")
$AuditRules += $AuditRule
$AuditRule = New-Object System.Security.AccessControl.FileSystemAuditRule("BM\SG_BM_Audit_PersonalFiles", "Read", "ContainerInherit, ObjectInherit", "None", "Failure")
$AuditRules += $AuditRule

<# Función para comparar ACL's #>
function Compare-ACL {
    
    Param(
        [parameter( Mandatory = $true, Position = 0 )]
        [System.Security.AccessControl.FileSystemAuditRule]$ACL1,
        [parameter( Mandatory = $true, Position = 1 )]
        [System.Security.AccessControl.FileSystemAuditRule]$ACL2
    )

    <# Propiedades a comparar que DEBEN ser iguales #>
    $Properties = "FileSystemRights","AuditFlags","IdentiryReference","IsInherited","InheritanceFlags","PropagationFlags"

    ForEach ($Property in $Properties) {

        if ($ACL1."$Property" -ne $ACL2."$Property"){ Return $True }
    }

    Return $False

}

<# Funcion para setear propietario del objeto con permisos elevados: http://cosmoskey.blogspot.com/2010/07/setting-owner-on-acl-in-powershell.html #>
function Set-OwnerElevated {

    Param(
        [parameter( Mandatory = $true, Position = 0 )]
        [System.IO.FileSystemInfo]$Object,
        [parameter( Mandatory = $true, Position = 1 )]
        [String]$Identity,
        [parameter( Mandatory = $true, Position = 2 )]
        [String]$Domain
    )

    $code = @"
        using System;
        using System.Runtime.InteropServices;

        namespace CosmosKey.Utils
        {
            public class TokenManipulator
            {

                [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall, ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);

                [DllImport("kernel32.dll", ExactSpelling = true)]internal static extern IntPtr GetCurrentProcess();

                [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);

                [DllImport("advapi32.dll", SetLastError = true)]internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);

                [StructLayout(LayoutKind.Sequential, Pack = 1)]internal struct TokPriv1Luid
                {
                    public int Count;
                    public long Luid;
                    public int Attr;
                }

                internal const int SE_PRIVILEGE_DISABLED = 0x00000000;
                internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
                internal const int TOKEN_QUERY = 0x00000008;
                internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;

                public const string SE_ASSIGNPRIMARYTOKEN_NAME = "SeAssignPrimaryTokenPrivilege";
                public const string SE_AUDIT_NAME = "SeAuditPrivilege";
                public const string SE_BACKUP_NAME = "SeBackupPrivilege";
                public const string SE_CHANGE_NOTIFY_NAME = "SeChangeNotifyPrivilege";
                public const string SE_CREATE_GLOBAL_NAME = "SeCreateGlobalPrivilege";
                public const string SE_CREATE_PAGEFILE_NAME = "SeCreatePagefilePrivilege";
                public const string SE_CREATE_PERMANENT_NAME = "SeCreatePermanentPrivilege";
                public const string SE_CREATE_SYMBOLIC_LINK_NAME = "SeCreateSymbolicLinkPrivilege";
                public const string SE_CREATE_TOKEN_NAME = "SeCreateTokenPrivilege";
                public const string SE_DEBUG_NAME = "SeDebugPrivilege";
                public const string SE_ENABLE_DELEGATION_NAME = "SeEnableDelegationPrivilege";
                public const string SE_IMPERSONATE_NAME = "SeImpersonatePrivilege";
                public const string SE_INC_BASE_PRIORITY_NAME = "SeIncreaseBasePriorityPrivilege";
                public const string SE_INCREASE_QUOTA_NAME = "SeIncreaseQuotaPrivilege";
                public const string SE_INC_WORKING_SET_NAME = "SeIncreaseWorkingSetPrivilege";
                public const string SE_LOAD_DRIVER_NAME = "SeLoadDriverPrivilege";
                public const string SE_LOCK_MEMORY_NAME = "SeLockMemoryPrivilege";
                public const string SE_MACHINE_ACCOUNT_NAME = "SeMachineAccountPrivilege";
                public const string SE_MANAGE_VOLUME_NAME = "SeManageVolumePrivilege";
                public const string SE_PROF_SINGLE_PROCESS_NAME = "SeProfileSingleProcessPrivilege";
                public const string SE_RELABEL_NAME = "SeRelabelPrivilege";
                public const string SE_REMOTE_SHUTDOWN_NAME = "SeRemoteShutdownPrivilege";
                public const string SE_RESTORE_NAME = "SeRestorePrivilege";
                public const string SE_SECURITY_NAME = "SeSecurityPrivilege";
                public const string SE_SHUTDOWN_NAME = "SeShutdownPrivilege";
                public const string SE_SYNC_AGENT_NAME = "SeSyncAgentPrivilege";
                public const string SE_SYSTEM_ENVIRONMENT_NAME = "SeSystemEnvironmentPrivilege";
                public const string SE_SYSTEM_PROFILE_NAME = "SeSystemProfilePrivilege";
                public const string SE_SYSTEMTIME_NAME = "SeSystemtimePrivilege";
                public const string SE_TAKE_OWNERSHIP_NAME = "SeTakeOwnershipPrivilege";
                public const string SE_TCB_NAME = "SeTcbPrivilege";
                public const string SE_TIME_ZONE_NAME = "SeTimeZonePrivilege";
                public const string SE_TRUSTED_CREDMAN_ACCESS_NAME = "SeTrustedCredManAccessPrivilege";
                public const string SE_UNDOCK_NAME = "SeUndockPrivilege";
                public const string SE_UNSOLICITED_INPUT_NAME = "SeUnsolicitedInputPrivilege";        

                public static bool AddPrivilege(string privilege)
                {
                    try
                    {
                        bool retVal;
                        TokPriv1Luid tp;
                        IntPtr hproc = GetCurrentProcess();
                        IntPtr htok = IntPtr.Zero;
                        retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
                        tp.Count = 1;
                        tp.Luid = 0;
                        tp.Attr = SE_PRIVILEGE_ENABLED;
                        retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
                        retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
                        
                        return retVal;
                    }
                    catch (Exception ex)
                    {
                        throw ex;
                    }

                }

                public static bool RemovePrivilege(string privilege)
                {
                    try
                    {
                        bool retVal;
                        TokPriv1Luid tp;
                        IntPtr hproc = GetCurrentProcess();
                        IntPtr htok = IntPtr.Zero;
                        retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
                        tp.Count = 1;
                        tp.Luid = 0;
                        tp.Attr = SE_PRIVILEGE_DISABLED;
                        retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
                        retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
                        
                        return retVal;
                    }
                    catch (Exception ex)
                    {
                        throw ex;
                    }
                }
            }
        }
"@

    $Account = New-Object System.Security.Principal.NTAccount("$Domain", "$Identity")
    "        Cambiando propietario de " + $Object.FullName + " por " + $Account

    $errPref = $ErrorActionPreference
    $ErrorActionPreference= "silentlycontinue"
    $type = [CosmosKey.Utils.TokenManipulator]
    $ErrorActionPreference = $errPref
    
    if($type -eq $null){ add-type $code }

    $Acl = Get-Acl $Object.FullName -Audit
    $Acl.psbase.SetOwner($Account)

    [void][CosmosKey.Utils.TokenManipulator]::AddPrivilege([CosmosKey.Utils.TokenManipulator]::SE_RESTORE_NAME)
    $Acl | Set-Acl $Object.FullName
    [void][CosmosKey.Utils.TokenManipulator]::RemovePrivilege([CosmosKey.Utils.TokenManipulator]::SE_RESTORE_NAME)

    if ($Object.Attributes -like "*Directory*") {
        
        $Objects = Get-ChildItem $Object.FullName

        ForEach ( $Object in $Objects ) {
            Set-OwnerElevated -Object $Object -Identity $Identity -Domain $Domain
        }
    }
}

<# Función para definir propietario del objeto y propagación en caso de contenedores #>
function Set-Owner {

    Param(
        [parameter( Mandatory = $true, Position = 0 )]
        [System.IO.FileSystemInfo]$Object,
        [parameter( Mandatory = $true, Position = 1 )]
        [String]$Identity,
        [parameter( Mandatory = $true, Position = 2 )]
        [String]$Domain
    )

    $Account = New-Object System.Security.Principal.NTAccount("$Domain", "$Identity")
    "    Cambiando propietario de " + $Object.FullName + " por " + $Account

    if ($Object.Attributes -like "*Directory*") {
        
        $Acl = Get-Acl $Object.FullName -Audit
    
        $Acl.SetOwner($Account)

        $Acl.SetAccessRuleProtection($false, $false) # Enable ($false) / Disable ($true) inheritance
    
        $Acl | Set-Acl $Object.FullName

        $Objects = Get-ChildItem $Object.FullName

        ForEach ( $Object in $Objects ) {
            Set-Owner -Object $Object -Identity $Identity -Domain $Domain
        }

    } else {
    
        $Acl = Get-Acl $Object.FullName -Audit
 
        $Acl.SetOwner($Account)

        $Acl.SetAccessRuleProtection($false, $false) # Enable ($false) / Disable ($true) inheritance
    
        $Acl | Set-Acl $Object.FullName
    }

}

<# Función para definir herencia de AuditRules en objetos y propagación en caso de contenedores #>
function Set-AuditInherit {

    Param(
        [parameter( Mandatory = $true, Position = 0 )]
        [System.IO.FileSystemInfo]$Object
    )

    "    Activando herencia de auditoria en " + $Object.FullName
    
    if ($Object.Attributes -like "*Directory*") {
        $DummyRule = New-Object System.Security.AccessControl.FileSystemAuditRule("Administrators", "Write, Read", "ContainerInherit, ObjectInherit", "None", "Success")
        
        $Acl = Get-Acl $Object.FullName -Audit
        $Acl.SetAuditRuleProtection($false, $false)
        $Acl | Set-Acl

        $Acl = Get-Acl $Object.FullName -Audit
        $Acl.AddAuditRule($DummyRule)
        $Acl.SetAuditRuleProtection($false, $false)
        $Acl | Set-Acl

        $Acl = Get-Acl $Object.FullName -Audit
        $Acl.RemoveAuditRule($DummyRule) | Out-Null
        $Acl | Set-Acl
        
        $o = Get-ChildItem $Object.FullName

        ForEach ($Ob in $o) {
            Set-AuditInherit -Object $Ob 
        }

    } else {
        $DummyRule = New-Object System.Security.AccessControl.FileSystemAuditRule("Administrators", "Write, Read", "None", "None", "Success")
        
        $Acl = Get-Acl $Object.FullName -Audit
        $Acl.SetAuditRuleProtection($false, $false)
        $Acl | Set-Acl

        $Acl = Get-Acl $Object.FullName -Audit
        $Acl.AddAuditRule($DummyRule)
        $Acl.SetAuditRuleProtection($false, $false)
        $Acl | Set-Acl

        $Acl = Get-Acl $Object.FullName -Audit
        $Acl.RemoveAuditRule($DummyRule) | Out-Null
        $Acl.SetAuditRuleProtection($false, $false)
        $Acl | Set-Acl
    }

    if ( -not ($Acl.AreAuditRulesProtected) ) {
        "        " + $Object.FullName + " esta propagando reglas de auditoria."
    } else {
        "        " + $Object.FullName + " NO esta propagando reglas de auditoria."
    }

}

<# Función para eliminar las AuditRules en objetos y llamar a Set-AuditInherit en caso de contenedores #>
function Remove-Audit {

    Param(
        [parameter( Mandatory = $true, Position = 0 )]
        [System.IO.FileSystemInfo]$Object,
        [parameter( Mandatory = $true, Position = 1 )]
        [System.Array]$AuditRules
    )

    "    Eliminando reglas de auditoria para "+$Object.FullName
    
    if ($Object.Attributes -like "*Directory*") {
        
        ForEach ($Rule in $AuditRules) {
            $Acl = Get-Acl $Object.FullName -Audit
            $Acl.RemoveAuditRule($Rule) | Out-Null
            $Acl.SetAuditRuleProtection($false, $false)
            $Acl | Set-Acl $Object.FullName
        }

        $Objects = Get-ChildItem $Object.FullName

        ForEach ( $Object in $Objects ) {

            Set-AuditInherit -Object $Object

        }

    } else { Set-AuditInherit -Object $Object }

}

<# Función para definir las AuditRules en objetos y llamar a Set-AuditInherit en caso de contenedores #>
function Set-Audit {

    Param(
        [parameter( Mandatory = $true, Position = 0 )]
        [System.IO.FileSystemInfo]$Object,
        [parameter( Mandatory = $true, Position = 1 )]
        [System.Array]$AuditRules
    )

    "    Aplicando reglas de auditoria para "+$Object.FullName
    
    if ($Object.Attributes -like "*Directory*") {
        
        ForEach ($Rule in $AuditRules) {
            $Acl = Get-Acl $Object.FullName -Audit
            $Acl.AddAuditRule($Rule)
            $Acl.SetAuditRuleProtection($false, $false)
            $Acl | Set-Acl $Object.FullName
        }

        $Objects = Get-ChildItem $Object.FullName

        ForEach ( $Object in $Objects ) {

            Set-AuditInherit -Object $Object

        }

    } else { Set-AuditInherit -Object $Object }

}

<# main_f #>
<# Enable audit #>
ForEach ($MyDoc in $MyDocs) {

    $Identity = $MyDoc.FullName.Split("\")[-2]
    $Acl = Get-Acl "$MyDoc" -Audit
    $x = $Acl.GetAuditRules($true, $true, [System.Security.Principal.NTAccount])
    $i = 0

    if ( $x.Count -ne $AuditRules.Count ) {
        "[E] $MyDoc NO tiene el Audit configurado."

        Set-Owner -Object $MyDoc -Identity $env:USERNAME -Domain $env:USERDOMAIN
        Set-Audit -Object $MyDoc -AuditRules $AuditRules
        Set-OwnerElevated -Object $MyDoc -Identity $Identity -Domain $Domain

    } else {
    
        $x | % {

            if (Compare-ACL -ACL1 $AuditRules[$i] -ACL2 $_) {
                "[E] $MyDoc NO tiene el Audit correctamente configurado."
                Set-Owner -Object $MyDoc -Identity $env:USERNAME -Domain $env:USERDOMAIN
                Remove-Audit -Object $MyDoc -AuditRules $AuditRules
                Set-Audit -Object $MyDoc -AuditRules $AuditRules
                Set-OwnerElevated -Object $MyDoc -Identity $Identity -Domain $Domain
                Break
            }
    
            $i++

            if ( $i -eq $x.Count ) { "[I] $MyDoc tiene el Audit correctamente configurado." }
        }
    }
}

<# Disable audit #>
$UsersFolders = Get-ChildItem "$Root" -Attributes Directory

ForEach ($UserFolder in $UsersFolders) {

    $User = $UserFolder.Name
    $UserFolderFN = $UserFolder.FullName
    $MyDoc = Get-Item "${UserFolderFN}\Documents"

    if ($User -notin $AuditedUsers) {

        $Acl = Get-Acl $MyDoc -Audit
        $x = $Acl.GetAuditRules($true, $true, [System.Security.Principal.NTAccount])
        $i = 0

        if ( $x.Count -eq $AuditRules.Count ) {
    
            $x | % {

                if ( -not (Compare-ACL -ACL1 $AuditRules[$i] -ACL2 $_) ) {
                    "[E] $MyDoc TIENE el Audit configurado cuando NO es un usuario auditado."
                    Set-Owner -Object $MyDoc -Identity $env:USERNAME -Domain $env:USERDOMAIN
                    Remove-Audit -Object $MyDoc -AuditRules $AuditRules
                    Set-OwnerElevated -Object $MyDoc -Identity $User -Domain $Domain
                    Break
                }
    
                $i++
            }
        }

    }

}
