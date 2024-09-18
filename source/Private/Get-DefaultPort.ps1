<#
    .SYNOPSIS
        Returns the port to use for the listener based on the transport and port.

    .PARAMETER Transport
        The transport type of WS-Man Listener.

    .PARAMETER Port
        The port the WS-Man Listener should use. Defaults to 5985 for HTTP and 5986 for HTTPS listeners.
#>
function Get-DefaultPort
{
    [CmdletBinding()]
    [OutputType([System.UInt16])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('HTTP', 'HTTPS')]
        [System.String]
        $Transport,

        [Parameter()]
        [System.UInt16]
        $Port
    )

    process
    {
        if (-not $Port)
        {
            # Set the default port because none was provided
            if ($Transport -eq 'HTTP')
            {
                $Port = 5985
            }
            else
            {
                $Port = 5986
            }
        }

        return $Port
    }
}
