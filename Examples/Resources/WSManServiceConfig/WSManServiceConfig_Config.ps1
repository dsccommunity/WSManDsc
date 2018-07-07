#Requires -module WSManDsc

<#
    .DESCRIPTION
        Enable compatibility HTTP and HTTPS listeners, set
        maximum connections to 100, allow CredSSP (not recommended)
        and allow unecrypted WS-Man Sessions (not recommended).
#>
Configuration Example
{
    Import-DscResource -Module WSManDsc

    Node localhost
    {
        WSManServiceConfig ServiceConfig
        {
            IsSingleInstance                 = 'Yes'
            MaxConnections                   = 100
            AllowUnencrypted                 = $False
            AuthCredSSP                      = $True
            EnableCompatibilityHttpListener  = $True
            EnableCompatibilityHttpsListener = $True
        } # End of WSManServiceConfig Resource
    } # End of Node
} # End of Configuration
