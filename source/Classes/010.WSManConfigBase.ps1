<#
    .SYNOPSIS
        `WSManConfigBase` contains properties and methods which are shared across all WSMan*Config DSC Resources.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER Reasons
        Returns the reason a property is not in desired state.
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
    hidden [System.Boolean] $HasAuthContainer = $false

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

        $uri = 'WSMan:\{0}' -f $this.ResourceURI

        # Get the desired state, only check the properties that are set as some will be set to a default value.
        $currentState = [System.Collections.Generic.List[System.Object]]::new()
        $currentState.AddRange(@(Get-ChildItem -Path $uri).Where({ $_.Name -in $props.Keys -and $_.Type -ne 'Container' }))

        if ($this.HasAuthContainer)
        {
            $childProperties = @(Get-ChildItem -Path ('{0}\Auth' -f $uri))
            $mappedProperties = @($this.MapFromAuthContainer($childProperties).Where({ $_.Name -in $props.Keys }))
            $currentState.AddRange($mappedProperties)
        }

        foreach ($property in $currentState)
        {
            $targetType = $this.($property.Name).GetType()
            if ($targetType -eq [System.Boolean])
            {
                # Parse string "true"/"false" correctly (case-insensitive)
                $state[$property.Name] = [System.Convert]::ToBoolean($property.Value)
                continue
            }

            $state[$property.Name] = [System.Management.Automation.LanguagePrimitives]::ConvertTo(
                $property.Value,
                $targetType
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
        $baseUri = 'WSMan:\{0}' -f $this.ResourceURI

        foreach ($property in $properties.GetEnumerator())
        {
            if ($property.Name.StartsWith('Auth'))
            {
                $property.Name = $property.Name -replace '^Auth', ''
                Set-Item -Path ('{0}\Auth\{1}' -f $baseUri, $property.Name) -Value $property.Value -Force
                continue
            }

            Set-Item -Path ('{0}\{1}' -f $baseUri, $property.Name) -Value $property.Value -Force
        }
    }

    hidden [System.Object[]] MapFromAuthContainer([System.Object[]] $properties)
    {
        foreach ($property in $properties)
        {
            # Need to add auth to the beginning.
            $property.Name = 'Auth{0}' -f $property.Name
        }

        return $properties
    }
}
