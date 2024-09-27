<#
    .SYNOPSIS
        Looks up a WS-Man listener on the machine and returns the details.

    .PARAMETER Transport
        The transport type of WS-Man Listener.
#>
function Get-Listener
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('HTTP', 'HTTPS')]
        [System.String]
        $Transport
    )

    $listeners = @(Get-WSManInstance -ResourceURI 'winrm/config/Listener' -Enumerate)

    if ($listeners)
    {
        return $listeners.Where(
            { ($_.Transport -eq $Transport) -and ($_.Source -ne 'Compatibility') }
        )
    }
}
