[string] $repoRoot = Split-Path -Path (Split-Path -Path $Script:MyInvocation.MyCommand.Path)
[string] $dscResourceTestsPath = Join-Path -Path $repoRoot -ChildPath 'Modules\WSManDsc\DSCResource.Tests'
if ((-not (Test-Path -Path $dscResourceTestsPath)) -or `
     (-not (Test-Path -Path (Join-Path -Path $dscResourceTestsPath -ChildPath 'TestHelper.psm1'))))
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $repoRoot -ChildPath 'Modules\WSManDsc\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $repoRoot -ChildPath 'Tests\TestHarness.psm1' -Resolve)
[string] $dscTestsPath = Join-Path -Path $dscResourceTestsPath -ChildPath 'Meta.Tests.ps1'
Invoke-TestHarness -DscTestsPath $dscTestsPath
