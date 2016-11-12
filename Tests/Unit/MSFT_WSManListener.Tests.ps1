$script:DSCModuleName   = 'WSManDsc'
$script:DSCResourceName = 'MSFT_WSManListener'

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

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $script:DSCResourceName {
        $script:DSCResourceName = 'MSFT_WSManListener'
        # Function to create a exception object for testing output exceptions
        function Get-InvalidArguementException
        {
            [CmdletBinding()]
            param
            (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [String]
                $Message,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [String]
                $ArgumentName
            )

            $argumentException = New-Object -TypeName 'ArgumentException' -ArgumentList @( $Message,
                $ArgumentName )
            $newObjectParams = @{
                TypeName = 'System.Management.Automation.ErrorRecord'
                ArgumentList = @( $argumentException, $ArgumentName, 'InvalidArgument', $null )
            }
            $errorRecord = New-Object @newObjectParams

            return $errorRecord
        } # end function Get-InvalidArguementException

        # Create the Mock Objects that will be used for running tests
        $MockFQDN = 'SERVER1.CONTOSO.COM'
        $MockCertificateThumbprint = '74FA31ADEA7FDD5333CED10910BFA6F665A1F2FC'
        $MockHostName = $([System.Net.Dns]::GetHostByName($ENV:computerName).Hostname)
        $MockIssuer = 'CN=CONTOSO.COM Issuing CA, DC=CONTOSO, DC=COM'
        $MockDN = 'O=Contoso Inc, ST=Pennsylvania, C=US'
        $MockCertificate = [PSObject]@{
            Thumbprint = $MockCertificateThumbprint
            Subject = "CN=$MockHostName"
            Issuer = $MockIssuer
            Extensions = @{ EnhancedKeyUsages = @{ FriendlyName = 'Server Authentication' } }
            DNSNameList = @{ Unicode = $MockHostname }
        }
        $MockCertificateDN = [PSObject]@{
            Thumbprint = $MockCertificateThumbprint
            Subject = "CN=$MockHostname,$MockDN"
            Issuer = $MockIssuer
            Extensions = @{ EnhancedKeyUsages = @{ FriendlyName = 'Server Authentication' } }
            DNSNameList = @{ Unicode = $MockHostname }
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

        Describe "$($script:DSCResourceName)\Get-TargetResource" {

            Mock -CommandName Get-WSManInstance

            Context 'No listeners exist' {
                It 'should return absent listener' {
                    $Result = Get-TargetResource `
                        -Transport HTTP `
                        -Ensure Present
                    $Result.Ensure | Should Be 'Absent'
                }
                It 'should call Get-WSManInstance once' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly 1
                }
            }

            Mock -CommandName Get-WSManInstance -MockWith { return @($MockListenerHTTP) }

            Context 'Requested listener does not exist' {
                It 'should return absent listener' {
                    $Result = Get-TargetResource `
                        -Transport $MockListenerHTTPS.Transport `
                        -Ensure Present
                    $Result.Ensure | Should Be 'Absent'
                }
                It 'should call Get-WSManInstance once' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly 1
                }
            }

            Context 'Requested listener does exist' {
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
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly 1
                }
            }
        }

        Describe "$($script:DSCResourceName)\Set-TargetResource" {

            Mock -CommandName Get-WSManInstance
            Mock -CommandName Remove-WSManInstance
            Mock -CommandName New-WSManInstance
            Mock -CommandName Find-Certificate

            Context 'HTTP Listener does not exist but should' {
                It 'should not throw error' {
                    { Set-TargetResource `
                        -Transport $MockListenerHTTP.Transport `
                        -Ensure 'Present' } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly 1
                    Assert-MockCalled -CommandName Remove-WSManInstance -Exactly 0
                    Assert-MockCalled -CommandName New-WSManInstance -Exactly 1
                    Assert-MockCalled -CommandName Find-Certificate -Exactly 0
                }
            }

            Mock -CommandName Find-Certificate -MockWith { return $MockCertificateThumbprint }

            Context 'HTTPS Listener does not exist but should' {
                It 'should not throw error' {
                    { Set-TargetResource `
                        -Transport $MockListenerHTTPS.Transport `
                        -Ensure 'Present' `
                        -Issuer $MockIssuer } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly 1
                    Assert-MockCalled -CommandName Remove-WSManInstance -Exactly 0
                    Assert-MockCalled -CommandName New-WSManInstance -Exactly 1
                    Assert-MockCalled -CommandName Find-Certificate -Exactly 1
                }
            }

            Mock -CommandName Find-Certificate

            Context 'HTTPS Listener does not exist but should but certificate missing' {
                $errorRecord = Get-InvalidArguementException `
                    -Message ($script:localizedData.ListenerCreateFailNoCertError -f `
                        $MockListenerHTTPS.Transport,'5986') `
                    -ArgumentName 'Issuer'
                It 'should throw error' {
                    { Set-TargetResource `
                        -Transport $MockListenerHTTPS.Transport `
                        -Ensure 'Present' `
                        -Issuer $MockIssuer } | Should Throw $errorRecord
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly 1
                    Assert-MockCalled -CommandName Remove-WSManInstance -Exactly 0
                    Assert-MockCalled -CommandName New-WSManInstance -Exactly 0
                    Assert-MockCalled -CommandName Find-Certificate -Exactly 1
                }
            }
            Mock -CommandName Get-WSManInstance -MockWith { return @($MockListenerHTTP) }
            Mock -CommandName Find-Certificate

            Context 'HTTP Listener exists but should not' {
                It 'should not throw error' {
                    { Set-TargetResource `
                        -Transport $MockListenerHTTP.Transport `
                        -Ensure 'Absent' } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly 1
                    Assert-MockCalled -CommandName Remove-WSManInstance -Exactly 1
                    Assert-MockCalled -CommandName New-WSManInstance -Exactly 0
                    Assert-MockCalled -CommandName Find-Certificate -Exactly 0
                }
            }

            Context 'HTTP Listener exists and should' {
                It 'should not throw error' {
                    { Set-TargetResource `
                        -Transport $MockListenerHTTP.Transport `
                        -Ensure 'Present' `
                        -Issuer $MockIssuer } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly 1
                    Assert-MockCalled -CommandName Remove-WSManInstance -Exactly 1
                    Assert-MockCalled -CommandName New-WSManInstance -Exactly 1
                    Assert-MockCalled -CommandName Find-Certificate -Exactly 0
                }
            }

            Mock -CommandName Get-WSManInstance -MockWith { return @($MockListenerHTTP) }
            Mock -CommandName Find-Certificate -MockWith { return $MockCertificateThumbprint }

            Context 'HTTP Listener exists and HTTPS is required' {
                It 'should not throw error' {
                    { Set-TargetResource `
                        -Transport $MockListenerHTTPS.Transport `
                        -Ensure 'Present' `
                        -Issuer $MockIssuer } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly 1
                    Assert-MockCalled -CommandName Remove-WSManInstance -Exactly 0
                    Assert-MockCalled -CommandName New-WSManInstance -Exactly 1
                    Assert-MockCalled -CommandName Find-Certificate -Exactly 1
                }
            }

            Mock -CommandName Get-WSManInstance -MockWith { return @($MockListenerHTTPS) }
            Mock -CommandName Find-Certificate

            Context 'HTTPS Listener exists and HTTP is required' {
                It 'should not throw error' {
                    { Set-TargetResource `
                        -Transport $MockListenerHTTP.Transport `
                        -Ensure 'Present' `
                        -Issuer $MockIssuer } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly 1
                    Assert-MockCalled -CommandName Remove-WSManInstance -Exactly 0
                    Assert-MockCalled -CommandName New-WSManInstance -Exactly 1
                    Assert-MockCalled -CommandName Find-Certificate -Exactly 0
                }
            }

            Mock -CommandName Get-WSManInstance -MockWith { return @($MockListenerHTTP,$MockListenerHTTPS) }
            Mock -CommandName Find-Certificate -MockWith { return $MockCertificateThumbprint }

            Context 'Both Listeners exist and HTTPS is required' {
                It 'should not throw error' {
                    { Set-TargetResource `
                        -Transport $MockListenerHTTPS.Transport `
                        -Ensure 'Present' `
                        -Issuer $MockIssuer } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly 1
                    Assert-MockCalled -CommandName Remove-WSManInstance -Exactly 1
                    Assert-MockCalled -CommandName New-WSManInstance -Exactly 1
                    Assert-MockCalled -CommandName Find-Certificate -Exactly 1
                }
            }

            Mock -CommandName Get-WSManInstance -MockWith { return @($MockListenerHTTP,$MockListenerHTTPS) }
            Mock -CommandName Find-Certificate

            Context 'Both Listeners exist and HTTP is required' {
                It 'should not throw error' {
                    { Set-TargetResource `
                        -Transport $MockListenerHTTP.Transport `
                        -Ensure 'Present' `
                        -Issuer $MockIssuer } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly 1
                    Assert-MockCalled -CommandName Remove-WSManInstance -Exactly 1
                    Assert-MockCalled -CommandName New-WSManInstance -Exactly 1
                    Assert-MockCalled -CommandName Find-Certificate -Exactly 0
                }
            }
        }

        Describe "$($script:DSCResourceName)\Test-TargetResource" {
            Mock -CommandName Get-WSManInstance

            Context 'HTTP Listener does not exist but should' {
                It 'should return false' {
                    Test-TargetResource `
                        -Transport $MockListenerHTTP.Transport `
                        -Ensure 'Present' | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly 1
                }
            }
            Context 'HTTPS Listener does not exist but should' {
                It 'should return false' {
                    Test-TargetResource `
                        -Transport $MockListenerHTTPS.Transport `
                        -Ensure 'Present' `
                        -Issuer $MockIssuer | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly 1
                }
            }

            Mock -CommandName Get-WSManInstance -MockWith { return @($MockListenerHTTP) }

            Context 'HTTP Listener exists but should not' {
                It 'should return false' {
                    Test-TargetResource `
                        -Transport $MockListenerHTTP.Transport `
                        -Ensure 'Absent' | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly 1
                }
            }

            Mock -CommandName Get-WSManInstance -MockWith { return @($MockListenerHTTPS) }

            Context 'HTTPS Listener exists but should not' {
                It 'should return false' {
                    Test-TargetResource `
                        -Transport $MockListenerHTTPS.Transport `
                        -Ensure 'Absent' | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly 1
                }
            }

            Mock -CommandName Get-WSManInstance -MockWith { return @($MockListenerHTTP) }

            Context 'HTTP Listener exists and should' {
                It 'should return true' {
                    Test-TargetResource `
                        -Transport $MockListenerHTTP.Transport `
                        -Ensure 'Present' | Should Be $True
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly 1
                }
            }

            Mock -CommandName Get-WSManInstance -MockWith { return @($MockListenerHTTPS) }

            Context 'HTTPS Listener exists and should' {
                It 'should return true' {
                    Test-TargetResource `
                        -Transport $MockListenerHTTPS.Transport `
                        -Ensure 'Present' | Should Be $True
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly 1
                }
            }

            Mock -CommandName Get-WSManInstance -MockWith { return @($MockListenerHTTP,$MockListenerHTTPS) }

            Context 'Both Listeners exists and HTTPS should' {
                It 'should return true' {
                    Test-TargetResource `
                        -Transport $MockListenerHTTPS.Transport `
                        -Ensure 'Present' | Should Be $True
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly 1
                }
            }
        }

        Describe "$($script:DSCResourceName)\Find-Certificate" {

            Mock -CommandName Get-ChildItem

            Context 'SubjectFormat is Both, Certificate does not exist, DN passed' {
                It 'should not throw error' {
                    { $script:ReturnedThumbprint = Find-Certificate `
                        -Issuer $MockIssuer `
                        -SubjectFormat 'Both' `
                        -MatchAlternate $True `
                        -DN $MockDN } | Should Not Throw
                }
                It "should return empty" {
                    $script:ReturnedThumbprint | Should BeNullOrEmpty
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly 2
                }
            }

            Mock -CommandName Get-ChildItem -MockWith { $MockCertificateDN }

            Context 'SubjectFormat is Both, Certificate with DN Exists, DN passed' {
                It 'should not throw error' {
                    { $script:ReturnedThumbprint = Find-Certificate `
                        -Issuer $MockIssuer `
                        -SubjectFormat 'Both' `
                        -MatchAlternate $True `
                        -DN $MockDN } | Should Not Throw
                }
                It "should return $MockCertificateThumbprint" {
                    $script:ReturnedThumbprint | Should Be $MockCertificateThumbprint
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly 1
                }
            }

            Mock -CommandName Get-ChildItem -MockWith { $MockCertificate }

            Context 'SubjectFormat is Both, Certificate without DN Exists, DN passed' {
                It 'should not throw error' {
                    { $script:ReturnedThumbprint = Find-Certificate `
                        -Issuer $MockIssuer `
                        -SubjectFormat 'Both' `
                        -MatchAlternate $True `
                        -DN $MockDN } | Should Not Throw
                }
                It "should return empty" {
                    $script:ReturnedThumbprint | Should BeNullOrEmpty
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly 2
                }
            }

            Mock -CommandName Get-ChildItem

            Context 'SubjectFormat is Both, Certificate does not exist, DN not passed' {
                It 'should not throw error' {
                    { $script:ReturnedThumbprint = Find-Certificate `
                        -Issuer $MockIssuer `
                        -SubjectFormat 'Both' `
                        -MatchAlternate $True } | Should Not Throw
                }
                It "should return empty" {
                    $script:ReturnedThumbprint | Should BeNullOrEmpty
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly 2
                }
            }

            Mock -CommandName Get-ChildItem -MockWith { $MockCertificateDN }

            Context 'SubjectFormat is Both, Certificate with DN Exists, DN not passed' {
                It 'should not throw error' {
                    { $script:ReturnedThumbprint = Find-Certificate `
                        -Issuer $MockIssuer `
                        -SubjectFormat 'Both' `
                        -MatchAlternate $True } | Should Not Throw
                }
                It "should return empty" {
                    $script:ReturnedThumbprint | Should BeNullOrEmpty
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly 2
                }
            }

            Mock -CommandName Get-ChildItem -MockWith { $MockCertificate }

            Context 'SubjectFormat is Both, Certificate without DN Exists, DN not passed' {
                It 'should not throw error' {
                    { $script:ReturnedThumbprint = Find-Certificate `
                        -Issuer $MockIssuer `
                        -SubjectFormat 'Both' `
                        -MatchAlternate $True } | Should Not Throw
                }
                It "should return $MockCertificateThumbprint" {
                    $script:ReturnedThumbprint | Should Be $MockCertificateThumbprint
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly 1
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
