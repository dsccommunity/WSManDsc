Configuration DSR_WSManListener_Config_Add_HTTPS {
    Import-DscResource -ModuleName WSManDsc
    node localhost {
        WSManListener Integration_Test {
            Name                 = $Node.Name
            Transport      = $Node.Transport
            Ensure         = $Node.Ensure
            Port           = $Node.Port
            Address        = $Node.Address
            Issuer         = $Node.Issuer
            SubjectFormat  = $Node.SubjectFormat
            MatchAlternate = $Node.MatchAlternate
            DN             = $Node.DN
        }
    }
}
