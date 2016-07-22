$Global:DSCModuleName   = 'WSManDsc'
$Global:DSCResourceName = 'MSFT_WSManListener'

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
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $DSCResourceName {

        # Create the Mock Objects that will be used for running tests
        $MockFQDN = 'SERVER1.CONTOSO.COM'
        $MockCertificateThumbprint = '74FA31ADEA7FDD5333CED10910BFA6F665A1F2FC'
        $MockIssuer = 'CN=CONTOSO.COM Issuing CA, DC=CONTOSO, DC=COM'
        $MockCertificate = [PSObject]@{
            Thumbprint = $MockCertificateThumbprint
            Subject = "CN=$([System.Net.Dns]::GetHostByName($ENV:computerName).Hostname)"
            Issuer = $MockIssuer
            Extensions = @{ EnhancedKeyUsages = @{ FriendlyName = 'Server Authentication' } }
            DNSNameList = @{ Unicode = "$([System.Net.Dns]::GetHostByName($ENV:computerName).Hostname)" }
        }
        $MockListenerHTTP = [PSObject]@{
            cfg = 'http://schemas.microsoft.com/wbem/wsman/1/config/listener'
            xsi = 'http://www.w3.org/2001/XMLSchema-instance'
            lang = 'en-US'
            Address = '*'
            Transport = 'HTTP'
            Port = 5985
            Hostname = ''
            Enabled = 'true'
            URLPrefix = 'wsman'
            CertificateThumbprint = ''
        }
        $MockListenerHTTPS = [PSObject]@{
            cfg = 'http://schemas.microsoft.com/wbem/wsman/1/config/listener'
            xsi = 'http://www.w3.org/2001/XMLSchema-instance'
            lang = 'en-US'
            Address = '*'
            Transport = 'HTTPS'
            Port = 5986
            Hostname = $MockFQDN
            Enabled = 'true'
            URLPrefix = 'wsman'
            CertificateThumbprint = $MockCertificateThumbprint
        }

        Describe "$($Global:DSCResourceName)\Get-TargetResource" {

            Context 'No listeners exist' {

                Mock Get-WSManInstance -MockWith { }

                It 'should return absent listener' {
                    $Result = Get-TargetResource `
                        -Transport HTTP `
                        -Ensure Present
                    $Result.Ensure | Should Be 'Absent'
                }
                It 'should call Get-WSManInstance once' {
                    Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
                }
            }

            Context 'Requested listener does not exist' {

                Mock Get-WSManInstance -MockWith { return @($MockListenerHTTP) }

                It 'should return absent listener' {
                    $Result = Get-TargetResource `
                        -Transport $MockListenerHTTPS.Transport `
                        -Ensure Present
                    $Result.Ensure | Should Be 'Absent'
                }
                It 'should call Get-WSManInstance once' {
                    Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
                }
            }

            Context 'Requested listener does exist' {

                Mock Get-WSManInstance -MockWith { return @($MockListenerHTTP) }

                It 'should return correct listener' {
                    $Result = Get-TargetResource `
                        -Transport $MockListenerHTTP.Transport `
                        -Ensure Present
                    $Result.Ensure | Should Be 'Present'
                    $Result.Port | Should Be $MockListenerHTTP.Port
                    $Result.Address | Should Be $MockListenerHTTP.Address
                    $Result.HostName | Should Be $MockListenerHTTP.HostName
                    $Result.Enabled | Should Be $MockListenerHTTP.Enabled
                    $Result.URLPrefix | Should Be $MockListenerHTTP.URLPrefix
                    $Result.CertificateThumbprint | Should Be $MockListenerHTTP.CertificateThumbprint
                }
                It 'should call Get-WSManInstance once' {
                    Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
                }
            }
        }

        Describe "$($Global:DSCResourceName)\Set-TargetResource" {

            Context 'HTTP Listener does not exist but should' {

                Mock Get-WSManInstance -MockWith { }
                Mock Remove-WSManInstance -MockWith { }
                Mock New-WSManInstance -MockWith { }

                It 'should not throw error' {
                    { Set-TargetResource `
                        -Transport $MockListenerHTTP.Transport `
                        -Ensure 'Present' } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
                    Assert-MockCalled -commandName Remove-WSManInstance -Exactly 0
                    Assert-MockCalled -commandName New-WSManInstance -Exactly 1
                }
            }
            Context 'HTTPS Listener does not exist but should' {

                Mock Get-WSManInstance -MockWith { }
                Mock Remove-WSManInstance -MockWith { }
                Mock New-WSManInstance -MockWith { }
                Mock Get-ChildItem -MockWith { $MockCertificate }

                It 'should not throw error' {
                    { Set-TargetResource `
                        -Transport $MockListenerHTTPS.Transport `
                        -Ensure 'Present' `
                        -Issuer $MockIssuer } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
                    Assert-MockCalled -commandName Remove-WSManInstance -Exactly 0
                    Assert-MockCalled -commandName New-WSManInstance -Exactly 1
                    Assert-MockCalled -commandName Get-ChildItem -Exactly 1
                }
            }

            Context 'HTTP Listener exists but should not' {

                Mock Get-WSManInstance -MockWith { return @($MockListenerHTTP) }
                Mock Remove-WSManInstance -MockWith { }
                Mock New-WSManInstance -MockWith { }

                It 'should not throw error' {
                    { Set-TargetResource `
                        -Transport $MockListenerHTTP.Transport `
                        -Ensure 'Absent' } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
                    Assert-MockCalled -commandName Remove-WSManInstance -Exactly 1
                    Assert-MockCalled -commandName New-WSManInstance -Exactly 0
                }
            }

            Context 'HTTP Listener exists and should' {

                Mock Get-WSManInstance -MockWith { return @($MockListenerHTTP) }
                Mock Remove-WSManInstance -MockWith { }
                Mock New-WSManInstance -MockWith { }
                Mock Get-ChildItem -MockWith { $MockCertificate }

                It 'should not throw error' {
                    { Set-TargetResource `
                        -Transport $MockListenerHTTP.Transport `
                        -Ensure 'Present' `
                        -Issuer $MockIssuer } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
                    Assert-MockCalled -commandName Remove-WSManInstance -Exactly 1
                    Assert-MockCalled -commandName New-WSManInstance -Exactly 1
                    Assert-MockCalled -commandName Get-ChildItem -Exactly 0
                }
            }

            Context 'HTTPS Listener exists and should' {

                Mock Get-WSManInstance -MockWith { return @($MockListenerHTTPS) }
                Mock Remove-WSManInstance -MockWith { }
                Mock New-WSManInstance -MockWith { }
                Mock Get-ChildItem -MockWith { $MockCertificate }

                It 'should not throw error' {
                    { Set-TargetResource `
                        -Transport $MockListenerHTTPS.Transport `
                        -Ensure 'Present' `
                        -Issuer $MockIssuer } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
                    Assert-MockCalled -commandName Remove-WSManInstance -Exactly 1
                    Assert-MockCalled -commandName New-WSManInstance -Exactly 1
                    Assert-MockCalled -commandName Get-ChildItem -Exactly 1
                }
            }

            Context 'Both Listeners exists and HTTPS should' {

                Mock Get-WSManInstance -MockWith { return @($MockListenerHTTP,$MockListenerHTTPS) }
                Mock Remove-WSManInstance -MockWith { }
                Mock New-WSManInstance -MockWith { }
                Mock Get-ChildItem -MockWith { $MockCertificate }

                It 'should not throw error' {
                    { Set-TargetResource `
                        -Transport $MockListenerHTTPS.Transport `
                        -Ensure 'Present' `
                        -Issuer $MockIssuer } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
                    Assert-MockCalled -commandName Remove-WSManInstance -Exactly 1
                    Assert-MockCalled -commandName New-WSManInstance -Exactly 1
                    Assert-MockCalled -commandName Get-ChildItem -Exactly 1
                }
            }
        }

        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
            Context 'HTTP Listener does not exist but should' {

                Mock Get-WSManInstance -MockWith { }

                It 'should return false' {
                    Test-TargetResource `
                        -Transport $MockListenerHTTP.Transport `
                        -Ensure 'Present' | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
                }
            }
            Context 'HTTPS Listener does not exist but should' {

                Mock Get-WSManInstance -MockWith { }

                It 'should return false' {
                    Test-TargetResource `
                        -Transport $MockListenerHTTPS.Transport `
                        -Ensure 'Present' `
                        -Issuer $MockIssuer | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
                }
            }

            Context 'HTTP Listener exists but should not' {

                Mock Get-WSManInstance -MockWith { return @($MockListenerHTTP) }

                It 'should return false' {
                    Test-TargetResource `
                        -Transport $MockListenerHTTP.Transport `
                        -Ensure 'Absent' | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
                }
            }

            Context 'HTTPS Listener exists but should not' {

                Mock Get-WSManInstance -MockWith { return @($MockListenerHTTPS) }

                It 'should return false' {
                    Test-TargetResource `
                        -Transport $MockListenerHTTPS.Transport `
                        -Ensure 'Absent' | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
                }
            }

            Context 'HTTP Listener exists and should' {

                Mock Get-WSManInstance -MockWith { return @($MockListenerHTTP) }

                It 'should return true' {
                    Test-TargetResource `
                        -Transport $MockListenerHTTP.Transport `
                        -Ensure 'Present' | Should Be $True
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
                }
            }

            Context 'HTTPS Listener exists and should' {

                Mock Get-WSManInstance -MockWith { return @($MockListenerHTTPS) }

                It 'should return true' {
                    Test-TargetResource `
                        -Transport $MockListenerHTTPS.Transport `
                        -Ensure 'Present' | Should Be $True
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
                }
            }

            Context 'Both Listeners exists and HTTPS should' {

                Mock Get-WSManInstance -MockWith { return @($MockListenerHTTP,$MockListenerHTTPS) }

                It 'should return true' {
                    Test-TargetResource `
                        -Transport $MockListenerHTTPS.Transport `
                        -Ensure 'Present' | Should Be $True
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
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
