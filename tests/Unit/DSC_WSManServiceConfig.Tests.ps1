<#
    .SYNOPSIS
        Unit test for DSC_WSManServiceConfig DSC resource.

    .NOTES
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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # This will throw an error if the dependencies have not been resolved.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }

    # Data To Generate Tests
    $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

    # Load the parameter List from the data file
    $resourceData = Import-LocalizedData `
        -BaseDirectory (Join-Path -Path $script:moduleRoot -ChildPath 'Source\DscResources\DSC_WSManServiceConfig') `
        -FileName 'DSC_WSManServiceConfig.data.psd1'

    $script:parameterList = $resourceData.ParameterList

    $script:dscResourceName = 'DSC_WSManServiceConfig'
}

BeforeAll {
    $script:dscModuleName = 'WSManDsc'
    $script:dscResourceName = 'DSC_WSManServiceConfig'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName

    # Test Data
    InModuleScope -ScriptBlock {
        # Create the Mock Objects that will be used for running tests
        $script:wsManServiceConfigSettings = @{}
        $script:wsManServiceConfigSplat = @{
            IsSingleInstance = 'Yes'
            Verbose          = $VerbosePreference
        }
    }
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}

Describe "$($script:dscResourceName)\Get-TargetResource" -Tag 'Get' {
    Context 'When WS-Man Service Config Exists for <Name>' -ForEach $parameterList {
        BeforeAll {
            Mock -CommandName Get-Item `
                -MockWith {
                @{
                    Value = $Default
                }
            }
        }

        It 'Should return current WS-Man Service Config values' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTargetResourceParameters = $wsManServiceConfigSettings.Clone()
                $getTargetResourceParameters[$Name] = $Default

                $result = Get-TargetResource -IsSingleInstance 'Yes'
                $result[$Name] | Should -Be $getTargetResourceParameters[$Name]
            }
        }

        It 'Should call the expected mocks' {
            $parameterPath = Join-Path `
                -Path 'WSMan:\Localhost\Service\' `
                -ChildPath $Path

            Should -Invoke `
                -CommandName Get-Item `
                -ParameterFilter {
                $Path -eq $parameterPath
            } -Exactly -Times 1 `
                -Scope Context
        }
    }
}

Describe "$($script:dscResourceName)\Set-TargetResource" -Tag 'Set' {
    Context 'When WS-Man Service Config parameter <Name> is the same' -ForEach $parameterList {
        BeforeAll {
            Mock -CommandName Get-Item `
                -MockWith {
                @{
                    Value = $Default
                }
            }
            Mock `
                -CommandName Set-Item
        }

        It 'Should not throw error' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                {
                    $setTargetResourceParameters = $wsManServiceConfigSplat.Clone()
                    $setTargetResourceParameters[$Name] = $Default
                    Set-TargetResource @setTargetResourceParameters
                } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            $parameterPath = Join-Path `
                -Path 'WSMan:\Localhost\Service\' `
                -ChildPath $Path

            Should -Invoke `
                -CommandName Get-Item `
                -ParameterFilter {
                $Path -eq $parameterPath
            } -Exactly -Times 1 `
                -Scope Context

            Should -Invoke `
                -CommandName Set-Item `
                -ParameterFilter {
                $Path -eq $parameterPath
            } -Exactly -Times 0 `
                -Scope Context
        }
    }

    Context 'WS-Man Service Config parameter <Name> is different' -ForEach $parameterList {
        BeforeAll {
            Mock -CommandName Get-Item `
                -MockWith {
                @{
                    Value = $Default
                }
            }
            Mock -CommandName Set-Item
        }

        It 'Should not throw error' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                {
                    $setTargetResourceParameters = $wsManServiceConfigSplat.Clone()
                    $setTargetResourceParameters[$Name] = $TestVal
                    Set-TargetResource @setTargetResourceParameters
                } | Should -Not -Throw
            }
        }

        It 'Should call expected Mocks' {
            $parameterPath = Join-Path `
                -Path 'WSMan:\Localhost\Service\' `
                -ChildPath $Path

            Should -Invoke `
                -CommandName Get-Item `
                -ParameterFilter {
                $Path -eq $parameterPath
            } -Exactly -Times 1 `
                -Scope Context

            Should -Invoke `
                -CommandName Set-Item `
                -ParameterFilter {
                $Path -eq $parameterPath
            } -Exactly -Times 1 `
                -Scope Context
        }
    }
}

Describe "$($script:dscResourceName)\Test-TargetResource" -Tag 'Test' {
    Context 'When WS-Man Service Config parameter <Name> is the same' -ForEach $parameterList {
        BeforeAll {
            Mock -CommandName Get-Item `
                -MockWith {
                @{
                    Value = $Default
                }
            }
        }

        It 'Should return true' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = $wsManServiceConfigSplat.Clone()
                Test-TargetResource @testTargetResourceParameters | Should -BeTrue
            }
        }

        It 'Should call expected Mocks' {
            Should -Invoke `
                -CommandName Get-Item `
                -Exactly -Times $($parameterList).Count `
                -Scope Context
        }
    }

    Context 'WS-Man Service Config parameter <Name> is different' -ForEach $parameterList {
        BeforeAll {
            Mock -CommandName Get-Item `
                -MockWith {
                @{
                    Value = $Default
                }
            }
        }

        It 'Should return false' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceSplat = $wsManServiceConfigSplat.Clone()
                $testTargetResourceSplat.$($Name) = $TestVal
                Test-TargetResource @testTargetResourceSplat | Should -BeFalse
            }
        }

        It 'Should call expected Mocks' {
            $parameterPath = Join-Path `
                -Path 'WSMan:\Localhost\Service\' `
                -ChildPath $Path

            Should -Invoke `
                -CommandName Get-Item `
                -ParameterFilter {
                $Path -eq $parameterPath
            } -Exactly -Times 1 `
                -Scope Context
        }
    }
}
