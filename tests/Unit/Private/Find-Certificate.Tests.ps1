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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
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
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Find-Certificate' -Tag 'Private' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:mockCertificateThumbprint = '74FA31ADEA7FDD5333CED10910BFA6F665A1F2FC'
        }
    }
    Context 'CertificateThumbprint is passed but does not exist' {
        BeforeAll {
            Mock -CommandName Get-ChildItem
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $findParameters = @{
                    CertificateThumbprint = $script:mockCertificateThumbprint
                    Verbose               = $VerbosePreference
                }

                $script:returnedCertificate = Find-Certificate @findParameters

                { $script:returnedCertificate } | Should -Not -Throw
            }
        }

        It 'Should return null' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:returnedCertificate | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Get-ChildItem -Exactly -Times 1 -Scope Context
        }
    }

    Context 'CertificateThumbprint is passed and does exist' {
        BeforeAll {
            Mock -CommandName Get-ChildItem -MockWith {
                @{
                    Thumbprint  = '74FA31ADEA7FDD5333CED10910BFA6F665A1F2FC'
                    Subject     = "CN=$([System.Net.Dns]::GetHostByName($ENV:computerName).Hostname), O=Contoso Inc, S=Pennsylvania, C=US"
                    Issuer      = 'CN=CONTOSO.COM Issuing CA, DC=CONTOSO, DC=COM'
                    Extensions  = @{ EnhancedKeyUsages = @{ FriendlyName = 'Server Authentication' } }
                    DNSNameList = @{ Unicode = $([System.Net.Dns]::GetHostByName($ENV:computerName).Hostname) }
                }
            }
        }

        It 'Should not throw error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $findParameters = @{
                    CertificateThumbprint = $script:mockCertificateThumbprint
                    Verbose               = $VerbosePreference
                }

                $script:returnedCertificate = Find-Certificate @findParameters

                { $script:returnedCertificate } | Should -Not -Throw
            }
        }

        It 'Should return expected certificate' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:returnedCertificate.Thumbprint | Should -Be $script:mockCertificateThumbprint
            }

            Should -Invoke -CommandName Get-ChildItem -Exactly -Times 1 -Scope Context
        }
    }

    # Context 'When SubjectFormat is ''Both''' {
    #     Context 'Certificate does not exist, DN passed' {
    #         BeforeAll {
    #             Mock -CommandName Get-ChildItem
    #         }

    #         It 'Should not throw error' {
    #             InModuleScope -Parameters @{
    #                 mockIssuer = $script:mockIssuer
    #                 mockDN     = $script:mockDN
    #             } -ScriptBlock {
    #                 Set-StrictMode -Version 1.0

    #                 { $script:returnedCertificate = Find-Certificate `
    #                         -Issuer $mockIssuer `
    #                         -SubjectFormat 'Both' `
    #                         -MatchAlternate $true `
    #                         -DN $mockDN  `
    #                         -Verbose:$VerbosePreference } | Should -Not -Throw
    #             }
    #         }

    #         It 'Should return null' {
    #             InModuleScope -ScriptBlock {
    #                 Set-StrictMode -Version 1.0

    #                 $script:returnedCertificate | Should -BeNullOrEmpty
    #             }
    #         }

    #         It 'Should call expected Mocks' {
    #             Should -Invoke `
    #                 -CommandName Get-ChildItem `
    #                 -Exactly -Times 2 `
    #                 -Scope Context
    #         }
    #     }

    #     Context 'Certificate with DN Exists, DN passed' {
    #         BeforeAll {
    #             Mock -CommandName Get-ChildItem -MockWith {
    #                 $mockCertificateDN
    #             }
    #         }

    #         It 'Should not throw error' {
    #             InModuleScope -Parameters @{
    #                 mockIssuer = $script:mockIssuer
    #                 mockDN     = $script:mockDN
    #             } -ScriptBlock {
    #                 Set-StrictMode -Version 1.0

    #                 { $script:returnedCertificate = Find-Certificate `
    #                         -Issuer $mockIssuer `
    #                         -SubjectFormat 'Both' `
    #                         -MatchAlternate $true `
    #                         -DN $mockDN  `
    #                         -Verbose:$VerbosePreference } | Should -Not -Throw
    #             }
    #         }

    #         It 'Should return expected certificate' {
    #             InModuleScope -Parameters @{
    #                 mockCertificateThumbprint = $script:mockCertificateThumbprint
    #             } -ScriptBlock {
    #                 Set-StrictMode -Version 1.0

    #                 $script:returnedCertificate.Thumbprint | Should -Be $mockCertificateThumbprint
    #             }
    #         }

    #         It 'Should call expected Mocks' {
    #             Should -Invoke `
    #                 -CommandName Get-ChildItem `
    #                 -Exactly -Times 1 `
    #                 -Scope Context
    #         }
    #     }

    #     Context 'Certificate without DN Exists, DN passed' {
    #         BeforeAll {
    #             Mock -CommandName Get-ChildItem -MockWith {
    #                 $mockCertificate
    #             }
    #         }

    #         It 'Should not throw error' {
    #             InModuleScope -Parameters @{
    #                 mockIssuer = $script:mockIssuer
    #                 mockDN     = $script:mockDN
    #             } -ScriptBlock {
    #                 Set-StrictMode -Version 1.0

    #                 { $script:returnedCertificate = Find-Certificate `
    #                         -Issuer $mockIssuer `
    #                         -SubjectFormat 'Both' `
    #                         -MatchAlternate $true `
    #                         -DN $mockDN  `
    #                         -Verbose:$VerbosePreference } | Should -Not -Throw
    #             }
    #         }

    #         It 'Should return null' {
    #             InModuleScope -ScriptBlock {
    #                 Set-StrictMode -Version 1.0

    #                 $script:returnedCertificate | Should -BeNullOrEmpty
    #             }
    #         }

    #         It 'Should call expected Mocks' {
    #             Should -Invoke `
    #                 -CommandName Get-ChildItem `
    #                 -Exactly -Times 2 `
    #                 -Scope Context
    #         }
    #     }

    #     Context 'Certificate does not exist, DN not passed' {
    #         BeforeAll {
    #             Mock -CommandName Get-ChildItem
    #         }

    #         It 'Should not throw error' {
    #             InModuleScope -Parameters @{
    #                 mockIssuer = $script:mockIssuer
    #             } -ScriptBlock {
    #                 Set-StrictMode -Version 1.0

    #                 { $script:returnedCertificate = Find-Certificate `
    #                         -Issuer $mockIssuer `
    #                         -SubjectFormat 'Both' `
    #                         -MatchAlternate $true `
    #                         -Verbose:$VerbosePreference } | Should -Not -Throw
    #             }
    #         }

    #         It 'Should return null' {
    #             InModuleScope -ScriptBlock {
    #                 Set-StrictMode -Version 1.0

    #                 $script:returnedCertificate | Should -BeNullOrEmpty
    #             }
    #         }

    #         It 'Should call expected Mocks' {
    #             Should -Invoke `
    #                 -CommandName Get-ChildItem `
    #                 -Exactly -Times 2 `
    #                 -Scope Context
    #         }
    #     }

    #     Context 'Certificate with DN Exists, DN not passed' {
    #         BeforeAll {
    #             Mock -CommandName Get-ChildItem -MockWith {
    #                 $mockCertificateDN
    #             }
    #         }

    #         It 'Should not throw error' {
    #             InModuleScope -Parameters @{
    #                 mockIssuer = $script:mockIssuer
    #             } -ScriptBlock {
    #                 Set-StrictMode -Version 1.0

    #                 { $script:returnedCertificate = Find-Certificate `
    #                         -Issuer $mockIssuer `
    #                         -SubjectFormat 'Both' `
    #                         -MatchAlternate $true `
    #                         -Verbose:$VerbosePreference } | Should -Not -Throw
    #             }
    #         }

    #         It 'Should return null' {
    #             InModuleScope -ScriptBlock {
    #                 Set-StrictMode -Version 1.0

    #                 $script:returnedCertificate | Should -BeNullOrEmpty
    #             }
    #         }

    #         It 'Should call expected Mocks' {
    #             Should -Invoke `
    #                 -CommandName Get-ChildItem `
    #                 -Exactly -Times 2 `
    #                 -Scope Context
    #         }
    #     }

    #     Context 'Certificate without DN Exists, DN not passed' {
    #         BeforeAll {
    #             Mock -CommandName Get-ChildItem -MockWith {
    #                 $mockCertificate
    #             }
    #         }

    #         It 'Should not throw error' {
    #             InModuleScope -Parameters @{
    #                 mockIssuer = $script:mockIssuer
    #             } -ScriptBlock {
    #                 Set-StrictMode -Version 1.0

    #                 { $script:returnedCertificate = Find-Certificate `
    #                         -Issuer $mockIssuer `
    #                         -SubjectFormat 'Both' `
    #                         -MatchAlternate $true `
    #                         -Verbose:$VerbosePreference } | Should -Not -Throw
    #             }
    #         }

    #         It 'Should return expected certificate' {
    #             InModuleScope -Parameters @{
    #                 mockCertificateThumbprint = $script:mockCertificateThumbprint
    #             } -ScriptBlock {
    #                 Set-StrictMode -Version 1.0

    #                 $script:returnedCertificate.Thumbprint | Should -Be $mockCertificateThumbprint
    #             }
    #         }

    #         It 'Should call expected Mocks' {
    #             Should -Invoke `
    #                 -CommandName Get-ChildItem `
    #                 -Exactly -Times 1 `
    #                 -Scope Context
    #         }
    #     }

    #     Context 'Certificate does not exist, DN not passed, MatchAlternate is false' {
    #         BeforeAll {
    #             Mock -CommandName Get-ChildItem
    #         }

    #         It 'Should not throw error' {
    #             InModuleScope -Parameters @{
    #                 mockIssuer = $script:mockIssuer
    #             } -ScriptBlock {
    #                 Set-StrictMode -Version 1.0

    #                 $findParameters = @{
    #                     Issuer         = $mockIssuer
    #                     SubjectFormat  = 'Both'
    #                     MatchAlternate = $false
    #                     Verbose        = $VerbosePreference
    #                 }

    #                 { $script:returnedCertificate = Find-Certificate @findParameters } | Should -Not -Throw
    #             }
    #         }

    #         It 'Should return null' {
    #             InModuleScope -ScriptBlock {
    #                 Set-StrictMode -Version 1.0

    #                 $script:returnedCertificate | Should -BeNullOrEmpty
    #             }

    #             Should -Invoke -CommandName Get-ChildItem -Exactly -Times 2 -Scope It
    #         }
    #     }

    #     Context 'Certificate without DN Exists, DN not passed, MatchAlternate is false' {
    #         BeforeAll {
    #             Mock -CommandName Get-ChildItem -MockWith {
    #                 $mockCertificate
    #             }
    #         }

    #         It 'Should not throw error' {
    #             InModuleScope -Parameters @{
    #                 mockIssuer = $script:mockIssuer
    #             } -ScriptBlock {
    #                 Set-StrictMode -Version 1.0

    #                 $findParameters = @{
    #                     Issuer         = $mockIssuer
    #                     SubjectFormat  = 'Both'
    #                     MatchAlternate = $false
    #                     Verbose        = $VerbosePreference
    #                 }

    #                 { $script:returnedCertificate = Find-Certificate @findParameters } | Should -Not -Throw
    #             }
    #         }

    #         It 'Should return expected certificate' {
    #             InModuleScope -Parameters @{
    #                 mockCertificateThumbprint = $script:mockCertificateThumbprint
    #             } -ScriptBlock {
    #                 Set-StrictMode -Version 1.0

    #                 $script:returnedCertificate.Thumbprint | Should -Be $mockCertificateThumbprint
    #             }

    #             Should -Invoke -CommandName Get-ChildItem -Exactly -Times 1 -Scope It
    #         }
    #     }
    # }
}
