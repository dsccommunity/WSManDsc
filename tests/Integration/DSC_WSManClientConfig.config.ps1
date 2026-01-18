# Integration Test Config Template Version: 1.0.0
configuration DSC_WSManClientConfig_Config {
    Import-DscResource -ModuleName WSManDsc

    node $AllNodes.NodeName {
        WSManClientConfig Integration_Test
        {
            IsSingleInstance                 = 'Yes'
            NetworkDelayms                   = $Node.NetworkDelayms
            URLPrefix                        = $Node.URLPrefix
            AllowUnencrypted                 = $Node.AllowUnencrypted
            TrustedHosts                     = $Node.TrustedHosts
            <#
Integration testing these values can result in difficult to reverse damage to the test server.
So these tests are disabled. Only perform them on a disposable test server.
            AuthBasic                        = $Node.AuthBasic
            AuthDigest                       = $Node.AuthDigest
            AuthKerberos                     = $Node.AuthKerberos
            AuthNegotiate                    = $Node.AuthNegotiate
#>
            AuthCertificate                  = $Node.AuthCertificate
            AuthCredSSP                      = $Node.AuthCredSSP
        }
    }
}
