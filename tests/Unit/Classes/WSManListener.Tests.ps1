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

                    $script:mockInstance = [WSManListener] @{
                        Transport = 'HTTP'
                        Ensure    = 'Present'
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
                                Transport = [WSManTransport] 'HTTP'
                                Port      = [System.UInt16] 5985
                                Address   = '*'
                                Enabled   = 'true'
                                URLPrefix = 'wsman'
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

                    $currentState = $script:mockInstance.Get()

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

                    $script:mockInstance = [WSManListener] @{
                        Transport = 'HTTPS'
                        Ensure    = 'Present'
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
                                Transport = [WSManTransport] 'HTTPS'
                                Port      = [System.UInt16] 5986
                                Address   = '*'
                                Enabled   = 'true'
                                URLPrefix = 'wsman'
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

                    $currentState = $script:mockInstance.Get()

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

                    $script:mockInstance = [WSManListener] @{
                        Transport = 'HTTP'
                        Ensure    = 'Absent'
                    }

                    <#
                        This mocks the method GetCurrentState().

                        Method Get() will call the base method Get() which will
                        call back to the derived class method GetCurrentState()
                        to get the result to return from the derived method Get().
                    #>
                    $script:mockInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return @{}
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        }
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $currentState = $script:mockInstance.Get()

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

                    # PS6+ treats empty enum as null
                    if ($PSVersionTable.PSVersion.Major -gt 5)
                    {
                        $currentState.Reasons[0].Phrase | Should -Be 'The property Transport should be "HTTP", but was null'
                    }
                    else
                    {
                        $currentState.Reasons[0].Phrase | Should -Be 'The property Transport should be "HTTP", but was ""'
                    }
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When property ''Port'' has the wrong value' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockInstance = [WSManListener] @{
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
                    $script:mockInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return @{
                                Transport = [WSManTransport] 'HTTPS'
                                Port      = [System.UInt16] 6000
                                Address   = '*'
                                Enabled   = 'true'
                                URLPrefix = 'wsman'
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

                    $currentState = $script:mockInstance.Get()

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

        Context 'When the listener exists but should not' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockInstance = [WSManListener] @{
                        Transport = 'HTTP'
                        Ensure    = 'Absent'
                    }

                    <#
                        This mocks the method GetCurrentState().

                        Method Get() will call the base method Get() which will
                        call back to the derived class method GetCurrentState()
                        to get the result to return from the derived method Get().
                    #>
                    $script:mockInstance |
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

                    $currentState = $script:mockInstance.Get()

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

Describe 'WSManListener\Set()' -Tag 'Set' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $script:mockInstance = [WSManListener] @{
                Transport = 'HTTP'
                Port      = 5000
                Ensure    = 'Present'
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

            $script:methodModifyCallCount = 0
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance |
                    # Mock method Compare() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                        return $null
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                        return
                    }
            }
        }

        It 'Should not call method Modify()' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance.Set()

                $script:methodModifyCallCount | Should -Be 0
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance |
                    # Mock method Compare() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                        return @(
                            @{
                                Property      = 'Port'
                                ExpectedValue = 5000
                                ActualValue   = 5985
                            }
                        )
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                        return
                    }
            }
        }

        It 'Should call method Modify()' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance.Set()

                $script:methodModifyCallCount | Should -Be 1
            }
        }
    }
}

Describe 'WSManListener\Test()' -Tag 'Test' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $script:mockInstance = [WSManListener] @{
                Transport             = 'HTTPS'
                Port                  = 5986
                CertificateThumbprint = '74FA31ADEA7FDD5333CED10910BFA6F665A1F2FC'
                Hostname              = $([System.Net.Dns]::GetHostByName($ENV:computerName).Hostname)
                Ensure                = 'Present'
            }
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance |
                    # Mock method Compare() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                        return $null
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                        return
                    }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockInstance.Test() | Should -BeTrue
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance |
                    # Mock method Compare() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                        return @(
                            @{
                                Property      = 'Port'
                                ExpectedValue = 5986
                                ActualValue   = 443
                            })
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                        return
                    }
            }
        }

        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance.Test() | Should -BeFalse
            }
        }
    }
}

Describe 'WSManListener\GetCurrentState()' -Tag 'HiddenMember' {
    Context 'When object is missing in the current state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance = [WSManListener] @{
                    Transport = 'HTTP'
                    Port      = 5985
                    Address   = '*'
                    Ensure    = 'Present'
                }
            }

            Mock -CommandName Get-Listener
        }

        It 'Should return the correct values' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $currentState = $script:mockInstance.GetCurrentState(
                    @{
                        Transport = 'HTTP'
                        Ensure    = [Ensure]::Present
                    }
                )

                $currentState.Transport | Should -BeNullOrEmpty
                $currentState.Port | Should -BeNullOrEmpty
                $currentState.Address | Should -BeNullOrEmpty
                $currentState.Issuer | Should -BeNullOrEmpty
                $currentState.CertificateThumbprint | Should -BeNullOrEmpty
                $currentState.Hostname | Should -BeNullOrEmpty
                $currentState.Enabled | Should -BeFalse
                $currentState.URLPrefix | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Get-Listener -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the object is present in the current state' {
        Context 'When ''Port'' and ''Address'' are supplied for HTTP Transport' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockInstance = [WSManListener] @{
                        Transport = 'HTTP'
                        Port      = 5985
                        Address   = '*'
                        Ensure    = 'Present'
                    }
                }

                Mock -CommandName Get-Listener -MockWith {
                    return @{
                        Transport             = 'HTTP'
                        Port                  = [System.UInt16] 5985
                        Address               = '*'

                        CertificateThumbprint = $null
                        Hostname              = $([System.Net.Dns]::GetHostByName($ENV:computerName).Hostname)

                        Enabled               = $true
                        URLPrefix             = 'wsman'
                    }
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $currentState = $script:mockInstance.GetCurrentState(
                        @{
                            Transport = 'HTTP'
                            Ensure    = [Ensure]::Present
                        }
                    )

                    $currentState.Transport | Should -Be 'HTTP'
                    $currentState.Port | Should -Be 5985
                    $currentState.Address | Should -Be '*'
                    $currentState.Issuer | Should -BeNullOrEmpty
                    $currentState.CertificateThumbprint | Should -BeNullOrEmpty
                    $currentState.Hostname | Should -Be $([System.Net.Dns]::GetHostByName($ENV:computerName).Hostname)
                    $currentState.Enabled | Should -BeTrue
                    $currentState.URLPrefix | Should -Be 'wsman'
                }

                Should -Invoke -CommandName Get-Listener -Exactly -Times 1 -Scope It
            }
        }

        Context 'When ''Port'' and ''Address'' are not supplied for HTTP Transport' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockInstance = [WSManListener] @{
                        Transport = 'HTTP'
                        Ensure    = 'Present'
                    }
                }

                Mock -CommandName Get-Listener -MockWith {
                    return @{
                        Transport             = 'HTTP'
                        Port                  = [System.UInt16] 5985
                        Address               = '*'

                        CertificateThumbprint = $null
                        Hostname              = $([System.Net.Dns]::GetHostByName($ENV:computerName).Hostname)

                        Enabled               = $true
                        URLPrefix             = 'wsman'
                    }
                }

                Mock -CommandName Get-DefaultPort -MockWith { return [System.UInt16] 5985 }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $currentState = $script:mockInstance.GetCurrentState(
                        @{
                            Transport = 'HTTP'
                            Ensure    = [Ensure]::Present
                        }
                    )

                    $currentState.Transport | Should -Be 'HTTP'
                    $currentState.Port | Should -Be 5985
                    $currentState.Address | Should -Be '*'
                    $currentState.Issuer | Should -BeNullOrEmpty
                    $currentState.CertificateThumbprint | Should -BeNullOrEmpty
                    $currentState.Hostname | Should -Be $([System.Net.Dns]::GetHostByName($ENV:computerName).Hostname)
                    $currentState.Enabled | Should -BeTrue
                    $currentState.URLPrefix | Should -Be 'wsman'
                }

                Should -Invoke -CommandName Get-Listener -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-DefaultPort -Exactly -Times 1 -Scope It
            }
        }

        Context 'When ''Port'' and ''Address'' are supplied for HTTPS Transport' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockInstance = [WSManListener] @{
                        Transport = 'HTTPS'
                        Port      = 5986
                        Address   = '*'
                        Ensure    = 'Present'
                    }
                }

                Mock -CommandName Get-Listener -MockWith {
                    return @{
                        Transport             = 'HTTPS'
                        Port                  = [System.UInt16] 5986
                        Address               = '*'

                        CertificateThumbprint = '74FA31ADEA7FDD5333CED10910BFA6F665A1F2FC'
                        Hostname              = $([System.Net.Dns]::GetHostByName($ENV:computerName).Hostname)

                        Enabled               = $true
                        URLPrefix             = 'wsman'
                    }
                }

                Mock -CommandName Find-Certificate -MockWith { return @{ Issuer = 'CN=CONTOSO.COM Issuing CA, DC=CONTOSO, DC=COM' } }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $currentState = $script:mockInstance.GetCurrentState(
                        @{
                            Transport = 'HTTPS'
                            Ensure    = [Ensure]::Present
                        }
                    )

                    $currentState.Transport | Should -Be 'HTTPS'
                    $currentState.Port | Should -Be 5986
                    $currentState.Address | Should -Be '*'
                    $currentState.Issuer | Should -Be 'CN=CONTOSO.COM Issuing CA, DC=CONTOSO, DC=COM'
                    $currentState.CertificateThumbprint | Should -Be '74FA31ADEA7FDD5333CED10910BFA6F665A1F2FC'
                    $currentState.Hostname | Should -Be $([System.Net.Dns]::GetHostByName($ENV:computerName).Hostname)
                    $currentState.Enabled | Should -BeTrue
                    $currentState.URLPrefix | Should -Be 'wsman'
                }

                Should -Invoke -CommandName Get-Listener -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Find-Certificate -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'WSManListener\Modify()' -Tag 'HiddenMember' {
    Context 'When the system is not in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance = [WSManListener] @{
                    Transport = 'HTTP'
                    Ensure    = 'Present'
                } |
                    # Mock method NewInstance which is called by the case method Modify().
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'NewInstance' -Value {
                        $script:methodNewInstanceCallCount += 1
                    } -PassThru |
                    # Mock method RemoveInstance which is called by the case method Modify().
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'RemoveInstance' -Value {
                        $script:methodRemoveInstanceCallCount += 1
                    } -PassThru |
                    # Mock method SetInstance which is called by the case method Modify().
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'SetInstance' -Value {
                        $script:methodSetInstanceCallCount += 1
                    } -PassThru
            }
        }

        BeforeEach {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:methodNewInstanceCallCount = 0
                $script:methodRemoveInstanceCallCount = 0
                $script:methodSetInstanceCallCount = 0
            }
        }

        Context 'When the resource does not exist' {
            It 'Should call method NewInstance()' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockProperties = @{
                        Transport = 'HTTP'
                        Ensure    = 'Present'
                    }

                    $script:mockInstance.Modify($mockProperties)

                    $script:methodNewInstanceCallCount | Should -Be 1
                }
            }
        }

        Context 'When the resource does exist' {
            It 'Should call method RemoveInstance()' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockInstance.Ensure = 'Absent'

                    $mockProperties = @{
                        Transport = 'HTTP'
                        Ensure    = 'Absent'
                    }

                    $script:mockInstance.Modify($mockProperties)

                    $script:methodRemoveInstanceCallCount | Should -Be 1
                }
            }
        }

        Context 'When the resource does exist but properties are incorrect' {
            It 'Should call method SetInstance()' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockInstance.Ensure = 'Absent'

                    $mockProperties = @{
                        Transport = 'HTTP'
                        Port      = 5000
                    }

                    $script:mockInstance.Modify($mockProperties)

                    $script:methodSetInstanceCallCount | Should -Be 1
                }
            }
        }
    }
}

Describe 'WSManListener\NewInstance()' -Tag 'HiddenMember' {
    BeforeAll {
        Mock -CommandName New-WSManInstance
    }

    Context 'When creating a HTTP Transport' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance = [WSManListener] @{
                    Transport = 'HTTP'
                    Port      = 5985
                    Address   = '*'
                    Ensure    = 'Present'
                }
            }
        }

        It 'Should call the correct mock' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance.NewInstance()
            }

            Should -Invoke -CommandName New-WSManInstance -Exactly -Times 1 -Scope It
        }
    }

    Context 'When creating a HTTPS Transport' {
        BeforeAll {
            Mock -CommandName Get-DscProperty
        }

        BeforeEach {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance = [WSManListener] @{
                    Transport = 'HTTPS'
                    Port      = 5986
                    Address   = '*'
                    Ensure    = 'Present'
                }
            }
        }

        Context 'When the certificate thumbprint exists' {
            BeforeAll {
                Mock -CommandName Find-Certificate -MockWith {
                    @{ Thumbprint = '74FA31ADEA7FDD5333CED10910BFA6F665A1F2FC' }
                }
            }

            Context 'When the hostname is provided' {
                It 'Should call the correct mocks' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockInstance.HostName = 'somehost'

                        $script:mockInstance.NewInstance()
                    }

                    Should -Invoke -CommandName Get-DscProperty -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Find-Certificate -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName New-WSManInstance -ParameterFilter {
                        $ValueSet.HostName -eq 'somehost'
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the hostname is not provided' {
                It 'Should call the correct mock' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockInstance.NewInstance()
                    }

                    Should -Invoke -CommandName Get-DscProperty -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Find-Certificate -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName New-WSManInstance -ParameterFilter {
                        $ValueSet.HostName -eq [System.Net.Dns]::GetHostByName($env:COMPUTERNAME).Hostname
                    } -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When the certificate thumbprint does not exist' {
            BeforeAll {
                Mock -CommandName Find-Certificate
            }

            It 'Should throw the correct exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockErrorMessage = Get-InvalidArgumentRecord -Message (
                        $script:mockInstance.localizedData.ListenerCreateFailNoCertError -f $script:mockInstance.Transport, $script:mockInstance.Port
                    ) -Argument 'Issuer'

                    { $script:mockInstance.NewInstance() } | Should -Throw -ExpectedMessage $mockErrorMessage.Exception.Message
                }

                Should -Invoke -CommandName New-WSManInstance -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Get-DscProperty -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Find-Certificate -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'WSManListener\RemoveInstance()' -Tag 'HiddenMember' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $script:mockInstance = [WSManListener] @{
                Transport = 'HTTPS'
                Port      = 5986
                Address   = '*'
                Ensure    = 'Present'
            }
        }

        Mock -CommandName Remove-WSManInstance
    }

    It 'Should call the correct mock' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $script:mockInstance.RemoveInstance()
        }

        Should -Invoke -CommandName Remove-WSManInstance -Exactly -Times 1 -Scope It
    }
}

#Describe 'WSManListener\SetInstance()' -Tag 'HiddenMember' {}
