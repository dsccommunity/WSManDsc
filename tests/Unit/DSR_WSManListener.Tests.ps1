Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

$script:DSCModuleName   = 'WSManDsc'
$script:DSCResourceName = 'DSR_WSManListener'

$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

function Invoke-TestSetup
{
    Import-Module -Name DscResource.Test -Force

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {
        $script:DSCResourceName = 'DSR_WSManListener'

        # Create the Mock Objects that will be used for running tests
        $mockFQDN = 'SERVER1.CONTOSO.COM'
        $mockCertificateThumbprint = '74FA31ADEA7FDD5333CED10910BFA6F665A1F2FC'
        $mockHostName = $([System.Net.Dns]::GetHostByName($ENV:computerName).Hostname)
        $mockIssuer = 'CN=CONTOSO.COM Issuing CA, DC=CONTOSO, DC=COM'
        $mockDN = 'O=Contoso Inc, S=Pennsylvania, C=US'

        $mockCertificate = [PSObject] @{
            Thumbprint = $mockCertificateThumbprint
            Subject = "CN=$mockHostName"
            Issuer = $mockIssuer
            Extensions = @{ EnhancedKeyUsages = @{ FriendlyName = 'Server Authentication' } }
            DNSNameList = @{ Unicode = $mockHostName }
        }

        $mockCertificateDN = [PSObject] @{
            Thumbprint = $mockCertificateThumbprint
            Subject = "CN=$mockHostName, $mockDN"
            Issuer = $mockIssuer
            Extensions = @{ EnhancedKeyUsages = @{ FriendlyName = 'Server Authentication' } }
            DNSNameList = @{ Unicode = $mockHostName }
        }

        $mockListenerHTTP = [PSObject] @{
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

        $mockListenerHTTPS = [PSObject] @{
            cfg = 'http://schemas.microsoft.com/wbem/wsman/1/config/listener'
            xsi = 'http://www.w3.org/2001/XMLSchema-instance'
            lang = 'en-US'
            Address = '*'
            Transport = 'HTTPS'
            Port = 5986
            Hostname = $mockFQDN
            Enabled = 'true'
            URLPrefix = 'wsman'
            CertificateThumbprint = $mockCertificateThumbprint
        }

        Describe "$($script:DSCResourceName)\Get-TargetResource" {
            Context 'No listeners exist' {
                Mock -CommandName Get-WSManInstance

                It 'Should return absent listener' {
                    $result = Get-TargetResource `
                        -Transport HTTP `
                        -Ensure Present `
                        -Verbose
                    $result.Ensure | Should -Be 'Absent'
                }

                It 'Should call Get-WSManInstance once' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly -Times 1
                }
            }

            Context 'Requested listener does not exist' {
                Mock -CommandName Get-WSManInstance -MockWith {
                    @($mockListenerHTTP)
                }

                It 'Should return absent listener' {
                    $result = Get-TargetResource `
                        -Transport $mockListenerHTTPS.Transport `
                        -Ensure Present `
                        -Verbose

                    $result.Ensure | Should -Be 'Absent'
                }

                It 'Should call Get-WSManInstance once' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly -Times 1
                }
            }

            Context 'Requested listener does exist' {
                Mock -CommandName Get-WSManInstance -MockWith {
                    @($mockListenerHTTP)
                }

                It 'Should return correct listener' {
                    $result = Get-TargetResource `
                        -Transport $mockListenerHTTP.Transport `
                        -Ensure Present `
                        -Verbose

                    $result.Ensure | Should -Be 'Present'
                    $result.Port | Should -Be $mockListenerHTTP.Port
                    $result.Address | Should -Be $mockListenerHTTP.Address
                    $result.HostName | Should -Be $mockListenerHTTP.HostName
                    $result.Enabled | Should -Be $mockListenerHTTP.Enabled
                    $result.URLPrefix | Should -Be $mockListenerHTTP.URLPrefix
                    $result.CertificateThumbprint | Should -Be $mockListenerHTTP.CertificateThumbprint
                }

                It 'Should call Get-WSManInstance once' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly -Times 1
                }
            }
        }

        Describe "$($script:DSCResourceName)\Set-TargetResource" {
            Context 'HTTP Listener does not exist but should' {
                Mock -CommandName Get-WSManInstance
                Mock -CommandName Remove-WSManInstance
                Mock -CommandName New-WSManInstance
                Mock -CommandName Find-Certificate

                It 'Should not throw error' {
                    { Set-TargetResource `
                        -Transport $mockListenerHTTP.Transport `
                        -Ensure 'Present' `
                        -Verbose } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly -Times 1
                    Assert-MockCalled -CommandName Remove-WSManInstance -Exactly -Times 0
                    Assert-MockCalled -CommandName New-WSManInstance -Exactly -Times 1
                    Assert-MockCalled -CommandName Find-Certificate -Exactly -Times 0
                }
            }

            Context 'HTTPS Listener does not exist but should' {
                Mock -CommandName Get-WSManInstance
                Mock -CommandName Remove-WSManInstance
                Mock -CommandName New-WSManInstance
                Mock -CommandName Find-Certificate -MockWith {
                    return $mockCertificate
                }

                It 'Should not throw error' {
                    { Set-TargetResource `
                        -Transport $mockListenerHTTPS.Transport `
                        -Ensure 'Present' `
                        -Issuer $mockIssuer `
                        -Verbose } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly -Times 1
                    Assert-MockCalled -CommandName Remove-WSManInstance -Exactly -Times 0
                    Assert-MockCalled -CommandName New-WSManInstance -Exactly -Times 1
                    Assert-MockCalled -CommandName Find-Certificate -Exactly -Times 1
                }
            }

            Context 'HTTPS Listener does not exist but should but certificate missing' {
                Mock -CommandName Get-WSManInstance
                Mock -CommandName Remove-WSManInstance
                Mock -CommandName New-WSManInstance
                Mock -CommandName Find-Certificate

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($script:localizedData.ListenerCreateFailNoCertError -f `
                        $mockListenerHTTPS.Transport,'5986') `
                    -ArgumentName 'Issuer'

                    It 'Should throw error' {
                    { Set-TargetResource `
                        -Transport $mockListenerHTTPS.Transport `
                        -Ensure 'Present' `
                        -Issuer $mockIssuer `
                        -Verbose } | Should -Throw $errorRecord
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly -Times 1
                    Assert-MockCalled -CommandName Remove-WSManInstance -Exactly -Times 0
                    Assert-MockCalled -CommandName New-WSManInstance -Exactly -Times 0
                    Assert-MockCalled -CommandName Find-Certificate -Exactly -Times 1
                }
            }

            Context 'HTTP Listener exists but should not' {
                Mock -CommandName Get-WSManInstance -MockWith {
                    @($mockListenerHTTP)
                }
                Mock -CommandName Remove-WSManInstance
                Mock -CommandName New-WSManInstance
                Mock -CommandName Find-Certificate

                It 'Should not throw error' {
                    { Set-TargetResource `
                        -Transport $mockListenerHTTP.Transport `
                        -Ensure 'Absent'  `
                        -Verbose} | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly -Times 1
                    Assert-MockCalled -CommandName Remove-WSManInstance -Exactly -Times 1
                    Assert-MockCalled -CommandName New-WSManInstance -Exactly -Times 0
                    Assert-MockCalled -CommandName Find-Certificate -Exactly -Times 0
                }
            }

            Context 'HTTP Listener exists and should' {
                Mock -CommandName Get-WSManInstance -MockWith {
                    @($mockListenerHTTP)
                }
                Mock -CommandName Remove-WSManInstance
                Mock -CommandName New-WSManInstance
                Mock -CommandName Find-Certificate

                It 'Should not throw error' {
                    { Set-TargetResource `
                        -Transport $mockListenerHTTP.Transport `
                        -Ensure 'Present' `
                        -Issuer $mockIssuer  `
                        -Verbose} | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly -Times 1
                    Assert-MockCalled -CommandName Remove-WSManInstance -Exactly -Times 1
                    Assert-MockCalled -CommandName New-WSManInstance -Exactly -Times 1
                    Assert-MockCalled -CommandName Find-Certificate -Exactly -Times 0
                }
            }

            Context 'HTTP Listener exists and HTTPS is required' {
                Mock -CommandName Get-WSManInstance -MockWith {
                    @($mockListenerHTTP)
                }
                Mock -CommandName Remove-WSManInstance
                Mock -CommandName New-WSManInstance
                Mock -CommandName Find-Certificate -MockWith {
                    $mockCertificate
                }

                It 'Should not throw error' {
                    { Set-TargetResource `
                        -Transport $mockListenerHTTPS.Transport `
                        -Ensure 'Present' `
                        -Issuer $mockIssuer  `
                        -Verbose} | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly -Times 1
                    Assert-MockCalled -CommandName Remove-WSManInstance -Exactly -Times 0
                    Assert-MockCalled -CommandName New-WSManInstance -Exactly -Times 1
                    Assert-MockCalled -CommandName Find-Certificate -Exactly -Times 1
                }
            }

            Context 'HTTPS Listener exists and HTTP is required' {
                Mock -CommandName Get-WSManInstance -MockWith {
                    @($mockListenerHTTPS)
                }
                Mock -CommandName Remove-WSManInstance
                Mock -CommandName New-WSManInstance
                Mock -CommandName Find-Certificate

                It 'Should not throw error' {
                    { Set-TargetResource `
                        -Transport $mockListenerHTTP.Transport `
                        -Ensure 'Present' `
                        -Issuer $mockIssuer  `
                        -Verbose} | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly -Times 1
                    Assert-MockCalled -CommandName Remove-WSManInstance -Exactly -Times 0
                    Assert-MockCalled -CommandName New-WSManInstance -Exactly -Times 1
                    Assert-MockCalled -CommandName Find-Certificate -Exactly -Times 0
                }
            }

            Context 'Both Listeners exist and HTTPS is required' {
                Mock -CommandName Get-WSManInstance -MockWith {
                    @($mockListenerHTTP,$mockListenerHTTPS)
                }
                Mock -CommandName Remove-WSManInstance
                Mock -CommandName New-WSManInstance
                Mock -CommandName Find-Certificate -MockWith {
                    $mockCertificate
                }

                It 'Should not throw error' {
                    { Set-TargetResource `
                        -Transport $mockListenerHTTPS.Transport `
                        -Ensure 'Present' `
                        -Issuer $mockIssuer  `
                        -Verbose} | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly -Times 1
                    Assert-MockCalled -CommandName Remove-WSManInstance -Exactly -Times 1
                    Assert-MockCalled -CommandName New-WSManInstance -Exactly -Times 1
                    Assert-MockCalled -CommandName Find-Certificate -Exactly -Times 1
                }
            }

            Context 'Both Listeners exist and HTTP is required' {
                Mock -CommandName Get-WSManInstance -MockWith {
                    @($mockListenerHTTP,$mockListenerHTTPS)
                }
                Mock -CommandName Remove-WSManInstance
                Mock -CommandName New-WSManInstance
                Mock -CommandName Find-Certificate

                It 'Should not throw error' {
                    { Set-TargetResource `
                        -Transport $mockListenerHTTP.Transport `
                        -Ensure 'Present' `
                        -Issuer $mockIssuer  `
                        -Verbose} | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly -Times 1
                    Assert-MockCalled -CommandName Remove-WSManInstance -Exactly -Times 1
                    Assert-MockCalled -CommandName New-WSManInstance -Exactly -Times 1
                    Assert-MockCalled -CommandName Find-Certificate -Exactly -Times 0
                }
            }
        }

        Describe "$($script:DSCResourceName)\Test-TargetResource" {
            Context 'HTTP Listener does not exist but should' {
                Mock -CommandName Get-WSManInstance

                It 'Should return false' {
                    Test-TargetResource `
                        -Transport $mockListenerHTTP.Transport `
                        -Ensure 'Present'  `
                        -Verbose | Should -BeFalse
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly -Times 1
                }
            }

            Context 'HTTPS Listener does not exist but should' {
                Mock -CommandName Get-WSManInstance

                It 'Should return false' {
                    Test-TargetResource `
                        -Transport $mockListenerHTTPS.Transport `
                        -Ensure 'Present' `
                        -Issuer $mockIssuer  `
                        -Verbose | Should -BeFalse
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly -Times 1
                }
            }

            Context 'HTTP Listener exists but should not' {
                Mock -CommandName Get-WSManInstance -MockWith {
                    @($mockListenerHTTP)
                }

                It 'Should return false' {
                    Test-TargetResource `
                        -Transport $mockListenerHTTP.Transport `
                        -Ensure 'Absent'  `
                        -Verbose | Should -BeFalse
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly -Times 1
                }
            }

            Context 'HTTPS Listener exists but should not' {
                Mock -CommandName Get-WSManInstance -MockWith {
                    @($mockListenerHTTPS)
                }

                It 'Should return false' {
                    Test-TargetResource `
                        -Transport $mockListenerHTTPS.Transport `
                        -Ensure 'Absent'  `
                        -Verbose | Should -BeFalse
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly -Times 1
                }
            }

            Context 'HTTP Listener exists and should' {
                Mock -CommandName Get-WSManInstance -MockWith {
                    @($mockListenerHTTP)
                }

                It 'Should return true' {
                    Test-TargetResource `
                        -Transport $mockListenerHTTP.Transport `
                        -Ensure 'Present'  `
                        -Verbose | Should -BeTrue
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly -Times 1
                }
            }

            Context 'HTTPS Listener exists and should' {
                Mock -CommandName Get-WSManInstance -MockWith {
                    @($mockListenerHTTPS)
                }

                It 'Should return true' {
                    Test-TargetResource `
                        -Transport $mockListenerHTTPS.Transport `
                        -Ensure 'Present'  `
                        -Verbose | Should -BeTrue
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly -Times 1
                }
            }

            Context 'Both Listeners exists and HTTPS should' {
                Mock -CommandName Get-WSManInstance -MockWith {
                    @($mockListenerHTTP,$mockListenerHTTPS)
                }

                It 'Should return true' {
                    Test-TargetResource `
                        -Transport $mockListenerHTTPS.Transport `
                        -Ensure 'Present'  `
                        -Verbose | Should -BeTrue
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-WSManInstance -Exactly -Times 1
                }
            }
        }

        Describe "$($script:DSCResourceName)\Find-Certificate" {
            Context 'CertificateThumbprint is passed but does not exist' {
                Mock -CommandName Get-ChildItem

                It 'Should not throw error' {
                    { $script:returnedCertificate = Find-Certificate `
                        -CertificateThumbprint $mockCertificateThumbprint `
                        -Verbose } | Should -Not -Throw
                }

                It 'Should return null' {
                    $script:returnedCertificate | Should -BeNullOrEmpty
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'CertificateThumbprint is passed and does exist' {
                Mock -CommandName Get-ChildItem -MockWith {
                    $mockCertificateDN
                }

                It 'Should not throw error' {
                    { $script:returnedCertificate = Find-Certificate `
                        -CertificateThumbprint $mockCertificateThumbprint `
                        -Verbose } | Should -Not -Throw
                }

                It 'Should return expected certificate' {
                    $script:returnedCertificate.Thumbprint | Should -Be $mockCertificateThumbprint
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'SubjectFormat is Both, Certificate does not exist, DN passed' {
                Mock -CommandName Get-ChildItem

                It 'Should not throw error' {
                    { $script:returnedCertificate = Find-Certificate `
                        -Issuer $mockIssuer `
                        -SubjectFormat 'Both' `
                        -MatchAlternate $True `
                        -DN $mockDN  `
                        -Verbose } | Should -Not -Throw
                }

                It 'Should return null' {
                    $script:returnedCertificate | Should -BeNullOrEmpty
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 2
                }
            }

            Context 'SubjectFormat is Both, Certificate with DN Exists, DN passed' {
                Mock -CommandName Get-ChildItem -MockWith {
                    $mockCertificateDN
                }

                It 'Should not throw error' {
                    { $script:returnedCertificate = Find-Certificate `
                        -Issuer $mockIssuer `
                        -SubjectFormat 'Both' `
                        -MatchAlternate $True `
                        -DN $mockDN  `
                        -Verbose } | Should -Not -Throw
                }

                It 'Should return expected certificate' {
                    $script:returnedCertificate.Thumbprint | Should -Be $mockCertificateThumbprint
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }

            Context 'SubjectFormat is Both, Certificate without DN Exists, DN passed' {
                Mock -CommandName Get-ChildItem -MockWith {
                    $mockCertificate
                }

                It 'Should not throw error' {
                    { $script:returnedCertificate = Find-Certificate `
                        -Issuer $mockIssuer `
                        -SubjectFormat 'Both' `
                        -MatchAlternate $True `
                        -DN $mockDN  `
                        -Verbose } | Should -Not -Throw
                }

                It 'Should return null' {
                    $script:returnedCertificate | Should -BeNullOrEmpty
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 2
                }
            }

            Context 'SubjectFormat is Both, Certificate does not exist, DN not passed' {
                Mock -CommandName Get-ChildItem

                It 'Should not throw error' {
                    { $script:returnedCertificate = Find-Certificate `
                        -Issuer $mockIssuer `
                        -SubjectFormat 'Both' `
                        -MatchAlternate $True  `
                        -Verbose } | Should -Not -Throw
                }

                It 'Should return null' {
                    $script:returnedCertificate | Should -BeNullOrEmpty
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 2
                }
            }

            Context 'SubjectFormat is Both, Certificate with DN Exists, DN not passed' {
                Mock -CommandName Get-ChildItem -MockWith {
                    $mockCertificateDN
                }

                It 'Should not throw error' {
                    { $script:returnedCertificate = Find-Certificate `
                        -Issuer $mockIssuer `
                        -SubjectFormat 'Both' `
                        -MatchAlternate $True  `
                        -Verbose } | Should -Not -Throw
                }

                It 'Should return null' {
                    $script:returnedCertificate | Should -BeNullOrEmpty
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 2
                }
            }

            Context 'SubjectFormat is Both, Certificate without DN Exists, DN not passed' {
                Mock -CommandName Get-ChildItem -MockWith {
                    $mockCertificate
                }

                It 'Should not throw error' {
                    { $script:returnedCertificate = Find-Certificate `
                        -Issuer $mockIssuer `
                        -SubjectFormat 'Both' `
                        -MatchAlternate $True  `
                        -Verbose } | Should -Not -Throw
                }

                It 'Should return expected certificate' {
                    $script:returnedCertificate.Thumbprint | Should -Be $mockCertificateThumbprint
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
