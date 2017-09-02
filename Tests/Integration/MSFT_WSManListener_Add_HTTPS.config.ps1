$Hostname = ([System.Net.Dns]::GetHostByName($ENV:computerName).Hostname)
$DN = 'O=Contoso Inc, S=Pennsylvania, C=US'
$Issuer = "CN=$Hostname, $DN"
$Listener = @{
    Transport      = 'HTTPS'
    Ensure         = 'Present'
    Port           = 5986
    Address        = '*'
    Issuer         = $Issuer
    SubjectFormat  = 'Both'
    MatchAlternate = $False
    DN             = $DN
    Hostname       = $Hostname
}

Configuration MSFT_WSManListener_Config_Add_HTTPS {
    Import-DscResource -ModuleName WSManDsc
    node localhost {
        WSManListener Integration_Test {
            Transport      = $Listener.Transport
            Ensure         = $Listener.Ensure
            Port           = $Listener.Port
            Address        = $Listener.Address
            Issuer         = $Listener.Issuer
            SubjectFormat  = $Listener.SubjectFormat
            MatchAlternate = $Listener.MatchAlternate
            DN             = $Listener.DN
        }
    }
}
