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

    .PARAMETER BaseDN
        This is the BaseDN (path part of the full Distinguished Name) used to identify the certificate
        to use for the HTTPS WS-Man Listener if a thumbprint is not specified.

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
        [WSManSubjectFormat]
        $SubjectFormat = [WSManSubjectFormat]::Both,

        [Parameter()]
        [System.Boolean]
        $MatchAlternate,

        [Parameter()]
        [System.String]
        $BaseDN,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [System.String]
        $Hostname
    )

    if ($PSBoundParameters.ContainsKey('CertificateThumbprint'))
    {
        Write-Verbose -Message ($script:localizedData.FindCertificate_ByThumbprintMessage -f $CertificateThumbprint)

        $certificate = Get-ChildItem -Path Cert:\localmachine\my | Where-Object -FilterScript {
                ($_.Thumbprint -eq $CertificateThumbprint)
        } | Select-Object -First 1
    }
    else
    {
        # First try and find a certificate that is used to the FQDN of the machine
        if ($SubjectFormat -in [WSManSubjectFormat]::Both, [WSManSubjectFormat]::FQDNOnly)
        {
            # Lookup the certificate using the FQDN of the machine
            if ([System.String]::IsNullOrEmpty($Hostname))
            {
                $Hostname = [System.Net.Dns]::GetHostByName($ENV:computerName).Hostname
            }
            $Subject = "CN=$Hostname"

            if ($PSBoundParameters.ContainsKey('BaseDN'))
            {
                $Subject = "$Subject, $BaseDN"
            } # if

            if ($MatchAlternate)
            {
                # Try and lookup the certificate using the subject and the alternate name
                Write-Verbose -Message ($script:localizedData.FindCertificate_AlternateMessage -f $Subject, $Issuer, $Hostname)

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
                Write-Verbose -Message ($script:localizedData.FindCertificate_Message -f $Subject, $Issuer)

                $certificate = Get-ChildItem -Path Cert:\localmachine\my | Where-Object -FilterScript {
                        ($_.Extensions.EnhancedKeyUsages.FriendlyName `
                        -contains 'Server Authentication') -and
                        ($_.Issuer -eq $Issuer) -and
                        ($_.Subject -eq $Subject)
                } | Select-Object -First 1
            } # if
        }

        if (-not $certificate -and ($SubjectFormat -in [WSManSubjectFormat]::Both, [WSManSubjectFormat]::NameOnly))
        {
            # If could not find an FQDN cert, try for one issued to the computer name
            [System.String] $Hostname = $ENV:ComputerName
            [System.String] $Subject = "CN=$Hostname"

            if ($PSBoundParameters.ContainsKey('BaseDN'))
            {
                $Subject = "$Subject, $BaseDN"
            } # if

            if ($MatchAlternate)
            {
                # Try and lookup the certificate using the subject and the alternate name
                Write-Verbose -Message ($script:localizedData.FindCertificate_AlternateMessage -f $Subject, $Issuer, $Hostname)

                $certificate = Get-ChildItem -Path Cert:\localmachine\my | Where-Object -FilterScript {
                        ($_.Extensions.EnhancedKeyUsages.FriendlyName -contains 'Server Authentication') -and
                        ($_.Issuer -eq $Issuer) -and
                        ($Hostname -in $_.DNSNameList.Unicode) -and
                        ($_.Subject -eq $Subject)
                } | Select-Object -First 1
            }
            else
            {
                # Try and lookup the certificate using the subject name
                Write-Verbose -Message ($script:localizedData.FindCertificate_Message -f $Subject, $Issuer)

                $certificate = Get-ChildItem -Path Cert:\localmachine\my | Where-Object -FilterScript {
                    $_.Extensions.EnhancedKeyUsages.FriendlyName -contains 'Server Authentication'
                    -and $_.Issuer -eq $Issuer
                    -and $_.Subject -eq $Subject
                } | Select-Object -First 1
            } # if
        } # if
    } # if

    if ($certificate)
    {
        Write-Verbose -Message ($script:localizedData.FindCertificate_FoundMessage -f $certificate.thumbprint)
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.FindCertificate_NotFoundMessage)
    } # if

    return $certificate
}
