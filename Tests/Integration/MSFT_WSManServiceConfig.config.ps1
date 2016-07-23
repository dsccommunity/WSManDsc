# These are the default values that the service config will be set to before being changed
$WSManServiceConfigDefault = @{
    RootSDDL                         = 'O:NSG:BAD:P(A;;GA;;;BA)(A;;GR;;;IU)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)'
    MaxConnections                   = 300
    MaxConcurrentOperationsPerUser   = 1500
    EnumerationTimeoutms             = 240000
    MaxPacketRetrievalTimeSeconds    = 120
    AllowUnencrypted                 = $false
    AuthBasic                        = $false
    AuthKerberos                     = $true
    AuthNegotiate                    = $true
    AuthCertificate                  = $false
    AuthCredSSP                      = $false
    AuthCbtHardeningLevel            = 'relaxed'
    EnableCompatibilityHttpListener  = $false
    EnableCompatibilityHttpsListener = $false
}
# These are the new values that the integration tests will set
$WSManServiceConfigNew = @{
    RootSDDL                         = 'O:NSG:BAD:P(A;;GA;;;BA)(A;;GR;;;IU)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)'
    MaxConnections                   = $WSManServiceConfigDefault.MaxConnections + 1
    MaxConcurrentOperationsPerUser   = $WSManServiceConfigDefault.MaxConcurrentOperationsPerUser + 1
    EnumerationTimeoutms             = $WSManServiceConfigDefault.EnumerationTimeoutms + 1
    MaxPacketRetrievalTimeSeconds    = $WSManServiceConfigDefault.MaxPacketRetrievalTimeSeconds + 1
    AllowUnencrypted                 = -not $WSManServiceConfigDefault.AllowUnencrypted
    AuthBasic                        = -not $WSManServiceConfigDefault.AuthBasic
    AuthKerberos                     = -not $WSManServiceConfigDefault.AuthKerberos
    AuthNegotiate                    = -not $WSManServiceConfigDefault.AuthNegotiate
    AuthCertificate                  = -not $WSManServiceConfigDefault.AuthCertificate
    AuthCredSSP                      = -not $WSManServiceConfigDefault.AuthCredSSP
    AuthCbtHardeningLevel            = 'strict'
    EnableCompatibilityHttpListener  = -not $WSManServiceConfigDefault.EnableCompatibilityHttpListener
    EnableCompatibilityHttpsListener = -not $WSManServiceConfigDefault.EnableCompatibilityHttpsListener
}

Configuration MSFT_WSManServiceConfig_Config {
    Import-DscResource -ModuleName WSManDsc
    node localhost {
        WSManServiceConfig Integration_Test {
            IsSingleInstance                 = 'Yes'
            RootSDDL                         = $WSManServiceConfigNew.RootSDDL
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
        }
    }
}
