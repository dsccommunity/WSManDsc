<#PSScriptInfo
.VERSION 1.0.0
.GUID c5ad1c71-ca78-4f8c-8a7c-eac499340676
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
        This will create or enable an HTTP WS-Man Listener on port 5985.
        configuration Sample_WSManListener_HTTP
#>
Configuration WSManListener_HTTP_Config
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
