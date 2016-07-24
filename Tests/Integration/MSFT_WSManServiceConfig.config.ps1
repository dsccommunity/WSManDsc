# These are the new values that the integration tests will set
$WSManServiceConfigNew = [PSObject] @{}

# Build the arrays using the ParameterList from the module itself
foreach ($parameter in $ParameterList)
{
    $WSManServiceConfigNew += [PSObject] @{ $($parameter.Name) = $($parameter.TestVal) }
} # foreach

Configuration MSFT_WSManServiceConfig_Config {
    Import-DscResource -ModuleName WSManDsc
    node localhost {
        WSManServiceConfig Integration_Test {
            IsSingleInstance                 = 'Yes'
            RootSDDL                         = $WSManServiceConfigNew.RootSDDL
<#
            MaxConnections                   = $WSManServiceConfigNew.MaxConnections
            MaxConcurrentOperationsPerUser   = $WSManServiceConfigNew.MaxConcurrentOperationsPerUser
            EnumerationTimeoutms             = $WSManServiceConfigNew.EnumerationTimeoutms
            MaxPacketRetrievalTimeSeconds    = $WSManServiceConfigNew.MaxPacketRetrievalTimeSeconds
            AllowUnencrypted                 = $WSManServiceConfigNew.AllowUnencrypted
            AuthBasic                        = $WSManServiceConfigNew.AuthBasic
            AuthKerberos                     = $WSManServiceConfigNew.AuthKerberos
            AuthNegotiate                    = $WSManServiceConfigNew.AuthNegotiate
            AuthCertificate                  = $WSManServiceConfigNew.AuthCertificate
            AuthCredSSP                      = $WSManServiceConfigNew.AuthCredSSP
            AuthCbtHardeningLevel            = $WSManServiceConfigNew.AuthCbtHardeningLevel
            EnableCompatibilityHttpListener  = $WSManServiceConfigNew.EnableCompatibilityHttpListener
            EnableCompatibilityHttpsListener = $WSManServiceConfigNew.EnableCompatibilityHttpsListener
#>
        }
    }
}
