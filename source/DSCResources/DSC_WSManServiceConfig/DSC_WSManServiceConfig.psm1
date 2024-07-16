$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')

# Import Localization Strings
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    This is an array of all the parameters used by this resource.
    The default and testval properties are only used by unit/integration tests
    but is stored here so that a duplicate table does not have to be created.
    The IntTests controls whether or not this parameter should be tested using
    integration tests. This prevents integration tests from preventing the WS-Man
    Service from being completely locked out.
#>
$resourceData = Import-LocalizedData `
    -BaseDirectory $PSScriptRoot `
    -FileName 'DSC_WSManServiceConfig.data.psd1'

$script:parameterList = $resourceData.ParameterList

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
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
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

    foreach ($parameter in $script:parameterList)
    {
        $parameterPath = Join-Path `
            -Path 'WSMan:\Localhost\Service\' `
            -ChildPath $($parameter.Path)
        $returnValue += @{
            $($parameter.Name) = (Get-Item -Path $ParameterPath).Value
        }
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
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [System.String]
        $RootSDDL,

        [Parameter()]
        [System.Uint32]
        $MaxConnections,

        [Parameter()]
        [System.Uint32]
        $MaxConcurrentOperationsPerUser,

        [Parameter()]
        [System.Uint32]
        $EnumerationTimeoutMS,

        [Parameter()]
        [System.Uint32]
        $MaxPacketRetrievalTimeSeconds,

        [Parameter()]
        [System.Boolean]
        $AllowUnencrypted,

        [Parameter()]
        [System.Boolean]
        $AuthBasic,

        [Parameter()]
        [System.Boolean]
        $AuthKerberos,

        [Parameter()]
        [System.Boolean]
        $AuthNegotiate,

        [Parameter()]
        [System.Boolean]
        $AuthCertificate,

        [Parameter()]
        [System.Boolean]
        $AuthCredSSP,

        [Parameter()]
        [ValidateSet('Strict', 'Relaxed', 'None')]
        [System.String]
        $AuthCbtHardeningLevel,

        [Parameter()]
        [System.Boolean]
        $EnableCompatibilityHttpListener,

        [Parameter()]
        [System.Boolean]
        $EnableCompatibilityHttpsListener
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.SettingWSManServiceConfigMessage)
        ) -join '' )

    # Step through each parameter and update any that differ
    foreach ($parameter in $script:parameterList)
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
                    -f $parameter.Name, $parameterCurrent, $parameterNew
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
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [System.String]
        $RootSDDL,

        [Parameter()]
        [System.Uint32]
        $MaxConnections,

        [Parameter()]
        [System.Uint32]
        $MaxConcurrentOperationsPerUser,

        [Parameter()]
        [System.Uint32]
        $EnumerationTimeoutMS,

        [Parameter()]
        [System.Uint32]
        $MaxPacketRetrievalTimeSeconds,

        [Parameter()]
        [System.Boolean]
        $AllowUnencrypted,

        [Parameter()]
        [System.Boolean]
        $AuthBasic,

        [Parameter()]
        [System.Boolean]
        $AuthKerberos,

        [Parameter()]
        [System.Boolean]
        $AuthNegotiate,

        [Parameter()]
        [System.Boolean]
        $AuthCertificate,

        [Parameter()]
        [System.Boolean]
        $AuthCredSSP,

        [Parameter()]
        [ValidateSet('Strict', 'Relaxed', 'None')]
        [System.String]
        $AuthCbtHardeningLevel,

        [Parameter()]
        [System.Boolean]
        $EnableCompatibilityHttpListener,

        [Parameter()]
        [System.Boolean]
        $EnableCompatibilityHttpsListener
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.TestingWSManServiceConfigMessage)
        ) -join '' )

    $currentSettings = Get-TargetResource `
        -IsSingleInstance $IsSingleInstance `
        -Verbose:$VerbosePreference

    return Test-DscParameterState `
        -CurrentValues $currentSettings `
        -DesiredValues $PSBoundParameters `
        -TurnOffTypeChecking `
        -ExcludeProperties @('IsSingleInstance') `
        -Verbose:$VerbosePreference
} # Test-TargetResource

Export-ModuleMember -Function *-TargetResource
