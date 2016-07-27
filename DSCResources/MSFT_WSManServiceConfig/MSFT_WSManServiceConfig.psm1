#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData `
        -BindingVariable LocalizedData `
        -Filename MSFT_WSManServiceConfig.psd1 `
        -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
}
else
{
    #fallback to en-US
    Import-LocalizedData `
        -BindingVariable LocalizedData `
        -Filename MSFT_WSManServiceConfig.psd1 `
        -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
    This is an array of all the parameters used by this resource.
    The default and testval properties are only used by unit/integration tests
    but is stored here so that a duplicate table does not have to be created.
    The IntTests controls whether or not this parameter should be tested using
    integration tests. This prevents integration tests from preventing the WS-Man
    Service from being completely locked out.
#>
$ParameterListPath = Join-Path `
    -Path $PSScriptRoot `
    -ChildPath 'MSFT_WSManServiceConfig.parameterlist.psd1'
$ParameterList = Invoke-Expression "DATA { $(Get-Content -Path $ParameterListPath -Raw) }"

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.GettingWSManServiceConfigMessage)
        ) -join '' )

    # Generate the return object.
    $ReturnValue = @{
        IsSingleInstance = 'Yes'
    }
    foreach ($parameter in $ParameterList)
    {
        $ParameterPath = Join-Path `
            -Path 'WSMan:\Localhost\Service\' `
            -ChildPath $($parameter.Path)
        $ReturnValue += @{ $($parameter.Name) = (Get-Item -Path $ParameterPath).Value }
    } # foreach

    return $ReturnValue
} # Get-TargetResource

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [String]
        $RootSDDL,

        [Uint32]
        $MaxConnections,

        [Uint32]
        $MaxConcurrentOperationsPerUser,

        [Uint32]
        $EnumerationTimeoutms,

        [Uint32]
        $MaxPacketRetrievalTimeSeconds,

        [Boolean]
        $AllowUnencrypted,

        [Boolean]
        $AuthBasic,

        [Boolean]
        $AuthKerberos,

        [Boolean]
        $AuthNegotiate,

        [Boolean]
        $AuthCertificate,

        [Boolean]
        $AuthCredSSP,

        [ValidateSet('Strict', 'Relaxed', 'None')]
        [String]
        $AuthCbtHardeningLevel,

        [Boolean]
        $EnableCompatibilityHttpListener,

        [Boolean]
        $EnableCompatibilityHttpsListener
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.SettingWSManServiceConfigMessage)
        ) -join '' )

    # Step through each parameter and update any that differ
    foreach ($parameter in $ParameterList)
    {
        $ParameterPath = Join-Path `
            -Path 'WSMan:\Localhost\Service\' `
            -ChildPath $parameter.Path

        $ParameterCurrent = (Get-Item -Path $ParameterPath).Value
        $ParameterNew = (Invoke-Expression -Command "`$$($Parameter.Name)")

        if ($PSBoundParameters.ContainsKey($Parameter.Name) `
            -and ($ParameterCurrent -ne $ParameterNew))
        {
            Set-Item -Path $ParameterPath -Value $ParameterNew -Force
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.WSManServiceConfigUpdateParameterMessage) `
                    -f $parameter.Name,$ParameterCurrent,$ParameterNew
                ) -join '' )
        } # if
    } # foreach
} # Set-TargetResource

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [String]
        $RootSDDL,

        [Uint32]
        $MaxConnections,

        [Uint32]
        $MaxConcurrentOperationsPerUser,

        [Uint32]
        $EnumerationTimeoutms,

        [Uint32]
        $MaxPacketRetrievalTimeSeconds,

        [Boolean]
        $AllowUnencrypted,

        [Boolean]
        $AuthBasic,

        [Boolean]
        $AuthKerberos,

        [Boolean]
        $AuthNegotiate,

        [Boolean]
        $AuthCertificate,

        [Boolean]
        $AuthCredSSP,

        [ValidateSet('Strict', 'Relaxed', 'None')]
        [String]
        $AuthCbtHardeningLevel,

        [Boolean]
        $EnableCompatibilityHttpListener,

        [Boolean]
        $EnableCompatibilityHttpsListener
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.TestingWSManServiceConfigMessage)
        ) -join '' )

    # Flag to signal whether settings are correct
    [Boolean] $DesiredConfigurationMatch = $true

    # Check each parameter
    foreach ($parameter in $ParameterList)
    {
        $ParameterPath = Join-Path `
            -Path 'WSMan:\Localhost\Service\' `
            -ChildPath $parameter.Path

        $ParameterCurrent = (Get-Item -Path $ParameterPath).Value
        $ParameterNew = (Invoke-Expression -Command "`$$($Parameter.Name)")

        if ($PSBoundParameters.ContainsKey($Parameter.Name) `
            -and ($ParameterCurrent -ne $ParameterNew))
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.WSManServiceConfigParameterNeedsUpdateMessage) `
                    -f $Parameter.Name,$ParameterCurrent,$ParameterNew
                ) -join '' )
            $desiredConfigurationMatch = $false
        } # if
    } # foreach

    return $DesiredConfigurationMatch
} # Test-TargetResource

function New-TerminatingError
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [String] $ErrorId,

        [Parameter(Mandatory)]
        [String] $ErrorMessage,

        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorCategory] $ErrorCategory
    )

    $exception = New-Object `
        -TypeName System.InvalidOperationException `
        -ArgumentList $errorMessage
    $errorRecord = New-Object `
        -TypeName System.Management.Automation.ErrorRecord `
        -ArgumentList $exception, $errorId, $errorCategory, $null
    $PSCmdlet.ThrowTerminatingError($errorRecord)
}

Export-ModuleMember -Function *-TargetResource
