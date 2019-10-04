$script:DSCModuleName   = 'WSManDsc'
$script:DSCResourceName = 'DSR_WSManConfig'

#region HEADER
# Integration Test Template Version: 1.1.1
[System.String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
Import-Module (Join-Path -Path $script:moduleRoot -ChildPath "$($script:DSCModuleName).psd1") -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration
#endregion

# Load the parameter List from the data file
$resourceData = Import-LocalizedData `
    -BaseDirectory ($script:moduleRoot | Join-Path -ChildPath 'DscResources' | Join-Path -ChildPath $script:DSCResourceName) `
    -FileName "$script:DSCResourceName.data.psd1"

$script:parameterList = $resourceData.ParameterList | Where-Object -Property IntTest -eq $True

# Backup the existing settings
$currentWsManConfig = [PSObject] @{}

foreach ($parameter in $script:parameterList)
{
    $parameterPath = Join-Path `
        -Path 'WSMan:\Localhost\' `
        -ChildPath $parameter.Path
    $currentWsManConfig.$($Parameter.Name) = (Get-Item -Path $parameterPath).Value
} # foreach

# Using try/finally to always cleanup even if something awful happens.
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

    # Set the Config to default settings
    foreach ($parameter in $script:parameterList)
    {
        $parameterPath = Join-Path `
            -Path 'WSMan:\Localhost\' `
            -ChildPath $parameter.Path

        Set-Item -Path $parameterPath -Value $($parameter.Default) -Force
    } # foreach

    #region Integration Tests
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile

    Describe "$($script:DSCResourceName)_Integration" {
        It 'Should compile without throwing' {
            {
                $configData = @{
                    AllNodes = @(
                        @{
                            NodeName   = 'localhost'
                        }
                    )
                }

                # Dynamically assemble the parameters from the parameter list
                foreach ($parameter in $script:parameterList)
                {
                    $configData.AllNodes[0] += @{
                        $($parameter.Name) = $($parameter.TestVal)
                    }
                } # foreach

                & "$($script:dscResourceName)_Config" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $configData

                $startDscConfigurationParameters = @{
                    Path         = $TestDrive
                    ComputerName = 'localhost'
                    Wait         = $true
                    Verbose      = $true
                    Force        = $true
                    ErrorAction  = 'Stop'
                }

                Start-DscConfiguration @startDscConfigurationParameters
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            # Get the Rule details
            foreach ($parameter in $script:parameterList)
            {
                $parameterPath = Join-Path `
                    -Path 'WSMan:\Localhost\' `
                    -ChildPath $parameter.Path
                (Get-Item -Path $parameterPath).Value | Should -Be $WSManConfigNew.$($parameter.Name)
            } # foreach
        }
    }
}
finally
{
    # Clean up by restoring all parameters
    foreach ($parameter in $script:parameterList)
    {
        $parameterPath = Join-Path `
            -Path 'WSMan:\Localhost\' `
            -ChildPath $parameter.Path
        Set-Item -Path $parameterPath -Value $currentWsManConfig.$($parameter.Name) -Force
    } # foreach

    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
