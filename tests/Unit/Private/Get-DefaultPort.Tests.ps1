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

Describe 'Get-DefaultPort' -Tag 'Private' {
    Context 'When a port is not provided' {
        BeforeDiscovery {
            $testCases = @(
                @{
                    Transport     = 'HTTP'
                    ExpectedValue = 5985
                }
                @{
                    Transport     = 'HTTPS'
                    ExpectedValue = 5986
                }
            )
        }

        It 'Should return ''<ExpectedValue>'' for ''<Transport>'' transport' -ForEach $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParams = @{
                    Transport = $Transport
                }

                $result = Get-DefaultPort @mockParams

                $result | Should -Be $ExpectedValue
                $result | Should -BeOfType System.UInt16
            }
        }
    }

    Context 'When a port is provided' {
        BeforeDiscovery {
            $testCases = @(
                @{
                    Transport     = 'HTTP'
                    Port          = 1000
                }
                @{
                    Transport     = 'HTTPS'
                    Port          = 2000
                }
            )
        }

        It 'Should return ''<Port>'' for ''<Transport>'' transport' -ForEach $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParams = @{
                    Transport = $Transport
                    Port      = $Port
                }

                $result = Get-DefaultPort @mockParams

                $result | Should -Be $Port
                $result | Should -BeOfType System.UInt16
            }
        }
    }

    Context 'When Transport is not ''HTTP'' or ''HTTPS''' {
        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParams = @{
                    Transport = $null
                    Port      = 9999
                }

                { Get-DefaultPort @mockParams } | Should -Throw
            }
        }
    }

    Context 'When Port is not valid' {
        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParams = @{
                    Transport = 'HTTP'
                    Port      = 'Something'
                }

                { Get-DefaultPort @mockParams } | Should -Not -Throw
            }
        }
    }
}
