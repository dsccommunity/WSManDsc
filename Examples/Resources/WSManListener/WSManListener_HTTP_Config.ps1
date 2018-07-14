#Requires -module WSManDsc

<#
    .DESCRIPTION
        This will create or enable an HTTP WS-Man Listener on port 5985.
        configuration Sample_WSManListener_HTTP
#>
Configuration Example
{
    Import-DscResource -Module WSManDsc

    Node localhost
    {
        WSManListener HTTP
        {
            Transport = 'HTTP'
            Ensure    = 'Present'
        } # End of WSManListener Resource
    } # End of Node
} # End of Configuration
