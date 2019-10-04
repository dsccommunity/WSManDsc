<#PSScriptInfo
.VERSION 1.0.0
.GUID f24bd48c-1a88-4969-8d93-a46a11caad8c
.AUTHOR Daniel Scott-Raynsford
.COMPANYNAME
.COPYRIGHT (c) Daniel Scott-Raynsford. All rights reserved.
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
