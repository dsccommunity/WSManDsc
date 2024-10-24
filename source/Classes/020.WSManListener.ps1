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
    [WSManTransport]
    $Transport

    [DscProperty(Mandatory)]
    [Ensure]
    $Ensure

    [DscProperty()]
    [ValidateRange(0, 65535)]
    [Nullable[System.UInt16]]
    $Port

    [DscProperty()]
    [System.String]
    $Address

    [DscProperty()]
    [System.String]
    $Issuer

    [DscProperty()]
    [WSManSubjectFormat]
    $SubjectFormat = [WSManSubjectFormat]::Both

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
    $HostName

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

        # Get the port if it's not provided and resource should exist
        if (-not $this.Port -and $this.Ensure -eq [Ensure]::Present)
        {
            $this.Port = Get-DefaultPort @getParameters
        }

        # Get the Address if it's not provided and resource should exist
        if (-not $this.Address -and $this.Ensure -eq [Ensure]::Present)
        {
            $this.Address = '*'
        }


        $getCurrentStateResult = Get-Listener @getParameters

        if ($getCurrentStateResult)
        {
            $state = @{
                Transport             = [WSManTransport] $getCurrentStateResult.Transport
                Port                  = [System.UInt16] $getCurrentStateResult.Port
                Address               = $getCurrentStateResult.Address

                CertificateThumbprint = $getCurrentStateResult.CertificateThumbprint
                Hostname              = $getCurrentStateResult.Hostname

                Enabled               = $getCurrentStateResult.Enabled
                URLPrefix             = $getCurrentStateResult.URLPrefix
            }

            if ($getCurrentStateResult.CertificateThumbprint)
            {
                $state.Issuer = (Find-Certificate -CertificateThumbprint $getCurrentStateResult.CertificateThumbprint).Issuer
            }
        }
        else
        {
            $state = @{}
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
    hidden [void] Modify([System.Collections.Hashtable] $properties)
    {
        if ($properties.ContainsKey('Ensure') -and $properties.Ensure -eq [Ensure]::Absent -and $this.Ensure -eq [Ensure]::Absent)
        {
            # Ensure was not in desired state so the resource should be removed
            $this.RemoveInstance()
        }
        elseif ($properties.ContainsKey('Ensure') -and $properties.Ensure -eq [Ensure]::Present -and $this.Ensure -eq [Ensure]::Present)
        {
            # Ensure was not in the desired state so the resource should be created
            $this.NewInstance()
        }
        else
        {
            # Resource exists but one or more properties are not in the desired state
            $this.RemoveInstance()
            $this.NewInstance()
        }
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
        #TODO: if HTTPS, CertificateThumbprint and Issuer, SubjectFormat, MatchAlternate, BaseDN are mutually exclusive
    }

    hidden [void] NewInstance()
    {
        Write-Verbose -Message ($this.localizedData.CreatingListenerMessage -f $this.Transport, $this.Port)

        $selectorSet = @{
            Transport = $this.Transport
            Address   = $this.Address
        }

        $valueSet = @{
            Port = $this.Port
        }


        if ($this.Transport -eq [WSManTransport]::HTTPS)
        {
            $findCertificateParams = $this | Get-DscProperty -Attribute @('Optional') -ExcludeName @('Port', 'Address') -HasValue

            $certificate = Find-Certificate @findCertificateParams
            [System.String] $thumbprint = $certificate.Thumbprint

            if ($thumbprint)
            {
                $valueSet.CertificateThumbprint = $thumbprint

                if ([System.String]::IsNullOrEmpty($this.Hostname))
                {
                    $valueSet.HostName = [System.Net.Dns]::GetHostByName($env:COMPUTERNAME).Hostname
                }
                else
                {
                    $valueSet.HostName = $this.HostName
                }
            }
            else
            {
                # A certificate could not be found to use for the HTTPS listener
                New-InvalidArgumentException -Message (
                    $this.localizedData.ListenerCreateFailNoCertError -f $this.Transport, $this.Port
                ) -Argument 'Issuer'
            } # if
        }

        New-WSManInstance -ResourceURI 'winrm/config/Listener' -SelectorSet $selectorSet -ValueSet $valueSet -ErrorAction Stop
    }

    hidden [void] RemoveInstance()
    {
        Write-Verbose -Message ($this.localizedData.ListenerExistsRemoveMessage -f $this.Transport, $this.Port)

        $selectorSet = @{
            Transport = $this.Transport
            Address   = $this.Address
        }

        Remove-WSManInstance -ResourceURI 'winrm/config/Listener' -SelectorSet $selectorSet
    }
}
