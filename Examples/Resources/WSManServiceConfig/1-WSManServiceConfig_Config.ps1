<#PSScriptInfo
.VERSION 1.0.0
.GUID edb78f56-0a8a-472b-8752-6ec9dbd8e9a9
.AUTHOR Daniel Scott-Raynsford
.COMPANYNAME
.COPYRIGHT (c) 2018 Daniel Scott-Raynsford. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/PlagueHO/WSManDsc/blob/master/LICENSE
.PROJECTURI https://github.com/PlagueHO/WSManDsc
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
            AllowUnencrypted                 = $False
            AuthCredSSP                      = $True
            EnableCompatibilityHttpListener  = $True
            EnableCompatibilityHttpsListener = $True
        } # End of WSManServiceConfig Resource
    } # End of Node
} # End of Configuration
