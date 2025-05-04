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

Describe 'Get-Listener' -Tag 'Private' {
    Context 'When the listener exists' {
        BeforeAll {
            Mock -CommandName Get-WSManInstance -MockWith {
                @{
                    Transport = 'HTTP'
                    Port      = 5985
                    Source    = 'Compatibility'
                }
                @{
                    Transport = 'HTTPS'
                    Port      = 5986
                    Source    = 'Compatibility'
                }
                @{
                    Transport = 'HTTP'
                    Port      = 5985
                    Source    = 'NotCompatibility'
                }
                @{
                    Transport = 'HTTPS'
                    Port      = 5986
                    Source    = 'NotCompatibility'
                }
            }
        }

        BeforeDiscovery {
            $testCases = @(
                @{
                    Transport    = 'HTTP'
                    ExpectedPort = 5985
                }
                @{
                    Transport    = 'HTTPS'
                    ExpectedPort = 5986
                }
            )
        }

        It 'Should return a listener for ''<Transport>''' -ForEach $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-Listener -Transport $Transport

                $result.Transport | Should -Be $Transport
                $result.Port | Should -Be $ExpectedPort
            }

            Should -Invoke -CommandName Get-WSManInstance -Exactly -Times 1
        }
    }

    Context 'When the listener does not exist' {
        BeforeAll {
            Mock -CommandName Get-WSManInstance -MockWith {
                @{
                    Transport = 'HTTP'
                    Port      = 5985
                    Source    = 'NotCompatibility'
                }
                @{
                    Transport = 'HTTPS'
                    Port      = 5986
                    Source    = 'NotCompatibility'
                }
            }
        }

        BeforeDiscovery {
            $testCases = @(
                @{
                    Transport    = 'HTTP'
                    ExpectedPort = 5985
                }
                @{
                    Transport    = 'HTTPS'
                    ExpectedPort = 5986
                }
            )
        }

        It 'Should return a listener for ''<Transport>''' -ForEach $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-Listener -Transport $Transport

                $result | Should -HaveCount 1
                $result | Should -BeOfType System.Collections.Hashtable
            }

            Should -Invoke -CommandName Get-WSManInstance -Exactly -Times 1
        }
    }
}
