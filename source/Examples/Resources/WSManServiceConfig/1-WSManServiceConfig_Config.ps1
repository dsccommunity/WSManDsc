<#PSScriptInfo
.VERSION 1.0.0
.GUID edb78f56-0a8a-472b-8752-6ec9dbd8e9a9
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
        Enable compatibility HTTP and HTTPS listeners, set
        maximum connections to 100, allow CredSSP (not recommended)
        and allow unecrypted WS-Man Sessions (not recommended).
#>
Configuration WSManServiceConfig_Config
{
    Import-DscResource -Module WSManDsc

    Node localhost
    {
        WSManServiceConfig ServiceConfig
        {
            IsSingleInstance                 = 'Yes'
            MaxConnections                   = 100
            AllowUnencrypted                 = $false
            AuthCredSSP                      = $true
            EnableCompatibilityHttpListener  = $true
            EnableCompatibilityHttpsListener = $true
        } # End of WSManServiceConfig Resource
    } # End of Node
} # End of Configuration
