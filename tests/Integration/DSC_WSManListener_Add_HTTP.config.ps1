Configuration DSC_WSManListener_Config_Add_HTTP {
    Import-DscResource -ModuleName WSManDsc

    node localhost {
        WSManListener Integration_Test {
            Transport = $Node.Transport
            Ensure    = $Node.Ensure
            Port      = $Node.Port
            Address   = $Node.Address
        }
    }
}
