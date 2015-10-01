$DSCResourceName = 'BMD_cWSManListener'
$DSCModuleName   = 'cWSMan'

$Splat = @{
    Path = $PSScriptRoot
    ChildPath = "..\..\DSCResources\$DSCResourceName\$DSCResourceName.psm1"
    Resolve = $true
    ErrorAction = 'Stop'
}

$DSCResourceModuleFile = Get-Item -Path (Join-Path @Splat)

$moduleRoot = "${env:ProgramFiles}\WindowsPowerShell\Modules\$DSCModuleName"

if(-not (Test-Path -Path $moduleRoot))
{
    $null = New-Item -Path $moduleRoot -ItemType Directory
}
else
{
    # Copy the existing folder out to the temp directory to hold until the end of the run
    # Delete the folder to remove the old files.
    $tempLocation = Join-Path -Path $env:Temp -ChildPath $DSCModuleName
    Copy-Item -Path $moduleRoot -Destination $tempLocation -Recurse -Force
    Remove-Item -Path $moduleRoot -Recurse -Force
    $null = New-Item -Path $moduleRoot -ItemType Directory
}

Copy-Item -Path $PSScriptRoot\..\..\* -Destination $moduleRoot -Recurse -Force -Exclude '.git'

if (Get-Module -Name $DSCResourceName)
{
    Remove-Module -Name $DSCResourceName
}

Import-Module -Name $DSCResourceModuleFile.FullName -Force

$breakvar = $True

InModuleScope $DSCResourceName {

######################################################################################

    # Create the Mock Objects that will be used for running tests
    $Global:MockFQDN = 'SERVER1.CONTOSO.COM'
    $Global:MockCertificateThumbprint = '74FA31ADEA7FDD5333CED10910BFA6F665A1F2FC'
    $Global:MockIssuer = 'CN=CONTOSO.COM Issuing CA, DC=CONTOSO, DC=COM'
    $Global:MockCertificate = [PSObject]@{
        Thumbprint = $Global:MockCertificateThumbprint
        Subject = "CN=$([System.Net.Dns]::GetHostByName($ENV:computerName).Hostname)"
        Issuer = $Global:MockIssuer
        Extensions = @{ EnhancedKeyUsages = @{ FriendlyName = 'Server Authentication' } }
        DNSNameList = @{ Unicode = "$([System.Net.Dns]::GetHostByName($ENV:computerName).Hostname)" }
    }
    $Global:MockListenerHTTP = [PSObject]@{
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
    $Global:MockListenerHTTPS = [PSObject]@{
        cfg = 'http://schemas.microsoft.com/wbem/wsman/1/config/listener'
        xsi = 'http://www.w3.org/2001/XMLSchema-instance'
        lang = 'en-US'
        Address = '*'
        Transport = 'HTTPS'
        Port = 5986
        Hostname = $Global:MockFQDN
        Enabled = 'true'
        URLPrefix = 'wsman'
        CertificateThumbprint = $Global:MockCertificateThumbprint
    }

######################################################################################

    Describe 'Get-TargetResource' {

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
            
            Mock Get-WSManInstance -MockWith { return @($Global:MockListenerHTTP) }

            It 'should return absent listener' {
                $Result = Get-TargetResource `
                    -Transport $Global:MockListenerHTTPS.Transport `
                    -Ensure Present
                $Result.Ensure | Should Be 'Absent'
            }
            It 'should call Get-WSManInstance once' {
                Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
            }
        }

        Context 'Requested listener does exist' {
            
            Mock Get-WSManInstance -MockWith { return @($Global:MockListenerHTTP) }

            It 'should return correct listener' {
                $Result = Get-TargetResource `
                    -Transport $Global:MockListenerHTTP.Transport `
                    -Ensure Present
                $Result.Ensure | Should Be 'Present'
                $Result.Port | Should Be $Global:MockListenerHTTP.Port
                $Result.Address | Should Be $Global:MockListenerHTTP.Address
                $Result.HostName | Should Be $Global:MockListenerHTTP.HostName
                $Result.Enabled | Should Be $Global:MockListenerHTTP.Enabled
                $Result.URLPrefix | Should Be $Global:MockListenerHTTP.URLPrefix
                $Result.CertificateThumbprint | Should Be $Global:MockListenerHTTP.CertificateThumbprint
            }
            It 'should call Get-WSManInstance once' {
                Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
            }
        }
    }

######################################################################################

    Describe 'Set-TargetResource' {

        Context 'HTTP Listener does not exist but should' {
            
            Mock Get-WSManInstance -MockWith { }
            Mock Remove-WSManInstance -MockWith { }
            Mock New-WSManInstance -MockWith { }

            It 'should not throw error' {
                { Set-TargetResource `
                    -Transport $Global:MockListenerHTTP.Transport `
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
            Mock Get-ChildItem -MockWith { $Global:MockCertificate }

            It 'should not throw error' {
                { Set-TargetResource `
                    -Transport $Global:MockListenerHTTPS.Transport `
                    -Ensure 'Present' `
                    -Issuer $Global:MockIssuer } | Should Not Throw
            }
            It 'should call expected Mocks' {
                Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
                Assert-MockCalled -commandName Remove-WSManInstance -Exactly 0
                Assert-MockCalled -commandName New-WSManInstance -Exactly 1
                Assert-MockCalled -commandName Get-ChildItem -Exactly 1
            }
        }

        Context 'HTTP Listener exists but should not' {
            
            Mock Get-WSManInstance -MockWith { return @($Global:MockListenerHTTP) }
            Mock Remove-WSManInstance -MockWith { }
            Mock New-WSManInstance -MockWith { }

            It 'should not throw error' {
                { Set-TargetResource `
                    -Transport $Global:MockListenerHTTP.Transport `
                    -Ensure 'Absent' } | Should Not Throw
            }
            It 'should call expected Mocks' {
                Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
                Assert-MockCalled -commandName Remove-WSManInstance -Exactly 1
                Assert-MockCalled -commandName New-WSManInstance -Exactly 0
            }
        }

        Context 'HTTP Listener exists and should' {
            
            Mock Get-WSManInstance -MockWith { return @($Global:MockListenerHTTP) }
            Mock Remove-WSManInstance -MockWith { }
            Mock New-WSManInstance -MockWith { }
            Mock Get-ChildItem -MockWith { $Global:MockCertificate }

            It 'should not throw error' {
                { Set-TargetResource `
                    -Transport $Global:MockListenerHTTP.Transport `
                    -Ensure 'Present' `
                    -Issuer $Global:MockIssuer } | Should Not Throw
            }
            It 'should call expected Mocks' {
                Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
                Assert-MockCalled -commandName Remove-WSManInstance -Exactly 1
                Assert-MockCalled -commandName New-WSManInstance -Exactly 1
                Assert-MockCalled -commandName Get-ChildItem -Exactly 0
            }
        }

        Context 'HTTPS Listener exists and should' {
            
            Mock Get-WSManInstance -MockWith { return @($Global:MockListenerHTTPS) }
            Mock Remove-WSManInstance -MockWith { }
            Mock New-WSManInstance -MockWith { }
            Mock Get-ChildItem -MockWith { $Global:MockCertificate }

            It 'should not throw error' {
                { Set-TargetResource `
                    -Transport $Global:MockListenerHTTPS.Transport `
                    -Ensure 'Present' `
                    -Issuer $Global:MockIssuer } | Should Not Throw
            }
            It 'should call expected Mocks' {
                Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
                Assert-MockCalled -commandName Remove-WSManInstance -Exactly 1
                Assert-MockCalled -commandName New-WSManInstance -Exactly 1
                Assert-MockCalled -commandName Get-ChildItem -Exactly 1
            }
        }

        Context 'Both Listeners exists and HTTPS should' {
            
            Mock Get-WSManInstance -MockWith { return @($Global:MockListenerHTTP,$Global:MockListenerHTTPS) }
            Mock Remove-WSManInstance -MockWith { }
            Mock New-WSManInstance -MockWith { }
            Mock Get-ChildItem -MockWith { $Global:MockCertificate }

            It 'should not throw error' {
                { Set-TargetResource `
                    -Transport $Global:MockListenerHTTPS.Transport `
                    -Ensure 'Present' `
                    -Issuer $Global:MockIssuer } | Should Not Throw
            }
            It 'should call expected Mocks' {
                Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
                Assert-MockCalled -commandName Remove-WSManInstance -Exactly 1
                Assert-MockCalled -commandName New-WSManInstance -Exactly 1
                Assert-MockCalled -commandName Get-ChildItem -Exactly 1
            }
        }
    }

######################################################################################

    Describe 'Test-TargetResource' {
        Context 'HTTP Listener does not exist but should' {
            
            Mock Get-WSManInstance -MockWith { }

            It 'should return false' {
                Test-TargetResource `
                    -Transport $Global:MockListenerHTTP.Transport `
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
                    -Transport $Global:MockListenerHTTPS.Transport `
                    -Ensure 'Present' `
                    -Issuer $Global:MockIssuer | Should Be $False
            }
            It 'should call expected Mocks' {
                Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
            }
        }

        Context 'HTTP Listener exists but should not' {
            
            Mock Get-WSManInstance -MockWith { return @($Global:MockListenerHTTP) }

            It 'should return false' {
                Test-TargetResource `
                    -Transport $Global:MockListenerHTTP.Transport `
                    -Ensure 'Absent' | Should Be $False
            }
            It 'should call expected Mocks' {
                Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
            }
        }

        Context 'HTTPS Listener exists but should not' {
            
            Mock Get-WSManInstance -MockWith { return @($Global:MockListenerHTTPS) }

            It 'should return false' {
                Test-TargetResource `
                    -Transport $Global:MockListenerHTTPS.Transport `
                    -Ensure 'Absent' | Should Be $False
            }
            It 'should call expected Mocks' {
                Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
            }
        }

        Context 'HTTP Listener exists and should' {
            
            Mock Get-WSManInstance -MockWith { return @($Global:MockListenerHTTP) }

            It 'should return true' {
                Test-TargetResource `
                    -Transport $Global:MockListenerHTTP.Transport `
                    -Ensure 'Present' | Should Be $True
            }
            It 'should call expected Mocks' {
                Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
            }
        }

        Context 'HTTPS Listener exists and should' {
            
            Mock Get-WSManInstance -MockWith { return @($Global:MockListenerHTTPS) }

            It 'should return true' {
                Test-TargetResource `
                    -Transport $Global:MockListenerHTTPS.Transport `
                    -Ensure 'Present' | Should Be $True
            }
            It 'should call expected Mocks' {
                Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
            }
        }

        Context 'Both Listeners exists and HTTPS should' {
            
            Mock Get-WSManInstance -MockWith { return @($Global:MockListenerHTTP,$Global:MockListenerHTTPS) }

            It 'should return true' {
                Test-TargetResource `
                    -Transport $Global:MockListenerHTTPS.Transport `
                    -Ensure 'Present' | Should Be $True
            }
            It 'should call expected Mocks' {
                Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
            }
        }
    }

######################################################################################

}

# Clean up after the test completes.
Remove-Item -Path $moduleRoot -Recurse -Force

# Restore previous versions, if it exists.
if ($tempLocation)
{
    $null = New-Item -Path $moduleRoot -ItemType Directory
    $script:Destination = "${env:ProgramFiles}\WindowsPowerShell\Modules"
    Copy-Item -Path $tempLocation -Destination $script:Destination -Recurse -Force
    Remove-Item -Path $tempLocation -Recurse -Force
}