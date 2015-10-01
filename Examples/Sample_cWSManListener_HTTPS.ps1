configuration Sample_cWSManListener_HTTPS
{
    Import-DscResource -Module cWSMan

    Node $NodeName
    {
        cWSManListener HTTP
        {
            Type = 'HTTPS'
            Ensure = 'Present'
            Issuer = 'CN=CONTOSO.COM Issuing CA, DC=CONTOSO, DC=COM'
        } # End of cWSManListener Resource
    } # End of Node
} # End of Configuration
