configuration Sample_cWSManListener_HTTP
{
    Import-DscResource -Module cWSMan

    Node $NodeName
    {
        cWSManListener HTTP
        {
            Transport = 'HTTP'
            Ensure = 'Present'
        } # End of cWSManListener Resource
    } # End of Node
} # End of Configuration
