<#
    .SYNOPSIS
        The `WSManListener` DSC resource is used to create, modify, or remove
        WSMan listeners.

    .PARAMETER Transport
        The transport type of WS-Man Listener.

    .PARAMETER Ensure
        Specifies whether the WS-Man Listener should exist.

    .PARAMETER Port
        The port the WS-Man Listener should use. Defaults to 5985 for HTTP and 5986 for HTTPS listeners.

    .PARAMETER Address
        The Address that the WS-Man Listener will be bound to. The default is * (any address).

    .PARAMETER Issuer
        The Issuer of the certificate to use for the HTTPS WS-Man Listener if a thumbprint is
        not specified.

    .PARAMETER SubjectFormat
        The format used to match the certificate subject to use for an HTTPS WS-Man Listener
        if a thumbprint is not specified.

    .PARAMETER MatchAlternate
        Should the FQDN/Name be used to also match the certificate alternate subject for an HTTPS WS-Man
        Listener if a thumbprint is not specified.

    .PARAMETER BaseDN
        This is the BaseDN (path part of the full Distinguished Name) used to identify the certificate
        to use for the HTTPS WS-Man Listener if a thumbprint is not specified.

    .PARAMETER CertificateThumbprint
        The Thumbprint of the certificate to use for the HTTPS WS-Man Listener.

    .PARAMETER HostName
        The HostName of WS-Man Listener.

    .PARAMETER Enabled
        Returns true if the existing WS-Man Listener is enabled.

    .PARAMETER URLPrefix
        The URL Prefix of the existing WS-Man Listener.

    .PARAMETER Reasons
        Returns the reason a property is not in desired state.
#>

[DscResource()]
class WSManListener : ResourceBase
{
    [DscProperty(Key)]
    [ValidateSet('HTTP', 'HTTPS')]
    [System.String]
    $Transport

    [DscProperty(Mandatory = $true)]
    [Ensure]
    $Ensure

    [DscProperty()]
    [ValidateRange(0, 65535)]
    [Nullable[System.UInt16]]
    $Port

    [DscProperty()]
    [System.String]
    $Address = '*'

    [DscProperty()]
    [System.String]
    $Issuer

    [DscProperty()]
    [ValidateSet('Both', 'FQDNOnly', 'NameOnly')]
    [System.String]
    $SubjectFormat = 'Both'

    [DscProperty()]
    [Nullable[System.Boolean]]
    $MatchAlternate

    [DscProperty()]
    [System.String]
    $BaseDN

    [DscProperty()]
    [System.String]
    $CertificateThumbprint

    [DscProperty()]
    [System.String]
    $Hostname

    [DscProperty(NotConfigurable)]
    [System.Boolean]
    $Enabled

    [DscProperty(NotConfigurable)]
    [System.String]
    $URLPrefix

    [DscProperty(NotConfigurable)]
    [WSManReason[]]
    $Reasons

    WSManListener () : base ($PSScriptRoot)
    {
        # These properties will not be enforced.
        $this.ExcludeDscProperties = @(
            'Issuer'
            'SubjectFormat'
            'MatchAlternate'
            'BaseDN'

        )

        # Get the port if it's not provided
        if ($this.Port)
        {
            $this.Port = Get-DefaultPort -Transport $this.Transport -Port $this.Port
        }
    }

    [WSManListener] Get()
    {
        # Call the base method to return the properties.
        return ([ResourceBase] $this).Get()
    }

    # Base method Get() call this method to get the current state as a Hashtable.
    [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        $getParameters = @{
            Transport = $properties.Transport
        }

        $getCurrentStateResult = Get-Listener @getParameters

        $currentCertificate = ''

        if ($getCurrentStateResult.CertificateThumbprint)
        {
            $currentCertificate = Find-Certificate -CertificateThumbprint $getCurrentStateResult.CertificateThumbprint
        }

        $state = @{
            Transport             = $properties.Transport
            Port                  = [System.UInt16] $getCurrentStateResult.Port
            Address               = $getCurrentStateResult.Address
            Enabled               = $getCurrentStateResult.Enabled
            URLPrefix             = $getCurrentStateResult.URLPrefix
            Issuer                = $currentCertificate.Issuer
            SubjectFormat         = $properties.SubjectFormat
            MatchAlternate        = $null
            BaseDN                = $null
            CertificateThumbprint = $getCurrentStateResult.CertificateThumbprint
            Hostname              = $getCurrentStateResult.HostName
        }

        return $state
    }

    [void] Set()
    {
        # Call the base method to enforce the properties.
        ([ResourceBase] $this).Set()
    }

    <#
        Base method Set() call this method with the properties that should be
        enforced and that are not in desired state.
    #>
    [void] Modify([System.Collections.Hashtable] $properties)
    {
        # <#
        #     If the property 'EnablePollutionProtection' was present and not in desired state,
        #     then the property name must be change for the cmdlet Set-DnsServerCache. In the
        #     cmdlet Get-DnsServerCache the property name is 'EnablePollutionProtection', but
        #     in the cmdlet Set-DnsServerCache the parameter is 'PollutionProtection'.
        # #>
        # if ($properties.ContainsKey('EnablePollutionProtection'))
        # {
        #     $properties['PollutionProtection'] = $properties.EnablePollutionProtection

        #     $properties.Remove('EnablePollutionProtection')
        # }

        # Set-DnsServerCache @properties
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
        # # The properties MaximumFiles and MaximumRolloverFiles are mutually exclusive.
        # $assertBoundParameterParameters = @{
        #     BoundParameterList     = $properties
        #     MutuallyExclusiveList1 = @(
        #         'MaximumFiles'
        #     )
        #     MutuallyExclusiveList2 = @(
        #         'MaximumRolloverFiles'
        #     )
        # }

        # Assert-BoundParameter @assertBoundParameterParameters
    }
}
