Configuration DSC_WSManListener_Config_Add_HTTP_NoPort {
    Import-DscResource -ModuleName WSManDsc

    node localhost {
        WSManListener Integration_Test {
            Transport = $Node.Transport
            Ensure    = $Node.Ensure
        }
    }
}
