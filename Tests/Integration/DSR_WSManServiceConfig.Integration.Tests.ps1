$script:DSCModuleName   = 'WSManDsc'
$script:DSCResourceName = 'DSR_WSManServiceConfig'

#region HEADER
# Integration Test Template Version: 1.1.1
[System.String] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\WSManDsc'

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
    -BaseDirectory (Join-Path -Path $script:moduleRoot -ChildPath 'DscResources\DSR_WSManServiceConfig') `
    -FileName 'DSR_WSManServiceConfig.data.psd1'

$script:parameterList = $resourceData.ParameterList

# Backup the existing settings
$currentWsManServiceConfig = [PSObject] @{}
foreach ($parameter in ($script:parameterList | Where-Object -Property IntTest -eq $True))
{
    $parameterPath = Join-Path `
        -Path 'WSMan:\Localhost\Service\' `
        -ChildPath $parameter.Path
    $currentWsManServiceConfig.$($Parameter.Name) = (Get-Item -Path $parameterPath).Value
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

    # Set the Service Config to default settings
    foreach ($parameter in ($script:parameterList | Where-Object -Property IntTest -eq $True))
    {
        $parameterPath = Join-Path `
            -Path 'WSMan:\Localhost\Service\' `
            -ChildPath $parameter.Path

        Set-Item -Path $parameterPath -Value $($parameter.Default) -Force
    } # foreach

    #region Integration Tests
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile

    Describe "$($script:DSCResourceName)_Integration" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                & "$($script:DSCResourceName)_Config" `
                    -OutputPath $TestDrive

                Start-DscConfiguration `
                    -Path $TestDrive `
                    -ComputerName localhost `
                    -Wait `
                    -Verbose `
                    -Force `
                    -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
        }
        #endregion

        It 'Should have set the resource and all the parameters should match' {
            # Get the Rule details
            foreach ($parameter in ($script:parameterList | Where-Object -Property IntTest -eq $True))
            {
                $parameterPath = Join-Path `
                    -Path 'WSMan:\Localhost\Service\' `
                    -ChildPath $parameter.Path
                (Get-Item -Path $parameterPath).Value | Should -Be $WSManServiceConfigNew.$($parameter.Name)
            } # foreach
        }
    }
    #endregion
}
finally
{
    # Clean up by restoring all parameters
    foreach ($parameter in ($script:parameterList | Where-Object -Property IntTest -eq $True))
    {
        $parameterPath = Join-Path `
            -Path 'WSMan:\Localhost\Service\' `
            -ChildPath $parameter.Path
        Set-Item -Path $parameterPath -Value $currentWsManServiceConfig.$($parameter.Name) -Force
    } # foreach

    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
