#Requires -module WSManDsc

<#
    .DESCRIPTION
        Create an HTTPS Listener using a LocalMachine certificate that
        is installed and issued by 'CN=CONTOSO.COM Issuing CA, DC=CONTOSO, DC=COM'
        on port 5986.
#>
Configuration Example
{
    Import-DscResource -Module WSManDsc

    Node localhost
    {
        WSManListener HTTPS
        {
            Transport = 'HTTPS'
            Ensure    = 'Present'
            Issuer    = 'CN=CONTOSO.COM Issuing CA, DC=CONTOSO, DC=COM'
        } # End of WSManListener Resource
    } # End of Node
} # End of Configuration
