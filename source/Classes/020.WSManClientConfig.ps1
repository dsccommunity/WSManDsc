<#
    .SYNOPSIS
        The `WSManClientConfig` DSC resource is used to configure WS-Man client specific settings.

    .DESCRIPTION
        This resource is used configure WS-Man Client settings.

    .PARAMETER NetworkDelayms
        Specifies the extra time in milliseconds that the client computer waits to accommodate for network delay time.

    .PARAMETER URLPrefix
        Specifies a URL prefix on which to accept HTTP or HTTPS requests. The default URL prefix is wsman.

    .PARAMETER AllowUnencrypted
        Allows the client computer to request unencrypted traffic.

    .PARAMETER TrustedHosts
        Specifies the list of remote computers that are trusted.

    .PARAMETER AuthBasic
        Allows the WinRM client to use Basic authentication.

    .PARAMETER AuthDigest
        Allows the WinRM client to use Digest authentication.

    .PARAMETER AuthCertificate
        Allows the WinRM client to use client certificate-based authentication.

    .PARAMETER AuthKerberos
        Allows the WinRM client to use Kerberos authentication.

    .PARAMETER AuthNegotiate
        Allows the WinRM client to use Negotiate authentication.

    .PARAMETER AuthCredSSP
        Allows the WinRM client to use Credential Security Support Provider (CredSSP) authentication.
#>

[DscResource()]
class WSManClientConfig : WSManConfigBase
{
    [DscProperty()]
    [Nullable[System.UInt32]]
    $NetworkDelayms

    [DscProperty()]
    [System.String]
    $URLPrefix

    [DscProperty()]
    [Nullable[System.Boolean]]
    $AllowUnencrypted

    [DscProperty()]
    [System.String[]]
    $TrustedHosts

    [DscProperty()]
    [Nullable[System.Boolean]]
    $AuthBasic

    [DscProperty()]
    [Nullable[System.Boolean]]
    $AuthDigest

    [DscProperty()]
    [Nullable[System.Boolean]]
    $AuthCertificate

    [DscProperty()]
    [Nullable[System.Boolean]]
    $AuthKerberos

    [DscProperty()]
    [Nullable[System.Boolean]]
    $AuthNegotiate

    [DscProperty()]
    [Nullable[System.Boolean]]
    $AuthCredSSP

    WSManClientConfig () : base ()
    {
        $this.ResourceURI = 'localhost\Client'
        $this.HasAuthContainer = $true
    }

    [WSManClientConfig] Get()
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
                'NetworkDelayms'
                'URLPrefix'
                'AllowUnencrypted'
                'TrustedHosts'
                'AuthBasic'
                'AuthDigest'
                'AuthCertificate'
                'AuthKerberos'
                'AuthNegotiate'
                'AuthCredSSP'
            )
            RequiredBehavior   = 'Any'
        }

        Assert-BoundParameter @assertBoundParameterParameters
    }
}
