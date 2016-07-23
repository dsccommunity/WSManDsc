configuration Sample_WSManServiceConfig
{
    Import-DscResource -Module WSManDsc

    Node $NodeName
    {
        WSManServiceConfig ServiceConfig
        {
            MaxConnections                   = 100
            AllowUnencrypted                 = $False
            AuthCredSSP                      = $True
            EnableCompatibilityHttpListener  = $True
            EnableCompatibilityHttpsListener = $True
        } # End of WSManServiceConfig Resource
    } # End of Node
} # End of Configuration

Sample_WSManServiceConfig
Start-DscConfiguration -Path Sample_WSManServiceConfig -Wait -Verbose -Force
