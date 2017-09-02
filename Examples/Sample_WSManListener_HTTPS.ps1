# Create an HTTPS Listener using a LocalMachine certificate that is installed and issued
# by 'CN=CONTOSO.COM Issuing CA, DC=CONTOSO, DC=COM' on port 5986.
configuration Sample_WSManListener_HTTPS
{
    Import-DscResource -Module WSManDsc

    Node $NodeName
    {
        WSManListener HTTPS
        {
            Transport = 'HTTPS'
            Ensure    = 'Present'
            Issuer    = 'CN=CONTOSO.COM Issuing CA, DC=CONTOSO, DC=COM'
        } # End of WSManListener Resource
    } # End of Node
} # End of Configuration

Sample_WSManListener_HTTPS
Start-DscConfiguration -Path Sample_WSManListener_HTTPS -Wait -Verbose -Force
