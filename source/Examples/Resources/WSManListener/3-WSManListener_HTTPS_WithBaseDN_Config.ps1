<#PSScriptInfo
.VERSION 1.0.0
.GUID 0781c089-cdf9-4687-b2c3-2a0ca8e1a752
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
        Create an HTTPS Listener using a LocalMachine certificate containing a BaseDN matching
        'O=Contoso Inc, S=Pennsylvania, C=US' that is installed and issued by
        'CN=CONTOSO.COM Issuing CA, DC=CONTOSO, DC=COM' on port 5986.
#>
Configuration WSManListener_HTTPS_WithBaseDN_Config
{
    Import-DscResource -Module WSManDsc

    Node localhost
    {
        WSManListener HTTPS
        {
            Transport = 'HTTPS'
            Ensure    = 'Present'
            Issuer    = 'CN=CONTOSO.COM Issuing CA, DC=CONTOSO, DC=COM'
            BaseDN    = 'O=Contoso Inc, S=Pennsylvania, C=US'
        } # End of WSManListener Resource
    } # End of Node
} # End of Configuration
