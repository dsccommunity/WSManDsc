<#PSScriptInfo
.VERSION 1.0.0
.GUID 0781c089-cdf9-4687-b2c3-2a0ca8e1a752
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
        Create an HTTPS Listener using a LocalMachine certificate containing a DN matching
        'O=Contoso Inc, S=Pennsylvania, C=US' that is installed and issued by
        'CN=CONTOSO.COM Issuing CA, DC=CONTOSO, DC=COM' on port 5986.
#>
Configuration WSManListener_HTTPS_WithDN_Config
{
    Import-DscResource -Module WSManDsc

    Node localhost
    {
        WSManListener HTTPS
        {
            Transport = 'HTTPS'
            Ensure    = 'Present'
            Issuer    = 'CN=CONTOSO.COM Issuing CA, DC=CONTOSO, DC=COM'
            DN        = 'O=Contoso Inc, S=Pennsylvania, C=US'
        } # End of WSManListener Resource
    } # End of Node
} # End of Configuration
