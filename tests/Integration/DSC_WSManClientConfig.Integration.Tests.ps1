<#
    .SYNOPSIS
        Integration test for DSC_WSManClientConfig DSC resource.

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

    $dscResourceName = 'DSC_WSManClientConfig'

    $ParameterList = @(
        @{
            Name    = 'NetworkDelayms'
            Path    = 'NetworkDelayms'
            Type    = 'UInt32'
            Default = 5000
            TestVal = 5001
            IntTest = $true
        },
        @{
            Name    = 'URLPrefix'
            Path    = 'URLPrefix'
            Type    = 'String'
            Default = 'wsman'
            TestVal = 'wsmanTest'
            IntTest = $true
        },
        @{
            Name    = 'AllowUnencrypted'
            Path    = 'AllowUnencrypted'
            Type    = 'Boolean'
            Default = $false
            TestVal = $true
            IntTest = $true
        },
        @{
            Name    = 'TrustedHosts'
            Path    = 'TrustedHosts'
            Type    = 'String'
            Default = ''
            TestVal = 'testserver1.contoso.com,testserver2.contoso.com'
            IntTest = $true
        },
        @{
            Name    = 'AuthBasic'
            Path    = 'Auth\Basic'
            Type    = 'Boolean'
            Default = $false
            TestVal = $true
            IntTest = $false
        },
        @{
            Name    = 'AuthDigest'
            Path    = 'Auth\Digest'
            Type    = 'Boolean'
            Default = $false
            TestVal = $true
            IntTest = $false
        },
        @{
            Name    = 'AuthKerberos'
            Path    = 'Auth\Kerberos'
            Type    = 'Boolean'
            Default = $true
            TestVal = $false
            IntTest = $false
        },
        @{
            Name    = 'AuthNegotiate'
            Path    = 'Auth\Negotiate'
            Type    = 'Boolean'
            Default = $true
            TestVal = $false
            IntTest = $false
        },
        @{
            Name    = 'AuthCertificate'
            Path    = 'Auth\Certificate'
            Type    = 'Boolean'
            Default = $false
            TestVal = $true
            IntTest = $true
        },
        @{
            Name    = 'AuthCredSSP'
            Path    = 'Auth\CredSSP'
            Type    = 'Boolean'
            Default = $false
            TestVal = $true
            IntTest = $true
        }
    )

    $script:wsmanClientConfigParameterList = $ParameterList.Where({ $_.IntTest } )
}

BeforeAll {
    $script:dscModuleName = 'WSManDsc'
    $script:dscResourceName = 'DSC_WSManClientConfig'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Integration'

    # Backup the existing settings
    $currentWsManServiceConfig = @{}

    foreach ($parameter in $wsmanClientConfigParameterList)
    {
        $parameterPath = Join-Path `
            -Path 'WSMan:\Localhost\Client\' `
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
    foreach ($parameter in $wsmanClientConfigParameterList)
    {
        $parameterPath = Join-Path `
            -Path 'WSMan:\Localhost\Client\' `
            -ChildPath $parameter.Path

        Set-Item -Path $parameterPath -Value $($parameter.Default) -Force
    } # foreach
}

AfterAll {
    # Clean up by restoring all parameters
    foreach ($parameter in $wsmanClientConfigParameterList)
    {
        $parameterPath = Join-Path `
            -Path 'WSMan:\Localhost\Client\' `
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
        foreach ($parameter in $wsmanClientConfigParameterList)
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

    It 'Should have set the resource and all the parameters should match' -ForEach $wsmanClientConfigParameterList {
        $parameterPath = Join-Path `
            -Path 'WSMan:\Localhost\Client\' `
            -ChildPath $Path

        (Get-Item -Path $parameterPath).Value | Should -Be $TestVal
    }
}
