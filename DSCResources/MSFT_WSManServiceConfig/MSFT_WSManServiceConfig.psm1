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
data ParameterList
{
    @(
        @{ Name    = 'RootSDDL';
           Path    = 'RootSDDL';
           Type    = 'String';
           Default = 'O:NSG:BAD:P(A;;GA;;;BA)(A;;GR;;;IU)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)';
           TestVal = 'O:BAG:SYD:PAI(D;OICI;FA;;;BG)(A;OICI;FA;;;BA)(A;OICIIO;FA;;;CO)(A;OICI;FA;;;SY)(A;OICI;FA;;;BU)S:AI(AU;OICINPFA;RPDTSDWD;;;BU)(AU;OICINPSA;CCSWRPDTLOSD;;;BU)';
           IntTest = $false;
        },
        @{ Name    = 'MaxConnections';
           Path    = 'MaxConnections';
           Type    = 'Uint32';
           Default = 300;
           TestVal = 301;
           IntTest = $false;
        },
        @{ Name    = 'MaxConcurrentOperationsPerUser';
           Path    = 'MaxConcurrentOperationsPerUser';
           Type    = 'Uint32';
           Default = 1500;
           TestVal = 1501;
           IntTest = $false;
        },
        @{ Name    = 'EnumerationTimeoutms';
           Path    = 'EnumerationTimeoutms';
           Type    = 'Uint32';
           Default = 240000;
           TestVal = 240001;
           IntTest = $false;
        },
        @{ Name    = 'MaxPacketRetrievalTimeSeconds';
           Path    = 'MaxPacketRetrievalTimeSeconds';
           Type    = 'Uint32';
           Default = 120;
           TestVal = 121;
           IntTest = $false;
        },
        @{ Name    = 'AllowUnencrypted';
           Path    = 'AllowUnencrypted';
           Type    = 'Boolean';
           Default = $false;
           TestVal = $true;
           IntTest = $false;
        },
        @{ Name    = 'AuthBasic';
           Path    = 'Auth\Basic';
           Type    = 'Boolean';
           Default = $false;
           TestVal = $true;
           IntTest = $false;
        },
        @{ Name    = 'AuthKerberos';
           Path    = 'Auth\Kerberos';
           Type    = 'Boolean';
           Default = $true;
           TestVal = $false;
           IntTest = $false;
        },
        @{ Name    = 'AuthNegotiate';
           Path    = 'Auth\Negotiate';
           Type    = 'Boolean';
           Default = $true;
           TestVal = $false;
           IntTest = $false;
        },
        @{ Name    = 'AuthCertificate';
           Path    = 'Auth\Certificate';
           Type    = 'Boolean';
           Default = $false;
           TestVal = $true;
           IntTest = $false;
        },
        @{ Name    = 'AuthCredSSP';
           Path    = 'Auth\CredSSP';
           Type    = 'Boolean';
           Default = $false;
           TestVal = $true;
           IntTest = $false;
        },
        @{ Name    = 'AuthCbtHardeningLevel';
           Path    = 'Auth\CbtHardeningLevel';
           Type    = 'String';
           Default = 'relaxed';
           TestVal = 'strict';
           IntTest = $false;
        },
        @{ Name    = 'EnableCompatibilityHttpListener';
           Path    = 'EnableCompatibilityHttpListener';
           Type    = 'Boolean';
           Default = $false;
           TestVal = $true;
           IntTest = $true;
        },
        @{ Name    = 'EnableCompatibilityHttpsListener';
           Path    = 'EnableCompatibilityHttpsListener';
           Type    = 'Boolean';
           Default = $false;
           TestVal = $true;
           IntTest = $true;
        }
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

Export-ModuleMember -Function *-TargetResource -Variable ParameterList
