<#PSScriptInfo
.VERSION 1.0.0
.GUID 5eb95759-9a02-4121-bfca-bba124bfc4f8
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT Copyright the DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/WSManDsc/blob/main/LICENSE
.PROJECTURI https://github.com/dsccommunity/WSManDsc
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES First version.
.PRIVATEDATA 2016-Datacenter,2016-Datacenter-Server-Core
#>

#Requires -module WSManDsc

<#
    .DESCRIPTION
        Set the WS-Man client to disallow unencrypted traffic,
        disable Basic authentication and set TrustedHosts to '*'.
#>
Configuration WSManClientConfig_Config
{
    Import-DscResource -Module WSManDsc

    Node localhost
    {
        WSManClientConfig ClientConfig
        {
            IsSingleInstance = 'Yes'
            AllowUnencrypted = $false
            AuthBasic        = $false
            TrustedHosts     = '*'

        } # End of WSManClientConfig Resource
    } # End of Node
} # End of Configuration
