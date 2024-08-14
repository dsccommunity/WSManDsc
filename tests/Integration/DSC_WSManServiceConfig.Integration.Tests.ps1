<#
    .SYNOPSIS
        Integration test for DSC_WSManServiceConfig DSC resource.

    .NOTES
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

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

    $dscResourceName = 'DSC_WSManServiceConfig'
    $moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

    # Load the parameter List from the data file
    $resourceData = Import-LocalizedData `
        -BaseDirectory (Join-Path -Path $script:moduleRoot -ChildPath "Source\DscResources\$($dscResourceName)") `
        -FileName "$($dscResourceName).data.psd1"

    $script:wsmanServiceConfigParameterList = $resourceData.ParameterList | Where-Object -Property IntTest -eq $true
}

BeforeAll {
    $script:dscModuleName = 'WSManDsc'
    $script:dscResourceName = 'DSC_WSManServiceConfig'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Integration'

    # Backup the existing settings
    $currentWsManServiceConfig = @{}

    foreach ($parameter in $wsmanServiceConfigParameterList)
    {
        $parameterPath = Join-Path `
            -Path 'WSMan:\Localhost\Service\' `
            -ChildPath $parameter.Path
        $currentWsManServiceConfig.$($Parameter.Name) = (Get-Item -Path $parameterPath).Value
    } # foreach

    # Make sure WS-Man is enabled
    if (-not (Get-PSProvider -PSProvider WSMan -ErrorAction SilentlyContinue))
    {
        $null = Enable-PSRemoting `
            -SkipNetworkProfileCheck `
            -Force `
            -ErrorAction Stop
    } # if

    # Set the Service Config to default settings
    foreach ($parameter in $wsmanServiceConfigParameterList)
    {
        $parameterPath = Join-Path `
            -Path 'WSMan:\Localhost\Service\' `
            -ChildPath $parameter.Path

        Set-Item -Path $parameterPath -Value $($parameter.Default) -Force
    } # foreach
}

AfterAll {
    # Clean up by restoring all parameters
    foreach ($parameter in $wsmanServiceConfigParameterList)
    {
        $parameterPath = Join-Path `
            -Path 'WSMan:\Localhost\Service\' `
            -ChildPath $parameter.Path
        Set-Item -Path $parameterPath -Value $currentWsManServiceConfig.$($parameter.Name) -Force
    } # foreach

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Describe "$($script:dscResourceName)_Integration" {
    BeforeAll {
        $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $ConfigFile

        $configData = @{
            AllNodes = @(
                @{
                    NodeName = 'localhost'
                }
            )
        }
        foreach ($parameter in $wsmanServiceConfigParameterList)
        {
            $configData.AllNodes[0] += @{
                $($parameter.Name) = $($parameter.TestVal)
            }
        } # foreach
    }

    It 'Should compile without throwing' {
        {
            & "$($script:dscResourceName)_Config" `
                -OutputPath $TestDrive `
                -ConfigurationData $configData

            Write-Verbose "TestDrive = $($TestDrive)"

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

    It 'Should have set the resource and all the parameters should match' -ForEach $wsmanServiceConfigParameterList {
        $parameterPath = Join-Path `
            -Path 'WSMan:\Localhost\Service\' `
            -ChildPath $Path

        (Get-Item -Path $parameterPath).Value | Should -Be $TestVal
    }
}
