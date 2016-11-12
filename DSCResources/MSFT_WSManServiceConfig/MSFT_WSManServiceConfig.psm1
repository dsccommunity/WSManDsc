Import-Module -Name (Join-Path -Path (Split-Path $PSScriptRoot -Parent) `
    -ChildPath 'CommonResourceHelper.psm1')

# Localized messages for Write-Verbose statements in this resource
$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_WSManServiceConfig'

<#
    This is an array of all the parameters used by this resource.
    The default and testval properties are only used by unit/integration tests
    but is stored here so that a duplicate table does not have to be created.
    The IntTests controls whether or not this parameter should be tested using
    integration tests. This prevents integration tests from completely locking
    out the WS-Man service and doing difficult to reverse damage to the OS config.
#>
$parameterList = Import-LocalizedData `
    -BaseDirectory $PSScriptRoot `
    -FileName 'MSFT_WSManServiceConfig.parameterlist.psd1'

<#
    .SYNOPSIS
    Returns the WS-Man Service configuration.
    .PARAMETER IsSingleInstance
    Specifies the resource is a single instance, the value must be 'Yes'
#>
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
            $($script:localizedData.GettingWSManServiceConfigMessage)
        ) -join '' )

    # Generate the return object.
    $returnValue = @{
        IsSingleInstance = 'Yes'
    }
    foreach ($parameter in $parameterList)
    {
        $ParameterPath = Join-Path `
            -Path 'WSMan:\Localhost\Service\' `
            -ChildPath $($parameter.Path)
        $returnValue += @{ $($parameter.Name) = (Get-Item -Path $ParameterPath).Value }
    } # foreach

    return $returnValue
} # Get-TargetResource

<#
    .SYNOPSIS
    Sets the current WS-Man Service configuration.
    .PARAMETER IsSingleInstance
    Specifies the resource is a single instance, the value must be 'Yes'
    .PARAMETER RootSDDL
    Specifies the security descriptor that controls remote access to the listener.
    .PARAMETER MaxConnections
    Specifies the maximum number of active requests that the service can process simultaneously.
    .PARAMETER MaxConcurrentOperationsPerUser
    Specifies the maximum number of concurrent operations that any user can remotely open on the
    same system.
    .PARAMETER EnumerationTimeoutMS
    Specifies the idle time-out in milliseconds between Pull messages.
    .PARAMETER MaxPacketRetrievalTimeSeconds
    Specifies the maximum length of time, in seconds, the WinRM service takes to retrieve a packet.
    .PARAMETER AllowUnencrypted
    Allows the client computer to request unencrypted traffic.
    .PARAMETER AuthBasic
    Allows the WinRM service to use Basic authentication.
    .PARAMETER AuthKerberos
    Allows the WinRM service to use Kerberos authentication.
    .PARAMETER AuthNegotiate
    Allows the WinRM service to use Negotiate authentication.
    .PARAMETER AuthCertificate
    Allows the WinRM service to use client certificate-based authentication.
    .PARAMETER AuthCredSSP
    Allows the WinRM service to use Credential Security Support Provider (CredSSP) authentication.
    .PARAMETER AuthCbtHardeningLevel
    Allows the client computer to request unencrypted traffic.
    .PARAMETER EnableCompatibilityHttpListener
    Specifies whether the compatibility HTTP listener is enabled.
    .PARAMETER EnableCompatibilityHttpsListener
    Specifies whether the compatibility HTTPS listener is enabled.
#>
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
        $EnumerationTimeoutMS,

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
            $($script:localizedData.SettingWSManServiceConfigMessage)
        ) -join '' )

    # Step through each parameter and update any that differ
    foreach ($parameter in $parameterList)
    {
        $parameterPath = Join-Path `
            -Path 'WSMan:\Localhost\Service\' `
            -ChildPath $parameter.Path

        $parameterCurrent = (Get-Item -Path $parameterPath).Value
        $parameterNew = (Get-Variable -Name $parameter.Name).Value

        if ($PSBoundParameters.ContainsKey($parameter.Name) `
            -and ($parameterCurrent -ne $parameterNew))
        {
            Set-Item -Path $parameterPath -Value $parameterNew -Force
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.WSManServiceConfigUpdateParameterMessage) `
                    -f $parameter.Name,$parameterCurrent,$parameterNew
                ) -join '' )
        } # if
    } # foreach
} # Set-TargetResource

<#
    .SYNOPSIS
    Tests the current WS-Man Service configuration to see if any changes need to be made.
    .PARAMETER IsSingleInstance
    Specifies the resource is a single instance, the value must be 'Yes'
    .PARAMETER RootSDDL
    Specifies the security descriptor that controls remote access to the listener.
    .PARAMETER MaxConnections
    Specifies the maximum number of active requests that the service can process simultaneously.
    .PARAMETER MaxConcurrentOperationsPerUser
    Specifies the maximum number of concurrent operations that any user can remotely open on the
    same system.
    .PARAMETER EnumerationTimeoutMS
    Specifies the idle time-out in milliseconds between Pull messages.
    .PARAMETER MaxPacketRetrievalTimeSeconds
    Specifies the maximum length of time, in seconds, the WinRM service takes to retrieve a packet.
    .PARAMETER AllowUnencrypted
    Allows the client computer to request unencrypted traffic.
    .PARAMETER AuthBasic
    Allows the WinRM service to use Basic authentication.
    .PARAMETER AuthKerberos
    Allows the WinRM service to use Kerberos authentication.
    .PARAMETER AuthNegotiate
    Allows the WinRM service to use Negotiate authentication.
    .PARAMETER AuthCertificate
    Allows the WinRM service to use client certificate-based authentication.
    .PARAMETER AuthCredSSP
    Allows the WinRM service to use Credential Security Support Provider (CredSSP) authentication.
    .PARAMETER AuthCbtHardeningLevel
    Allows the client computer to request unencrypted traffic.
    .PARAMETER EnableCompatibilityHttpListener
    Specifies whether the compatibility HTTP listener is enabled.
    .PARAMETER EnableCompatibilityHttpsListener
    Specifies whether the compatibility HTTPS listener is enabled.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
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
        $EnumerationTimeoutMS,

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
            $($script:localizedData.TestingWSManServiceConfigMessage)
        ) -join '' )

    # Flag to signal whether settings are correct
    [Boolean] $desiredConfigurationMatch = $true

    # Check each parameter
    foreach ($parameter in $parameterList)
    {
        $parameterPath = Join-Path `
            -Path 'WSMan:\Localhost\Service\' `
            -ChildPath $parameter.Path

        $parameterCurrent = (Get-Item -Path $parameterPath).Value
        $parameterNew = (Get-Variable -Name $parameter.Name).Value

        if ($PSBoundParameters.ContainsKey($parameter.Name) `
            -and ($parameterCurrent -ne $parameterNew))
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.WSManServiceConfigParameterNeedsUpdateMessage) `
                    -f $parameter.Name,$parameterCurrent,$parameterNew
                ) -join '' )
            $desiredConfigurationMatch = $false
        } # if
    } # foreach

    return $desiredConfigurationMatch
} # Test-TargetResource

# Helper Functions
<#
    .SYNOPSIS
    Throw a custome exception.
    .PARAMETER ErrorId
    The identifier representing the exception being thrown.
    .PARAMETER ErrorMessage
    The error message to be used for this exception.
    .PARAMETER ErrorCategory
    The exception error category.
#>
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
