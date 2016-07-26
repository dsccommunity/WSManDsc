#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData `
        -BindingVariable LocalizedData `
        -Filename MSFT_WSManListener.psd1 `
        -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
}
else
{
    #fallback to en-US
    Import-LocalizedData `
        -BindingVariable LocalizedData `
        -Filename MSFT_WSManListener.psd1 `
        -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion


function Get-TargetResource
{
    [OutputType([Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('HTTP','HTTPS')]
        [String]
        $Transport,

        [parameter(Mandatory = $true)]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure
    )

    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        $($LocalizedData.GettingListenerMessage)
        ) -join '' )

    $returnValue = @{
        Transport = $Transport
    }

    # Lookup the existing Listener
    $Listener = Get-Listener -Transport $Transport
    if ($Listener)
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.ListenerExistsMessage) `
                -f $Transport
            ) -join '' )
        $returnValue += @{
            Ensure = 'Present'
            Port = $Listener.Port
            Address = $Listener.Address
            HostName = $Listener.HostName
            Enabled = $Listener.Enabled
            URLPrefix = $Listener.URLPrefix
            CertificateThumbprint = $Listener.CertificateThumbprint
            }
    }
    else
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.ListenerDoesNotExistMessage) `
                -f $Transport
            ) -join '' )
        $returnValue += @{ Ensure = 'Absent' }
    } # if

    $returnValue
} # Get-TargetResource

function Set-TargetResource
{
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('HTTP','HTTPS')]
        [String]
        $Transport,

        [parameter(Mandatory = $true)]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure,

        [UInt16]
        $Port,

        [String]
        $Address = '*',

        [String]
        $Issuer,

        [ValidateSet('Both','FQDNOnly','NameOnly')]
        [String]
        $SubjectFormat = 'Both',

        [Boolean]
        $MatchAlternate
    )

    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        $($LocalizedData.SettingListenerMessage)
        ) -join '' )

    # Lookup the existing Listener
    $Listener = Get-Listener -Transport $Transport

    # Get the default port for the transport if none was provided
    $Port = Get-DefaultPort -Transport $Transport -Port $Port

    if ($Ensure -eq 'Present')
    {
        # The listener should exist
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.EnsureListenerExistsMessage) `
                -f $Transport,$Port
            ) -join '' )
        if ($Listener)
        {
            # The Listener exists already - delete it
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.ListenerExistsRemoveMessage) `
                    -f $Transport,$Port
                ) -join '' )
            Remove-WSManInstance `
                -ResourceURI winrm/config/Listener `
                -SelectorSet @{ Transport=$Listener.Transport;Address=$Listener.Address }
        }
        else
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.ListenerOnPortDoesNotExistMessage) `
                    -f $Transport,$Port
                ) -join '' )
            # Ths listener doesn't exist - do nothing
        }
        # Create the listener
        if ($Transport -eq 'HTTPS')
        {
            [String] $Thumbprint = ''
            # First try and find a certificate that is used to the FQDN of the machine
            if ($SubjectFormat -in 'Both','FQDNOnly')
            {
                [String] $HostName = [System.Net.Dns]::GetHostByName($ENV:computerName).Hostname
                if ($MatchAlternate) {
                    $Thumbprint = (Get-ChildItem -Path Cert:\localmachine\my | Where-Object {
                            ($_.Extensions.EnhancedKeyUsages.FriendlyName -contains 'Server Authentication') -and
                            ($_.Issuer -eq $Issuer) -and
                            ($HostName -in $_.DNSNameList.Unicode) -and
                            ($_.Subject -eq "CN=$HostName") } | Select-Object -First 1
                        ).Thumbprint
                }
                else
                {
                    $Thumbprint = (Get-ChildItem -Path Cert:\localmachine\my | Where-Object {
                            ($_.Extensions.EnhancedKeyUsages.FriendlyName -contains 'Server Authentication') -and
                            ($_.Issuer -eq $Issuer) -and
                            ($_.Subject -eq "CN=$HostName") } | Select-Object -First 1
                        ).Thumbprint
                } # if
            }
            if (($SubjectFormat -in 'Both','NameOnly') -and -not $Thumbprint)
            {
                # If could not find an FQDN cert, try for one issued to the computer name
                [String] $HostName = $ENV:ComputerName
                if ($MatchAlternate)
                {
                    $Thumbprint = (Get-ChildItem -Path Cert:\localmachine\my | Where-Object {
                            ($_.Extensions.EnhancedKeyUsages.FriendlyName -contains 'Server Authentication') -and
                            ($_.Issuer -eq $Issuer) -and
                            ($HostName -in $_.DNSNameList.Unicode) -and
                            ($_.Subject -eq "CN=$HostName") } | Select-Object -First 1
                        ).Thumbprint
                }
                else
                {
                    $Thumbprint = (Get-ChildItem -Path Cert:\localmachine\my | Where-Object {
                            ($_.Extensions.EnhancedKeyUsages.FriendlyName -contains 'Server Authentication') -and
                            ($_.Issuer -eq $Issuer) -and
                            ($_.Subject -eq "CN=$HostName") } | Select-Object -First 1
                        ).Thumbprint
                } # if
            } # if
            if ($Thumbprint)
            {
                # A certificate was found, so use it to enable the HTTPS WinRM listener
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.CreatingListenerMessage) `
                        -f $Transport,$Port
                    ) -join '' )
                New-WSManInstance `
                    -ResourceURI winrm/config/Listener `
                    -SelectorSet @{Address=$Address;Transport=$Transport} `
                    -ValueSet @{Hostname=$HostName;CertificateThumbprint=$Thumbprint;Port=$Port} `
                    -ErrorAction Stop
            }
            else
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.ListenerCreateFailNoCertError) `
                        -f $Transport,$Port
                    ) -join '' )
            } # if
        }
        else
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.CreatingListenerMessage) `
                    -f $Transport,$Port
                ) -join '' )
            New-WSManInstance `
                -ResourceURI winrm/config/Listener `
                -SelectorSet @{Address=$Address;Transport=$Transport} `
                -ValueSet @{Port=$Port} `
                -ErrorAction Stop
        }
    }
    else
    {
        # The listener should not exist
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.EnsureListenerDoesNotExistMessage) `
                -f $Transport,$Port
            ) -join '' )
        if ($Listener)
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.ListenerExistsRemoveMessage) `
                    -f $Transport,$Port
                ) -join '' )
            Remove-WSManInstance `
                -ResourceURI winrm/config/Listener `
                -SelectorSet @{ Transport=$Listener.Transport;Address=$Listener.Address }
        }
    } # if
} # Set-TargetResource

function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('HTTP','HTTPS')]
        [String]
        $Transport,

        [parameter(Mandatory = $true)]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure,

        [UInt16]
        $Port,

        [String]
        $Address = '*',

        [String]
        $Issuer,

        [ValidateSet('Both','FQDNOnly','NameOnly')]
        [String]
        $SubjectFormat = 'Both',

        [Boolean]
        $MatchAlternate
    )

    # Flag to signal whether settings are correct
    [Boolean] $desiredConfigurationMatch = $true

    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        $($LocalizedData.TestingListenerMessage)
        ) -join '' )

    # Lookup the existing Listener
    $Listener = Get-Listener -Transport $Transport

    # Get the default port for the transport if none was provided
    $Port = Get-DefaultPort -Transport $Transport -Port $Port

    if ($Ensure -eq 'Present')
    {
        # The listener should exist
        if ($Listener)
        {
            # The Listener exists already
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.ListenerExistsMessage) `
                    -f $Transport
                ) -join '' )
            # Check it is setup as per parameters
            if ($Listener.Port -ne $Port)
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.ListenerOnWrongPortMessage) `
                        -f $Transport,$Listener.Port,$Port
                    ) -join '' )
                $desiredConfigurationMatch = $false
            }
            if ($Listener.Address -ne $Address)
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.ListenerOnWrongAddressMessage) `
                        -f $Transport,$Listener.Address,$Address
                    ) -join '' )
                $desiredConfigurationMatch = $false
            }
        }
        else
        {
            # Ths listener doesn't exist but should
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                 $($LocalizedData.ListenerDoesNotExistButShouldMessage) `
                    -f $Transport
                ) -join '' )
            $desiredConfigurationMatch = $false
        }
    }
    else
    {
        # The listener should not exist
        if ($Listener)
        {
            # The listener exists but should not
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                 $($LocalizedData.ListenerExistsButShouldNotMessage) `
                    -f $Transport
                ) -join '' )
            $desiredConfigurationMatch = $false
        }
        else
        {
            # The listener does not exist and should not
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.ListenerDoesNotExistAndShouldNotMessage) `
                    -f $Transport
                ) -join '' )
        }
    } # if
    return $desiredConfigurationMatch
} # Test-TargetResource

function Get-Listener
{
    [OutputType([Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('HTTP','HTTPS')]
        [String]
        $Transport
    )

    $Listeners = @(Get-WSManInstance `
        -ResourceURI winrm/config/Listener `
        -Enumerate)
    if ($Listeners)
    {

        return $Listeners.Where( { ($_.Transport -eq $Transport) `
            -and ($_.Source -ne 'Compatibility') } )
    }
} # Get-Listener

function Get-DefaultPort
{
    [OutputType([UInt16])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('HTTP','HTTPS')]
        [String]
        $Transport,

        [UInt16]
        $Port
    )

    if (-not $Port)
    {
        # Set the default port because none was provided
        if ($Transport -eq 'HTTP')
        {
            $Port = 5985
        }
        else
        {
            $Port = 5986
        }
    }
    return $Port
}

Export-ModuleMember -Function *-TargetResource
