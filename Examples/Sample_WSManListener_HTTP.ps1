# This will create or enable an HTTP WS-Man Listener on port 5985.
configuration Sample_WSManListener_HTTP
{
    Import-DscResource -Module WSManDsc

    Node $NodeName
    {
        WSManListener HTTP
        {
            Transport = 'HTTP'
            Ensure    = 'Present'
        } # End of WSManListener Resource
    } # End of Node
} # End of Configuration

Sample_WSManListener_HTTP
Start-DscConfiguration -Path Sample_WSManListener_HTTP -Wait -Verbose -Force
