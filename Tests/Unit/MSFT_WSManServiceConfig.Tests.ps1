$script:DSCModuleName   = 'WSManDsc'
$script:DSCResourceName = 'MSFT_WsManServiceConfig'

#region HEADER
# Unit Test Template Version: 1.1.0
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Load the parameter List from the data file
$parameterList = Import-LocalizedData `
    -BaseDirectory $PSScriptRoot `
    -FileName 'MSFT_WSManServiceConfig.parameterlist.psd1'

# Begin Testing
try
{
    # Make sure WS-Man is enabled
    if (-not (Get-PSPRovider -PSProvider WSMan -ErrorAction SilentlyContinue))
    {
        $null = Enable-PSRemoting `
            -SkipNetworkProfileCheck `
            -Force `
            -ErrorAction Stop
    } # if

    #region Pester Tests
    InModuleScope $script:DSCResourceName {

        # Create the Mock Objects that will be used for running tests
        $WsManServiceConfigSettings = [PSObject]@{}
        $WsManServiceConfigSplat = [PSObject]@{
            IsSingleInstance             = 'Yes'
        }
        foreach ($parameter in $parameterList)
        {
            $WSManServiceConfigSettings += [PSObject] @{ $($parameter.Name) = $parameter.default }
            $WSManServiceConfigSplat += [PSObject] @{ $($parameter.Name) = $parameter.default }
        }

        Describe "$($script:DSCResourceName)\Get-TargetResource" {

            Context 'WS-Man Service Config Exists' {

                # Set up Mocks
                foreach ($parameter in $parameterList)
                {
                    $ParameterPath = Join-Path `
                        -Path 'WSMan:\Localhost\Service\' `
                        -ChildPath $parameter.Path
                    Mock -CommandName Get-Item -ParameterFilter { $Path -eq $ParameterPath } -MockWith { @{ Value = $Parameter.Default } }
                }

                It 'should return current WS-Man Service Config values' {
                    $Result = Get-TargetResource -IsSingleInstance 'Yes'
                    foreach ($parameter in $parameterList)
                    {
                        $Result.$($parameter.Name) | Should Be $WSManServiceConfigSettings.$($parameter.Name)
                    }
                }
                It 'should call the expected mocks' {
                    foreach ($parameter in $parameterList)
                    {
                        $ParameterPath = Join-Path `
                            -Path 'WSMan:\Localhost\Service\' `
                            -ChildPath $parameter.Path
                        Assert-MockCalled -CommandName Get-Item -ParameterFilter { $Path -eq $ParameterPath } -Exactly 1
                    }
                }
            }
        }

        Describe "$($script:DSCResourceName)\Set-TargetResource" {

            # Set up Mocks
            foreach ($parameter in $parameterList)
            {
                $ParameterPath = Join-Path `
                    -Path 'WSMan:\Localhost\Service\' `
                    -ChildPath $parameter.Path
                Mock -CommandName Get-Item -ParameterFilter { $Path -eq $ParameterPath } -MockWith { @{ Value = $Parameter.Default } }
                Mock -CommandName Set-Item -ParameterFilter { $Path -eq $ParameterPath }
            }

            Context 'WS-Man Service Config all parameters are the same' {
                It 'should not throw error' {
                    {
                        $Splat = $WSManServiceConfigSplat.Clone()
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    foreach ($parameter in $parameterList)
                    {
                        $ParameterPath = Join-Path `
                            -Path 'WSMan:\Localhost\Service\' `
                            -ChildPath $parameter.Path
                        Assert-MockCalled -CommandName Get-Item -ParameterFilter { $Path -eq $ParameterPath } -Exactly 1
                        Assert-MockCalled -CommandName Set-Item -ParameterFilter { $Path -eq $ParameterPath } -Exactly 0
                    }
                }
            }

            foreach ($parameter in $parameterList)
            {
                Context "WS-Man Service Config $($Parameter.Name) is different" {
                    It 'should not throw error' {
                        {
                            $Splat = $WSManServiceConfigSplat.Clone()
                            $Splat.$($parameter.Name) = $parameter.TestVal
                            Set-TargetResource @Splat
                        } | Should Not Throw
                    }
                    It 'should call expected Mocks' {
                        foreach ($parameter1 in $parameterList)
                        {
                            $ParameterPath = Join-Path `
                                -Path 'WSMan:\Localhost\Service\' `
                                -ChildPath $parameter1.Path
                            Assert-MockCalled -CommandName Get-Item -ParameterFilter { $Path -eq $ParameterPath } -Exactly 1
                            if ($parameter.Name -eq $parameter1.Name)
                            {
                                Assert-MockCalled -CommandName Set-Item -ParameterFilter { $Path -eq $ParameterPath } -Exactly 1
                            }
                            else
                            {
                                Assert-MockCalled -CommandName Set-Item -ParameterFilter { $Path -eq $ParameterPath } -Exactly 0
                            }
                        }
                    }
                }
            }
        }

        Describe "$($script:DSCResourceName)\Test-TargetResource" {

            # Set up Mocks
            foreach ($parameter in $parameterList)
            {
                $ParameterPath = Join-Path `
                    -Path 'WSMan:\Localhost\Service\' `
                    -ChildPath $parameter.Path
                Mock -CommandName Get-Item -ParameterFilter { $Path -eq $ParameterPath } -MockWith { @{ Value = $Parameter.Default } }
            }

            Context 'WS-Man Service Config all parameters are the same' {
                It 'should return true' {
                    $Splat = $WSManServiceConfigSplat.Clone()
                    Test-TargetResource @Splat | Should Be $True
                }
                It 'should call expected Mocks' {
                    foreach ($parameter in $parameterList)
                    {
                        $ParameterPath = Join-Path `
                            -Path 'WSMan:\Localhost\Service\' `
                            -ChildPath $parameter.Path
                        Assert-MockCalled -CommandName Get-Item -ParameterFilter { $Path -eq $ParameterPath } -Exactly 1
                    }
                }
            }

            foreach ($parameter in $parameterList)
            {
                Context "WS-Man Service Config $($Parameter.Name) is different" {
                    It 'should return false' {
                        $Splat = $WSManServiceConfigSplat.Clone()
                        $Splat.$($parameter.Name) = $parameter.TestVal
                        Test-TargetResource @Splat | Should Be $False
                    }
                    It 'should call expected Mocks' {
                        foreach ($parameter in $parameterList)
                        {
                            $ParameterPath = Join-Path `
                                -Path 'WSMan:\Localhost\Service\' `
                                -ChildPath $parameter.Path
                            Assert-MockCalled -CommandName Get-Item -ParameterFilter { $Path -eq $ParameterPath } -Exactly 1
                        }
                    }
                }
            }
        }

        Describe "$($script:DSCResourceName)\New-TerminatingError" {

            Context 'Create a TestError Exception' {

                It 'should throw a TestError exception' {
                    $errorId = 'TestError'
                    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    $errorMessage = 'Test Error Message'
                    $exception = New-Object `
                        -TypeName System.InvalidOperationException `
                        -ArgumentList $errorMessage
                    $errorRecord = New-Object `
                        -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $exception, $errorId, $errorCategory, $null

                    { New-TerminatingError `
                        -ErrorId $errorId `
                        -ErrorMessage $errorMessage `
                        -ErrorCategory $errorCategory } | Should Throw $errorRecord
                }
            }
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
