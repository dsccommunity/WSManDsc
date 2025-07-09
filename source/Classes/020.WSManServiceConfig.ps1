<#
    .SYNOPSIS
        The `WSManServiceConfig` DSC resource is used to configure WS-Man service specific settings.

    .DESCRIPTION
        This resource is used configure WS-Man Service settings.

    .PARAMETER RootSDDL
        Specifies the security descriptor that controls remote access to the listener.

    .PARAMETER MaxConnections
        Specifies the maximum number of active requests that the service can process simultaneously.

    .PARAMETER MaxConcurrentOperationsPerUser
        Specifies the maximum number of concurrent operations that any user can remotely open on the
        same system.

    .PARAMETER EnumerationTimeoutMS
        Specifies the idle time-out in milliseconds between Pull messages.

    .PARAMETER MaxPacketRetrievalTimeSeconds
        Specifies the maximum length of time, in seconds, the WinRM service takes to retrieve a packet.

    .PARAMETER AllowUnencrypted
        Allows the client computer to request unencrypted traffic.

    .PARAMETER AuthBasic
        Allows the WinRM service to use Basic authentication.

    .PARAMETER AuthKerberos
        Allows the WinRM service to use Kerberos authentication.

    .PARAMETER AuthNegotiate
        Allows the WinRM service to use Negotiate authentication.

    .PARAMETER AuthCertificate
        Allows the WinRM service to use client certificate-based authentication.

    .PARAMETER AuthCredSSP
        Allows the WinRM service to use Credential Security Support Provider (CredSSP) authentication.

    .PARAMETER AuthCbtHardeningLevel
        Allows the client computer to request unencrypted traffic.

    .PARAMETER EnableCompatibilityHttpListener
        Specifies whether the compatibility HTTP listener is enabled.

    .PARAMETER EnableCompatibilityHttpsListener
        Specifies whether the compatibility HTTPS listener is enabled.

    .NOTES
        Used Functions:
            Name                  | Module
            --------------------- |-------------------
            Assert-BoundParameter | DscResource.Common
#>

[DscResource()]
class WSManServiceConfig : WSManConfigBase
{
    [DscProperty()]
    [System.String]
    $RootSDDL

    [DscProperty()]
    [Nullable[System.Uint32]]
    $MaxConnections

    [DscProperty()]
    [Nullable[System.Uint32]]
    $MaxConcurrentOperationsPerUser

    [DscProperty()]
    [Nullable[System.Uint32]]
    $EnumerationTimeoutMS

    [DscProperty()]
    [Nullable[System.Uint32]]
    $MaxPacketRetrievalTimeSeconds

    [DscProperty()]
    [Nullable[System.Boolean]]
    $AllowUnencrypted

    [DscProperty()]
    [Nullable[System.Boolean]]
    $AuthBasic

    [DscProperty()]
    [Nullable[System.Boolean]]
    $AuthKerberos

    [DscProperty()]
    [Nullable[System.Boolean]]
    $AuthNegotiate

    [DscProperty()]
    [Nullable[System.Boolean]]
    $AuthCertificate

    [DscProperty()]
    [Nullable[System.Boolean]]
    $AuthCredSSP

    [DscProperty()]
    [WSManAuthCbtHardeningLevel]
    $AuthCbtHardeningLevel

    [DscProperty()]
    [Nullable[System.Boolean]]
    $EnableCompatibilityHttpListener

    [DscProperty()]
    [Nullable[System.Boolean]]
    $EnableCompatibilityHttpsListener

    WSManServiceConfig () : base ()
    {
        $this.ResourceURI = 'localhost\Service'

        $this.ResourceMap = = @{
            AuthBasic             = 'Auth\Basic'
            AuthKerberos          = 'Auth\Kerberos'
            AuthNegotiate         = 'Auth\Negotiate'
            AuthCertificate       = 'Auth\Certificate'
            AuthCredSSP           = 'Auth\CredSSP'
            AuthCbtHardeningLevel = 'Auth\CbtHardeningLevel'
        }

        <#

        # Configure Service Authentication
            Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $false # Configured by default
            Set-Item -Path WSMan:\localhost\Service\Auth\Digest -Value $true # Configured by default
            Set-Item -Path WSMan:\localhost\Service\Auth\Kerberos -Value $true # Configured by default
            Set-Item -Path WSMan:\localhost\Service\Auth\Negotiate -Value $true # Configured by default
            Set-Item -Path WSMan:\localhost\Service\Auth\Certificate -Value $true # Configured by default
            Set-Item -Path WSMan:\localhost\Service\Auth\CredSSP -Value $false # Configured by default

        # Configure Client
            Set-Item -Path WSMan:\localhost\Client\Auth\Basic -Value $false # Configured by default
            Set-Item -Path WSMan:\localhost\Client\Auth\Digest -Value $true # Configured by default
            Set-Item -Path WSMan:\localhost\Client\Auth\Kerberos -Value $true # Configured by default
            Set-Item -Path WSMan:\localhost\Client\Auth\Negotiate -Value $true # Configured by default
            Set-Item -Path WSMan:\localhost\Client\Auth\Certificate -Value $true # Configured by default
            Set-Item -Path WSMan:\localhost\Client\Auth\CredSSP -Value $false # Configured by default
        #>
    }

    [WSManServiceConfig] Get()
    {
        # Call the base method to return the properties.
        return ([ResourceBase] $this).Get()
    }

    [void] Set()
    {
        # Call the base method to enforce the properties.
        ([ResourceBase] $this).Set()
    }

    [System.Boolean] Test()
    {
        # Call the base method to test all of the properties that should be enforced.
        return ([ResourceBase] $this).Test()
    }

    <#
        Base method Assert() call this method with the properties that was assigned
        a value.
    #>
    hidden [void] AssertProperties([System.Collections.Hashtable] $properties)
    {
        $assertBoundParameterParameters = @{
            BoundParameterList = $properties
            RequiredParameter  = @(
                'RootSDDL'
                'MaxConnections'
                'EnumerationTimeoutMS'
                'MaxPacketRetrievalTimeSeconds'
                'AllowUnencrypted'
                'AuthBasic'
                'AuthKerberos'
                'AuthNegotiate'
                'AuthCertificate'
                'AuthCredSSP'
                'AuthCbtHardeningLevel'
                'EnableCompatibilityHttpListener'
                'EnableCompatibilityHttpsListener'
            )
            RequiredBehavior   = 'Any'
        }

        Assert-BoundParameter @assertBoundParameterParameters

        # Validate SDDL?


    }
}
