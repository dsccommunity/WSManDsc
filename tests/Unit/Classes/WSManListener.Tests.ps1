<#
    .SYNOPSIS
        Unit test for DSC_WSManListener DSC resource.
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

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '../../TestHelpers/CommonTestHelper.psm1')

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

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}

Describe 'WSManListener' {
    Context 'When class is instantiated' {
        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { [WSManListener]::new() } | Should -Not -Throw
            }
        }

        It 'Should have a default or empty constructor' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $instance = [WSManListener]::new()
                $instance | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should be the correct type' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $instance = [WSManListener]::new()
                $instance.GetType().Name | Should -Be 'WSManListener'
            }
        }
    }
}

Describe 'WSManListener\Get()' -Tag 'Get' {
    Context 'When the system is in the desired state' {
        Context 'When getting a HTTP listener' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockWSManListenerInstance = [WSManListener] @{
                        Transport = 'HTTP'
                        Ensure    = 'Present'
                    }

                    <#
                        This mocks the method GetCurrentState().

                        Method Get() will call the base method Get() which will
                        call back to the derived class method GetCurrentState()
                        to get the result to return from the derived method Get().
                    #>
                    $script:mockWSManListenerInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Transport             = [WSManTransport] 'HTTP'
                                Port                  = [System.UInt16] 5985
                                Address               = '*'
                                Enabled               = 'true'
                                URLPrefix             = 'wsman'
                            }
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        }
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $currentState = $script:mockWSManListenerInstance.Get()

                    $currentState.Transport | Should -Be 'HTTP'
                    $currentState.Port | Should -Be 5985
                    $currentState.Port | Should -BeOfType System.UInt16
                    $currentState.Address | Should -Be '*'

                    $currentState.Enabled | Should -BeTrue
                    $currentState.URLPrefix | Should -Be 'wsman'

                    $currentState.Issuer | Should -BeNullOrEmpty
                    $currentState.SubjectFormat | Should -Be 'Both'
                    $currentState.MatchAlternate | Should -BeNullOrEmpty
                    $currentState.BaseDN | Should -BeNullOrEmpty
                    $currentState.CertificateThumbprint | Should -BeNullOrEmpty
                    $currentState.Hostname | Should -BeNullOrEmpty

                    $currentState.Ensure | Should -Be 'Present'
                    $currentState.Reasons | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When getting a HTTPS listener' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockWSManListenerInstance = [WSManListener] @{
                        Transport = 'HTTPS'
                        Ensure    = 'Present'
                    }

                    <#
                        This mocks the method GetCurrentState().

                        Method Get() will call the base method Get() which will
                        call back to the derived class method GetCurrentState()
                        to get the result to return from the derived method Get().
                    #>
                    $script:mockWSManListenerInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Transport             = [WSManTransport] 'HTTPS'
                                Port                  = [System.UInt16] 5986
                                Address               = '*'
                                Enabled               = 'true'
                                URLPrefix             = 'wsman'
                            }
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        }
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $currentState = $script:mockWSManListenerInstance.Get()

                    $currentState.Transport | Should -Be 'HTTPS'
                    $currentState.Port | Should -Be 5986
                    $currentState.Port | Should -BeOfType System.UInt16
                    $currentState.Address | Should -Be '*'
                    $currentState.Enabled | Should -BeTrue
                    $currentState.URLPrefix | Should -Be 'wsman'

                    $currentState.Issuer | Should -BeNullOrEmpty
                    $currentState.SubjectFormat | Should -Be 'Both'
                    $currentState.MatchAlternate | Should -BeNullOrEmpty
                    $currentState.BaseDN | Should -BeNullOrEmpty
                    $currentState.CertificateThumbprint | Should -BeNullOrEmpty
                    $currentState.Hostname | Should -BeNullOrEmpty

                    $currentState.Ensure | Should -Be 'Present'
                    $currentState.Reasons | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When no listener should exist' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockWSManListenerInstance = [WSManListener] @{
                        Transport = 'HTTP'
                        Ensure    = 'Absent'
                    }

                    <#
                        This mocks the method GetCurrentState().

                        Method Get() will call the base method Get() which will
                        call back to the derived class method GetCurrentState()
                        to get the result to return from the derived method Get().
                    #>
                    $script:mockWSManListenerInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{}
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        }
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $currentState = $script:mockWSManListenerInstance.Get()

                    $currentState.Transport | Should -Be 'HTTP'
                    $currentState.Port | Should -BeNullOrEmpty
                    $currentState.Address | Should -BeNullOrEmpty

                    $currentState.Enabled | Should -BeFalse
                    $currentState.URLPrefix | Should -BeNullOrEmpty

                    $currentState.Issuer | Should -BeNullOrEmpty
                    $currentState.SubjectFormat | Should -Be 'Both'
                    $currentState.MatchAlternate | Should -BeNullOrEmpty
                    $currentState.BaseDN | Should -BeNullOrEmpty
                    $currentState.CertificateThumbprint | Should -BeNullOrEmpty
                    $currentState.Hostname | Should -BeNullOrEmpty

                    $currentState.Ensure | Should -Be 'Absent'
                    $currentState.Reasons | Should -HaveCount 1
                    $currentState.Reasons[0].Code | Should -Be 'WSManListener:WSManListener:Transport'
                    $currentState.Reasons[0].Phrase | Should -Be 'The property Transport should be "HTTP", but was null'
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When property ''Port'' has the wrong value' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockWSManListenerInstance = [WSManListener] @{
                        Transport = 'HTTPS'
                        Port      = 5986
                        Ensure    = 'Present'
                    }

                    <#
                        This mocks the method GetCurrentState().

                        Method Get() will call the base method Get() which will
                        call back to the derived class method GetCurrentState()
                        to get the result to return from the derived method Get().
                    #>
                    $script:mockWSManListenerInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Transport             = [WSManTransport] 'HTTPS'
                                Port                  = [System.UInt16] 6000
                                Address               = '*'
                                Enabled               = 'true'
                                URLPrefix             = 'wsman'
                            }
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        }
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $currentState = $script:mockWSManListenerInstance.Get()

                    $currentState.Transport | Should -Be 'HTTPS'

                    $currentState.Port | Should -Be 6000
                    $currentState.Port | Should -BeOfType System.UInt16

                    $currentState.Address | Should -Be '*'
                    $currentState.Enabled | Should -Be $true
                    $currentState.URLPrefix | Should -Be 'wsman'

                    $currentState.Issuer | Should -BeNullOrEmpty
                    $currentState.SubjectFormat | Should -Be 'Both'
                    $currentState.MatchAlternate | Should -BeNullOrEmpty
                    $currentState.BaseDN | Should -BeNullOrEmpty
                    $currentState.CertificateThumbprint | Should -BeNullOrEmpty
                    $currentState.Hostname | Should -BeNullOrEmpty

                    $currentState.Ensure | Should -Be 'Present'

                    $currentState.Reasons | Should -HaveCount 1
                    $currentState.Reasons[0].Code | Should -Be 'WSManListener:WSManListener:Port'
                    $currentState.Reasons[0].Phrase | Should -Be 'The property Port should be 5986, but was 6000'
                }
            }
        }

        Context 'When the listener exists' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockWSManListenerInstance = [WSManListener] @{
                        Transport = 'HTTPS'
                        Ensure    = 'Present'
                    }

                    <#
                        This mocks the method GetCurrentState().

                        Method Get() will call the base method Get() which will
                        call back to the derived class method GetCurrentState()
                        to get the result to return from the derived method Get().
                    #>
                    $script:mockWSManListenerInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{}
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        }
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $currentState = $script:mockWSManListenerInstance.Get()

                    $currentState.Transport | Should -Be 'HTTPS'
                    $currentState.Port | Should -BeNullOrEmpty

                    $currentState.Address | Should -BeNullOrEmpty
                    $currentState.Enabled | Should -BeFalse
                    $currentState.URLPrefix | Should -BeNullOrEmpty

                    $currentState.Issuer | Should -BeNullOrEmpty
                    $currentState.SubjectFormat | Should -Be 'Both'
                    $currentState.MatchAlternate | Should -BeNullOrEmpty
                    $currentState.BaseDN | Should -BeNullOrEmpty
                    $currentState.CertificateThumbprint | Should -BeNullOrEmpty
                    $currentState.Hostname | Should -BeNullOrEmpty

                    $currentState.Ensure | Should -Be 'Absent'

                    $currentState.Reasons | Should -HaveCount 2
                    $currentState.Reasons[0].Code | Should -Be 'WSManListener:WSManListener:Ensure'
                    $currentState.Reasons[0].Phrase | Should -Be 'The property Ensure should be "Present", but was "Absent"'
                    $currentState.Reasons[1].Code | Should -Be 'WSManListener:WSManListener:Transport'
                    $currentState.Reasons[1].Phrase | Should -Be 'The property Transport should be "HTTPS", but was null'
                }
            }
        }

        Context 'When the listener exists but should not' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockWSManListenerInstance = [WSManListener] @{
                        Transport = 'HTTP'
                        Ensure    = 'Absent'
                    }

                    <#
                        This mocks the method GetCurrentState().

                        Method Get() will call the base method Get() which will
                        call back to the derived class method GetCurrentState()
                        to get the result to return from the derived method Get().
                    #>
                    $script:mockWSManListenerInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Transport             = [WSManTransport] 'HTTP'
                                Port                  = [System.UInt16] 5985
                                Address               = '*'
                                Enabled               = 'true'
                                URLPrefix             = 'wsman'
                                Issuer                = $null
                                MatchAlternate        = $null
                                BaseDN                = $null
                                CertificateThumbprint = $null
                                Hostname              = $null
                            }
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        }
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $currentState = $script:mockWSManListenerInstance.Get()

                    $currentState.Transport | Should -Be 'HTTP'
                    $currentState.Port | Should -Be 5985

                    $currentState.Address | Should -Be '*'
                    $currentState.Enabled | Should -BeTrue
                    $currentState.URLPrefix | Should -Be 'wsman'

                    $currentState.Issuer | Should -BeNullOrEmpty
                    $currentState.SubjectFormat | Should -Be 'Both'
                    $currentState.MatchAlternate | Should -BeNullOrEmpty
                    $currentState.BaseDN | Should -BeNullOrEmpty
                    $currentState.CertificateThumbprint | Should -BeNullOrEmpty
                    $currentState.Hostname | Should -BeNullOrEmpty

                    $currentState.Ensure | Should -Be 'Present'

                    $currentState.Reasons | Should -HaveCount 1
                    $currentState.Reasons[0].Code | Should -Be 'WSManListener:WSManListener:Ensure'
                    $currentState.Reasons[0].Phrase | Should -Be 'The property Ensure should be "Absent", but was "Present"'
                }
            }
        }
    }
}
