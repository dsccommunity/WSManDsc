$script:dscModuleName = 'WSManDsc'
$script:dscResourceName = 'DSC_WSManListener'

$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'

$script:testEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -ResourceType 'Mof' `
    -TestType 'Integration'

# Using try/finally to always cleanup even if something awful happens.
try
{
    # Make sure WS-Man is enabled
    if (-not (Get-PSProvider -PSProvider WSMan -ErrorAction SilentlyContinue))
    {
        $null = Enable-PSRemoting `
            -SkipNetworkProfileCheck `
            -Force `
            -ErrorAction Stop
    } # if

    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName)_Add_HTTP.config.ps1"
    . $ConfigFile

    Describe "$($script:dscResourceName)_Integration_Add_HTTP" {
        $configData = @{
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
                $NewListener = $Listeners.Where( {$_.Transport -eq $configData.AllNodes[0].Transport } )
            }
            $NewListener                    | Should -Not -Be $null
            $NewListener.Port               | Should -Be $configData.AllNodes[0].Port
            $NewListener.Address            | Should -Be $configData.AllNodes[0].Address
        }
    }

    <#
        Note: Removing the WS-Man listener will cause DSC to stop working.
        So there is no integration test defined that will remove the listener created above.
    #>

    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName)_Add_HTTPS.config.ps1"
    . $ConfigFile

    # Create a certificate to use for the HTTPS listener
    $CertFriendlyName = 'WS-Man HTTPS Integration Test Cert'

    # Remove the certificate if it already exists
    Get-ChildItem -Path 'Cert:\LocalMachine\My' |
        Where-Object -Property FriendlyName -EQ $CertFriendlyName |
        Remove-Item -Force

    $Hostname = ([System.Net.Dns]::GetHostByName($ENV:computerName).Hostname)
    $DN = 'O=Contoso Inc, S=Pennsylvania, C=US'
    $Issuer = "CN=$Hostname, $DN"

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

    Describe "$($script:dscResourceName)_Integration_Add_HTTPS" {
        # This is to pass to the Config
        $configData = @{
            AllNodes = @(
                @{
                    NodeName       = 'localhost'
                    Transport      = 'HTTPS'
                    Ensure         = 'Present'
                    Port           = 5986
                    Address        = '*'
                    Issuer         = $Issuer
                    SubjectFormat  = 'Both'
                    MatchAlternate = $False
                    DN             = $DN
                    Hostname       = $Hostname
                }
            )
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
                $NewListener = $Listeners.Where( {$_.Transport -eq $configData.AllNodes[0].Transport } )
            }
            $NewListener                    | Should -Not -Be $null
            $NewListener.Port               | Should -Be $configData.AllNodes[0].Port
            $NewListener.Address            | Should -Be $configData.AllNodes[0].Address
        }
    }

    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName)_Remove_HTTPS.config.ps1"
    . $ConfigFile

    Describe "$($script:dscResourceName)_Integration_Remove_HTTPS" {
        $configData = @{
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
                $NewListener = $Listeners.Where( {$_.Transport -eq $configData.AllNodes[0].Transport } )
            }
            $NewListener                    | Should -BeNullOrEmpty
        }
    }

    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName)_Add_HTTPS_Thumbprint.config.ps1"
    . $ConfigFile

    Describe "$($script:dscResourceName)_Integration_Add_HTTPS_Thumbprint" {
        $configData = @{
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
                $NewListener = $Listeners.Where( {$_.Transport -eq $configData.AllNodes[0].Transport } )
            }
            $NewListener                    | Should -Not -Be $null
            $NewListener.Port               | Should -Be $configData.AllNodes[0].Port
            $NewListener.Address            | Should -Be $configData.AllNodes[0].Address
        }
    }

    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName)_Remove_HTTPS.config.ps1"
    . $ConfigFile

    Describe "$($script:dscResourceName)_Integration_Remove_HTTPS_Thumbprint" {
        $configData = @{
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
                $NewListener = $Listeners.Where( {$_.Transport -eq $configData.AllNodes[0].Transport } )
            }
            $NewListener                    | Should -BeNullOrEmpty
        }
    }

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

    Describe "$($script:dscResourceName)_Integration_Add_HTTPS_Thumbprint_Hostname" {
        # This is to pass to the Config
        $configData = @{
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
                $NewListener = $Listeners.Where( {$_.Transport -eq $configData.AllNodes[0].Transport } )
            }
            $NewListener                    | Should -Not -Be $null
            $NewListener.Port               | Should -Be $configData.AllNodes[0].Port
            $NewListener.Address            | Should -Be $configData.AllNodes[0].Address
        }
    }

    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName)_Remove_HTTPS.config.ps1"
    . $ConfigFile

    Describe "$($script:dscResourceName)_Integration_Remove_HTTPS" {
        $configData = @{
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
                $NewListener = $Listeners.Where( {$_.Transport -eq $configData.AllNodes[0].Transport } )
            }
            $NewListener                    | Should -BeNullOrEmpty
        }
    }

    # Remove the certificate if it already exists
    Get-ChildItem -Path 'Cert:\LocalMachine\My' |
        Where-Object -Property FriendlyName -EQ $CertFriendlyName |
        Remove-Item -Force
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
