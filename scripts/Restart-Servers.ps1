Add-pssnapin VMWare.VimAutomation.Core

$VCENTER    = "vcenter.corp.com"
$VMS        = "servicefrontend.corp.com","appserver.corp.com"
$VMSDB      = "servicedb.corp.com"
$SQL_PORT   = 1405
$TIMEOUT    = 600
$COUNTER    = 0

<#
    Function to connect to a vCenter server, it returns a boolean value:
    - $true if the function has completed succesfully.
    - false if the function hasn't completed succesfully.
#>
Function Connect()
{

    Write-Host "Connecting to... $VCENTER"
    
    Try
    {
        Connect-VIServer $VCENTER | Out-Null
        Return $true

    } Catch {
        Return $false

    }

}


<#
    Function to shutdown a array of virtual servers, it returns a boolean value:
    - $true if the function has completed succesfully.
    - false if the function hasn't completed succesfully.
#>
Function ShutdownVMs($VMS) {

    $COUNTER = 0

    ForEach ( $VM in $VMS) {
        Write-Host "[!] Shutdown-VMGuest $VM"
        
        if ( ( Get-VM $VM ).PowerState -eq "PoweredOff" ) {
            Write-Host "    The server $VM is already PoweredOff."
        } else {
            Shutdown-VMGuest $VM -Confirm:$false

            While ( !(( Get-VM $VM ).PowerState -eq "PoweredOff") -and $COUNTER -le $TIMEOUT) {
                Write-Host "    Server $VM isn't PoweredOff, waiting 30 sec."
                $COUNTER += 30
                Sleep 30

            }  
        }

    }
    
    if ( $COUNTER -gt $TIMEOUT)
    {
        
        Write-Host "    The server has not been stopped in time. Now has this situation:"

        ForEach ( $VM in $VMS) {
            Write-Host (Get-VM $VM | ft Name,PowerState | Out-String)
            Return $false

        }

    }

    Return $true

}

<#
    Function to start a array of virtual servers, it returns a boolean value:
    - $true if the function has completed succesfully.
    - false if the function hasn't completed succesfully.
#>
Function StartVMs($VMS) {

    $COUNTER = 0

    ForEach ( $VM in $VMS) {

        Write-Host "[!] Start-VMGuest $VM"
        Start-VM $VM -Confirm:$false | Out-Null

        While ( !(( Get-VM $VM ).PowerState -eq "PoweredOn") -and $COUNTER -le $TIMEOUT)
        {
            Write-Host "    Server $VM isn't PoweredOn, waiting 30 sec."
            $COUNTER += 30
            Sleep 30
        }

    }
    
    if ( $COUNTER -gt $TIMEOUT) {

        Write-Host "    The server has not been started in time. Now has this situation:"

        ForEach ( $VM in $VMS) {
            Write-Host (Get-VM $VM | ft Name,PowerState | Out-String)
            Return $false
        }

    }

    Return $true
}

<#
    Function to test the accessibility of a port, it returns a boolean value:
    - $true if the function has completed succesfully.
    - false if the function hasn't completed succesfully.
#>
Function Test-Port( $Server, $PORT ) {

    $tcpclient = new-Object system.Net.Sockets.TcpClient

    Try {
        $tcpclient.Connect( "$Server", $PORT )

    } catch {
        Return $false

    }

    $tcpclient.Close()

    Return $true
}


<#    Main    #>
if ( Connect( $VCENTER ) -eq $true ) {

    if ( ShutdownVMs( $VMS ) -eq $true ) {
        Write-Host "[!] Restarting database server: $VMSDB."
        Restart-VMGuest $VMSDB -Confirm:$false | Out-null

        $COUNTER = 0

        While ( ( Test-Port $VMSDB $SQL_PORT ) -and $COUNTER -le $TIMEOUT ) {
            Write-Host "    Database listener still active, waiting 30 sec."
            $COUNTER += 30
            Sleep 30

        }

        if ( $COUNTER -le $TIMEOUT ) {
            Write-Host "[!] Starting database server..."
            $COUNTER = 0

            While ( !( Test-Port $VMSDB $SQL_PORT ) -and $COUNTER -le $TIMEOUT ) {
                Write-Host "    Database listener still inactive, waiting 30 sec."
                $COUNTER += 30
                Sleep 30

            }

            if ( $COUNTER -le $TIMEOUT ) {
                StartVMs( $VMS )
                Write-Host "`n[!] Restart completed Succesfully"

            } else {
                Write-Host "`n[X] The db listener has not been started in time."

            }

        } else {
            Write-Host "`n[X] The db listener has not been stopped in time."

        }


    } else {
        Write-Host "`n[X] The servers couldn't be stopped succesfully."

    }

} else {
    Write-Host "`n[X] Couldn't connect to vCenter Server: $VCENTER"

}
