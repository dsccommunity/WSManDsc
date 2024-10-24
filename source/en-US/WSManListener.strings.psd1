<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource WSManListener module. This file should only contain
        localized strings for private functions, public command, and
        classes (that are not a DSC resource).
#>

ConvertFrom-StringData @'
    ## Strings overrides for the ResourceBase's default strings.
    # None

    ## Strings directly used by the derived class WSManListener.
    ListenerExistsRemoveMessage = Removing {0} Listener on port {1} (WSML0001).
    ListenerCreateFailNoCertError = Failed to create {0} Listener on port {1} because an applicable certificate could not be found (WSM0002).
    CreatingListenerMessage = Creating {0} Listener on port {1} (WSML0003).
'@
