Param(
    [parameter(Mandatory=$true)]
    [alias("f")]
    [string]
    $Filter)

Import-Module ActiveDirectory

function get-Miembros( $grupo, $linea )
{
    Get-ADGroup -Filter "name -like '$grupo'" | %{
        $gname = $_.name
        if ( $linea -eq "" ) { $linea = $gname+"," }
        
        Get-ADGroupMember $gname | %{
            $iname = $_
            $inombre = $_.name

            if ( $iname.ObjectClass -eq "group" )
            {
                get-Miembros $iname.name "$linea$inombre,"

            } else {
                $linea+$inombre
            }

        }

        $linea=""
    }
}

get-Miembros $Filter ""
