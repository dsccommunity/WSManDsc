<#
    .SYNOPSIS
        Integration test for DSC_WSManListener DSC resource.

    .NOTES
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # This will throw an error if the dependencies have not been resolved.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }

    $script:dscResourceName = 'DSC_WSManListener'
}

BeforeAll {
    $script:dscModuleName = 'WSManDsc'
    $script:dscResourceName = 'DSC_WSManListener'

    $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Integration'

    # Make sure WS-Man is enabled
    if (-not (Get-PSProvider -PSProvider WSMan -ErrorAction SilentlyContinue))
    {
        $null = Enable-PSRemoting `
            -SkipNetworkProfileCheck `
            -Force `
            -ErrorAction Stop
    } # if

    # Create a certificate to use for the HTTPS listener
    $CertFriendlyName = 'WS-Man HTTPS Integration Test Cert'

    # Remove the certificate if it already exists
    Get-ChildItem -Path 'Cert:\LocalMachine\My' |
        Where-Object -Property FriendlyName -EQ $CertFriendlyName |
        Remove-Item -Force

    $script:Hostname = ([System.Net.Dns]::GetHostByName($ENV:computerName).Hostname)
    $script:BaseDN = 'O=Contoso Inc, S=Pennsylvania, C=US'
    $script:Issuer = "CN=$Hostname, $BaseDN"

    # Create the certificate
    if ([System.Environment]::OSVersion.Version.Major -ge 10)
    {
        # For Windows 10 or Windows Server 2016
        $script:Certificate = New-SelfSignedCertificate `
            -CertstoreLocation 'Cert:\LocalMachine\My' `
            -Subject $Issuer `
            -DnsName $Hostname `
            -FriendlyName $CertFriendlyName
    }
    else
    {
        <#
        New-SelfSignedCertificate in earlier OS versions will not make
        a certificate that can be used for WS-Man. So we will use the
        New-SelfSignedCertificateEx.ps1 script from the Script Center.
        A request has been made to the author of this script to make it
        available on PowerShellGallery.
    #>
        $ScriptFile = Join-Path -Path $ENV:Temp -ChildPath 'New-SelfSignedCertificateEx.ps1'
        if (-not (Test-Path -Path $ScriptFile))
        {
            $ScriptZip = Join-Path -Path $ENV:Temp -ChildPath 'New-SelfSignedCertificateEx.zip'
            Invoke-WebRequest `
                -Uri 'https://gallery.technet.microsoft.com/scriptcenter/Self-signed-certificate-5920a7c6/file/101251/2/New-SelfSignedCertificateEx.zip' `
                -OutFile $ScriptZip
            Expand-Archive -Path $ScriptZip -DestinationPath $ENV:Temp
            Remove-Item -Path $ScriptZip -Force
        } # If
        . $ScriptFile

        $script:Certificate = New-SelfSignedCertificateEx `
            -storeLocation 'LocalMachine' `
            -Subject $Issuer `
            -SubjectAlternativeName $($Hostname) `
            -FriendlyName $CertFriendlyName `
            -EnhancedKeyUsage 'Server Authentication'
    } # if
}

AfterAll {
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Remove the certificate if it already exists
    Get-ChildItem -Path 'Cert:\LocalMachine\My' |
        Where-Object -Property FriendlyName -EQ $CertFriendlyName |
        Remove-Item -Force
}

Describe "$($script:dscResourceName)_Integration_Add_HTTP" {
    BeforeAll {
        $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName)_Add_HTTP.config.ps1"
        . $ConfigFile

        $script:configData = @{
            AllNodes = @(
                @{
                    NodeName  = 'localhost'
                    Transport = 'HTTP'
                    Ensure    = 'Present'
                    Port      = 5985
                    Address   = '*'
                }
            )
        }
    }

    It 'Should compile without throwing' {
        {
            & "$($script:dscResourceName)_Config_Add_HTTP" `
                -OutputPath $TestDrive `
                -ConfigurationData $configData

            Start-DscConfiguration `
                -Path $TestDrive `
                -ComputerName localhost `
                -Wait `
                -Verbose `
                -Force `
                -ErrorAction Stop
        } | Should -Not -Throw
    }

    It 'Should compile and apply the MOF without throwing' {
        { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
    }

    It 'Should have set the resource and all the parameters should match' {
        # Get the Rule details
        $Listeners = @(Get-WSManInstance `
                -ResourceURI winrm/config/Listener `
                -Enumerate)
        if ($Listeners)
        {
            $NewListener = $Listeners.Where( { $_.Transport -eq $configData.AllNodes[0].Transport } )
        }
        $NewListener                    | Should -Not -Be $null
        $NewListener.Port               | Should -Be $configData.AllNodes[0].Port
        $NewListener.Address            | Should -Be $configData.AllNodes[0].Address
    }
}

Describe "$($script:dscResourceName)_Integration_Add_HTTPS" {
    BeforeAll {
        <#
        Note: Removing the WS-Man listener will cause DSC to stop working.
        So there is no integration test defined that will remove the listener created above.
    #>

        $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName)_Add_HTTPS.config.ps1"
        . $ConfigFile

        # This is to pass to the Config
        $script:configData = @{
            AllNodes = @(
                @{
                    NodeName       = 'localhost'
                    Transport      = 'HTTPS'
                    Ensure         = 'Present'
                    Port           = 5986
                    Address        = '*'
                    Issuer         = $Issuer
                    SubjectFormat  = 'Both'
                    MatchAlternate = $false
                    BaseDN         = $BaseDN
                    Hostname       = $Hostname
                }
            )
        }
    }

    It 'Should compile and apply the MOF without throwing' {
        {
            & "$($script:dscResourceName)_Config_Add_HTTPS" `
                -OutputPath $TestDrive `
                -ConfigurationData $configData

            Start-DscConfiguration `
                -Path $TestDrive `
                -ComputerName localhost `
                -Wait `
                -Verbose `
                -Force `
                -ErrorAction Stop
        } | Should -Not -Throw
    }

    It 'Should be able to call Get-DscConfiguration without throwing' {
        { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
    }

    It 'Should have set the resource and all the parameters should match' {
        # Get the Rule details
        $Listeners = @(Get-WSManInstance `
                -ResourceURI winrm/config/Listener `
                -Enumerate)
        if ($Listeners)
        {
            $NewListener = $Listeners.Where( { $_.Transport -eq $configData.AllNodes[0].Transport } )
        }
        $NewListener                    | Should -Not -Be $null
        $NewListener.Port               | Should -Be $configData.AllNodes[0].Port
        $NewListener.Address            | Should -Be $configData.AllNodes[0].Address
    }
}

Describe "$($script:dscResourceName)_Integration_Remove_HTTPS" {
    BeforeAll {
        $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName)_Remove_HTTPS.config.ps1"
        . $ConfigFile

        $script:configData = @{
            AllNodes = @(
                @{
                    NodeName  = 'localhost'
                    Transport = 'HTTPS'
                    Ensure    = 'Absent'
                    Port      = 5986
                    Address   = '*'
                }
            )
        }
    }

    It 'Should compile and apply the MOF without throwing' {
        {
            & "$($script:dscResourceName)_Config_Remove_HTTPS" `
                -OutputPath $TestDrive `
                -ConfigurationData $configData

            Start-DscConfiguration `
                -Path $TestDrive `
                -ComputerName localhost `
                -Wait `
                -Verbose `
                -Force `
                -ErrorAction Stop
        } | Should -Not -Throw
    }

    It 'Should be able to call Get-DscConfiguration without throwing' {
        { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
    }

    It 'Should have set the resource and all the parameters should match' {
        # Get the Rule details
        $Listeners = @(Get-WSManInstance `
                -ResourceURI winrm/config/Listener `
                -Enumerate)
        if ($Listeners)
        {
            $NewListener = $Listeners.Where( { $_.Transport -eq $configData.AllNodes[0].Transport } )
        }
        $NewListener                    | Should -BeNullOrEmpty
    }
}

Describe "$($script:dscResourceName)_Integration_Add_HTTPS_Thumbprint" {
    BeforeAll {
        $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName)_Add_HTTPS_Thumbprint.config.ps1"
        . $ConfigFile

        $script:configData = @{
            AllNodes = @(
                @{
                    NodeName              = 'localhost'
                    Transport             = 'HTTPS'
                    Ensure                = 'Present'
                    Port                  = 5986
                    Address               = '*'
                    CertificateThumbprint = $Certificate.Thumbprint
                }
            )
        }
    }

    It 'Should compile and apply the MOF without throwing' {
        {
            & "$($script:dscResourceName)_Config_Add_HTTPS_Thumbprint" `
                -OutputPath $TestDrive `
                -ConfigurationData $configData

            Start-DscConfiguration `
                -Path $TestDrive `
                -ComputerName localhost `
                -Wait `
                -Verbose `
                -Force `
                -ErrorAction Stop
        } | Should -Not -Throw
    }

    It 'Should be able to call Get-DscConfiguration without throwing' {
        { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
    }

    It 'Should have set the resource and all the parameters should match' {
        # Get the Rule details
        $Listeners = @(Get-WSManInstance `
                -ResourceURI winrm/config/Listener `
                -Enumerate)
        if ($Listeners)
        {
            $NewListener = $Listeners.Where( { $_.Transport -eq $configData.AllNodes[0].Transport } )
        }
        $NewListener                    | Should -Not -Be $null
        $NewListener.Port               | Should -Be $configData.AllNodes[0].Port
        $NewListener.Address            | Should -Be $configData.AllNodes[0].Address
    }
}

Describe "$($script:dscResourceName)_Integration_Remove_HTTPS_Thumbprint" {
    BeforeAll {
        $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName)_Remove_HTTPS.config.ps1"
        . $ConfigFile

        $script:configData = @{
            AllNodes = @(
                @{
                    NodeName  = 'localhost'
                    Transport = 'HTTPS'
                    Ensure    = 'Absent'
                    Port      = 5986
                    Address   = '*'
                }
            )
        }
    }

    It 'Should compile and apply the MOF without throwing' {
        {
            & "$($script:dscResourceName)_Config_Remove_HTTPS" `
                -OutputPath $TestDrive `
                -ConfigurationData $configData

            Start-DscConfiguration `
                -Path $TestDrive `
                -ComputerName localhost `
                -Wait `
                -Verbose `
                -Force `
                -ErrorAction Stop
        } | Should -Not -Throw
    }

    It 'Should be able to call Get-DscConfiguration without throwing' {
        { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
    }

    It 'Should have set the resource and all the parameters should match' {
        # Get the Rule details
        $Listeners = @(Get-WSManInstance `
                -ResourceURI winrm/config/Listener `
                -Enumerate)
        if ($Listeners)
        {
            $NewListener = $Listeners.Where( { $_.Transport -eq $configData.AllNodes[0].Transport } )
        }
        $NewListener                    | Should -BeNullOrEmpty
    }
}

Describe "$($script:dscResourceName)_Integration_Add_HTTPS_Thumbprint_Hostname" {
    BeforeAll {
        $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName)_Add_HTTPS_ThumbprintHostname.config.ps1"
        . $ConfigFile

        # Create a certificate to use for the HTTPS listener
        $CertFriendlyName = 'WS-Man HTTPS Integration Test Cert'

        # Remove the certificate if it already exists
        Get-ChildItem -Path 'Cert:\LocalMachine\My' |
            Where-Object -Property FriendlyName -EQ $CertFriendlyName |
            Remove-Item -Force

        $Hostname = 'DummyHostName'
        $Issuer = "CN=$Hostname"

        # Create the certificate
        if ([System.Environment]::OSVersion.Version.Major -ge 10)
        {
            # For Windows 10 or Windows Server 2016
            $Certificate = New-SelfSignedCertificate `
                -CertstoreLocation 'Cert:\LocalMachine\My' `
                -Subject $Issuer `
                -DnsName $Hostname `
                -FriendlyName $CertFriendlyName
        }
        else
        {
            <#
            New-SelfSignedCertificate in earlier OS versions will not make
            a certificate that can be used for WS-Man. So we will use the
            New-SelfSignedCertificateEx.ps1 script from the Script Center.
            A request has been made to the author of this script to make it
            available on PowerShellGallery.
        #>
            $ScriptFile = Join-Path -Path $ENV:Temp -ChildPath 'New-SelfSignedCertificateEx.ps1'
            if (-not (Test-Path -Path $ScriptFile))
            {
                $ScriptZip = Join-Path -Path $ENV:Temp -ChildPath 'New-SelfSignedCertificateEx.zip'
                Invoke-WebRequest `
                    -Uri 'https://gallery.technet.microsoft.com/scriptcenter/Self-signed-certificate-5920a7c6/file/101251/2/New-SelfSignedCertificateEx.zip' `
                    -OutFile $ScriptZip
                Expand-Archive -Path $ScriptZip -DestinationPath $ENV:Temp
                Remove-Item -Path $ScriptZip -Force
            } # If
            . $ScriptFile

            $Certificate = New-SelfSignedCertificateEx `
                -storeLocation 'LocalMachine' `
                -Subject $Issuer `
                -SubjectAlternativeName $($Hostname) `
                -FriendlyName $CertFriendlyName `
                -EnhancedKeyUsage 'Server Authentication'
        } # if

        # This is to pass to the Config
        $script:configData = @{
            AllNodes = @(
                @{
                    NodeName              = 'localhost'
                    Transport             = 'HTTPS'
                    Ensure                = 'Present'
                    Port                  = 5986
                    Address               = '*'
                    CertificateThumbprint = $Certificate.Thumbprint
                    Hostname              = $Hostname
                }
            )
        }
    }

    It 'Should compile and apply the MOF without throwing' {
        {
            & "$($script:dscResourceName)_Config_Add_HTTPS_Thumbprint_Hostname" `
                -OutputPath $TestDrive `
                -ConfigurationData $configData

            Start-DscConfiguration `
                -Path $TestDrive `
                -ComputerName localhost `
                -Wait `
                -Verbose `
                -Force `
                -ErrorAction Stop
        } | Should -Not -Throw
    }

    It 'Should be able to call Get-DscConfiguration without throwing' {
        { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
    }

    It 'Should have set the resource and all the parameters should match' {
        # Get the Rule details
        $Listeners = @(Get-WSManInstance `
                -ResourceURI winrm/config/Listener `
                -Enumerate)
        if ($Listeners)
        {
            $NewListener = $Listeners.Where( { $_.Transport -eq $configData.AllNodes[0].Transport } )
        }
        $NewListener                    | Should -Not -Be $null
        $NewListener.Port               | Should -Be $configData.AllNodes[0].Port
        $NewListener.Address            | Should -Be $configData.AllNodes[0].Address
    }
}

Describe "$($script:dscResourceName)_Integration_Remove_HTTPS" {
    BeforeAll {
        $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName)_Remove_HTTPS.config.ps1"
        . $ConfigFile

        $script:configData = @{
            AllNodes = @(
                @{
                    NodeName  = 'localhost'
                    Transport = 'HTTPS'
                    Ensure    = 'Absent'
                    Port      = 5986
                    Address   = '*'
                }
            )
        }
    }

    It 'Should compile and apply the MOF without throwing' {
        {
            & "$($script:dscResourceName)_Config_Remove_HTTPS" `
                -OutputPath $TestDrive `
                -ConfigurationData $configData

            Start-DscConfiguration `
                -Path $TestDrive `
                -ComputerName localhost `
                -Wait `
                -Verbose `
                -Force `
                -ErrorAction Stop
        } | Should -Not -Throw
    }

    It 'Should be able to call Get-DscConfiguration without throwing' {
        { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
    }

    It 'Should have set the resource and all the parameters should match' {
        # Get the Rule details
        $Listeners = @(Get-WSManInstance `
                -ResourceURI winrm/config/Listener `
                -Enumerate)
        if ($Listeners)
        {
            $NewListener = $Listeners.Where( { $_.Transport -eq $configData.AllNodes[0].Transport } )
        }
        $NewListener                    | Should -BeNullOrEmpty
    }
}
