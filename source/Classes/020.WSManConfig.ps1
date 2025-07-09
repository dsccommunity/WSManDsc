<#
    .SYNOPSIS
        The `WSManConfig` DSC resource is used to configure general WS-Man settings.

    .DESCRIPTION
        This resource is used to edit WS-Management configuration.

    .PARAMETER MaxEnvelopeSizekb
        Specifies the WS-Man maximum envelope size in KB. The minimum value is 32 and the maximum is 4294967295.

    .PARAMETER MaxTimeoutms
        Specifies the WS-Man maximum timeout in milliseconds. The minimum value is 500 and the maximum is 4294967295.

    .PARAMETER MaxBatchItems
        Specifies the WS-Man maximum batch items. The minimum value is 1 and the maximum is 4294967295.

    .NOTES
        Used Functions:
            Name                  | Module
            --------------------- |-------------------
            Assert-BoundParameter | DscResource.Common
#>

[DscResource()]
class WSManConfig : WSManConfigBase
{
    [DscProperty()]
    [ValidateRange(32, 4294967295)]
    [Nullable[System.Uint32]]
    $MaxEnvelopeSizekb

    [DscProperty()]
    [ValidateRange(500, 4294967295)]
    [Nullable[System.Uint32]]
    $MaxTimeoutms

    [DscProperty()]
    [ValidateRange(1, 4294967295)]
    [Nullable[System.Uint32]]
    $MaxBatchItems

    WSManConfig () : base ()
    {
        $this.ResourceURI = 'localhost'
    }

    [WSManConfig] Get()
    {
        # Call the base method to return the properties.
        return ([ResourceBase] $this).Get()
    }

    [void] Set()
    {
        # Call the base method to enforce the properties.
        ([ResourceBase] $this).Set()
    }

    [System.Boolean] Test()
    {
        # Call the base method to test all of the properties that should be enforced.
        return ([ResourceBase] $this).Test()
    }

    <#
        Base method Assert() call this method with the properties that was assigned
        a value.
    #>
    hidden [void] AssertProperties([System.Collections.Hashtable] $properties)
    {
        $assertBoundParameterParameters = @{
            BoundParameterList = $properties
            RequiredParameter  = @(
                'MaxEnvelopeSizekb'
                'MaxTimeoutms'
                'MaxBatchItems'
            )
            RequiredBehavior   = 'Any'
        }

        Assert-BoundParameter @assertBoundParameterParameters
    }
}
