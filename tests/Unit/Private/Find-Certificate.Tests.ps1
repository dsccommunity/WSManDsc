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
    # Context 'CertificateThumbprint is passed but does not exist' {
    #     BeforeAll {
    #         Mock -CommandName Get-ChildItem
    #     }

    #     It 'Should not throw error' {
    #         InModuleScope -Parameters @{
    #             mockCertificateThumbprint = $script:mockCertificateThumbprint
    #         } -ScriptBlock {
    #             Set-StrictMode -Version 1.0

    #             { $script:returnedCertificate = Find-Certificate `
    #                     -CertificateThumbprint $mockCertificateThumbprint `
    #                     -Verbose:$VerbosePreference } | Should -Not -Throw
    #         }
    #     }

    #     It 'Should return null' {
    #         InModuleScope -ScriptBlock {
    #             Set-StrictMode -Version 1.0

    #             $script:returnedCertificate | Should -BeNullOrEmpty
    #         }
    #     }

    #     It 'Should call expected Mocks' {
    #         Should -Invoke `
    #             -CommandName Get-ChildItem `
    #             -Exactly -Times 1 `
    #             -Scope Context
    #     }
    # }

    # Context 'CertificateThumbprint is passed and does exist' {
    #     BeforeAll {
    #         Mock -CommandName Get-ChildItem -MockWith {
    #             $mockCertificateDN
    #         }
    #     }

    #     It 'Should not throw error' {
    #         InModuleScope -Parameters @{
    #             mockCertificateThumbprint = $script:mockCertificateThumbprint
    #         } -ScriptBlock {
    #             Set-StrictMode -Version 1.0

    #             { $script:returnedCertificate = Find-Certificate `
    #                     -CertificateThumbprint $mockCertificateThumbprint `
    #                     -Verbose:$VerbosePreference } | Should -Not -Throw
    #         }
    #     }

    #     It 'Should return expected certificate' {
    #         InModuleScope -Parameters @{
    #             mockCertificateThumbprint = $script:mockCertificateThumbprint
    #         } -ScriptBlock {
    #             Set-StrictMode -Version 1.0

    #             $script:returnedCertificate.Thumbprint | Should -Be $mockCertificateThumbprint
    #         }
    #     }

    #     It 'Should call expected Mocks' {
    #         Should -Invoke `
    #             -CommandName Get-ChildItem `
    #             -Exactly -Times 1 `
    #             -Scope Context
    #     }
    # }

    # Context 'SubjectFormat is Both, Certificate does not exist, DN passed' {
    #     BeforeAll {
    #         Mock -CommandName Get-ChildItem
    #     }

    #     It 'Should not throw error' {
    #         InModuleScope -Parameters @{
    #             mockIssuer = $script:mockIssuer
    #             mockDN     = $script:mockDN
    #         } -ScriptBlock {
    #             Set-StrictMode -Version 1.0

    #             { $script:returnedCertificate = Find-Certificate `
    #                     -Issuer $mockIssuer `
    #                     -SubjectFormat 'Both' `
    #                     -MatchAlternate $true `
    #                     -DN $mockDN  `
    #                     -Verbose:$VerbosePreference } | Should -Not -Throw
    #         }
    #     }

    #     It 'Should return null' {
    #         InModuleScope -ScriptBlock {
    #             Set-StrictMode -Version 1.0

    #             $script:returnedCertificate | Should -BeNullOrEmpty
    #         }
    #     }

    #     It 'Should call expected Mocks' {
    #         Should -Invoke `
    #             -CommandName Get-ChildItem `
    #             -Exactly -Times 2 `
    #             -Scope Context
    #     }
    # }

    # Context 'SubjectFormat is Both, Certificate with DN Exists, DN passed' {
    #     BeforeAll {
    #         Mock -CommandName Get-ChildItem -MockWith {
    #             $mockCertificateDN
    #         }
    #     }

    #     It 'Should not throw error' {
    #         InModuleScope -Parameters @{
    #             mockIssuer = $script:mockIssuer
    #             mockDN     = $script:mockDN
    #         } -ScriptBlock {
    #             Set-StrictMode -Version 1.0

    #             { $script:returnedCertificate = Find-Certificate `
    #                     -Issuer $mockIssuer `
    #                     -SubjectFormat 'Both' `
    #                     -MatchAlternate $true `
    #                     -DN $mockDN  `
    #                     -Verbose:$VerbosePreference } | Should -Not -Throw
    #         }
    #     }

    #     It 'Should return expected certificate' {
    #         InModuleScope -Parameters @{
    #             mockCertificateThumbprint = $script:mockCertificateThumbprint
    #         } -ScriptBlock {
    #             Set-StrictMode -Version 1.0

    #             $script:returnedCertificate.Thumbprint | Should -Be $mockCertificateThumbprint
    #         }
    #     }

    #     It 'Should call expected Mocks' {
    #         Should -Invoke `
    #             -CommandName Get-ChildItem `
    #             -Exactly -Times 1 `
    #             -Scope Context
    #     }
    # }

    # Context 'SubjectFormat is Both, Certificate without DN Exists, DN passed' {
    #     BeforeAll {
    #         Mock -CommandName Get-ChildItem -MockWith {
    #             $mockCertificate
    #         }
    #     }

    #     It 'Should not throw error' {
    #         InModuleScope -Parameters @{
    #             mockIssuer = $script:mockIssuer
    #             mockDN     = $script:mockDN
    #         } -ScriptBlock {
    #             Set-StrictMode -Version 1.0

    #             { $script:returnedCertificate = Find-Certificate `
    #                     -Issuer $mockIssuer `
    #                     -SubjectFormat 'Both' `
    #                     -MatchAlternate $true `
    #                     -DN $mockDN  `
    #                     -Verbose:$VerbosePreference } | Should -Not -Throw
    #         }
    #     }

    #     It 'Should return null' {
    #         InModuleScope -ScriptBlock {
    #             Set-StrictMode -Version 1.0

    #             $script:returnedCertificate | Should -BeNullOrEmpty
    #         }
    #     }

    #     It 'Should call expected Mocks' {
    #         Should -Invoke `
    #             -CommandName Get-ChildItem `
    #             -Exactly -Times 2 `
    #             -Scope Context
    #     }
    # }

    # Context 'SubjectFormat is Both, Certificate does not exist, DN not passed' {
    #     BeforeAll {
    #         Mock -CommandName Get-ChildItem
    #     }

    #     It 'Should not throw error' {
    #         InModuleScope -Parameters @{
    #             mockIssuer = $script:mockIssuer
    #         } -ScriptBlock {
    #             Set-StrictMode -Version 1.0

    #             { $script:returnedCertificate = Find-Certificate `
    #                     -Issuer $mockIssuer `
    #                     -SubjectFormat 'Both' `
    #                     -MatchAlternate $true `
    #                     -Verbose:$VerbosePreference } | Should -Not -Throw
    #         }
    #     }

    #     It 'Should return null' {
    #         InModuleScope -ScriptBlock {
    #             Set-StrictMode -Version 1.0

    #             $script:returnedCertificate | Should -BeNullOrEmpty
    #         }
    #     }

    #     It 'Should call expected Mocks' {
    #         Should -Invoke `
    #             -CommandName Get-ChildItem `
    #             -Exactly -Times 2 `
    #             -Scope Context
    #     }
    # }

    # Context 'SubjectFormat is Both, Certificate with DN Exists, DN not passed' {
    #     BeforeAll {
    #         Mock -CommandName Get-ChildItem -MockWith {
    #             $mockCertificateDN
    #         }
    #     }

    #     It 'Should not throw error' {
    #         InModuleScope -Parameters @{
    #             mockIssuer = $script:mockIssuer
    #         } -ScriptBlock {
    #             Set-StrictMode -Version 1.0

    #             { $script:returnedCertificate = Find-Certificate `
    #                     -Issuer $mockIssuer `
    #                     -SubjectFormat 'Both' `
    #                     -MatchAlternate $true `
    #                     -Verbose:$VerbosePreference } | Should -Not -Throw
    #         }
    #     }

    #     It 'Should return null' {
    #         InModuleScope -ScriptBlock {
    #             Set-StrictMode -Version 1.0

    #             $script:returnedCertificate | Should -BeNullOrEmpty
    #         }
    #     }

    #     It 'Should call expected Mocks' {
    #         Should -Invoke `
    #             -CommandName Get-ChildItem `
    #             -Exactly -Times 2 `
    #             -Scope Context
    #     }
    # }

    # Context 'SubjectFormat is Both, Certificate without DN Exists, DN not passed' {
    #     BeforeAll {
    #         Mock -CommandName Get-ChildItem -MockWith {
    #             $mockCertificate
    #         }
    #     }

    #     It 'Should not throw error' {
    #         InModuleScope -Parameters @{
    #             mockIssuer = $script:mockIssuer
    #         } -ScriptBlock {
    #             Set-StrictMode -Version 1.0

    #             { $script:returnedCertificate = Find-Certificate `
    #                     -Issuer $mockIssuer `
    #                     -SubjectFormat 'Both' `
    #                     -MatchAlternate $true `
    #                     -Verbose:$VerbosePreference } | Should -Not -Throw
    #         }
    #     }

    #     It 'Should return expected certificate' {
    #         InModuleScope -Parameters @{
    #             mockCertificateThumbprint = $script:mockCertificateThumbprint
    #         } -ScriptBlock {
    #             Set-StrictMode -Version 1.0

    #             $script:returnedCertificate.Thumbprint | Should -Be $mockCertificateThumbprint
    #         }
    #     }

    #     It 'Should call expected Mocks' {
    #         Should -Invoke `
    #             -CommandName Get-ChildItem `
    #             -Exactly -Times 1 `
    #             -Scope Context
    #     }
    # }

    # Context 'SubjectFormat is Both, Certificate does not exist, DN not passed, MatchAlternate is false' {
    #     BeforeAll {
    #         Mock -CommandName Get-ChildItem
    #     }

    #     It 'Should not throw error' {
    #         InModuleScope -Parameters @{
    #             mockIssuer = $script:mockIssuer
    #         } -ScriptBlock {
    #             Set-StrictMode -Version 1.0

    #             { $script:returnedCertificate = Find-Certificate `
    #                     -Issuer $mockIssuer `
    #                     -SubjectFormat 'Both' `
    #                     -MatchAlternate $false `
    #                     -Verbose:$VerbosePreference } | Should -Not -Throw
    #         }
    #     }

    #     It 'Should return null' {
    #         InModuleScope -ScriptBlock {
    #             Set-StrictMode -Version 1.0

    #             $script:returnedCertificate | Should -BeNullOrEmpty
    #         }
    #     }

    #     It 'Should call expected Mocks' {
    #         Should -Invoke `
    #             -CommandName Get-ChildItem `
    #             -Exactly -Times 2 `
    #             -Scope Context
    #     }
    # }

    # Context 'SubjectFormat is Both, Certificate without DN Exists, DN not passed, MatchAlternate is false' {
    #     BeforeAll {
    #         Mock -CommandName Get-ChildItem -MockWith {
    #             $mockCertificate
    #         }
    #     }

    #     It 'Should not throw error' {
    #         InModuleScope -Parameters @{
    #             mockIssuer = $script:mockIssuer
    #         } -ScriptBlock {
    #             Set-StrictMode -Version 1.0

    #             { $script:returnedCertificate = Find-Certificate `
    #                     -Issuer $mockIssuer `
    #                     -SubjectFormat 'Both' `
    #                     -MatchAlternate $false `
    #                     -Verbose:$VerbosePreference } | Should -Not -Throw
    #         }
    #     }

    #     It 'Should return expected certificate' {
    #         InModuleScope -Parameters @{
    #             mockCertificateThumbprint = $script:mockCertificateThumbprint
    #         } -ScriptBlock {
    #             Set-StrictMode -Version 1.0

    #             $script:returnedCertificate.Thumbprint | Should -Be $mockCertificateThumbprint
    #         }
    #     }

    #     It 'Should call expected Mocks' {
    #         Should -Invoke `
    #             -CommandName Get-ChildItem `
    #             -Exactly -Times 1 `
    #             -Scope Context
    #     }
    # }
}
