$Listener = @{
    Transport = 'HTTP'
    Ensure    = 'Present'
    Port      = 5985
    Address   = '*'
}

Configuration BMD_cWSManListener_Config {
    Import-DscResource -ModuleName cWSMan
    node localhost {
        cWSManListener Integration_Test {
            Transport = $Listener.Transport
            Ensure    = $Listener.Ensure
            Port      = $Listener.Port
            Address   = $Listener.Address
        }
    }
}
