# Integration Test Config Template Version: 1.0.0
configuration DSR_WSManConfig_Config {
    Import-DscResource -ModuleName WSManDsc

    node $AllNodes.NodeName {
        WSManConfig Integration_Test {
            IsSingleInstance    = 'Yes'
            MaxEnvelopeSizekb   = $Node.MaxEnvelopeSizekb
            MaxTimeoutms        = $Node.MaxTimeoutms
            MaxBatchItems       = $Node.MaxBatchItems
            MaxProviderRequests = $Node.MaxProviderRequests
        }
    }
}
