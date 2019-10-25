<#PSScriptInfo
.VERSION 1.0.0
.GUID 664b29c1-c8cd-4400-860e-d7e90a76586e
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
        Create an HTTPS Listener using a LocalMachine certificate with a thumbprint
        matching 'F2BE91E92AF040EF116E1CDC91D75C22F47D7BD6'. If the subject in the
        certificate does not match the name of the host then the Hostname parameter
        must be specified. In this example the subject in the certificate is
        'WsManListenerCert'.
#>
Configuration WSManListener_HTTPS_WithThumbprintAndHostname_Config
{
    Import-DscResource -Module WSManDsc

    Node localhost
    {
        WSManListener HTTPS
        {
            Transport             = 'HTTPS'
            Ensure                = 'Present'
            CertificateThumbprint = 'F2BE91E92AF040EF116E1CDC91D75C22F47D7BD6'
            Hostname              = 'WsManListenerCert'
        } # End of WSManListener Resource
    } # End of Node
} # End of Configuration
