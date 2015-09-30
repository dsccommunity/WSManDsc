configuration Sample_cWSManListener_HTTP
{
    Import-DscResource -Module cWSManListener

    Node $NodeName
    {
        cWSManListener HTTP
        {
            Port = 5985
            Ensure = 'Present'
            Type = 'HTTP'
        } # End of cWSManListener Resource
    } # End of Node
} # End of Configuration
