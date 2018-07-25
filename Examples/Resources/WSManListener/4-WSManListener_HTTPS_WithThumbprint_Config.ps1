<#PSScriptInfo
.VERSION 1.0.0
.GUID 5a93f138-865c-4151-bade-8a10ca7ce758
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
        Create an HTTPS Listener using a LocalMachine certificate with a thumbprint
        matching 'F2BE91E92AF040EF116E1CDC91D75C22F47D7BD6'. The host name in the
        certificate must match the name of the host machine.
#>
Configuration Example
{
    Import-DscResource -Module WSManDsc

    Node localhost
    {
        WSManListener HTTPS
        {
            Transport             = 'HTTPS'
            Ensure                = 'Present'
            CertificateThumbprint = 'F2BE91E92AF040EF116E1CDC91D75C22F47D7BD6'
        } # End of WSManListener Resource
    } # End of Node
} # End of Configuration
