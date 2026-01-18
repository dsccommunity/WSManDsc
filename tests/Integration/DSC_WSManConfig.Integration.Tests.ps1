<#
    .SYNOPSIS
        Integration test for WSManConfig DSC resource.

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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # This will throw an error if the dependencies have not been resolved.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }

    $script:dscResourceName = 'DSC_WSManConfig'

    $ParameterList = @(
        @{
            Name    = 'MaxEnvelopeSizekb'
            Path    = 'MaxEnvelopeSizekb'
            Type    = 'Uint32'
            Default = 500
            TestVal = 501
        },
        @{
            Name    = 'MaxTimeoutms'
            Path    = 'MaxTimeoutms'
            Type    = 'Uint32'
            Default = 60000
            TestVal = 60001
        },
        @{
            Name    = 'MaxBatchItems'
            Path    = 'MaxBatchItems'
            Type    = 'Uint32'
            Default = 32000
            TestVal = 32001
        }
    )

    $script:wsmanConfigParameterList = $ParameterList
}

BeforeAll {
    $script:dscModuleName = 'WSManDsc'
    $script:dscResourceName = 'DSC_WSManConfig'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Integration'

    Backup the existing settings
    $script:currentWsManConfig = @{}

    foreach ($parameter in $wsmanConfigParameterList)
    {
        $parameterPath = Join-Path `
            -Path 'WSMan:\Localhost\' `
            -ChildPath $parameter.Path
        $currentWsManConfig.$($Parameter.Name) = (Get-Item -Path $parameterPath).Value
    } # foreach

    # Make sure WS-Man is enabled (usually enabled via azure-pipelines)
    if (-not (Get-PSProvider -PSProvider WSMan -ErrorAction SilentlyContinue))
    {
        $null = Enable-PSRemoting `
            -SkipNetworkProfileCheck `
            -Force `
            -ErrorAction Stop
    } # if

    # Set the Config to default settings
    foreach ($parameter in $wsmanConfigParameterList)
    {
        $parameterPath = Join-Path `
            -Path 'WSMan:\Localhost\' `
            -ChildPath $parameter.Path

        Set-Item -Path $parameterPath -Value $($parameter.Default) -Force
    } # foreach
}

AfterAll {
    # Clean up by restoring all parameters
    foreach ($parameter in $wsmanConfigParameterList)
    {
        $parameterPath = Join-Path `
            -Path 'WSMan:\Localhost\' `
            -ChildPath $parameter.Path

        Set-Item -Path $parameterPath -Value $script:currentWsManConfig.$($parameter.Name) -Force
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
        foreach ($parameter in $wsmanConfigParameterList)
        {
            $configData.AllNodes[0] += @{
                $($parameter.Name) = $($parameter.TestVal)
            }
        } # foreach
    }

    AfterEach {
        Wait-ForIdleLcm
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

    It 'Should have set the resource and all the parameters should match' -ForEach $wsmanConfigParameterList {
        # Get the Rule details
        $parameterPath = Join-Path `
            -Path 'WSMan:\Localhost\' `
            -ChildPath $Path

        (Get-Item -Path $parameterPath).Value | Should -Be $TestVal
    }
}
