# Integration Test Config Template Version: 1.0.0
configuration DSR_WSManServiceConfig_Config {
    Import-DscResource -ModuleName WSManDsc

    node $AllNodes.NodeName {
        WSManServiceConfig Integration_Test {
            IsSingleInstance                 = 'Yes'
            RootSDDL                         = $Node.RootSDDL
            MaxConnections                   = $Node.MaxConnections
            MaxConcurrentOperationsPerUser   = $Node.MaxConcurrentOperationsPerUser
            EnumerationTimeoutMS             = $Node.EnumerationTimeoutMS
            MaxPacketRetrievalTimeSeconds    = $Node.MaxPacketRetrievalTimeSeconds
            AllowUnencrypted                 = $Node.AllowUnencrypted
<#
Integration testing these values can result in difficult to reverse damage to the test server.
So these tests are disabled. Only perform them on a disposable test server.
            AuthBasic                        = $Node.AuthBasic
            AuthKerberos                     = $Node.AuthKerberos
            AuthNegotiate                    = $Node.AuthNegotiate
#>
            AuthCertificate                  = $Node.AuthCertificate
            AuthCredSSP                      = $Node.AuthCredSSP
            AuthCbtHardeningLevel            = $Node.AuthCbtHardeningLevel
            EnableCompatibilityHttpListener  = $Node.EnableCompatibilityHttpListener
            EnableCompatibilityHttpsListener = $Node.EnableCompatibilityHttpsListener
        }
    }
}
