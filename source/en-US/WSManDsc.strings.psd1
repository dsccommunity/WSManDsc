<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource WSManDsc module. This file should only contain
        localized strings for private functions, public command, and
        classes (that are not a DSC resource).
#>

ConvertFrom-StringData @'

    ## Find-Certificate
    FindCertificate_ByThumbprintMessage = Looking for machine server certificate with thumbprint '{0}'.
    FindCertificate_AlternateMessage = Looking for machine server certificate with subject '{0}' issued by '{1}' and DNS name '{2}'.
    FindCertificate_Message = Looking for machine server certificate with subject '{0}' issued by '{1}'.
    FindCertificate_FoundMessage = Certificate found with thumbprint '{0}' to use for HTTPS Listener.
    FindCertificate_NotFoundMessage = Certificate not found.
'@
