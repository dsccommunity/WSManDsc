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
    The default value is only used by unit/integration tests but is stored here so that a duplicate
    table does not have to be created.
#>
data ParameterList
{
    @(
        @{ Name = 'RootSDDL';                         Type = 'String';                 Default = 'O:NSG:BAD:P(A;;GA;;;BA)(A;;GR;;;IU)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)' },
        @{ Name = 'MaxConnections';                   Type = 'Uint32';                 Default = 300                                                                      },
        @{ Name = 'MaxConcurrentOperationsPerUser';   Type = 'Uint32';                 Default = 1500                                                                     },
        @{ Name = 'EnumerationTimeoutms';             Type = 'Uint32';                 Default = 240000                                                                   },
        @{ Name = 'MaxPacketRetrievalTimeSeconds';    Type = 'Uint32';                 Default = 120                                                                      },
        @{ Name = 'AllowUnencrypted';                 Type = 'Boolean';                Default = $false                                                                   },
        @{ Name = 'Basic';                            Type = 'Boolean'; Path = 'Auth'; Default = $false                                                                   },
        @{ Name = 'Kerberos';                         Type = 'Boolean'; Path = 'Auth'; Default = $true                                                                    },
        @{ Name = 'Negotiate';                        Type = 'Boolean'; Path = 'Auth'; Default = $true                                                                    },
        @{ Name = 'Certificate';                      Type = 'Boolean'; Path = 'Auth'; Default = $false                                                                   },
        @{ Name = 'CredSSP';                          Type = 'Boolean'; Path = 'Auth'; Default = $false                                                                   },
        @{ Name = 'CbtHardeningLevel';                Type = 'String';  Path = 'Auth'; Default = 'relaxed'                                                                },
        @{ Name = 'EnableCompatibilityHttpListener';  Type = 'Boolean';                Default = $false                                                                   },
        @{ Name = 'EnableCompatibilityHttpsListener'; Type = 'Boolean';                Default = $false                                                                   }
    )
}

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
        if ($parameter.Path)
        {
            $ParameterPath = Join-Path `
                -Path 'WSMan:\Localhost\Service\' `
                -ChildPath "$($parameter.Path)\$($parameter.Name)"
            $ParameterName = "$($parameter.Path)$($parameter.Name)"
        }
        else
        {
            $ParameterPath = Join-Path `
                -Path 'WSMan:\Localhost\Service\' `
                -ChildPath $($parameter.Path)
            $ParameterName = $($parameter.Name)
        } # if

        $ReturnValue += @{ $parameterName = (Get-Item -Path $ParameterPath).Value }
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

    # Get the current Dns Client Global Settings
    $WSManServiceConfig = Get-WSManServiceConfig `
        -ErrorAction Stop

    # Step through each parameter and update any that differ
    foreach ($parameter in $ParameterList)
    {
        if ($parameter.Path)
        {
            $ParameterPath = Join-Path `
                -Path 'WSMan:\Localhost\Service\' `
                -ChildPath "$($parameter.Path)\$($parameter.Name)"
            $ParameterName = "$($parameter.Path)$($parameter.Name)"
            $ParameterNew = (Invoke-Expression -Command "`$$ParameterName")
        }
        else
        {
            $ParameterPath = Join-Path `
                -Path 'WSMan:\Localhost\Service\' `
                -ChildPath $($parameter.Name)
            $ParameterName = $($parameter.Name)
            $ParameterNew = (Invoke-Expression -Command "`$$ParameterName")
        } # if

        $ParameterCurrent = (Get-Item -Path $ParameterPath).Value

        if ($PSBoundParameters.ContainsKey($ParameterName) `
            -and ($ParameterSource -ne $ParameterNew))
        {
            Set-Item -Path $ParameterPath -Value $ParameterNew -Force
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.WSManServiceConfigUpdateParameterMessage) `
                    -f $parameterName,$ParameterNew
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
        if ($parameter.Path)
        {
            $ParameterPath = Join-Path `
                -Path 'WSMan:\Localhost\Service\' `
                -ChildPath "$($parameter.Path)\$($parameter.Name)"
            $ParameterName = "$($parameter.Path)$($parameter.Name)"
            $ParameterNew = (Invoke-Expression -Command "`$$ParameterName")
        }
        else
        {
            $ParameterPath = Join-Path `
                -Path 'WSMan:\Localhost\Service\' `
                -ChildPath $($parameter.Name)
            $ParameterName = $($parameter.Name)
            $ParameterNew = (Invoke-Expression -Command "`$$ParameterName")
        } # if

        $ParameterCurrent = (Get-Item -Path $ParameterPath).Value

        if ($PSBoundParameters.ContainsKey($ParameterName) `
            -and ($ParameterCurrent -ne $ParameterNew))
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.WSManServiceConfigParameterNeedsUpdateMessage) `
                    -f $ParameterName,$ParameterCurrent,$ParameterNew
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

Export-ModuleMember -Function *-TargetResource -Variable ParameterList
