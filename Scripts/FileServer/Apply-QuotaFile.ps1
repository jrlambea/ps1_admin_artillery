<# 
    .Synopsis
        Apply quota to directories based on a CSV file. Also can generate a CSV file with the Quota configuration with "dirquota"
    
    .Description
        Apply quota to directories based on a CSV file. Also can generate a CSV file with the Quota configuration with "dirquota"
    
    .Example
        Apply-QuotaFile.ps1 -GenerateFile -QuotaFile c:\temp\quotas.csv -Path F:\Users
    Generate a CSV file with all the configured quotas setted on F:\Users subfolders.
    
    .Example
        Apply-QuotaFile.ps1 -QuotaFile c:\temp\quotas.csv -Path F:\Users_New
    Apply all the quota configuration over the F:\Users_New subfolders.

    .Parameter GenerateFile
        Generate a CSV file with the quota configuration of the subfolders of the specified path.

    .Parameter QuotaFile
        Output or input file.
           
    .Parameter Path
        Directory to modify or get Quota configuration.
           
    .Parameter Force
        Do not ask for confirmation.
           
    .Example

    .Example

#>
Param(
    [parameter( Mandatory = $false )]
    [Switch]$GenerateFile,
    [parameter( Mandatory = $true )]
    [String]$QuotaFile,
    [parameter( Mandatory = $true )]
    [String]$Path,
    [parameter( Mandatory = $false )]
    [Switch]$Force
)

function Parse-Data ($data)
{

    ForEach ($line in $data)
    {

        If ( ($line -eq "") -Or ($line -eq $null) ) {
            $buff = "" | Select-Object "Quota Path", "Share Path", "Source Template", "Quota Status", "Limit"
        }

        Else
        {
            Switch ( $line.Split(":")[0] )
            {
                ("Quota Path") { $buff."Quota Path" = $line.Split(":",2)[1].Trim() }
                ("Share Path") { $buff."Share Path" = $line.Split(":")[1].Trim() }
                ("Source Template") { $buff."Source Template" = $line.Split(":")[1].Trim() }
                ("Quota Status") { $buff."Quota Status" = $line.Split(":")[1].Trim() }
                ("Limit") { $buff."Limit" = $line.Split(":")[1].Trim(); $buff }
            }
        }
    }
}

function Create-QuotaFile ([String]$OutputFile, [String]$Path)
{

    $data = &dirquota quota list /Path:${Path}...

    If ($data[3].Trim() -notlike "No quotas exist*")
    {
        $QuotaObject = Parse-Data $data
        $QuotaObject | Export-Csv $OutputFile -Delimiter ";" -NoTypeInformation
        Get-Item $OutputFile
    }

    Else
    {
        Write-Host $data[3] -ForegroundColor Yellow
    }
}

If ( -Not ( Test-Path -PathType leaf $QuotaFile ) -And -Not ($GenerateFile))
{
    Write-Error "The file $QuotaFile does not exist."
    Exit 1
}

If ($Path[-1] -ne "\") {$Path = $Path + "\" }

If ( -not ( Test-Path -PathType container $Path ) )
{
    Write-Error "The directory $Path does not exist."
    Exit 1    
}

If ($GenerateFile)
{
    Create-QuotaFile $QuotaFile $Path
}

Else
{

    $QuotaObject = Import-Csv $QuotaFile -Delimiter ";"
    $QuotaCount = $QuotaObject.Count

    If ( ($QuotaCount -eq $null) -And ($QuotaObject."Quota Path" -eq "") )
    {
        Write-Error "Maybe $QuotaFile is not a quota file? :("
        Exit 1
    }

    If ( -not ($Force) )
    {
        $Answer = Read-Host ("Hey! Are you sure you want to apply ${QuotaCount} configurations to ${Path}?[Y/n]")
        If ($Answer -eq "") { $Answer = "Y" }
    }

    If ( ($Force) -Or ($Answer -eq "Y"))
    {

        Write-Host "Backing up existing quotas into Quotas.bkp..." -ForegroundColor Yellow

        #Create-QuotaFile "Quotas.bkp" $Path

        Write-Host "Applying..." -ForegroundColor Yellow

        ForEach ($Quota in $QuotaObject)
        {
            $dir = $Quota."Quota Path".Split("\")[-1]
            $template = $Quota."Source Template".Split("(")[0].Trim()

            Write-Host "Applying quota ${template} to ${Path}${dir}... " -NoNewLine
            $QStatus = $Quota."Quota Status"
            $data = &dirquota quota add /Path:"${Path}${dir}" /SourceTemplate:"${template}" /Status:$QStatus /Overwrite
            
            If ($data[1] -Like "Quota successfully created for*") {
                Write-Host "Done" -ForegroundColor Green
            }

            Else
            {
                Write-Host "Fail: $data" -ForegroundColor Red
            }
            # "dirquota quota add /Path:""" + ${Path} + ${dir} + """ /SourceTemplate:""" + ${template} + """ /Status:" + $QStatus + " /Overwrite"
        }
    }

    Else
    {
        "Process cancelled."
        Exit 1
    }

}
