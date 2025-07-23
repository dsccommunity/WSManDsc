<#
    .SYNOPSIS
        `WSManConfigBase` contains properties and methods which are shared across all WSMan*Config DSC Resources.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER Reasons
        Returns the reason a property is not in desired state.

    .NOTES
        Used Functions:
            Name            | Module
            --------------- |-------------------
            Get-DscProperty | DscResource.Common
#>

class WSManConfigBase : ResourceBase
{
    [DscProperty(Key)]
    [ValidateSet('Yes')]
    [System.String]
    $IsSingleInstance

    [DscProperty(NotConfigurable)]
    [WSManReason[]]
    $Reasons

    hidden [System.String] $ResourceURI

    WSManConfigBase () : base ($PSScriptRoot)
    {
        # These properties will not be enforced.
        $this.ExcludeDscProperties = @(
            'IsSingleInstance'
        )
    }

    # Base method Get() call this method to get the current state as a Hashtable.
    [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        $state = @{}

        # Get the properties that have a value. Assert has checked at least one property is set.
        $props = $this | Get-DscProperty -Attribute @('Optional') -HasValue

        $uri = ('WSMan:\{0}' -f $this.ResourceURI)

        # Get the desired state, only check the properties that are set as some will be set to a default value.
        $currentState = Get-ChildItem -Path $uri | Where-Object { $_.Name -in $props.Keys }

        foreach ($property in $currentState)
        {
            $state.($property.Name) = [System.Management.Automation.LanguagePrimitives]::ConvertTo(
                $property.Value,
                $this.($property.Name).GetType().FullName
            )
        }

        return $state
    }

    <#
        Base method Set() calls this method with the properties that should be
        enforced and that are not in desired state.
    #>
    hidden [void] Modify([System.Collections.Hashtable] $properties)
    {
        foreach ($property in $properties.Keys)
        {
            Set-Item -Path ('WSMan:\{0}\{1}' -f $this.ResourceURI, $property) -Value $properties.$property -Force
        }
    }
}
