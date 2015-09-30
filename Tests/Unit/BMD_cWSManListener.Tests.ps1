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
            
            Mock Get-WSManInstance  -MockWith { }

            It 'should return absent listener' {
                $Result = Get-TargetResource -Port 5985 -Transport HTTP -Ensure Present
                $Result.Ensure | Should Be 'Absent'
            }
            It 'should call Get-WSManInstance once' {
                Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
            }
        }

        Context 'Requested listener does not exist' {
            
            Mock Get-WSManInstance  -MockWith { return @($Global:MockListenerHTTP) }

            It 'should return absent listener' {
                $Result = Get-TargetResource `
                    -Port $Global:MockListenerHTTPS.Port `
                    -Transport $Global:MockListenerHTTPS.Transport `
                    -Ensure Present
                $Result.Ensure | Should Be 'Absent'
            }
            It 'should call Get-WSManInstance once' {
                Assert-MockCalled -commandName Get-WSManInstance -Exactly 1
            }
        }

        Context 'Listener exists' {
            
            Mock Get-WSManInstance -MockWith { return @($Global:MockListenerHTTP) }

            It 'should return correct listener' {
                $Result = Get-TargetResource `
                    -Port $Global:MockListenerHTTP.Port `
                    -Transport $Global:MockListenerHTTP.Transport `
                    -Ensure Present
                $Result.Ensure | Should Be 'Present'
                $Result.Transport | Should Be $Global:MockListenerHTTP.Transport
                $Result.HostName | Should Be $Global:MockListenerHTTP.HostName
                $Result.Enabled | Should Be $Global:MockListenerHTTP.Enabled
                $Result.Address | Should Be $Global:MockListenerHTTP.Address
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

    }

######################################################################################

    Describe 'Test-TargetResource' {

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