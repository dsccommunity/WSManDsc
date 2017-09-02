$Listener = @{
    Transport      = 'HTTPS'
    Ensure         = 'Absent'
    Port           = 5986
    Address        = '*'
}

Configuration MSFT_WSManListener_Config_Remove_HTTPS {
    Import-DscResource -ModuleName WSManDsc
    node localhost {
        WSManListener Integration_Test {
            Transport      = $Listener.Transport
            Ensure         = $Listener.Ensure
            Port           = $Listener.Port
            Address        = $Listener.Address
        }
    }
}
