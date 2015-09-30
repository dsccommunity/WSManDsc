configuration Sample_cWSManListener_HTTPS
{
    Import-DscResource -Module cWSManListener

    Node $NodeName
    {
        cWSManListener HTTP
        {
            Port = 5986
            Ensure = 'Present'
            Type = 'HTTPS'
            Issuer = 'CN=CONTOSO.COM Issuing CA, DC=CONTOSO, DC=COM'
        } # End of cWSManListener Resource
    } # End of Node
} # End of Configuration
