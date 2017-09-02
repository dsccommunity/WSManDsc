[System.String] $repoRoot = Split-Path -Path (Split-Path -Path $Script:MyInvocation.MyCommand.Path)
if ( (-not (Test-Path -Path (Join-Path -Path $repoRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $repoRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $repoRoot -ChildPath 'Modules\WSManDsc\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $repoRoot -ChildPath 'Tests\TestHarness.psm1' -Resolve)
$dscTestsPath = Join-Path -Path $repoRoot -ChildPath 'Modules\WSManDsc\DscResource.Tests\Meta.Tests.ps1'
Invoke-TestHarness -DscTestsPath $dscTestsPath
