Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

$script:dscModuleName = 'WSManDsc'
$script:dscResourceName = 'DSR_WSManServiceConfig'

$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

function Invoke-TestSetup
{
    Import-Module -Name DscResource.Test -Force

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

# Load the parameter List from the data file
$resourceData = Import-LocalizedData `
    -BaseDirectory (Join-Path -Path $script:moduleRoot -ChildPath 'DscResources\DSR_WSManServiceConfig') `
    -FileName 'DSR_WSManServiceConfig.data.psd1'

$script:parameterList = $resourceData.ParameterList

# Begin Testing
try
{
    Invoke-TestSetup

    # Make sure WS-Man is enabled
    if (-not (Get-PSProvider -PSProvider WSMan -ErrorAction SilentlyContinue))
    {
        $null = Enable-PSRemoting `
            -SkipNetworkProfileCheck `
            -Force `
            -ErrorAction Stop
    } # if

    InModuleScope $script:dscResourceName {
        $script:dscResourceName = 'DSR_WSManListener'

        # Create the Mock Objects that will be used for running tests
        $wsManServiceConfigSettings = [PSObject] @{}
        $wsManServiceConfigSplat = [PSObject] @{
            IsSingleInstance = 'Yes'
            Verbose          = $True
        }

        foreach ($parameter in $parameterList)
        {
            $wsManServiceConfigSettings += [PSObject] @{
                $($parameter.Name) = $parameter.default
            }

            $wsManServiceConfigSplat += [PSObject] @{
                $($parameter.Name) = $parameter.default
            }
        }

        Describe "$($script:dscResourceName)\Get-TargetResource" {
            Context 'When WS-Man Service Config Exists' {
                # Set up Mocks
                foreach ($parameter in $parameterList)
                {
                    $parameterPath = Join-Path `
                        -Path 'WSMan:\Localhost\Service\' `
                        -ChildPath $parameter.Path

                    Mock `
                        -CommandName Get-Item `
                        -ParameterFilter {
                            $Path -eq $parameterPath
                        } `
                        -MockWith {
                            @{
                                Value = $parameter.Default
                            }
                        }
                }

                It 'Should return current WS-Man Service Config values' {
                    $result = Get-TargetResource -IsSingleInstance 'Yes'

                    foreach ($parameter in $parameterList)
                    {
                        $result.$($parameter.Name) | Should -Be $wsManServiceConfigSettings.$($parameter.Name)
                    }
                }

                It 'Should call the expected mocks' {
                    foreach ($parameter in $parameterList)
                    {
                        $parameterPath = Join-Path `
                            -Path 'WSMan:\Localhost\Service\' `
                            -ChildPath $parameter.Path

                        Assert-MockCalled `
                            -CommandName Get-Item `
                            -ParameterFilter {
                                $Path -eq $parameterPath
                            } -Exactly 1
                    }
                }
            }
        }

        Describe "$($script:dscResourceName)\Set-TargetResource" {
            Context 'When WS-Man Service Config all parameters are the same' {
                # Set up Mocks
                foreach ($parameter in $parameterList)
                {
                    $parameterPath = Join-Path `
                        -Path 'WSMan:\Localhost\Service\' `
                        -ChildPath $parameter.Path

                    Mock `
                        -CommandName Get-Item `
                        -ParameterFilter {
                            $Path -eq $parameterPath
                        } `
                        -MockWith {
                            @{
                                Value = $parameter.Default
                            }
                        }

                    Mock `
                        -CommandName Set-Item `
                        -ParameterFilter {
                            $Path -eq $parameterPath
                        }
                }

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $wsManServiceConfigSplat.Clone()
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    foreach ($parameter in $parameterList)
                    {
                        $parameterPath = Join-Path `
                            -Path 'WSMan:\Localhost\Service\' `
                            -ChildPath $parameter.Path

                        Assert-MockCalled `
                            -CommandName Get-Item `
                            -ParameterFilter {
                                $Path -eq $parameterPath
                            } -Exactly -Times 1

                        Assert-MockCalled `
                            -CommandName Set-Item `
                            -ParameterFilter {
                                $Path -eq $parameterPath
                            } -Exactly -Times 0
                    }
                }
            }

            foreach ($parameter in $parameterList)
            {
                Context "WS-Man Service Config $($parameter.Name) is different" {
                    $parameterPath = Join-Path `
                        -Path 'WSMan:\Localhost\Service\' `
                        -ChildPath $parameter.Path

                    Mock `
                        -CommandName Get-Item `
                        -ParameterFilter {
                            $Path -eq $parameterPath
                        } `
                        -MockWith {
                            @{
                                Value = $parameter.Default
                            }
                        }

                    Mock `
                        -CommandName Set-Item `
                        -ParameterFilter {
                            $Path -eq $parameterPath
                        }

                    It 'Should not throw error' {
                        {
                            $setTargetResourceParameters = $wsManServiceConfigSplat.Clone()
                            $setTargetResourceParameters.$($parameter.Name) = $parameter.TestVal
                            Set-TargetResource @setTargetResourceParameters
                        } | Should -Not -Throw
                    }

                    It 'Should call expected Mocks' {
                        foreach ($parameter1 in $parameterList)
                        {
                            $parameterPath = Join-Path `
                                -Path 'WSMan:\Localhost\Service\' `
                                -ChildPath $parameter1.Path

                            Assert-MockCalled `
                                -CommandName Get-Item `
                                -ParameterFilter {
                                    $Path -eq $parameterPath
                                } -Exactly -Times 1

                            if ($parameter.Name -eq $parameter1.Name)
                            {
                                Assert-MockCalled `
                                    -CommandName Set-Item `
                                    -ParameterFilter {
                                        $Path -eq $parameterPath
                                    } -Exactly -Times 1
                            }
                            else
                            {
                                Assert-MockCalled `
                                    -CommandName Set-Item `
                                    -ParameterFilter {
                                        $Path -eq $parameterPath
                                    } -Exactly -Times 0
                            }
                        }
                    }
                }
            }
        }

        Describe "$($script:dscResourceName)\Test-TargetResource" {
            # Set up Mocks
            foreach ($parameter in $parameterList)
            {
                $parameterPath = Join-Path `
                    -Path 'WSMan:\Localhost\Service\' `
                    -ChildPath $parameter.Path

                Mock `
                    -CommandName Get-Item `
                    -ParameterFilter {
                        $Path -eq $parameterPath
                    } `
                    -MockWith {
                        @{
                            Value = $parameter.Default
                        }
                    }
            }

            Context 'When WS-Man Service Config all parameters are the same' {
                It 'Should return true' {
                    $testTargetResourceParameters = $wsManServiceConfigSplat.Clone()
                    Test-TargetResource @testTargetResourceParameters | Should -BeTrue
                }

                It 'Should call expected Mocks' {
                    foreach ($parameter in $parameterList)
                    {
                        $parameterPath = Join-Path `
                            -Path 'WSMan:\Localhost\Service\' `
                            -ChildPath $parameter.Path

                        Assert-MockCalled `
                            -CommandName Get-Item `
                            -ParameterFilter {
                                $Path -eq $parameterPath
                            } -Exactly -Times 1
                    }
                }
            }

            foreach ($parameter in $parameterList)
            {
                Context "WS-Man Service Config $($parameter.Name) is different" {
                    It 'Should return false' {
                        $testTargetResourceSplat = $wsManServiceConfigSplat.Clone()
                        $testTargetResourceSplat.$($parameter.Name) = $parameter.TestVal
                        Test-TargetResource @testTargetResourceSplat | Should -BeFalse
                    }

                    It 'Should call expected Mocks' {
                        foreach ($parameter in $parameterList)
                        {
                            $parameterPath = Join-Path `
                                -Path 'WSMan:\Localhost\Service\' `
                                -ChildPath $parameter.Path

                            Assert-MockCalled `
                                -CommandName Get-Item `
                                -ParameterFilter {
                                    $Path -eq $parameterPath
                                } -Exactly -Times 1
                        }
                    }
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
