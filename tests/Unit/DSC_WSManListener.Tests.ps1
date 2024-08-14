<#
    .SYNOPSIS
        Unit test for DSC_WSManListener DSC resource.

    .NOTES
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

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

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName

    # Create the Mock Objects that will be used for running tests
    $script:mockCertificateThumbprint = '74FA31ADEA7FDD5333CED10910BFA6F665A1F2FC'
    $mockFQDN = 'SERVER1.CONTOSO.COM'
    $mockHostName = $([System.Net.Dns]::GetHostByName($ENV:computerName).Hostname)
    $script:mockIssuer = 'CN=CONTOSO.COM Issuing CA, DC=CONTOSO, DC=COM'
    $script:mockDN = 'O=Contoso Inc, S=Pennsylvania, C=US'
    $mockCertificate = @{
        Thumbprint  = $mockCertificateThumbprint
        Subject     = "CN=$mockHostName"
        Issuer      = $mockIssuer
        Extensions  = @{ EnhancedKeyUsages = @{ FriendlyName = 'Server Authentication' } }
        DNSNameList = @{ Unicode = $mockHostName }
    }

    $script:mockCertificateDN = @{
        Thumbprint  = $mockCertificateThumbprint
        Subject     = "CN=$mockHostName, $mockDN"
        Issuer      = $mockIssuer
        Extensions  = @{ EnhancedKeyUsages = @{ FriendlyName = 'Server Authentication' } }
        DNSNameList = @{ Unicode = $mockHostName }
    }

    $script:mockListenerHTTP = @{
        cfg                   = 'http://schemas.microsoft.com/wbem/wsman/1/config/listener'
        xsi                   = 'http://www.w3.org/2001/XMLSchema-instance'
        lang                  = 'en-US'
        Address               = '*'
        Transport             = 'HTTP'
        Port                  = 5985
        Hostname              = ''
        Enabled               = 'true'
        URLPrefix             = 'wsman'
        CertificateThumbprint = ''
    }

    $script:mockListenerHTTPS = @{
        cfg                   = 'http://schemas.microsoft.com/wbem/wsman/1/config/listener'
        xsi                   = 'http://www.w3.org/2001/XMLSchema-instance'
        lang                  = 'en-US'
        Address               = '*'
        Transport             = 'HTTPS'
        Port                  = 5986
        Hostname              = $mockFQDN
        Enabled               = 'true'
        URLPrefix             = 'wsman'
        CertificateThumbprint = $mockCertificateThumbprint
    }
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}

Describe "$($script:dscResourceName)\Get-TargetResource" -Tag 'Get' {
    Context 'No listeners exist' {
        BeforeAll {
            Mock -CommandName Get-WSManInstance
        }

        It 'Should return absent listener' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource `
                    -Transport HTTP `
                    -Ensure Present `
                    -Verbose:$VerbosePreference
                $result.Ensure | Should -Be 'Absent'
            }
        }

        It 'Should call Get-WSManInstance once' {
            Should -Invoke `
                -CommandName Get-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
        }
    }

    Context 'Requested listener does not exist' {
        BeforeAll {
            Mock -CommandName Get-WSManInstance -MockWith {
                @($mockListenerHTTP)
            }
        }

        It 'Should return absent listener' {
            InModuleScope -Parameters @{
                mockListenerHTTPS = $script:mockListenerHTTPS
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource `
                    -Transport $mockListenerHTTPS.Transport `
                    -Ensure Present `
                    -Verbose:$VerbosePreference

                $result.Ensure | Should -Be 'Absent'
            }
        }

        It 'Should call Get-WSManInstance once' {
            Should -Invoke `
                -CommandName Get-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
        }
    }

    Context 'Requested listener does exist' {
        BeforeAll {
            Mock -CommandName Get-WSManInstance -MockWith {
                @($mockListenerHTTP)
            }
        }

        It 'Should return correct listener' {
            InModuleScope -Parameters @{
                mockListenerHTTP = $script:mockListenerHTTP
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource `
                    -Transport $mockListenerHTTP.Transport `
                    -Ensure Present `
                    -Verbose:$VerbosePreference

                $result.Ensure | Should -Be 'Present'
                $result.Port | Should -Be $mockListenerHTTP.Port
                $result.Address | Should -Be $mockListenerHTTP.Address
                $result.HostName | Should -Be $mockListenerHTTP.HostName
                $result.Enabled | Should -Be $mockListenerHTTP.Enabled
                $result.URLPrefix | Should -Be $mockListenerHTTP.URLPrefix
                $result.CertificateThumbprint | Should -Be $mockListenerHTTP.CertificateThumbprint
            }
        }

        It 'Should call Get-WSManInstance once' {
            Should -Invoke `
                -CommandName Get-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
        }
    }
}

Describe "$($script:dscResourceName)\Set-TargetResource" -Tag 'Set' {
    Context 'HTTP Listener does not exist but should' {
        BeforeAll {
            Mock -CommandName Get-WSManInstance
            Mock -CommandName Remove-WSManInstance
            Mock -CommandName New-WSManInstance
            Mock -CommandName Find-Certificate
        }

        It 'Should not throw error' {
            InModuleScope -Parameters @{
                mockListenerHTTP = $script:mockListenerHTTP
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource `
                        -Transport $mockListenerHTTP.Transport `
                        -Ensure 'Present' `
                        -Verbose:$VerbosePreference } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
            Should -Invoke `
                -CommandName Remove-WSManInstance `
                -Exactly -Times 0 `
                -Scope Context
            Should -Invoke `
                -CommandName New-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
            Should -Invoke `
                -CommandName Find-Certificate `
                -Exactly -Times 0 `
                -Scope Context
        }
    }

    Context 'HTTPS Listener does not exist but should' {
        BeforeAll {
            Mock -CommandName Get-WSManInstance
            Mock -CommandName Remove-WSManInstance
            Mock -CommandName New-WSManInstance
            Mock -CommandName Find-Certificate -MockWith {
                return $mockCertificate
            }
        }

        It 'Should not throw error' {
            InModuleScope -Parameters @{
                mockListenerHTTPS = $script:mockListenerHTTPS
                mockIssuer        = $script:mockIssuer
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource `
                        -Transport $mockListenerHTTPS.Transport `
                        -Ensure 'Present' `
                        -Issuer $mockIssuer `
                        -Verbose:$VerbosePreference } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
            Should -Invoke `
                -CommandName Remove-WSManInstance `
                -Exactly -Times 0 `
                -Scope Context
            Should -Invoke `
                -CommandName New-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
            Should -Invoke `
                -CommandName Find-Certificate `
                -Exactly -Times 1 `
                -Scope Context
        }
    }

    Context 'HTTPS Listener does not exist but should but certificate missing' {
        BeforeAll {
            Mock -CommandName Get-WSManInstance
            Mock -CommandName Remove-WSManInstance
            Mock -CommandName New-WSManInstance
            Mock -CommandName Find-Certificate
        }

        It 'Should throw error' {
            InModuleScope -Parameters @{
                mockListenerHTTPS = $script:mockListenerHTTPS
                mockIssuer        = $script:mockIssuer
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($script:localizedData.ListenerCreateFailNoCertError -f `
                        $mockListenerHTTPS.Transport, '5986') `
                    -ArgumentName 'Issuer'

                { Set-TargetResource `
                        -Transport $mockListenerHTTPS.Transport `
                        -Ensure 'Present' `
                        -Issuer $mockIssuer `
                        -Verbose:$VerbosePreference } | Should -Throw $errorRecord
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
            Should -Invoke `
                -CommandName Remove-WSManInstance `
                -Exactly -Times 0 `
                -Scope Context
            Should -Invoke `
                -CommandName New-WSManInstance `
                -Exactly -Times 0 `
                -Scope Context
            Should -Invoke `
                -CommandName Find-Certificate `
                -Exactly -Times 1 `
                -Scope Context
        }
    }

    Context 'HTTP Listener exists but should not' {
        BeforeAll {
            Mock -CommandName Get-WSManInstance -MockWith {
                @($mockListenerHTTP)
            }
            Mock -CommandName Remove-WSManInstance
            Mock -CommandName New-WSManInstance
            Mock -CommandName Find-Certificate
        }

        It 'Should not throw error' {
            InModuleScope -Parameters @{
                mockListenerHTTP = $script:mockListenerHTTP
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource `
                        -Transport $mockListenerHTTP.Transport `
                        -Ensure 'Absent'  `
                        -Verbose:$VerbosePreference } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
            Should -Invoke `
                -CommandName Remove-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
            Should -Invoke `
                -CommandName New-WSManInstance `
                -Exactly -Times 0 `
                -Scope Context
            Should -Invoke `
                -CommandName Find-Certificate `
                -Exactly -Times 0 `
                -Scope Context
        }
    }

    Context 'HTTP Listener exists and should' {
        BeforeAll {
            Mock -CommandName Get-WSManInstance -MockWith {
                @($mockListenerHTTP)
            }
            Mock -CommandName Remove-WSManInstance
            Mock -CommandName New-WSManInstance
            Mock -CommandName Find-Certificate
        }

        It 'Should not throw error' {
            InModuleScope -Parameters @{
                mockListenerHTTP = $script:mockListenerHTTP
                mockIssuer       = $script:mockIssuer
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource `
                        -Transport $mockListenerHTTP.Transport `
                        -Ensure 'Present' `
                        -Issuer $mockIssuer  `
                        -Verbose:$VerbosePreference } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
            Should -Invoke `
                -CommandName Remove-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
            Should -Invoke `
                -CommandName New-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
            Should -Invoke `
                -CommandName Find-Certificate `
                -Exactly -Times 0 `
                -Scope Context
        }
    }

    Context 'HTTP Listener exists and HTTPS is required' {
        BeforeAll {
            Mock -CommandName Get-WSManInstance -MockWith {
                @($mockListenerHTTP)
            }
            Mock -CommandName Remove-WSManInstance
            Mock -CommandName New-WSManInstance
            Mock -CommandName Find-Certificate -MockWith {
                $mockCertificate
            }
        }

        It 'Should not throw error' {
            InModuleScope -Parameters @{
                mockListenerHTTPS = $script:mockListenerHTTPS
                mockIssuer        = $script:mockIssuer
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource `
                        -Transport $mockListenerHTTPS.Transport `
                        -Ensure 'Present' `
                        -Issuer $mockIssuer  `
                        -Verbose:$VerbosePreference } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
            Should -Invoke `
                -CommandName Remove-WSManInstance `
                -Exactly -Times 0 `
                -Scope Context
            Should -Invoke `
                -CommandName New-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
            Should -Invoke `
                -CommandName Find-Certificate `
                -Exactly -Times 1 `
                -Scope Context
        }
    }

    Context 'HTTPS Listener exists and HTTP is required' {
        BeforeAll {
            Mock -CommandName Get-WSManInstance -MockWith {
                @($mockListenerHTTPS)
            }
            Mock -CommandName Remove-WSManInstance
            Mock -CommandName New-WSManInstance
            Mock -CommandName Find-Certificate
        }

        It 'Should not throw error' {
            InModuleScope -Parameters @{
                mockListenerHTTP = $script:mockListenerHTTP
                mockIssuer       = $script:mockIssuer
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource `
                        -Transport $mockListenerHTTP.Transport `
                        -Ensure 'Present' `
                        -Issuer $mockIssuer  `
                        -Verbose:$VerbosePreference } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
            Should -Invoke `
                -CommandName Remove-WSManInstance `
                -Exactly -Times 0 `
                -Scope Context
            Should -Invoke `
                -CommandName New-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
            Should -Invoke `
                -CommandName Find-Certificate `
                -Exactly -Times 0 `
                -Scope Context
        }
    }

    Context 'Both Listeners exist and HTTPS is required' {
        BeforeAll {
            Mock -CommandName Get-WSManInstance -MockWith {
                @($mockListenerHTTP, $mockListenerHTTPS)
            }
            Mock -CommandName Remove-WSManInstance
            Mock -CommandName New-WSManInstance
            Mock -CommandName Find-Certificate -MockWith {
                $mockCertificate
            }
        }

        It 'Should not throw error' {
            InModuleScope -Parameters @{
                mockListenerHTTPS = $script:mockListenerHTTPS
                mockIssuer        = $script:mockIssuer
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource `
                        -Transport $mockListenerHTTPS.Transport `
                        -Ensure 'Present' `
                        -Issuer $mockIssuer  `
                        -Verbose:$VerbosePreference } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
            Should -Invoke `
                -CommandName Remove-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
            Should -Invoke `
                -CommandName New-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
            Should -Invoke `
                -CommandName Find-Certificate `
                -Exactly -Times 1 `
                -Scope Context
        }
    }

    Context 'Both Listeners exist and HTTP is required' {
        BeforeAll {
            Mock -CommandName Get-WSManInstance -MockWith {
                @($mockListenerHTTP, $mockListenerHTTPS)
            }
            Mock -CommandName Remove-WSManInstance
            Mock -CommandName New-WSManInstance
            Mock -CommandName Find-Certificate
        }

        It 'Should not throw error' {
            InModuleScope -Parameters @{
                mockListenerHTTP = $script:mockListenerHTTP
                mockIssuer       = $script:mockIssuer
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource `
                        -Transport $mockListenerHTTP.Transport `
                        -Ensure 'Present' `
                        -Issuer $mockIssuer  `
                        -Verbose:$VerbosePreference } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
            Should -Invoke `
                -CommandName Remove-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
            Should -Invoke `
                -CommandName New-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
            Should -Invoke `
                -CommandName Find-Certificate `
                -Exactly -Times 0 `
                -Scope Context
        }
    }
}

Describe "$($script:dscResourceName)\Test-TargetResource" -Tag 'Test' {
    Context 'HTTP Listener does not exist but should' {
        BeforeAll {
            Mock -CommandName Get-WSManInstance
        }

        It 'Should return false' {
            InModuleScope -Parameters @{
                mockListenerHTTP = $script:mockListenerHTTP
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource `
                    -Transport $mockListenerHTTP.Transport `
                    -Ensure 'Present'  `
                    -Verbose:$VerbosePreference | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
        }
    }

    Context 'HTTP Listener does not exist and should not' {
        BeforeAll {
            Mock -CommandName Get-WSManInstance
        }

        It 'Should return false' {
            InModuleScope -Parameters @{
                mockListenerHTTP = $script:mockListenerHTTP
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource `
                    -Transport $mockListenerHTTP.Transport `
                    -Ensure 'Absent'  `
                    -Verbose:$VerbosePreference | Should -BeTrue
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
        }
    }

    Context 'HTTPS Listener does not exist but should' {
        BeforeAll {
            Mock -CommandName Get-WSManInstance
        }

        It 'Should return false' {
            InModuleScope -Parameters @{
                mockListenerHTTPS = $script:mockListenerHTTPS
                mockIssuer        = $script:mockIssuer
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource `
                    -Transport $mockListenerHTTPS.Transport `
                    -Ensure 'Present' `
                    -Issuer $mockIssuer  `
                    -Verbose:$VerbosePreference | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
        }
    }

    Context 'HTTP Listener exists but should not' {
        BeforeAll {
            Mock -CommandName Get-WSManInstance -MockWith {
                @($mockListenerHTTP)
            }
        }

        It 'Should return false' {
            InModuleScope -Parameters @{
                mockListenerHTTP = $script:mockListenerHTTP
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource `
                    -Transport $mockListenerHTTP.Transport `
                    -Ensure 'Absent'  `
                    -Verbose:$VerbosePreference | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
        }
    }

    Context 'HTTPS Listener exists but should not' {
        BeforeAll {
            Mock -CommandName Get-WSManInstance -MockWith {
                @($mockListenerHTTPS)
            }
        }

        It 'Should return false' {
            InModuleScope -Parameters @{
                mockListenerHTTPS = $script:mockListenerHTTPS
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource `
                    -Transport $mockListenerHTTPS.Transport `
                    -Ensure 'Absent'  `
                    -Verbose:$VerbosePreference | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
        }
    }

    Context 'HTTP Listener exists and should' {
        BeforeAll {
            Mock -CommandName Get-WSManInstance -MockWith {
                @($mockListenerHTTP)
            }
        }

        It 'Should return true' {
            InModuleScope -Parameters @{
                mockListenerHTTP = $script:mockListenerHTTP
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource `
                    -Transport $mockListenerHTTP.Transport `
                    -Ensure 'Present'  `
                    -Verbose:$VerbosePreference | Should -BeTrue
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
        }
    }

    Context 'HTTPS Listener exists and should' {
        BeforeAll {
            Mock -CommandName Get-WSManInstance -MockWith {
                @($mockListenerHTTPS)
            }
        }

        It 'Should return true' {
            InModuleScope -Parameters @{
                mockListenerHTTPS = $script:mockListenerHTTPS
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource `
                    -Transport $mockListenerHTTPS.Transport `
                    -Ensure 'Present'  `
                    -Verbose:$VerbosePreference | Should -BeTrue
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
        }
    }

    Context 'HTTP Listener exists but port is incorrect' {
        BeforeAll {
            Mock -CommandName Get-WSManInstance -MockWith {
                @($mockListenerHTTP)
            }
        }

        It 'Should return true' {
            InModuleScope -Parameters @{
                mockListenerHTTP = $script:mockListenerHTTP
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource `
                    -Transport $mockListenerHTTP.Transport `
                    -Port 9999 `
                    -Ensure 'Present'  `
                    -Verbose:$VerbosePreference | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
        }
    }

    Context 'HTTP Listener exists but address is incorrect' {
        BeforeAll {
            Mock -CommandName Get-WSManInstance -MockWith {
                @($mockListenerHTTP)
            }
        }

        It 'Should return true' {
            InModuleScope -Parameters @{
                mockListenerHTTP = $script:mockListenerHTTP
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource `
                    -Transport $mockListenerHTTP.Transport `
                    -Address '192.168.1.1' `
                    -Ensure 'Present'  `
                    -Verbose:$VerbosePreference | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
        }
    }

    Context 'HTTP Listener exists but hostname is incorrect' {
        BeforeAll {
            Mock -CommandName Get-WSManInstance -MockWith {
                @($mockListenerHTTPS)
            }
        }

        It 'Should return true' {
            InModuleScope -Parameters @{
                mockListenerHTTPS = $script:mockListenerHTTPS
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource `
                    -Transport $mockListenerHTTPS.Transport `
                    -Hostname 'thewronghostname.example.local' `
                    -Ensure 'Present'  `
                    -Verbose:$VerbosePreference | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
        }
    }
    Context 'HTTP Listener exists but CertificateThumbprint is incorrect' {
        BeforeAll {
            Mock -CommandName Get-WSManInstance -MockWith {
                @($mockListenerHTTPS)
            }
        }

        It 'Should return true' {
            InModuleScope -Parameters @{
                mockListenerHTTPS = $script:mockListenerHTTPS
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource `
                    -Transport $mockListenerHTTPS.Transport `
                    -CertificateThumbprint '' `
                    -Ensure 'Present'  `
                    -Verbose:$VerbosePreference | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
        }
    }

    Context 'Both Listeners exists and HTTPS should' {
        BeforeAll {
            Mock -CommandName Get-WSManInstance -MockWith {
                @($mockListenerHTTP, $mockListenerHTTPS)
            }
        }

        It 'Should return true' {
            InModuleScope -Parameters @{
                mockListenerHTTPS = $script:mockListenerHTTPS
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource `
                    -Transport $mockListenerHTTPS.Transport `
                    -Ensure 'Present'  `
                    -Verbose:$VerbosePreference | Should -BeTrue
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-WSManInstance `
                -Exactly -Times 1 `
                -Scope Context
        }
    }
}

Describe "$($script:dscResourceName)\Find-Certificate" -Tag 'Private' {
    Context 'CertificateThumbprint is passed but does not exist' {
        BeforeAll {
            Mock -CommandName Get-ChildItem
        }

        It 'Should not throw error' {
            InModuleScope -Parameters @{
                mockCertificateThumbprint = $script:mockCertificateThumbprint
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:returnedCertificate = Find-Certificate `
                        -CertificateThumbprint $mockCertificateThumbprint `
                        -Verbose:$VerbosePreference } | Should -Not -Throw
            }
        }

        It 'Should return null' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:returnedCertificate | Should -BeNullOrEmpty
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-ChildItem `
                -Exactly -Times 1 `
                -Scope Context
        }
    }

    Context 'CertificateThumbprint is passed and does exist' {
        BeforeAll {
            Mock -CommandName Get-ChildItem -MockWith {
                $mockCertificateDN
            }
        }

        It 'Should not throw error' {
            InModuleScope -Parameters @{
                mockCertificateThumbprint = $script:mockCertificateThumbprint
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:returnedCertificate = Find-Certificate `
                        -CertificateThumbprint $mockCertificateThumbprint `
                        -Verbose:$VerbosePreference } | Should -Not -Throw
            }
        }

        It 'Should return expected certificate' {
            InModuleScope -Parameters @{
                mockCertificateThumbprint = $script:mockCertificateThumbprint
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:returnedCertificate.Thumbprint | Should -Be $mockCertificateThumbprint
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-ChildItem `
                -Exactly -Times 1 `
                -Scope Context
        }
    }

    Context 'SubjectFormat is Both, Certificate does not exist, DN passed' {
        BeforeAll {
            Mock -CommandName Get-ChildItem
        }

        It 'Should not throw error' {
            InModuleScope -Parameters @{
                mockIssuer = $script:mockIssuer
                mockDN     = $script:mockDN
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:returnedCertificate = Find-Certificate `
                        -Issuer $mockIssuer `
                        -SubjectFormat 'Both' `
                        -MatchAlternate $true `
                        -DN $mockDN  `
                        -Verbose:$VerbosePreference } | Should -Not -Throw
            }
        }

        It 'Should return null' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:returnedCertificate | Should -BeNullOrEmpty
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-ChildItem `
                -Exactly -Times 2 `
                -Scope Context
        }
    }

    Context 'SubjectFormat is Both, Certificate with DN Exists, DN passed' {
        BeforeAll {
            Mock -CommandName Get-ChildItem -MockWith {
                $mockCertificateDN
            }
        }

        It 'Should not throw error' {
            InModuleScope -Parameters @{
                mockIssuer = $script:mockIssuer
                mockDN     = $script:mockDN
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:returnedCertificate = Find-Certificate `
                        -Issuer $mockIssuer `
                        -SubjectFormat 'Both' `
                        -MatchAlternate $true `
                        -DN $mockDN  `
                        -Verbose:$VerbosePreference } | Should -Not -Throw
            }
        }

        It 'Should return expected certificate' {
            InModuleScope -Parameters @{
                mockCertificateThumbprint = $script:mockCertificateThumbprint
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:returnedCertificate.Thumbprint | Should -Be $mockCertificateThumbprint
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-ChildItem `
                -Exactly -Times 1 `
                -Scope Context
        }
    }

    Context 'SubjectFormat is Both, Certificate without DN Exists, DN passed' {
        BeforeAll {
            Mock -CommandName Get-ChildItem -MockWith {
                $mockCertificate
            } }

        It 'Should not throw error' {
            InModuleScope -Parameters @{
                mockIssuer = $script:mockIssuer
                mockDN     = $script:mockDN
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:returnedCertificate = Find-Certificate `
                        -Issuer $mockIssuer `
                        -SubjectFormat 'Both' `
                        -MatchAlternate $true `
                        -DN $mockDN  `
                        -Verbose:$VerbosePreference } | Should -Not -Throw
            }
        }

        It 'Should return null' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:returnedCertificate | Should -BeNullOrEmpty
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-ChildItem `
                -Exactly -Times 2 `
                -Scope Context
        }
    }

    Context 'SubjectFormat is Both, Certificate does not exist, DN not passed' {
        BeforeAll {
            Mock -CommandName Get-ChildItem
        }

        It 'Should not throw error' {
            InModuleScope -Parameters @{
                mockIssuer = $script:mockIssuer
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:returnedCertificate = Find-Certificate `
                        -Issuer $mockIssuer `
                        -SubjectFormat 'Both' `
                        -MatchAlternate $true `
                        -Verbose:$VerbosePreference } | Should -Not -Throw
            }
        }

        It 'Should return null' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:returnedCertificate | Should -BeNullOrEmpty
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-ChildItem `
                -Exactly -Times 2 `
                -Scope Context
        }
    }

    Context 'SubjectFormat is Both, Certificate with DN Exists, DN not passed' {
        BeforeAll {
            Mock -CommandName Get-ChildItem -MockWith {
                $mockCertificateDN
            }
        }

        It 'Should not throw error' {
            InModuleScope -Parameters @{
                mockIssuer = $script:mockIssuer
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:returnedCertificate = Find-Certificate `
                        -Issuer $mockIssuer `
                        -SubjectFormat 'Both' `
                        -MatchAlternate $true `
                        -Verbose:$VerbosePreference } | Should -Not -Throw
            }
        }

        It 'Should return null' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:returnedCertificate | Should -BeNullOrEmpty
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-ChildItem `
                -Exactly -Times 2 `
                -Scope Context
        }
    }

    Context 'SubjectFormat is Both, Certificate without DN Exists, DN not passed' {
        BeforeAll {
            Mock -CommandName Get-ChildItem -MockWith {
                $mockCertificate
            }
        }

        It 'Should not throw error' {
            InModuleScope -Parameters @{
                mockIssuer = $script:mockIssuer
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:returnedCertificate = Find-Certificate `
                        -Issuer $mockIssuer `
                        -SubjectFormat 'Both' `
                        -MatchAlternate $true `
                        -Verbose:$VerbosePreference } | Should -Not -Throw
            }
        }

        It 'Should return expected certificate' {
            InModuleScope -Parameters @{
                mockCertificateThumbprint = $script:mockCertificateThumbprint
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:returnedCertificate.Thumbprint | Should -Be $mockCertificateThumbprint
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-ChildItem `
                -Exactly -Times 1 `
                -Scope Context
        }
    }

    Context 'SubjectFormat is Both, Certificate does not exist, DN not passed, MatchAlternate is false' {
        BeforeAll {
            Mock -CommandName Get-ChildItem
        }

        It 'Should not throw error' {
            InModuleScope -Parameters @{
                mockIssuer = $script:mockIssuer
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:returnedCertificate = Find-Certificate `
                        -Issuer $mockIssuer `
                        -SubjectFormat 'Both' `
                        -MatchAlternate $false `
                        -Verbose:$VerbosePreference } | Should -Not -Throw
            }
        }

        It 'Should return null' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:returnedCertificate | Should -BeNullOrEmpty
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-ChildItem `
                -Exactly -Times 2 `
                -Scope Context
        }
    }

    Context 'SubjectFormat is Both, Certificate without DN Exists, DN not passed, MatchAlternate is false' {
        BeforeAll {
            Mock -CommandName Get-ChildItem -MockWith {
                $mockCertificate
            }
        }

        It 'Should not throw error' {
            InModuleScope -Parameters @{
                mockIssuer = $script:mockIssuer
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $script:returnedCertificate = Find-Certificate `
                        -Issuer $mockIssuer `
                        -SubjectFormat 'Both' `
                        -MatchAlternate $false `
                        -Verbose:$VerbosePreference } | Should -Not -Throw
            }
        }

        It 'Should return expected certificate' {
            InModuleScope -Parameters @{
                mockCertificateThumbprint = $script:mockCertificateThumbprint
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:returnedCertificate.Thumbprint | Should -Be $mockCertificateThumbprint
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-ChildItem `
                -Exactly -Times 1 `
                -Scope Context
        }
    }
}
