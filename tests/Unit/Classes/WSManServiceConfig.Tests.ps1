<#
    .SYNOPSIS
        Unit test for WSManServiceConfig DSC resource.
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

Describe 'WSManServiceConfig' {
    Context 'When class is instantiated' {
        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { [WSManServiceConfig]::new() } | Should -Not -Throw
            }
        }

        It 'Should have a default or empty constructor' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $instance = [WSManServiceConfig]::new()
                $instance | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should be the correct type' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $instance = [WSManServiceConfig]::new()
                $instance.GetType().Name | Should -Be 'WSManServiceConfig'
            }
        }
    }
}

Describe 'WSManServiceConfig\Get()' -Tag 'Get' {
    Context 'When the system is in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance = [WSManServiceConfig] @{
                    IsSingleInstance                 = 'Yes'
                    RootSDDL                         = 'O:NSG:BAD:P(A;;GA;;;BA)(A;;GR;;;IU)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)'
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
                    AuthCbtHardeningLevel            = [WSManAuthCbtHardeningLevel]::Strict
                    EnableCompatibilityHttpListener  = $false
                    EnableCompatibilityHttpsListener = $false
                }

                <#
                        This mocks the method GetCurrentState().

                        Method Get() will call the base method Get() which will
                        call back to the derived class method GetCurrentState()
                        to get the result to return from the derived method Get().
                    #>
                $script:mockInstance |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                        return @{
                            IsSingleInstance                 = 'Yes'
                            RootSDDL                         = 'O:NSG:BAD:P(A;;GA;;;BA)(A;;GR;;;IU)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)'
                            MaxConnections                   = [System.UInt32] 500
                            MaxConcurrentOperationsPerUser   = [System.UInt32] 50
                            EnumerationTimeoutMS             = [System.UInt32] 1000
                            MaxPacketRetrievalTimeSeconds    = [System.UInt32] 1
                            AllowUnencrypted                 = $false
                            AuthBasic                        = $false
                            AuthKerberos                     = $true
                            AuthNegotiate                    = $true
                            AuthCertificate                  = $true
                            AuthCredSSP                      = $false
                            AuthCbtHardeningLevel            = [WSManAuthCbtHardeningLevel] 'Strict'
                            EnableCompatibilityHttpListener  = $false
                            EnableCompatibilityHttpsListener = $false
                        }
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Assert' -Value {
                        return
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Normalize' -Value {
                        return
                    } -PassThru
            }
        }

        It 'Should return the correct values' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $currentState = $script:mockInstance.Get()

                $currentState.IsSingleInstance | Should -Be 'Yes'

                $currentState.RootSDDL | Should -Be 'O:NSG:BAD:P(A;;GA;;;BA)(A;;GR;;;IU)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)'
                $currentState.RootSDDL | Should -BeOfType System.String

                $currentState.MaxConnections | Should -Be 500
                $currentState.MaxConnections | Should -BeOfType System.UInt32

                $currentState.MaxConcurrentOperationsPerUser | Should -Be 50
                $currentState.MaxConcurrentOperationsPerUser | Should -BeOfType System.UInt32

                $currentState.EnumerationTimeoutMS | Should -Be 1000
                $currentState.EnumerationTimeoutMS | Should -BeOfType System.UInt32

                $currentState.MaxPacketRetrievalTimeSeconds | Should -Be 1
                $currentState.MaxPacketRetrievalTimeSeconds | Should -BeOfType System.UInt32

                $currentState.AllowUnencrypted | Should -BeFalse
                $currentState.AllowUnencrypted | Should -BeOfType System.Boolean

                $currentState.AuthBasic | Should -BeFalse
                $currentState.AuthBasic | Should -BeOfType System.Boolean

                $currentState.AuthKerberos | Should -BeTrue
                $currentState.AuthKerberos | Should -BeOfType System.Boolean

                $currentState.AuthNegotiate | Should -BeTrue
                $currentState.AuthNegotiate | Should -BeOfType System.Boolean

                $currentState.AuthCertificate | Should -BeTrue
                $currentState.AuthCertificate | Should -BeOfType System.Boolean

                $currentState.AuthCredSSP | Should -BeFalse
                $currentState.AuthCredSSP | Should -BeOfType System.Boolean

                $currentState.AuthCbtHardeningLevel | Should -Be 'Strict'

                $currentState.EnableCompatibilityHttpListener | Should -BeFalse
                $currentState.EnableCompatibilityHttpListener | Should -BeOfType System.Boolean

                $currentState.EnableCompatibilityHttpsListener | Should -BeFalse
                $currentState.EnableCompatibilityHttpsListener | Should -BeOfType System.Boolean

                $currentState.Reasons | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When property ''MaxConnections'' has the wrong value' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockInstance = [WSManServiceConfig] @{
                        IsSingleInstance = 'Yes'
                        MaxConnections   = 8000
                    }

                    <#
                        This mocks the method GetCurrentState().

                        Method Get() will call the base method Get() which will
                        call back to the derived class method GetCurrentState()
                        to get the result to return from the derived method Get().
                    #>
                    $script:mockInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return @{
                                IsSingleInstance = 'Yes'
                                MaxConnections   = [System.UInt32] 500
                            }
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'Assert' -Value {
                            return
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'Normalize' -Value {
                            return
                        } -PassThru
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $currentState = $script:mockInstance.Get()

                    $currentState.IsSingleInstance | Should -Be 'Yes'

                    $currentState.MaxConnections | Should -Be 500
                    $currentState.MaxConnections | Should -BeOfType System.UInt32

                    $currentState.Reasons | Should -HaveCount 1
                    $currentState.Reasons[0].Code | Should -Be 'WSManServiceConfig:WSManServiceConfig:MaxConnections'
                    $currentState.Reasons[0].Phrase | Should -Be 'The property MaxConnections should be 8000, but was 500'
                }
            }
        }
    }
}

Describe 'WSManServiceConfig\Set()' -Tag 'Set' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $script:mockInstance = [WSManServiceConfig] @{
                IsSingleInstance                 = 'Yes'
                RootSDDL                         = 'O:NSG:BAD:P(A;;GA;;;BA)(A;;GR;;;IU)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)'
                MaxConnections                   = [System.UInt32] 500
                MaxConcurrentOperationsPerUser   = [System.UInt32] 50
                EnumerationTimeoutMS             = [System.UInt32] 1000
                MaxPacketRetrievalTimeSeconds    = [System.UInt32] 1
                AllowUnencrypted                 = $false
                AuthBasic                        = $false
                AuthKerberos                     = $true
                AuthNegotiate                    = $true
                AuthCertificate                  = $true
                AuthCredSSP                      = $false
                AuthCbtHardeningLevel            = [WSManAuthCbtHardeningLevel] 'Strict'
                EnableCompatibilityHttpListener  = $false
                EnableCompatibilityHttpsListener = $false
            } |
                # Mock method Modify which is called by the case method Set().
                Add-Member -Force -MemberType 'ScriptMethod' -Name 'Modify' -Value {
                    $script:methodModifyCallCount += 1
                } -PassThru
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $script:methodTestCallCount = 0
            $script:methodModifyCallCount = 0
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance |
                    # Mock method Test() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Test' -Value {
                        $script:methodTestCallCount += 1
                        return $true
                    }
            }
        }

        It 'Should not call method Modify()' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance.Set()

                $script:methodTestCallCount | Should -Be 1
                $script:methodModifyCallCount | Should -Be 0
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance |
                    # Mock method Test() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Test' -Value {
                        $script:methodTestCallCount += 1
                        return $false
                    }

                $script:mockInstance.PropertiesNotInDesiredState = @(
                    @{
                        Property      = 'MaxConnections'
                        ExpectedValue = 500
                        ActualValue   = 600
                    }
                )
            }
        }

        It 'Should call method Modify()' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance.Set()

                $script:methodTestCallCount | Should -Be 1
                $script:methodModifyCallCount | Should -Be 1
            }
        }
    }
}

Describe 'WSManServiceConfig\Test()' -Tag 'Test' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $script:mockInstance = [WSManServiceConfig] @{
                IsSingleInstance                 = 'Yes'
                RootSDDL                         = 'O:NSG:BAD:P(A;;GA;;;BA)(A;;GR;;;IU)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)'
                MaxConnections                   = [System.UInt32] 500
                MaxConcurrentOperationsPerUser   = [System.UInt32] 50
                EnumerationTimeoutMS             = [System.UInt32] 1000
                MaxPacketRetrievalTimeSeconds    = [System.UInt32] 1
                AllowUnencrypted                 = $false
                AuthBasic                        = $false
                AuthKerberos                     = $true
                AuthNegotiate                    = $true
                AuthCertificate                  = $true
                AuthCredSSP                      = $false
                AuthCbtHardeningLevel            = [WSManAuthCbtHardeningLevel] 'Strict'
                EnableCompatibilityHttpListener  = $false
                EnableCompatibilityHttpsListener = $false
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $script:getMethodCallCount = 0
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance |
                    # Mock method Get() which is called by the base method Test()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Get' -Value {
                        $script:getMethodCallCount += 1
                    }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockInstance.Test() | Should -BeTrue

                    $script:getMethodCallCount | Should -Be 1
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance |
                    # Mock method Get() which is called by the base method Test()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Get' -Value {
                        $script:getMethodCallCount += 1
                    }

                $script:mockInstance.PropertiesNotInDesiredState = @(
                    @{
                        Property      = 'MaxConnections'
                        ExpectedValue = 500
                        ActualValue   = 600
                    }
                )
            }
        }

        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance.Test() | Should -BeFalse

                $script:getMethodCallCount | Should -Be 1
            }
        }
    }
}

Describe 'WSManServiceConfig\AssertProperties()' -Tag 'AssertProperties' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $script:mockInstance = [WSManServiceConfig] @{}
        }
    }

    Context 'When required parameters are missing' {
        BeforeDiscovery {
            $testCases = @(
                @{
                    IsSingleInstance = 'Yes'
                }
            )
        }

        It 'Should throw the correct error' -ForEach $testCases {
            InModuleScope -Parameters @{
                mockProperties = $_
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $mockInstance.AssertProperties($mockProperties) } | Should -Throw -ExpectedMessage ('*' + 'DRC0050' + '*')
            }
        }
    }

    Context 'When passing required parameters' {
        BeforeDiscovery {
            $testCases = @(
                @{
                    RootSDDL                         = 'O:NSG:BAD:P(A;;GA;;;BA)(A;;GR;;;IU)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)'
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
                    AuthCbtHardeningLevel            = 'Strict'
                    EnableCompatibilityHttpListener  = $false
                    EnableCompatibilityHttpsListener = $false
                }
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
                    AuthCbtHardeningLevel            = 'Strict'
                    EnableCompatibilityHttpListener  = $false
                    EnableCompatibilityHttpsListener = $false
                }
                @{
                    MaxConcurrentOperationsPerUser   = 50
                    EnumerationTimeoutMS             = 1000
                    MaxPacketRetrievalTimeSeconds    = 1
                    AllowUnencrypted                 = $false
                    AuthBasic                        = $false
                    AuthKerberos                     = $true
                    AuthNegotiate                    = $true
                    AuthCertificate                  = $true
                    AuthCredSSP                      = $false
                    AuthCbtHardeningLevel            = 'Strict'
                    EnableCompatibilityHttpListener  = $false
                    EnableCompatibilityHttpsListener = $false
                }
                @{
                    EnumerationTimeoutMS             = 1000
                    MaxPacketRetrievalTimeSeconds    = 1
                    AllowUnencrypted                 = $false
                    AuthBasic                        = $false
                    AuthKerberos                     = $true
                    AuthNegotiate                    = $true
                    AuthCertificate                  = $true
                    AuthCredSSP                      = $false
                    AuthCbtHardeningLevel            = 'Strict'
                    EnableCompatibilityHttpListener  = $false
                    EnableCompatibilityHttpsListener = $false
                }
                @{
                    MaxPacketRetrievalTimeSeconds    = 1
                    AllowUnencrypted                 = $false
                    AuthBasic                        = $false
                    AuthKerberos                     = $true
                    AuthNegotiate                    = $true
                    AuthCertificate                  = $true
                    AuthCredSSP                      = $false
                    AuthCbtHardeningLevel            = 'Strict'
                    EnableCompatibilityHttpListener  = $false
                    EnableCompatibilityHttpsListener = $false
                }
            )
        }

        It 'Should not throw an error' -ForEach $testCases {
            InModuleScope -Parameters @{
                mockProperties = $_
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $mockInstance.AssertProperties($mockProperties) } | Should -Not -Throw
            }
        }
    }
}
