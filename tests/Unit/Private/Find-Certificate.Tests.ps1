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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # This will throw an error if the dependencies have not been resolved.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'WSManDsc'

    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName

    # Create the Mock Objects that will be used for running tests
    $script:mockCertificateThumbprint = '74FA31ADEA7FDD5333CED10910BFA6F665A1F2FC'
    $mockFQDN = 'SERVER1.CONTOSO.COM'
    $mockHostName = Get-ComputerName
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

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Find-Certificate' -Tag 'Private' {
    Context 'CertificateThumbprint is passed but does not exist' {
        BeforeAll {
            Mock -CommandName Get-ChildItem
        }

        It 'Should not throw error' {
            InModuleScope -Parameters @{
                mockCertificateThumbprint = $script:mockCertificateThumbprint
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $findCertificateParams = @{
                    CertificateThumbprint = $mockCertificateThumbprint
                    Verbose               = $VerbosePreference
                }

                $script:returnedCertificate = Find-Certificate @findCertificateParams

                { $script:returnedCertificate } | Should -Not -Throw
            }
        }

        It 'Should return null' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:returnedCertificate | Should -BeNullOrEmpty
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-ChildItem -Exactly -Times 1 -Scope Context
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

                $findCertificateParams = @{
                    CertificateThumbprint = $mockCertificateThumbprint
                    Verbose               = $VerbosePreference
                }

                $script:returnedCertificate = Find-Certificate @findCertificateParams

                { $script:returnedCertificate } | Should -Not -Throw
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
            Should -Invoke -CommandName Get-ChildItem -Exactly -Times 1 -Scope Context
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

                $findCertificateParams = @{
                    Issuer         = $mockIssuer
                    SubjectFormat  = 'Both'
                    MatchAlternate = $true
                    BaseDN         = $mockDN
                    Verbose        = $VerbosePreference
                }

                $script:returnedCertificate = Find-Certificate @findCertificateParams

                { $script:returnedCertificate } | Should -Not -Throw
            }
        }

        It 'Should return null' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:returnedCertificate | Should -BeNullOrEmpty
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-ChildItem -Exactly -Times 2 -Scope Context
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

                $findCertificateParams = @{
                    Issuer         = $mockIssuer
                    SubjectFormat  = 'Both'
                    MatchAlternate = $true
                    BaseDN         = $mockDN
                    Verbose        = $VerbosePreference
                }

                $script:returnedCertificate = Find-Certificate @findCertificateParams

                { $script:returnedCertificate } | Should -Not -Throw
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
            Should -Invoke -CommandName Get-ChildItem -Exactly -Times 1 -Scope Context
        }
    }

    Context 'SubjectFormat is Both, Certificate without DN Exists, DN passed' {
        BeforeAll {
            Mock -CommandName Get-ChildItem -MockWith {
                $mockCertificate
            }
        }

        It 'Should not throw error' {
            InModuleScope -Parameters @{
                mockIssuer = $script:mockIssuer
                mockDN     = $script:mockDN
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $findCertificateParams = @{
                    Issuer         = $mockIssuer
                    SubjectFormat  = 'Both'
                    MatchAlternate = $true
                    BaseDN         = $mockDN
                    Verbose        = $VerbosePreference
                }

                $script:returnedCertificate = Find-Certificate @findCertificateParams

                { $script:returnedCertificate } | Should -Not -Throw
            }
        }

        It 'Should return null' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:returnedCertificate | Should -BeNullOrEmpty
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-ChildItem -Exactly -Times 2 -Scope Context
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

                $findCertificateParams = @{
                    Issuer         = $mockIssuer
                    SubjectFormat  = 'Both'
                    MatchAlternate = $true
                    Verbose        = $VerbosePreference
                }

                $script:returnedCertificate = Find-Certificate @findCertificateParams

                { $script:returnedCertificate } | Should -Not -Throw
            }
        }

        It 'Should return null' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:returnedCertificate | Should -BeNullOrEmpty
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-ChildItem -Exactly -Times 2 -Scope Context
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

                $findCertificateParams = @{
                    Issuer         = $mockIssuer
                    SubjectFormat  = 'Both'
                    MatchAlternate = $true
                    Verbose        = $VerbosePreference
                }

                $script:returnedCertificate = Find-Certificate @findCertificateParams

                { $script:returnedCertificate } | Should -Not -Throw
            }
        }

        It 'Should return null' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:returnedCertificate | Should -BeNullOrEmpty
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-ChildItem -Exactly -Times 2 -Scope Context
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

                $findCertificateParams = @{
                    Issuer         = $mockIssuer
                    SubjectFormat  = 'Both'
                    MatchAlternate = $true
                    Verbose        = $VerbosePreference
                }

                $script:returnedCertificate = Find-Certificate @findCertificateParams

                { $script:returnedCertificate } | Should -Not -Throw
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
            Should -Invoke -CommandName Get-ChildItem -Exactly -Times 1 -Scope Context
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

                $findCertificateParams = @{
                    Issuer         = $mockIssuer
                    SubjectFormat  = 'Both'
                    MatchAlternate = $false
                    Verbose        = $VerbosePreference
                }

                $script:returnedCertificate = Find-Certificate @findCertificateParams

                { $script:returnedCertificate } | Should -Not -Throw
            }
        }

        It 'Should return null' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:returnedCertificate | Should -BeNullOrEmpty
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke -CommandName Get-ChildItem -Exactly -Times 2 -Scope Context
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

                $findCertificateParams = @{
                    Issuer         = $mockIssuer
                    SubjectFormat  = 'Both'
                    MatchAlternate = $false
                    Verbose        = $VerbosePreference
                }

                $script:returnedCertificate = Find-Certificate @findCertificateParams

                { $script:returnedCertificate } | Should -Not -Throw
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
            Should -Invoke -CommandName Get-ChildItem -Exactly -Times 1 -Scope Context
        }
    }
}
