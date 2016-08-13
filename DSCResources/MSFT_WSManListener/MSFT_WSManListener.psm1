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

# Standard Transport Ports
$Default_HTTP_Port  = 5985
$Default_HTTPS_Port = 5986

<#
    .SYNOPSIS
    Returns the current WS-Man Listener details.
    .PARAMETER Transport
    The transport type of WS-Man Listener.
    .PARAMETER Ensure
    Specifies whether the WS-Man Listener should exist.
#>
function Get-TargetResource
{
    [CmdletBinding()]
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
    $listener = Get-Listener -Transport $Transport
    if ($listener)
    {
        # An existing listener matching the transport was found
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.ListenerExistsMessage) `
                -f $Transport
            ) -join '' )
        $returnValue += @{
            Ensure = 'Present'
            Port = $listener.Port
            Address = $listener.Address
            HostName = $listener.HostName
            Enabled = $listener.Enabled
            URLPrefix = $listener.URLPrefix
            CertificateThumbprint = $listener.CertificateThumbprint
        }
    }
    else
    {
        # An existing listener matching the transport was not found
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.ListenerDoesNotExistMessage) `
                -f $Transport
            ) -join '' )
        $returnValue += @{ Ensure = 'Absent' }
    } # if

    $returnValue
} # Get-TargetResource

<#
    .SYNOPSIS
    Sets the state of a WS-Man Listener.
    .PARAMETER Transport
    The transport type of WS-Man Listener.
    .PARAMETER Ensure
    Specifies whether the WS-Man Listener should exist.
    .PARAMETER Port
    The port the WS-Man Listener should use. Defaults to 5985 for HTTP and 5986 for HTTPS listeners.
    .PARAMETER Address
    The Address that the WS-Man Listener will be bound to. The default is * (any address).
    .PARAMETER Issuer
    The Issuer of the certificate to use for the HTTPS WS-Man Listener.
    .PARAMETER SubjectFormat
    The format used to match the certificate subject to use for an HTTPS WS-Man Listener.
    .PARAMETER MatchAlternate
    Should the FQDN/Name be used to also match the certificate alternate subject for an HTTPS WS-Man
    Listener.
#>
function Set-TargetResource
{
    [CmdletBinding()]
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
    $listener = Get-Listener -Transport $Transport

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
        if ($listener)
        {
            # The Listener exists already - delete it
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.ListenerExistsRemoveMessage) `
                    -f $Transport,$Port
                ) -join '' )
            Remove-WSManInstance `
                -ResourceURI winrm/config/Listener `
                -SelectorSet @{ Transport=$listener.Transport;Address=$listener.Address }
        }
        else
        {
            # Ths listener doesn't exist - do nothing
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.ListenerOnPortDoesNotExistMessage) `
                    -f $Transport,$Port
                ) -join '' )
        }
        # Create the listener
        if ($Transport -eq 'HTTPS')
        {
            [String] $Thumbprint = ''
            # First try and find a certificate that is used to the FQDN of the machine
            if ($SubjectFormat -in 'Both','FQDNOnly')
            {
                # Lookup the certificate using the FQDN of the machine
                [String] $HostName = [System.Net.Dns]::GetHostByName($ENV:computerName).Hostname
                if ($MatchAlternate) {
                    # Try and lookup the certificate using the subject and the alternate name
                    $Thumbprint = (Get-ChildItem -Path Cert:\localmachine\my | Where-Object {
                            ($_.Extensions.EnhancedKeyUsages.FriendlyName `
                                -contains 'Server Authentication') -and
                            ($_.Issuer -eq $Issuer) -and
                            ($HostName -in $_.DNSNameList.Unicode) -and
                            ($_.Subject -eq "CN=$HostName") } | Select-Object -First 1
                        ).Thumbprint
                }
                else
                {
                    # Try and lookup the certificate using the subject name
                    $Thumbprint = (Get-ChildItem -Path Cert:\localmachine\my | Where-Object {
                            ($_.Extensions.EnhancedKeyUsages.FriendlyName `
                                -contains 'Server Authentication') -and
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
                    # Try and lookup the certificate using the subject and the alternate name
                    $Thumbprint = (Get-ChildItem -Path Cert:\localmachine\my | Where-Object {
                            ($_.Extensions.EnhancedKeyUsages.FriendlyName `
                                -contains 'Server Authentication') -and
                            ($_.Issuer -eq $Issuer) -and
                            ($HostName -in $_.DNSNameList.Unicode) -and
                            ($_.Subject -eq "CN=$HostName") } | Select-Object -First 1
                        ).Thumbprint
                }
                else
                {
                    # Try and lookup the certificate using the subject name
                    $Thumbprint = (Get-ChildItem -Path Cert:\localmachine\my | Where-Object {
                            ($_.Extensions.EnhancedKeyUsages.FriendlyName `
                                -contains 'Server Authentication') -and
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
                # A certificate could not be found to use for the HTTPS listener
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.ListenerCreateFailNoCertError) `
                        -f $Transport,$Port
                    ) -join '' )
            } # if
        }
        else
        {
            # Create a plain HTTPS listener
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
        if ($listener)
        {
            # The listener does exist - so delete it
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.ListenerExistsRemoveMessage) `
                    -f $Transport,$Port
                ) -join '' )
            Remove-WSManInstance `
                -ResourceURI winrm/config/Listener `
                -SelectorSet @{ Transport=$listener.Transport;Address=$listener.Address }
        }
    } # if
} # Set-TargetResource

<#
    .SYNOPSIS
    Tests the state of a WS-Man Listener.
    .PARAMETER Transport
    The transport type of WS-Man Listener.
    .PARAMETER Ensure
    Specifies whether the WS-Man Listener should exist.
    .PARAMETER Port
    The port the WS-Man Listener should use. Defaults to 5985 for HTTP and 5986 for HTTPS listeners.
    .PARAMETER Address
    The Address that the WS-Man Listener will be bound to. The default is * (any address).
    .PARAMETER Issuer
    The Issuer of the certificate to use for the HTTPS WS-Man Listener.
    .PARAMETER SubjectFormat
    The format used to match the certificate subject to use for an HTTPS WS-Man Listener.
    .PARAMETER MatchAlternate
    Should the FQDN/Name be used to also match the certificate alternate subject for an HTTPS WS-Man
    Listener.
#>
function Test-TargetResource
{
    [CmdletBinding()]
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
    $listener = Get-Listener -Transport $Transport

    # Get the default port for the transport if none was provided
    $Port = Get-DefaultPort -Transport $Transport -Port $Port

    if ($Ensure -eq 'Present')
    {
        # The listener should exist
        if ($listener)
        {
            # The Listener exists already
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.ListenerExistsMessage) `
                    -f $Transport
                ) -join '' )
            # Check it is setup as per parameters
            if ($listener.Port -ne $Port)
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.ListenerOnWrongPortMessage) `
                        -f $Transport,$listener.Port,$Port
                    ) -join '' )
                $desiredConfigurationMatch = $false
            }
            if ($listener.Address -ne $Address)
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.ListenerOnWrongAddressMessage) `
                        -f $Transport,$listener.Address,$Address
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
        if ($listener)
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

# Helper functions
<#
    .SYNOPSIS
    Looks up a WS-Man listener on the machine and returns the details.
    .PARAMETER Transport
    The transport type of WS-Man Listener.
#>
function Get-Listener
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('HTTP','HTTPS')]
        [String]
        $Transport
    )

    $listeners = @(Get-WSManInstance `
        -ResourceURI winrm/config/Listener `
        -Enumerate)
    if ($listeners)
    {
        return $listeners.Where( { ($_.Transport -eq $Transport) `
            -and ($_.Source -ne 'Compatibility') } )
    }
} # Get-Listener

<#
    .SYNOPSIS
    Returns the port to use for the listener based on the transport and port.
    .PARAMETER Transport
    The transport type of WS-Man Listener.
    .PARAMETER Port
    The port the WS-Man Listener should use. Defaults to 5985 for HTTP and 5986 for HTTPS listeners.
#>
function Get-DefaultPort
{
    [CmdletBinding()]
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
            $Port = $Default_HTTP_Port
        }
        else
        {
            $Port = $Default_HTTPS_Port
        }
    }
    return $Port
}

Export-ModuleMember -Function *-TargetResource
