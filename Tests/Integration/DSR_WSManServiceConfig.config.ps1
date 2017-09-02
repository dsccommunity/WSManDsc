# Load the parameter List from the data file
[System.String] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\WSManDsc'

# Load the parameter List from the data file
$resourceData = Import-LocalizedData `
    -BaseDirectory (Join-Path -Path $script:moduleRoot -ChildPath 'DscResources\DSR_WSManServiceConfig') `
    -FileName 'DSR_WSManServiceConfig.data.psd1'

$script:parameterList = $resourceData.ParameterList

# These are the new values that the integration tests will set
$WSManServiceConfigNew = [PSObject] @{}

# Build the arrays using the ParameterList from the module itself
foreach ($parameter in $script:parameterList)
{
    $WSManServiceConfigNew.$($parameter.Name) = $($parameter.TestVal)
} # foreach

Configuration DSR_WSManServiceConfig_Config {
    Import-DscResource -ModuleName WSManDsc
    node localhost {
        WSManServiceConfig Integration_Test {
            IsSingleInstance                 = 'Yes'
            RootSDDL                         = $WSManServiceConfigNew.RootSDDL
            MaxConnections                   = $WSManServiceConfigNew.MaxConnections
            MaxConcurrentOperationsPerUser   = $WSManServiceConfigNew.MaxConcurrentOperationsPerUser
            EnumerationTimeoutMS             = $WSManServiceConfigNew.EnumerationTimeoutMS
            MaxPacketRetrievalTimeSeconds    = $WSManServiceConfigNew.MaxPacketRetrievalTimeSeconds
            AllowUnencrypted                 = $WSManServiceConfigNew.AllowUnencrypted
<#
Integration testing these values can result in difficult to reverse damage to the test server.
So these tests are disabled. Only perform them on a disposable test server.
            AuthBasic                        = $WSManServiceConfigNew.AuthBasic
            AuthKerberos                     = $WSManServiceConfigNew.AuthKerberos
            AuthNegotiate                    = $WSManServiceConfigNew.AuthNegotiate
#>
            AuthCertificate                  = $WSManServiceConfigNew.AuthCertificate
            AuthCredSSP                      = $WSManServiceConfigNew.AuthCredSSP
            AuthCbtHardeningLevel            = $WSManServiceConfigNew.AuthCbtHardeningLevel
            EnableCompatibilityHttpListener  = $WSManServiceConfigNew.EnableCompatibilityHttpListener
            EnableCompatibilityHttpsListener = $WSManServiceConfigNew.EnableCompatibilityHttpsListener
        }
    }
}
