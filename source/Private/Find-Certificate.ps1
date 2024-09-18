<#
    .SYNOPSIS
        Finds the certificate to use for the HTTPS WS-Man Listener

    .PARAMETER Issuer
        The Issuer of the certificate to use for the HTTPS WS-Man Listener if a thumbprint is
        not specified.

    .PARAMETER SubjectFormat
        The format used to match the certificate subject to use for an HTTPS WS-Man Listener
        if a thumbprint is not specified.

    .PARAMETER MatchAlternate
        Should the FQDN/Name be used to also match the certificate alternate subject for an HTTPS WS-Man
        Listener if a thumbprint is not specified.

    .PARAMETER DN
        This is a Distinguished Name component that will be used to identify the certificate to use
        for the HTTPS WS-Man Listener if a thumbprint is not specified.

    .PARAMETER CertificateThumbprint
        The Thumbprint of the certificate to use for the HTTPS WS-Man Listener.
#>
function Find-Certificate
{
    [CmdletBinding()]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
    param
    (
        [Parameter()]
        [System.String]
        $Issuer,

        [Parameter()]
        [ValidateSet('Both', 'FQDNOnly', 'NameOnly')]
        [System.String]
        $SubjectFormat = 'Both',

        [Parameter()]
        [System.Boolean]
        $MatchAlternate,

        [Parameter()]
        [System.String]
        $DN,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [System.String]
        $Hostname
    )

    if ($PSBoundParameters.ContainsKey('CertificateThumbprint'))
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.FindCertificateByThumbprintMessage) `
                    -f $CertificateThumbprint
            ) -join '' )

        $certificate = Get-ChildItem -Path Cert:\localmachine\my | Where-Object -FilterScript {
                ($_.Thumbprint -eq $CertificateThumbprint)
        } | Select-Object -First 1
    }
    else
    {
        # First try and find a certificate that is used to the FQDN of the machine
        if ($SubjectFormat -in 'Both', 'FQDNOnly')
        {
            # Lookup the certificate using the FQDN of the machine
            if ([System.String]::IsNullOrEmpty($Hostname))
            {
                $Hostname = [System.Net.Dns]::GetHostByName($ENV:computerName).Hostname
            }
            $Subject = "CN=$Hostname"

            if ($PSBoundParameters.ContainsKey('DN'))
            {
                $Subject = "$Subject, $DN"
            } # if

            if ($MatchAlternate)
            {
                # Try and lookup the certificate using the subject and the alternate name
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.FindCertificateAlternateMessage) `
                            -f $Subject, $Issuer, $Hostname
                    ) -join '' )

                $certificate = (Get-ChildItem -Path Cert:\localmachine\my | Where-Object -FilterScript {
                        ($_.Extensions.EnhancedKeyUsages.FriendlyName `
                            -contains 'Server Authentication') -and
                        ($_.Issuer -eq $Issuer) -and
                        ($Hostname -in $_.DNSNameList.Unicode) -and
                        ($_.Subject -eq $Subject)
                    } | Select-Object -First 1)
            }
            else
            {
                # Try and lookup the certificate using the subject name
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.FindCertificateMessage) `
                            -f $Subject, $Issuer
                    ) -join '' )

                $certificate = Get-ChildItem -Path Cert:\localmachine\my | Where-Object -FilterScript {
                        ($_.Extensions.EnhancedKeyUsages.FriendlyName `
                        -contains 'Server Authentication') -and
                        ($_.Issuer -eq $Issuer) -and
                        ($_.Subject -eq $Subject)
                } | Select-Object -First 1
            } # if
        }

        if (-not $certificate `
                -and ($SubjectFormat -in 'Both', 'NameOnly'))
        {
            # If could not find an FQDN cert, try for one issued to the computer name
            [System.String] $Hostname = $ENV:ComputerName
            [System.String] $Subject = "CN=$Hostname"

            if ($PSBoundParameters.ContainsKey('DN'))
            {
                $Subject = "$Subject, $DN"
            } # if

            if ($MatchAlternate)
            {
                # Try and lookup the certificate using the subject and the alternate name
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.FindCertificateAlternateMessage) `
                            -f $Subject, $Issuer, $Hostname
                    ) -join '' )

                $certificate = Get-ChildItem -Path Cert:\localmachine\my | Where-Object -FilterScript {
                        ($_.Extensions.EnhancedKeyUsages.FriendlyName `
                        -contains 'Server Authentication') -and
                        ($_.Issuer -eq $Issuer) -and
                        ($Hostname -in $_.DNSNameList.Unicode) -and
                        ($_.Subject -eq $Subject)
                } | Select-Object -First 1
            }
            else
            {
                # Try and lookup the certificate using the subject name
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.FindCertificateMessage) `
                            -f $Subject, $Issuer
                    ) -join '' )

                $certificate = Get-ChildItem -Path Cert:\localmachine\my | Where-Object -FilterScript {
                        ($_.Extensions.EnhancedKeyUsages.FriendlyName `
                        -contains 'Server Authentication') -and
                        ($_.Issuer -eq $Issuer) -and
                        ($_.Subject -eq $Subject)
                } | Select-Object -First 1
            } # if
        } # if
    } # if

    if ($certificate)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.CertificateFoundMessage) `
                    -f $certificate.thumbprint
            ) -join '' )
    }
    else
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.CertificateNotFoundMessage) `
            ) -join '' )
    } # if

    return $certificate
}
