<#
    .EXAMPLE
        Create an HTTPS Listener using a LocalMachine certificate with a thumbprint
        matching 'F2BE91E92AF040EF116E1CDC91D75C22F47D7BD6'. The host name in the
        certificate must match the name of the host machine.
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
        } # End of WSManListener Resource
    } # End of Node
} # End of Configuration
