<#
    .SYNOPSIS
        Unit test for WSManClientConfig DSC resource.
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

Describe 'WSManClientConfig' {
    Context 'When class is instantiated' {
        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { [WSManClientConfig]::new() } | Should -Not -Throw
            }
        }

        It 'Should have a default or empty constructor' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $instance = [WSManClientConfig]::new()
                $instance | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should be the correct type' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $instance = [WSManClientConfig]::new()
                $instance.GetType().Name | Should -Be 'WSManClientConfig'
            }
        }
    }
}

Describe 'WSManClientConfig\Get()' -Tag 'Get' {
    Context 'When the system is in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance = [WSManClientConfig] @{
                    IsSingleInstance = 'Yes'
                    NetworkDelayms   = 5000
                    URLPrefix        = 'wsmclient'
                    AllowUnencrypted = $false
                    TrustedHosts     = @()
                    AuthBasic        = $false
                    AuthDigest       = $false
                    AuthCertificate  = $true
                    AuthKerberos     = $true
                    AuthNegotiate    = $true
                    AuthCredSSP      = $false
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
                            NetworkDelayms   = [System.UInt32] 5000
                            URLPrefix        = 'wsmclient'
                            AllowUnencrypted = $false
                            TrustedHosts     = [System.String[]] @()
                            AuthBasic        = $false
                            AuthDigest       = $false
                            AuthCertificate  = $true
                            AuthKerberos     = $true
                            AuthNegotiate    = $true
                            AuthCredSSP      = $false
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

                $currentState.NetworkDelayms | Should -Be 5000
                $currentState.NetworkDelayms | Should -BeOfType System.UInt32

                $currentState.URLPrefix | Should -Be 'wsmclient'
                $currentState.URLPrefix | Should -BeOfType System.String

                $currentState.TrustedHosts | Should -BeNullOrEmpty

                $currentState.AuthBasic | Should -BeFalse
                $currentState.AuthBasic | Should -BeOfType System.Boolean

                $currentState.AuthDigest | Should -BeFalse
                $currentState.AuthDigest | Should -BeOfType System.Boolean

                $currentState.AuthKerberos | Should -BeTrue
                $currentState.AuthKerberos | Should -BeOfType System.Boolean

                $currentState.AuthNegotiate | Should -BeTrue
                $currentState.AuthNegotiate | Should -BeOfType System.Boolean

                $currentState.AuthCertificate | Should -BeTrue
                $currentState.AuthCertificate | Should -BeOfType System.Boolean

                $currentState.AuthCredSSP | Should -BeFalse
                $currentState.AuthCredSSP | Should -BeOfType System.Boolean

                $currentState.Reasons | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When property ''MaxConnections'' has the wrong value' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockInstance = [WSManClientConfig] @{
                        IsSingleInstance = 'Yes'
                        URLPrefix        = 'wsmclient'
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
                                URLPrefix        = 'wsmclient4'
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

                    $currentState.URLPrefix | Should -Be 'wsmclient4'
                    $currentState.URLPrefix | Should -BeOfType System.String

                    $currentState.Reasons | Should -HaveCount 1
                    $currentState.Reasons[0].Code | Should -Be 'WSManClientConfig:WSManClientConfig:URLPrefix'
                    $currentState.Reasons[0].Phrase | Should -Be 'The property URLPrefix should be "wsmclient", but was "wsmclient4"'
                }
            }
        }
    }
}

Describe 'WSManClientConfig\Set()' -Tag 'Set' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $script:mockInstance = [WSManClientConfig] @{
                IsSingleInstance = 'Yes'
                NetworkDelayms   = 5000
                URLPrefix        = 'wsmclient'
                AllowUnencrypted = $false
                TrustedHosts     = @()
                AuthBasic        = $false
                AuthDigest       = $false
                AuthCertificate  = $true
                AuthKerberos     = $true
                AuthNegotiate    = $true
                AuthCredSSP      = $false
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

                $null = $script:mockInstance.Set()

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
                        Property      = 'AuthKerberos'
                        ExpectedValue = $true
                        ActualValue   = $false
                    }
                )
            }
        }

        It 'Should call method Modify()' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $null = $script:mockInstance.Set()

                $script:methodTestCallCount | Should -Be 1
                $script:methodModifyCallCount | Should -Be 1
            }
        }
    }
}

Describe 'WSManClientConfig\Test()' -Tag 'Test' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $script:mockInstance = [WSManClientConfig] @{
                IsSingleInstance = 'Yes'
                NetworkDelayms   = 5000
                URLPrefix        = 'wsmclient'
                AllowUnencrypted = $false
                TrustedHosts     = @()
                AuthBasic        = $false
                AuthDigest       = $false
                AuthCertificate  = $true
                AuthKerberos     = $true
                AuthNegotiate    = $true
                AuthCredSSP      = $false
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
        }

        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance.Test() | Should -BeTrue

                $script:getMethodCallCount | Should -Be 1
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
                        Property      = 'AuthCredSSP'
                        ExpectedValue = $false
                        ActualValue   = $true
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

Describe 'WSManClientConfig\AssertProperties()' -Tag 'AssertProperties' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $script:mockInstance = [WSManClientConfig] @{}
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

                {
                    $mockInstance.AssertProperties($mockProperties)
                 } | Should -Throw -ExpectedMessage ('*' + 'DRC0050' + '*')
            }
        }
    }

    Context 'When passing required parameters' {
        BeforeDiscovery {
            $testCases = @(
                @{
                    URLPrefix        = 'wsmclient'
                    NetworkDelayms   = 5000
                    AllowUnencrypted = $false
                    TrustedHosts     = @()
                    AuthBasic        = $false
                    AuthDigest       = $false
                    AuthCertificate  = $true
                    AuthKerberos     = $true
                    AuthNegotiate    = $true
                    AuthCredSSP      = $false
                }
                @{
                    NetworkDelayms   = 5000
                    AllowUnencrypted = $false
                    TrustedHosts     = @()
                    AuthBasic        = $false
                    AuthDigest       = $false
                    AuthCertificate  = $true
                    AuthKerberos     = $true
                    AuthNegotiate    = $true
                    AuthCredSSP      = $false
                }
                @{
                    TrustedHosts     = @()
                    AuthBasic       = $false
                    AuthDigest      = $false
                    AuthCertificate = $true
                    AuthKerberos    = $true
                    AuthNegotiate   = $true
                    AuthCredSSP     = $false
                }
                @{
                    AuthBasic       = $false
                    AuthDigest      = $false
                    AuthCertificate = $true
                    AuthKerberos    = $true
                    AuthNegotiate   = $true
                    AuthCredSSP     = $false
                }
                @{
                    AuthDigest      = $false
                    AuthCertificate = $true
                    AuthKerberos    = $true
                    AuthNegotiate   = $true
                    AuthCredSSP     = $false
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
