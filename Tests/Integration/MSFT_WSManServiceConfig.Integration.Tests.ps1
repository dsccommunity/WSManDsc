$Global:DSCModuleName   = 'WSManDsc'
$Global:DSCResourceName = 'MSFT_WSManServiceConfig'

#region HEADER
# Integration Test Template Version: 1.1.0
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Integration
#endregion

# Backup the existing settings
$CurrentWsManServiceConfig = @{}
foreach ($parameter in $ParameterList)
{
    if ($parameter.Path)
    {
        $ParameterPath = Join-Path `
            -Path 'WSMan:\Localhost\Service\' `
            -ChildPath "$($parameter.Path)\$($parameter.Name)"
        $ParameterName = "$($parameter.Path)$($parameter.Name)"
    }
    else
    {
        $ParameterPath = Join-Path `
            -Path 'WSMan:\Localhost\Service\' `
            -ChildPath $($parameter.Name)
        $ParameterName = $($parameter.Name)
    } # if
    $CurrentWsManServiceConfig += @{ $ParameterName = (Get-Item -Path $ParameterPath).Value }
} # foreach

# Using try/finally to always cleanup even if something awful happens.
try
{
    # Set the Service Config to default settings
    foreach ($parameter in $ParameterList)
    {
        if ($parameter.Path)
        {
            $ParameterPath = Join-Path `
                -Path 'WSMan:\Localhost\Service\' `
                -ChildPath "$($parameter.Path)\$($parameter.Name)"
        }
        else
        {
            $ParameterPath = Join-Path `
                -Path 'WSMan:\Localhost\Service\' `
                -ChildPath $($parameter.Name)
        } # if
        Set-Item -Path $ParameterPath -Value $($parameter.Default) -Force
    } # foreach

    #region Integration Tests
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($Global:DSCResourceName).config.ps1"
    . $ConfigFile

    Describe "$($Global:DSCResourceName)_Integration" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($Global:DSCResourceName)_Config -OutputPath `$TestEnvironment.WorkingFolder"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Should have set the resource and all the parameters should match' {
            # Get the Rule details
            foreach ($parameter in $ParameterList)
            {
                if ($parameter.Path)
                {
                    $ParameterPath = Join-Path `
                        -Path 'WSMan:\Localhost\Service\' `
                        -ChildPath "$($parameter.Path)\$($parameter.Name)"
                    $ParameterName = "$($parameter.Path)$($parameter.Name)"
                }
                else
                {
                    $ParameterPath = Join-Path `
                        -Path 'WSMan:\Localhost\Service\' `
                        -ChildPath $($parameter.Name)
                    $ParameterName = $($parameter.Name)
                } # if
                (Get-Item -Path $ParameterPath).Value | Should Be $WSManServiceConfigNew.$ParameterName
            } # foreach
        }
    }
    #endregion
}
finally
{
    # Clean up by restoring all parameters
    foreach ($parameter in $ParameterList)
    {

        if ($parameter.Path)
        {
            $ParameterPath = Join-Path `
                -Path 'WSMan:\Localhost\Service\' `
                -ChildPath "$($parameter.Path)\$($parameter.Name)"
            $ParameterName = "$($parameter.Path)$($parameter.Name)"
        }
        else
        {
            $ParameterPath = Join-Path `
                -Path 'WSMan:\Localhost\Service\' `
                -ChildPath $($parameter.Name)
            $ParameterName = $($parameter.Name)
        } # if
        Set-Item -Path $ParameterPath -Value $CurrentWsManServiceConfig.$ParameterName -Force
    } # foreach

    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
