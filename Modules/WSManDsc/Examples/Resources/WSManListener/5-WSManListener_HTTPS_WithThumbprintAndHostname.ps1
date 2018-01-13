<#
    .EXAMPLE
        Create an HTTPS Listener using a LocalMachine certificate with a thumbprint
        matching 'F2BE91E92AF040EF116E1CDC91D75C22F47D7BD6'. If the subject in the
        certificate does not match the name of the host then the Hostname parameter
        must be specified. In this example the subject in the certificate is
        'WsManListenerCert'.
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DscResource -Module WSManDsc

    Node $NodeName
    {
        WSManListener HTTPS
        {
            Transport             = 'HTTPS'
            Ensure                = 'Present'
            CertificateThumbprint = 'F2BE91E92AF040EF116E1CDC91D75C22F47D7BD6'
            Hostname              = 'WsManListenerCert'
        } # End of WSManListener Resource
    } # End of Node
} # End of Configuration
