$script:dscModuleName   = 'WSManDsc'
$script:dscResourceName = 'DSC_WSManConfig'

$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'

$script:testEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -ResourceType 'Mof' `
    -TestType 'Integration'

# Load the parameter List from the data file
$resourceData = Import-LocalizedData `
    -BaseDirectory (Join-Path -Path $script:moduleRoot -ChildPath 'Source\DscResources\DSC_WSManConfig') `
    -FileName 'DSC_WSManConfig.data.psd1'

$parameterList = $resourceData.ParameterList | Where-Object -Property IntTest -eq $True

# Backup the existing settings
$currentWsManConfig = [PSObject] @{}

foreach ($parameter in $parameterList)
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
    if (-not (Get-PSProvider -PSProvider WSMan -ErrorAction SilentlyContinue))
    {
        $null = Enable-PSRemoting `
            -SkipNetworkProfileCheck `
            -Force `
            -ErrorAction Stop
    } # if

    # Set the Config to default settings
    foreach ($parameter in $parameterList)
    {
        $parameterPath = Join-Path `
            -Path 'WSMan:\Localhost\' `
            -ChildPath $parameter.Path

        Set-Item -Path $parameterPath -Value $($parameter.Default) -Force
    } # foreach

    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $ConfigFile

    Describe "$($script:dscResourceName)_Integration" {
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
                foreach ($parameter in $parameterList)
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
            foreach ($parameter in $parameterList)
            {
                $parameterPath = Join-Path `
                    -Path 'WSMan:\Localhost\' `
                    -ChildPath $parameter.Path
                (Get-Item -Path $parameterPath).Value | Should -Be $($parameter.TestVal)
            } # foreach
        }
    }
}
finally
{
    # Clean up by restoring all parameters
    foreach ($parameter in $parameterList)
    {
        $parameterPath = Join-Path `
            -Path 'WSMan:\Localhost\' `
            -ChildPath $parameter.Path
        Set-Item -Path $parameterPath -Value $currentWsManConfig.$($parameter.Name) -Force
    } # foreach

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
