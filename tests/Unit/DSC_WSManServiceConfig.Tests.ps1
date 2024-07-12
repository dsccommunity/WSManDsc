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

            # If the dependencies has not been resolved, this will throw an error.
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
            #Verbose          = $True
        }

        foreach ($parameter in $parameterList)
        {
            $script:wsManServiceConfigSettings[$parameter.Name] = $parameter.default
            $script:wsManServiceConfigSplat[$parameter.Name] = $parameter.default
        }
    }

    #Make sure WS-Man is enabled
    if (-not (Get-PSProvider -PSProvider WSMan -ErrorAction SilentlyContinue))
    {
        $null = Enable-PSRemoting `
            -SkipNetworkProfileCheck `
            -Force `
            -ErrorAction Stop
    } # if
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

                $result = Get-TargetResource -IsSingleInstance 'Yes'

                $result.$($Name) | Should -Be $wsManServiceConfigSettings.$($Name)
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

# Describe "$($script:dscResourceName)\Set-TargetResource" -Tag 'Set' {
#     Context 'When WS-Man Service Config all parameters are the same <Name>' -ForEach $parameterList {
#         BeforeAll {
#             # Set up Mocks
#             $parameterPath = Join-Path `
#                 -Path 'WSMan:\Localhost\Service\' `
#                 -ChildPath $Path

#             Mock `
#                 -CommandName Get-Item `
#                 -ParameterFilter {
#                 $Path -eq $parameterPath
#             } `
#                 -MockWith {
#                 @{
#                     Value = $Default
#                 }
#             }

#             Mock `
#                 -CommandName Set-Item `
#                 -ParameterFilter {
#                 $Path -eq $parameterPath
#             }

#             # Mock other Get-Item calls
#             Mock -CommandName Get-Item
#         }

#         It 'Should not throw error' {
#             InModuleScope -ScriptBlock {
#                 Set-StrictMode -Version 1.0

#                 {
#                     $setTargetResourceParameters = $wsManServiceConfigSplat.Clone()
#                     Set-TargetResource @setTargetResourceParameters
#                 } | Should -Not -Throw
#             }
#         }

#         It 'Should call expected Mocks' {
#             $parameterPath = Join-Path `
#                 -Path 'WSMan:\Localhost\Service\' `
#                 -ChildPath $Path

#             Should -Invoke `
#                 -CommandName Get-Item `
#                 -ParameterFilter {
#                 $Path -eq $parameterPath
#             } -Exactly -Times 1 `
#                 -Scope Context

#             Should -Invoke `
#                 -CommandName Set-Item `
#                 -ParameterFilter {
#                 $Path -eq $parameterPath
#             } -Exactly -Times 0 `
#                 -Scope Context
#         }
#     }

#     # foreach ($parameter in $parameterList)
#     # {
#     #     Context "WS-Man Service Config $($parameter.Name) is different" {
#     #         $parameterPath = Join-Path `
#     #             -Path 'WSMan:\Localhost\Service\' `
#     #             -ChildPath $parameter.Path

#     #         Mock `
#     #             -CommandName Get-Item `
#     #             -ParameterFilter {
#     #             $Path -eq $parameterPath
#     #         } `
#     #             -MockWith {
#     #             @{
#     #                 Value = $parameter.Default
#     #             }
#     #         }

#     #         Mock `
#     #             -CommandName Set-Item `
#     #             -ParameterFilter {
#     #             $Path -eq $parameterPath
#     #         }

#     #         It 'Should not throw error' {
#     #             {
#     #                 $setTargetResourceParameters = $wsManServiceConfigSplat.Clone()
#     #                 $setTargetResourceParameters.$($parameter.Name) = $parameter.TestVal
#     #                 Set-TargetResource @setTargetResourceParameters
#     #             } | Should -Not -Throw
#     #         }

#     #         It 'Should call expected Mocks' {
#     #             foreach ($parameter1 in $parameterList)
#     #             {
#     #                 $parameterPath = Join-Path `
#     #                     -Path 'WSMan:\Localhost\Service\' `
#     #                     -ChildPath $parameter1.Path

#     #                 Assert-MockCalled `
#     #                     -CommandName Get-Item `
#     #                     -ParameterFilter {
#     #                     $Path -eq $parameterPath
#     #                 } -Exactly -Times 1

#     #                 if ($parameter.Name -eq $parameter1.Name)
#     #                 {
#     #                     Assert-MockCalled `
#     #                         -CommandName Set-Item `
#     #                         -ParameterFilter {
#     #                         $Path -eq $parameterPath
#     #                     } -Exactly -Times 1
#     #                 }
#     #                 else
#     #                 {
#     #                     Assert-MockCalled `
#     #                         -CommandName Set-Item `
#     #                         -ParameterFilter {
#     #                         $Path -eq $parameterPath
#     #                     } -Exactly -Times 0
#     #                 }
#     #             }
#     #         }
#     #     }
#     # }
# }

Describe "$($script:dscResourceName)\Test-TargetResource" -Tag 'Test' {
    Context 'When WS-Man Service Config all parameters are the same' {
        BeforeAll {
            # Mock `
            #     -CommandName Get-Item `
            #     -MockWith {
            #     @{
            #         Value = $Default
            #     }
            # }
            Mock -CommandName Get-Item
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


    Context 'WS-Man Service Config <Name> is different' -ForEach $parameterList {
        BeforeAll {
            Mock `
                -CommandName Get-Item `
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
