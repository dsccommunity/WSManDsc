<#
    .SYNOPSIS
        The `WSManConfig` DSC resource is used to configure general WS-Man settings.

    .DESCRIPTION
        This resource is used to create, edit or remove WS-Management HTTP/HTTPS listeners.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER MaxEnvelopeSizekb
        Specifies the WS-Man maximum envelope size in KB. The minimum value is 32 and the maximum is 4294967295.

    .PARAMETER MaxTimeoutms
        Specifies the WS-Man maximum timeout in milliseconds. The minimum value is 500 and the maximum is 4294967295.

    .PARAMETER MaxBatchItems
        Specifies the WS-Man maximum batch items. The minimum value is 1 and the maximum is 4294967295.

    .PARAMETER Reasons
        Returns the reason a property is not in desired state.
#>

[DscResource()]
class WSManConfig : ResourceBase
{
    [DscProperty(Key)]
    [ValidateSet('Yes')]
    [System.String]
    $IsSingleInstance

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

    [DscProperty(NotConfigurable)]
    [WSManReason[]]
    $Reasons

    WSManConfig () : base ($PSScriptRoot)
    {
        # These properties will not be enforced.
        $this.ExcludeDscProperties = @(
            'IsSingleInstance'
        )
    }

    [WSManConfig] Get()
    {
        # Call the base method to return the properties.
        return ([ResourceBase] $this).Get()
    }

    # Base method Get() call this method to get the current state as a Hashtable.
    [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        $state = @{}

        # Get the properties that have a value. Assert has checked at least one property is set.
        $props = $this | Get-DscProperty -Attribute @('Optional') -HasValue

        # Get the desired state, only check the properties that are set as some will be set to a default value.
        $currentState = Get-ChildItem -Path WSMan:\localhost\* | Where-Object { $_.Name -in $props.Keys }

        foreach ($property in $currentState)
        {
            $state.($property.Name) = [System.Management.Automation.LanguagePrimitives]::ConvertTo(
                $property.Value,
                $this.($property.Name).GetType().FullName
            )
        }

        return $state
    }

    [void] Set()
    {
        # Call the base method to enforce the properties.
        ([ResourceBase] $this).Set()
    }

    <#
        Base method Set() call this method with the properties that should be
        enforced and that are not in desired state.
    #>
    hidden [void] Modify([System.Collections.Hashtable] $properties)
    {
        $valueSet = @{}

        foreach ($property in $properties.Keys)
        {
            $valueSet[$property] = $properties[$property]
        }

        Set-WSManInstance -ResourceURI winrm/config -ValueSet $valueSet
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
            BoundParameterList     = $properties
            RequiredParameter = @(
                'MaxEnvelopeSizekb'
                'MaxTimeoutms'
                'MaxBatchItems'
            )
            RequiredBehavior = 'Any'
        }

        Assert-BoundParameter @assertBoundParameterParameters
    }
}
