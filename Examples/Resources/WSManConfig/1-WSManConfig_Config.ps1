<#PSScriptInfo
.VERSION 1.0.0
.GUID f24bd48c-1a88-4969-8d93-a46a11caad8c
.AUTHOR Daniel Scott-Raynsford
.COMPANYNAME
.COPYRIGHT (c) Daniel Scott-Raynsford. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/WSManDsc/blob/master/LICENSE
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
        Set the WS-Man maximum envelope size to 2000KB, the
        maximum timeout to 120 seconds and the maximum batch
        items to 64000.
#>
Configuration WSManConfig_Config
{
    Import-DscResource -Module WSManDsc

    Node localhost
    {
        WSManConfig Config
        {
            IsSingleInstance  = 'Yes'
            MaxEnvelopeSizekb = 2000
            MaxTimeoutms      = 120000
            MaxBatchItems     = 64000
        } # End of WSManConfig Resource
    } # End of Node
} # End of Configuration
