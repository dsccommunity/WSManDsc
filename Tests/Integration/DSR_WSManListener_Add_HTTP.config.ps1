$Listener = @{
    Transport = 'HTTP'
    Ensure    = 'Present'
    Port      = 5985
    Address   = '*'
}

Configuration DSR_WSManListener_Config_Add_HTTP {
    Import-DscResource -ModuleName WSManDsc
    node localhost {
        WSManListener Integration_Test {
            Transport = $Listener.Transport
            Ensure    = $Listener.Ensure
            Port      = $Listener.Port
            Address   = $Listener.Address
        }
    }
}
