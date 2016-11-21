<#
.SYNOPSIS
Script with GUI for change a user domain password.
.DESCRIPTION
Script with GUI for change a user domain password. The user domain does not have to be the current user domain.
.EXAMPLE
Change-Password -Domain contoso.com -Identifier DOMUSER -NewPassword P@ssword
.EXAMPLE
Give another example of how to use it
.PARAMETER computername
The computer name to query. Just one.
.PARAMETER logname
The name of a file to write failed computer names to. Defaults to errors.txt.
.INPUTS
None
.OUTPUTS
Log file stored in file defined in LogFile variable.
.LINK
.NOTES
  Version:        1.0
  Author:         JR. Lambea
  Creation Date:  15/11/2016
  Purpose/Change: Initial script development
#>

#OPTIONAL: Set Error Action to Silently Continue
#$ErrorActionPreference = "SilentlyContinue"

begin
{
    # Form Design
    $Domains = "contoso", "contoso"
    Add-Type -AssemblyName System.Windows.Forms
    $Form = New-Object system.Windows.Forms.Form
    $Form.MaximizeBox = $False
    $Form.SizeGripStyle = "Hide"
    $Form.ShowIcon = $False
    $Form.Text = "Change domain password"
    $Form.Width = 250
    $Form.Height = 180
    $Form.StartPosition = "CenterScreen"

    $Label1 = New-Object System.Windows.Forms.Label
    $Label1.Text = "Domain: "
    $Label1.Top = 15
    $Label1.Left = 10
    $Label1.Autosize = $True

    $Combo = New-Object System.Windows.Forms.ComboBox
    ForEach ($Domain in $Domains) { $Combo.Items.Add($Domain) }
    $Combo.Top = 10
    $Combo.Left = 100
    $Combo.Text = $Domain
        
    $Label2 = New-Object System.Windows.Forms.Label
    $Label2.Text = "User: "
    $Label2.Autosize = $True
    $Label2.Top = 40
    $Label2.Left = 10

    $TxtUser = New-Object System.Windows.Forms.TextBox
    $TxtUser.Text = [environment]::UserName
    $TxtUser.Top = 35
    $TxtUser.Left = 100

    $Label3 = New-Object System.Windows.Forms.Label
    $Label3.Text = "Last Password: "
    $Label3.Autosize = $True
    $Label3.Top = 65
    $Label3.Left = 10

    $TxtLastPass = New-Object System.Windows.Forms.TextBox
    $TxtLastPass.Top = 60
    $TxtLastPass.Left = 100
    $TxtLastPass.PasswordChar = "*"

    $Label4 = New-Object System.Windows.Forms.Label
    $Label4.Text = "New Password: "
    $Label4.Autosize = $True
    $Label4.Top = 90
    $Label4.Left = 10
    
    $TxtNextPass = New-Object System.Windows.Forms.TextBox
    $TxtNextPass.Top = 85
    $TxtNextPass.Left = 100
    $TxtNextPass.PasswordChar = "*"

    $BtnOK = New-Object System.Windows.Forms.Button
    $BtnOK.Text = "Change"
    $BtnOK.Top = 115
    $BtnOK.Left = 10

    $Form.Controls.Add($Label1)
    $Form.Controls.Add($Label2)
    $Form.Controls.Add($Label3)
    $Form.Controls.Add($Label4)
    $Form.Controls.Add($Combo)
    $Form.Controls.Add($TxtUser)
    $Form.Controls.Add($TxtLastPass)
    $Form.Controls.Add($TxtNextPass)
    $Form.Controls.Add($TxtNextPass)
    $Form.Controls.Add($BtnOK)

    $BtnOK.add_click({
        If ( $TxtLastPass.Text -Eq "" -Or $TxtNextPass.Text -Eq "" )
        {
            [System.Windows.Forms.Messagebox]::Show("The new and last password does not match.")
        }

        Else
        {
            Write-Host "Set-ADAccountPassword -Identity  $($TxtUser.Text) -NewPassword $($TxtNextPass.Text) -OldPassword $($TxtLastPass.Text) -Server $($Combo.Text)"
            Change-Password ($TxtLastPass.Text | ConvertTo-SecureString -AsPlainText -Force) ($TxtNextPass.Text | ConvertTo-SecureString -AsPlainText -Force) $TxtUser.Text $Combo.Text
        }
    })
}

process {

    function Change-Password([SecureString]$OldPassword, [SecureString]$NewPassword, [String]$Username, [String]$Server)
    {
        try {
            Set-ADAccountPassword -Identity $Username -NewPassword $NewPassword -OldPassword $OldPassword -Server $Server
            [System.Windows.Forms.Messagebox]::Show("The password has been changed successfully", "Information", "OK", "Information")        
        }
        
        catch [System.Exception]
        {
            [System.Windows.Forms.Messagebox]::Show($_.Exception.Message, "Alert", "OK", "Error")
        }
    }

    $Form.ShowDialog() 
}

