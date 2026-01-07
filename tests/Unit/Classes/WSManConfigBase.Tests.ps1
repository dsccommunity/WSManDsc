<#
    .SYNOPSIS
        Unit test for WSManConfigBase DSC base class.
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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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

Describe 'WSManConfigBase' {
    Context 'When class is instantiated' {
        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { [WSManConfigBase]::new() } | Should -Not -Throw
            }
        }

        It 'Should have a default or empty constructor' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $instance = [WSManConfigBase]::new()
                $instance | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should be the correct type' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $instance = [WSManConfigBase]::new()
                $instance.GetType().Name | Should -Be 'WSManConfigBase'
            }
        }
    }
}

Describe 'WSManConfigBase\GetCurrentState()' -Tag 'HiddenMember' {
    Context 'When $HasAuthContainer is $false' {
        Context 'When object is present in the current state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockInstance = [WSManConfig] @{
                        IsSingleInstance  = 'Yes'
                        MaxEnvelopeSizekb = 500
                    }
                }

                Mock -CommandName Get-DscProperty -MockWith {
                    @{
                        MaxEnvelopeSizekb = 500
                    }
                }

                Mock -CommandName Get-ChildItem -MockWith {
                    @(
                        [PSCustomObject] @{
                            Name          = 'MaxEnvelopeSizekb'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 500
                        }
                        [PSCustomObject] @{
                            Name          = 'MaxTimeoutms'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 60000
                        }
                        [PSCustomObject] @{
                            Name          = 'MaxBatchItems'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 32000
                        }
                        [PSCustomObject] @{
                            Name          = 'MaxProviderRequests'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 4294967295
                        }
                    )
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $currentState = $script:mockInstance.GetCurrentState(
                        @{
                            IsSingleInstance = 'Yes'
                        }
                    )

                    $currentState.IsSingleInstance | Should -BeNullOrEmpty
                    $currentState.MaxEnvelopeSizekb | Should -Be 500
                    $currentState.MaxEnvelopeSizekb | Should -BeOfType System.Uint32

                    $currentState.MaxTimeoutms | Should -BeNullOrEmpty
                    $currentState.MaxBatchItems | Should -BeNullOrEmpty
                }

                Should -Invoke -CommandName Get-DscProperty -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-ChildItem -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When $HasAuthContainer is $true' {
        Context 'When object is present in the current state and has Auth properties' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockInstance = [WSManServiceConfig] @{
                        IsSingleInstance                 = 'Yes'
                        MaxConnections                   = 500
                        MaxConcurrentOperationsPerUser   = 50
                        EnumerationTimeoutMS             = 1000
                        MaxPacketRetrievalTimeSeconds    = 1
                        AllowUnencrypted                 = $false
                        AuthBasic                        = $false
                        AuthKerberos                     = $true
                        AuthNegotiate                    = $true
                        AuthCertificate                  = $true
                        AuthCredSSP                      = $false
                        EnableCompatibilityHttpListener  = $false
                        EnableCompatibilityHttpsListener = $false
                    }
                }

                Mock -CommandName Get-DscProperty -MockWith {
                    @{
                        MaxConnections                   = 500
                        MaxConcurrentOperationsPerUser   = 50
                        EnumerationTimeoutMS             = 1000
                        MaxPacketRetrievalTimeSeconds    = 1
                        AllowUnencrypted                 = $false
                        AuthBasic                        = $false
                        AuthKerberos                     = $true
                        AuthNegotiate                    = $true
                        AuthCertificate                  = $true
                        AuthCredSSP                      = $false
                        EnableCompatibilityHttpListener  = $false
                        EnableCompatibilityHttpsListener = $false
                    }
                }

                Mock -CommandName Get-ChildItem -ParameterFilter { $Path -eq 'WSMan:\localhost\Service' } -MockWith {
                    @(
                        [PSCustomObject] @{
                            Name          = 'MaxConnections'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 500
                        }
                        [PSCustomObject] @{
                            Name          = 'MaxConcurrentOperationsPerUser'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 50
                        }
                        [PSCustomObject] @{
                            Name          = 'EnumerationTimeoutMS'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 1000
                        }
                        [PSCustomObject] @{
                            Name          = 'MaxPacketRetrievalTimeSeconds'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 1
                        }
                        [PSCustomObject] @{
                            Name          = 'AllowUnencrypted'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 'False'
                        }
                        [PSCustomObject] @{
                            Name          = 'EnableCompatibilityHttpListener'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 'False'
                        }
                        [PSCustomObject] @{
                            Name          = 'EnableCompatibilityHttpsListener'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 'False'
                        }
                    )
                }

                Mock -CommandName Get-ChildItem -ParameterFilter { $Path -eq 'WSMan:\localhost\Service\Auth' } -MockWith {
                    @(
                        [PSCustomObject] @{
                            Name          = 'Basic'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 'false'
                        }
                        [PSCustomObject] @{
                            Name          = 'Kerberos'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 'true'
                        }
                        [PSCustomObject] @{
                            Name          = 'Negotiate'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 'true'
                        }
                        [PSCustomObject] @{
                            Name          = 'Certificate'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 'true'
                        }
                        [PSCustomObject] @{
                            Name          = 'CredSSP'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 'false'
                        }
                    )
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $currentState = $script:mockInstance.GetCurrentState(
                        @{
                            IsSingleInstance = 'Yes'
                        }
                    )

                    $currentState.IsSingleInstance | Should -BeNullOrEmpty

                    $currentState.MaxConnections | Should -Be 500
                    $currentState.MaxConcurrentOperationsPerUser | Should -Be 50
                    $currentState.EnumerationTimeoutMS | Should -Be 1000
                    $currentState.MaxPacketRetrievalTimeSeconds | Should -Be 1
                    $currentState.AllowUnencrypted | Should -BeFalse
                    $currentState.AuthBasic | Should -BeFalse
                    $currentState.AuthKerberos | Should -BeTrue
                    $currentState.AuthNegotiate | Should -BeTrue
                    $currentState.AuthCertificate | Should -BeTrue
                    $currentState.AuthCredSSP | Should -BeFalse
                    $currentState.EnableCompatibilityHttpListener | Should -BeFalse
                    $currentState.EnableCompatibilityHttpsListener | Should -BeFalse
                }

                Should -Invoke -CommandName Get-DscProperty -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-ChildItem -ParameterFilter { $Path -eq 'WSMan:\localhost\Service' } -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-ChildItem -ParameterFilter { $Path -eq 'WSMan:\localhost\Service\Auth' } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When object is present in the current state and has ONLY Auth properties' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockInstance = [WSManServiceConfig] @{
                        IsSingleInstance                 = 'Yes'
                        AuthBasic                        = $false
                        AuthKerberos                     = $true
                        AuthNegotiate                    = $true
                        AuthCertificate                  = $true
                        AuthCredSSP                      = $false
                    }
                }

                Mock -CommandName Get-DscProperty -MockWith {
                    @{
                        AuthBasic                        = $false
                        AuthKerberos                     = $true
                        AuthNegotiate                    = $true
                        AuthCertificate                  = $true
                        AuthCredSSP                      = $false
                    }
                }

                Mock -CommandName Get-ChildItem -ParameterFilter { $Path -eq 'WSMan:\localhost\Service' } -MockWith {
                    @(
                        [PSCustomObject] @{
                            Name          = 'MaxConnections'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 500
                        }
                        [PSCustomObject] @{
                            Name          = 'MaxConcurrentOperationsPerUser'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 50
                        }
                        [PSCustomObject] @{
                            Name          = 'EnumerationTimeoutMS'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 1000
                        }
                        [PSCustomObject] @{
                            Name          = 'MaxPacketRetrievalTimeSeconds'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 1
                        }
                        [PSCustomObject] @{
                            Name          = 'AllowUnencrypted'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 'False'
                        }
                        [PSCustomObject] @{
                            Name          = 'EnableCompatibilityHttpListener'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 'False'
                        }
                        [PSCustomObject] @{
                            Name          = 'EnableCompatibilityHttpsListener'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 'False'
                        }
                    )
                }

                Mock -CommandName Get-ChildItem -ParameterFilter { $Path -eq 'WSMan:\localhost\Service\Auth' } -MockWith {
                    @(
                        [PSCustomObject] @{
                            Name          = 'Basic'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 'false'
                        }
                        [PSCustomObject] @{
                            Name          = 'Kerberos'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 'true'
                        }
                        [PSCustomObject] @{
                            Name          = 'Negotiate'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 'true'
                        }
                        [PSCustomObject] @{
                            Name          = 'Certificate'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 'true'
                        }
                        [PSCustomObject] @{
                            Name          = 'CredSSP'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 'false'
                        }
                    )
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $currentState = $script:mockInstance.GetCurrentState(
                        @{
                            IsSingleInstance = 'Yes'
                        }
                    )

                    $currentState.AuthBasic | Should -BeFalse
                    $currentState.AuthKerberos | Should -BeTrue
                    $currentState.AuthNegotiate | Should -BeTrue
                    $currentState.AuthCertificate | Should -BeTrue
                    $currentState.AuthCredSSP | Should -BeFalse

                    $currentState.IsSingleInstance | Should -BeNullOrEmpty
                    $currentState.MaxConnections | Should -BeNullOrEmpty
                    $currentState.MaxConcurrentOperationsPerUser | Should -BeNullOrEmpty
                    $currentState.EnumerationTimeoutMS | Should -BeNullOrEmpty
                    $currentState.MaxPacketRetrievalTimeSeconds | Should -BeNullOrEmpty
                    $currentState.AllowUnencrypted | Should -BeNullOrEmpty
                    $currentState.EnableCompatibilityHttpListener | Should -BeNullOrEmpty
                    $currentState.EnableCompatibilityHttpsListener | Should -BeNullOrEmpty
                }

                Should -Invoke -CommandName Get-DscProperty -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-ChildItem -ParameterFilter { $Path -eq 'WSMan:\localhost\Service' } -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-ChildItem -ParameterFilter { $Path -eq 'WSMan:\localhost\Service\Auth' } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When object is present in the current state and has NO Auth properties' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockInstance = [WSManServiceConfig] @{
                        IsSingleInstance                 = 'Yes'
                        MaxConnections                   = 500
                        MaxConcurrentOperationsPerUser   = 50
                        EnumerationTimeoutMS             = 1000
                        MaxPacketRetrievalTimeSeconds    = 1
                        AllowUnencrypted                 = $false
                        EnableCompatibilityHttpListener  = $false
                        EnableCompatibilityHttpsListener = $false
                    }
                }

                Mock -CommandName Get-DscProperty -MockWith {
                    @{
                        MaxConnections                   = 500
                        MaxConcurrentOperationsPerUser   = 50
                        EnumerationTimeoutMS             = 1000
                        MaxPacketRetrievalTimeSeconds    = 1
                        AllowUnencrypted                 = $false
                        EnableCompatibilityHttpListener  = $false
                        EnableCompatibilityHttpsListener = $false
                    }
                }

                Mock -CommandName Get-ChildItem -ParameterFilter { $Path -eq 'WSMan:\localhost\Service' } -MockWith {
                    @(
                        [PSCustomObject] @{
                            Name          = 'MaxConnections'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 500
                        }
                        [PSCustomObject] @{
                            Name          = 'MaxConcurrentOperationsPerUser'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 50
                        }
                        [PSCustomObject] @{
                            Name          = 'EnumerationTimeoutMS'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 1000
                        }
                        [PSCustomObject] @{
                            Name          = 'MaxPacketRetrievalTimeSeconds'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 1
                        }
                        [PSCustomObject] @{
                            Name          = 'AllowUnencrypted'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 'False'
                        }
                        [PSCustomObject] @{
                            Name          = 'EnableCompatibilityHttpListener'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 'False'
                        }
                        [PSCustomObject] @{
                            Name          = 'EnableCompatibilityHttpsListener'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 'False'
                        }
                    )
                }

                Mock -CommandName Get-ChildItem -ParameterFilter { $Path -eq 'WSMan:\localhost\Service\Auth' } -MockWith {
                    @(
                        [PSCustomObject] @{
                            Name          = 'Basic'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 'false'
                        }
                        [PSCustomObject] @{
                            Name          = 'Kerberos'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 'true'
                        }
                        [PSCustomObject] @{
                            Name          = 'Negotiate'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 'true'
                        }
                        [PSCustomObject] @{
                            Name          = 'Certificate'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 'true'
                        }
                        [PSCustomObject] @{
                            Name          = 'CredSSP'
                            SourceOfValue = $null
                            Type          = 'System.String'
                            Value         = 'false'
                        }
                    )
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $currentState = $script:mockInstance.GetCurrentState(
                        @{
                            IsSingleInstance = 'Yes'
                        }
                    )

                    $currentState.IsSingleInstance | Should -BeNullOrEmpty

                    $currentState.MaxConnections | Should -Be 500
                    $currentState.MaxConcurrentOperationsPerUser | Should -Be 50
                    $currentState.EnumerationTimeoutMS | Should -Be 1000
                    $currentState.MaxPacketRetrievalTimeSeconds | Should -Be 1
                    $currentState.AllowUnencrypted | Should -BeFalse
                    $currentState.AuthBasic | Should -BeNullOrEmpty
                    $currentState.AuthKerberos | Should -BeNullOrEmpty
                    $currentState.AuthNegotiate | Should -BeNullOrEmpty
                    $currentState.AuthCertificate | Should -BeNullOrEmpty
                    $currentState.AuthCredSSP | Should -BeNullOrEmpty
                    $currentState.EnableCompatibilityHttpListener | Should -BeFalse
                    $currentState.EnableCompatibilityHttpsListener | Should -BeFalse
                }

                Should -Invoke -CommandName Get-DscProperty -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-ChildItem -ParameterFilter { $Path -eq 'WSMan:\localhost\Service' } -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-ChildItem -ParameterFilter { $Path -eq 'WSMan:\localhost\Service\Auth' } -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'WSManConfigBase\Modify()' -Tag 'HiddenMember' {
    Context 'When $HasAuthContainer is $false' {
        Context 'When the system does NOT have Auth properties' {
            Context 'When the system is not in the desired state' {
                BeforeAll {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockInstance = [WSManConfig] @{
                            IsSingleInstance  = 'Yes'
                            MaxEnvelopeSizekb = 500
                            MaxTimeoutms      = 60000
                            MaxBatchItems     = 32000
                        }

                        Mock -CommandName Set-Item
                    }
                }

                Context 'When the properties are incorrect' {
                    It 'Should call the expected mocks' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $mockProperties = @{
                                MaxEnvelopeSizekb = 600
                                MaxTimeoutms      = 50000
                                MaxBatchItems     = 32001
                            }

                            $null = $script:mockInstance.Modify($mockProperties)
                        }

                        Should -Invoke -CommandName Set-Item -Exactly -Times 3 -Scope It
                    }
                }
            }
        }
    }

    Context 'When $HasAuthContainer is $true' {
        Context 'When the system does have Auth properties' {
            Context 'When the system is not in the desired state' {
                BeforeAll {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockInstance = [WSManServiceConfig] @{
                            IsSingleInstance                 = 'Yes'
                            MaxConnections                   = 500
                            MaxConcurrentOperationsPerUser   = 50
                            EnumerationTimeoutMS             = 1000
                            MaxPacketRetrievalTimeSeconds    = 1
                            AllowUnencrypted                 = $false
                            AuthBasic                        = $false
                            AuthKerberos                     = $true
                            AuthNegotiate                    = $true
                            AuthCertificate                  = $true
                            AuthCredSSP                      = $false
                            EnableCompatibilityHttpListener  = $false
                            EnableCompatibilityHttpsListener = $false
                        }

                        Mock -CommandName Set-Item -ParameterFilter { $Path -like '*Auth*' }
                        Mock -CommandName Set-Item -ParameterFilter { $Path -notlike '*Auth*' }
                    }
                }

                Context 'When the properties are incorrect' {
                    It 'Should call the expected mocks' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $mockProperties = @{
                                MaxConnections                   = 600
                                MaxConcurrentOperationsPerUser   = 60
                                EnumerationTimeoutMS             = 2000
                                MaxPacketRetrievalTimeSeconds    = 5
                                AllowUnencrypted                 = $true
                                EnableCompatibilityHttpListener  = $true
                                EnableCompatibilityHttpsListener = $true

                                AuthBasic                        = $true
                                AuthKerberos                     = $false
                                AuthNegotiate                    = $false
                                AuthCertificate                  = $false
                                AuthCredSSP                      = $true
                            }

                            $null = $script:mockInstance.Modify($mockProperties)
                        }

                        Should -Invoke -CommandName Set-Item -ParameterFilter { $Path -notlike '*Auth*' } -Exactly -Times 7 -Scope It
                        Should -Invoke -CommandName Set-Item -ParameterFilter { $Path -like '*Auth*' } -Exactly -Times 5 -Scope It
                    }
                }
            }
        }

        Context 'When the system does NOT have Auth properties' {
            Context 'When the system is not in the desired state' {
                BeforeAll {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockInstance = [WSManServiceConfig] @{
                            IsSingleInstance                 = 'Yes'
                            MaxConnections                   = 500
                            MaxConcurrentOperationsPerUser   = 50
                            EnumerationTimeoutMS             = 1000
                            MaxPacketRetrievalTimeSeconds    = 1
                            AllowUnencrypted                 = $false
                            EnableCompatibilityHttpListener  = $false
                            EnableCompatibilityHttpsListener = $false
                        }

                        Mock -CommandName Set-Item -ParameterFilter { $Path -like '*Auth*' }
                        Mock -CommandName Set-Item -ParameterFilter { $Path -notlike '*Auth*' }
                    }
                }

                Context 'When the properties are incorrect' {
                    It 'Should call the expected mocks' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $mockProperties = @{
                                MaxConnections                   = 600
                                MaxConcurrentOperationsPerUser   = 60
                                EnumerationTimeoutMS             = 2000
                                MaxPacketRetrievalTimeSeconds    = 5
                                AllowUnencrypted                 = $true
                                EnableCompatibilityHttpListener  = $true
                                EnableCompatibilityHttpsListener = $true
                            }

                            $null = $script:mockInstance.Modify($mockProperties)
                        }

                        Should -Invoke -CommandName Set-Item -ParameterFilter { $Path -notlike '*Auth*' } -Exactly -Times 7 -Scope It
                    }
                }
            }
        }
    }
}
