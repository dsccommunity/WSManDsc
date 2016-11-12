$script:DSCModuleName   = 'WSManDsc'
$script:DSCResourceName = 'MSFT_WSManListener'

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
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration
#endregion HEADER

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

    #region Integration Tests
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName)_Add_HTTP.config.ps1"
    . $ConfigFile

    Describe "$($script:DSCResourceName)_Integration_Add_HTTP" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                & "$($script:DSCResourceName)_Config_Add_HTTP" `
                    -OutputPath $TestEnvironment.WorkingFolder
                Start-DscConfiguration `
                    -Path $TestEnvironment.WorkingFolder `
                    -ComputerName localhost `
                    -Wait `
                    -Verbose `
                    -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Should have set the resource and all the parameters should match' {
            # Get the Rule details
            $Listeners = @(Get-WSManInstance `
                -ResourceURI winrm/config/Listener `
                -Enumerate)
            if ($Listeners)
            {
                $NewListener = $Listeners.Where( {$_.Transport -eq $Listener.Transport } )
            }
            $NewListener                    | Should Not Be $null
            $NewListener.Port               | Should Be $Listener.Port
            $NewListener.Address            | Should Be $Listener.Address
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
