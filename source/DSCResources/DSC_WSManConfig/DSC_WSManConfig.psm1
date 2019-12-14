$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Networking Resource Helper Module
Import-Module -Name (Join-Path -Path $modulePath `
    -ChildPath (Join-Path -Path 'WSManDsc.Common' `
        -ChildPath 'WSManDsc.Common.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData -ResourceName 'DSC_WSManConfig'

<#
    This is an array of all the parameters used by this resource.
    The default and testval properties are only used by unit/integration tests
    but is stored here so that a duplicate table does not have to be created.
    The IntTests controls whether or not this parameter should be tested using
    integration tests. This prevents integration tests from preventing the WS-Man
    from being completely locked out.
#>
$resourceData = Import-LocalizedData `
    -BaseDirectory $PSScriptRoot `
    -FileName 'DSC_WSManConfig.data.psd1'

$script:parameterList = $resourceData.ParameterList

<#
    .SYNOPSIS
        Returns the WS-Man configuration.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.GettingWSManConfigMessage)
        ) -join '' )

    # Generate the return object.
    $returnValue = @{
        IsSingleInstance = 'Yes'
    }

    foreach ($parameter in $script:parameterList)
    {
        $parameterPath = Join-Path `
            -Path 'WSMan:\Localhost\' `
            -ChildPath $($parameter.Path)
        $returnValue += @{
            $($parameter.Name) = (Get-Item -Path $parameterPath).Value
        }
    } # foreach

    return $returnValue
} # Get-TargetResource

<#
    .SYNOPSIS
        Sets the current WS-Man configuration.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'

    .PARAMETER MaxEnvelopeSizekb
        Specifies the WS-Man maximum envelope size in KB. The minimum value is 32 and the maximum is 4294967295.

    .PARAMETER MaxTimeoutms
        Specifies the WS-Man maximum timeout in milliseconds. The minimum value is 500 and the maximum is 4294967295.

    .PARAMETER MaxBatchItems
        Specifies the WS-Man maximum batch items. The minimum value is 1 and the maximum is 4294967295.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [ValidateRange(32,4294967295)]
        [System.Uint32]
        $MaxEnvelopeSizekb,

        [Parameter()]
        [ValidateRange(500,4294967295)]
        [System.Uint32]
        $MaxTimeoutms,

        [Parameter()]
        [ValidateRange(1,4294967295)]
        [System.Uint32]
        $MaxBatchItems
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.SettingWSManConfigMessage)
        ) -join '' )

    # Step through each parameter and update any that differ
    foreach ($parameter in $script:parameterList)
    {
        $parameterPath = Join-Path `
            -Path 'WSMan:\Localhost\' `
            -ChildPath $parameter.Path

        $parameterCurrent = (Get-Item -Path $parameterPath).Value
        $parameterNew = (Get-Variable -Name $parameter.Name).Value

        if ($PSBoundParameters.ContainsKey($parameter.Name) `
            -and ($parameterCurrent -ne $parameterNew))
        {
            Set-Item -Path $parameterPath -Value $parameterNew -Force

            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.WSManConfigUpdateParameterMessage) `
                    -f $parameter.Name,$parameterCurrent,$parameterNew
                ) -join '' )
        } # if
    } # foreach
} # Set-TargetResource

<#
    .SYNOPSIS
        Tests the current WS-Man configuration to see if any changes need to be made.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'

    .PARAMETER MaxEnvelopeSizekb
        Specifies the WS-Man maximum envelope size in KB. The minimum value is 32 and the maximum is 4294967295.

    .PARAMETER MaxTimeoutms
        Specifies the WS-Man maximum timeout in milliseconds. The minimum value is 500 and the maximum is 4294967295.

    .PARAMETER MaxBatchItems
        Specifies the WS-Man maximum batch items. The minimum value is 1 and the maximum is 4294967295.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [ValidateRange(32,4294967295)]
        [System.Uint32]
        $MaxEnvelopeSizekb,

        [Parameter()]
        [ValidateRange(500,4294967295)]
        [System.Uint32]
        $MaxTimeoutms,

        [Parameter()]
        [ValidateRange(1,4294967295)]
        [System.Uint32]
        $MaxBatchItems
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.TestingWSManConfigMessage)
        ) -join '' )

    # Flag to signal whether settings are correct
    $desiredConfigurationMatch = $true

    # Check each parameter
    foreach ($parameter in $script:parameterList)
    {
        $parameterPath = Join-Path `
            -Path 'WSMan:\Localhost\' `
            -ChildPath $parameter.Path

        $parameterCurrent = (Get-Item -Path $parameterPath).Value
        $parameterNew = (Get-Variable -Name $parameter.Name).Value

        if ($PSBoundParameters.ContainsKey($parameter.Name) `
            -and ($parameterCurrent -ne $parameterNew))
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.WSManConfigParameterNeedsUpdateMessage) `
                    -f $parameter.Name,$parameterCurrent,$parameterNew
                ) -join '' )

            $desiredConfigurationMatch = $false
        } # if
    } # foreach

    return $desiredConfigurationMatch
} # Test-TargetResource

Export-ModuleMember -Function *-TargetResource
