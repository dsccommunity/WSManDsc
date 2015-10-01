#######################################################################################
#  cWSManListener : DSC Resource that will set/test/get the WS-Man Listerner on a 
#  specified port.
#######################################################################################
 


######################################################################################
# The Get-TargetResource cmdlet.
# This function will return the details of a Listener on the specified Port.
######################################################################################
function Get-TargetResource
{
    [OutputType([Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('HTTP','HTTPS')]
        [String]
        $Transport,

        [parameter(Mandatory = $true)]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure
    )
    
    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        'Getting Listener.'
        ) -join '' )

    $returnValue = @{
        Transport = $Transport
    }

    # Lookup the existing Listener
    $Listeners = Get-Listener -Transport $Transport
    if ($Listeners) {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            "$Transport Listener exists."
            ) -join '' )
        $returnValue += @{
            Ensure = 'Present'
            Port = $Listeners.Port
            Address = $Listeners.Address
            HostName = $Listeners.HostName
            Enabled = $Listeners.Enabled
            URLPrefix = $Listeners.URLPrefix
            CertificateThumbprint = $Listeners.CertificateThumbprint
            }
    } Else {       
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            "$Transport Listener does not exist."
            ) -join '' )
        $returnValue += @{ Ensure = 'Absent' }
    }

    $returnValue
} # Get-TargetResource

######################################################################################
# The Set-TargetResource cmdlet.
# This function will configure (or remove) a WS-Man Listener on the specified port
######################################################################################
function Set-TargetResource
{
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('HTTP','HTTPS')]
        [String]
        $Transport,

        [parameter(Mandatory = $true)]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure,

        [UInt16]
        $Port,

        [String]
        $Address = '*',

        [String]
        $Issuer,

        [ValidateSet('Both','FQDNOnly','NameOnly')]
        [String]
        $SubjectFormat = 'Both',

        [Boolean]
        $MatchAlternate
    )

    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        'Setting Listener.'
        ) -join '' )

    # Lookup the existing Listener
    $Listeners = Get-Listener -Transport $Transport

    # Get the default port for the transport if none was provided
    $Port = Get-DefaultPort -Transport $Transport -Port $Port

    if ($Ensure -eq 'Present') {
        # The listener should exist
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            "Ensuring $Transport Listener on $Port exists."
            ) -join '' )
        if ($Listeners) {
            # The Listener exists already - delete it
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                "$Transport Listener on $Port exists. Removing."
                ) -join '' )
            Remove-WSManInstance `
                -ResourceURI winrm/config/Listener `
                -SelectorSet @{ Transport=$Listeners.Transport;Address=$Listeners.Address }
        } else {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                "$Transport Listener on $Port does not exist."
                ) -join '' )
            # Ths listener doesn't exist - do nothing
        }
        # Create the listener
        if ($Transport -eq 'HTTPS') {
            [String] $Thumbprint = ''
            # First try and find a certificate that is used to the FQDN of the machine
            if ($SubjectFormat -in 'Both','FQDNOnly') {
                [String] $HostName = [System.Net.Dns]::GetHostByName($ENV:computerName).Hostname
                if ($MatchAlternate) {
                    $Thumbprint = (Get-ChildItem -Path Cert:\localmachine\my | Where-Object { 
                            ($_.Extensions.EnhancedKeyUsages.FriendlyName -contains 'Server Authentication') -and
                            ($_.Issuer -eq $Issuer) -and
                            ($HostName -in $_.DNSNameList.Unicode) -and
                            ($_.Subject -eq "CN=$HostName") } | Select-Object -First 1
                        ).Thumbprint
                } else {
                    $Thumbprint = (Get-ChildItem -Path Cert:\localmachine\my | Where-Object { 
                            ($_.Extensions.EnhancedKeyUsages.FriendlyName -contains 'Server Authentication') -and
                            ($_.Issuer -eq $Issuer) -and
                            ($_.Subject -eq "CN=$HostName") } | Select-Object -First 1
                        ).Thumbprint    
                } # if
            }
            if (($SubjectFormat -in 'Both','NameOnly') -and -not $Thumbprint) {
                # If could not find an FQDN cert, try for one issued to the computer name
                [String] $HostName = $ENV:ComputerName
                if ($MatchAlternate) {
                    $Thumbprint = (Get-ChildItem -Path Cert:\localmachine\my | Where-Object { 
                            ($_.Extensions.EnhancedKeyUsages.FriendlyName -contains 'Server Authentication') -and
                            ($_.Issuer -eq $Issuer) -and
                            ($HostName -in $_.DNSNameList.Unicode) -and
                            ($_.Subject -eq "CN=$HostName") } | Select-Object -First 1
                        ).Thumbprint
                } else {
                    $Thumbprint = (Get-ChildItem -Path Cert:\localmachine\my | Where-Object { 
                            ($_.Extensions.EnhancedKeyUsages.FriendlyName -contains 'Server Authentication') -and
                            ($_.Issuer -eq $Issuer) -and
                            ($_.Subject -eq "CN=$HostName") } | Select-Object -First 1
                        ).Thumbprint    
                } # if
            } # if
            if ($Thumbprint) {
                # A certificate was found, so use it to enable the HTTPS WinRM listener
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    "Creating $Transport Listener on $Port."
                    ) -join '' )
                New-WSManInstance `
                    -ResourceURI winrm/config/Listener `
                    -SelectorSet @{Address=$Address;Transport=$Transport} `
                    -ValueSet @{Hostname=$HostName;CertificateThumbprint=$Thumbprint;Port=$Port} `
                    -ErrorAction Stop
            } else {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    "Failed to create $Transport Listener on $Port because a "
                    'usable certificate could not be found.'
                    ) -join '' )
            } # if
        } else {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                "Creating $Transport Listener on $Port."
                ) -join '' )
            New-WSManInstance `
                -ResourceURI winrm/config/Listener `
                -SelectorSet @{Address=$Address;Transport=$Transport} `
                -ValueSet @{Port=$Port} `
                -ErrorAction Stop
        }
    } else {
        # The listener should not exist
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            "Ensuring Listener on $Port does not exist."
            ) -join '' )
        if ($Listeners) {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                "Listener on $Port exists. Removing."
                ) -join '' )
            Remove-WSManInstance `
                -ResourceURI winrm/config/Listener `
                -SelectorSet @{ Transport=$Listeners.Transport;Address=$Listeners.Address }
        }
    } # if
} # Set-TargetResource

######################################################################################
# The Test-TargetResource cmdlet.
# This function will detect if any changes need to be made on the listener on the
# specified port.
######################################################################################
function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('HTTP','HTTPS')]
        [String]
        $Transport,

        [parameter(Mandatory = $true)]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure,

        [UInt16]
        $Port,

        [String]
        $Address = '*',

        [String]
        $Issuer,

        [ValidateSet('Both','FQDNOnly','NameOnly')]
        [String]
        $SubjectFormat = 'Both',

        [Boolean]
        $MatchAlternate
    )

    # Flag to signal whether settings are correct
    [Boolean] $desiredConfigurationMatch = $true

    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        'Testing Listener.'
        ) -join '' )

    # Lookup the existing Listener
    $Listeners = Get-Listener -Transport $Transport
    
    # Get the default port for the transport if none was provided
    $Port = Get-DefaultPort -Transport $Transport -Port $Port

    if ($Ensure -eq 'Present') {
        # The listener should exist
        if ($Listeners) {
            # The Listener exists already
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                "$Transport Listener exists."
                ) -join '' )
            # Check it is setup as per parameters
            if ($Listeners.Port -ne $Port) {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    "$Transport Listener is on Port $($Listeners.Port), should be on $Port. "
                    'Change required.'
                    ) -join '' )
                $desiredConfigurationMatch = $false                
            }
            if ($Listeners.Address -ne $Address) {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    "$Transport Listener is bound to $($Listeners.Address), should be $Address. "
                    'Change required.'
                    ) -join '' )
                $desiredConfigurationMatch = $false                
            }
        } else {
            # Ths listener doesn't exist but should
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                "$Transport Listener does not exist but should."
                'Change required.'
                ) -join '' )
            $desiredConfigurationMatch = $false
        }
    } else {
        # The listener should not exist
        if ($Listeners) {
            # The listener exists but should not
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                "$Transport Listener exists but should not."
                'Change required.'
                ) -join '' )
            $desiredConfigurationMatch = $false
        } else {
            # The listener does not exist and should not
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                "$Transport Listener does not exist and should not."
                'Change not required.'
                ) -join '' )
        }
    } # if
    return $desiredConfigurationMatch
} # Test-TargetResource

######################################################################################
# Helpers
######################################################################################
function Get-Listener
{
    [OutputType([Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('HTTP','HTTPS')]
        [String]
        $Transport
    )
    
    $Listeners = Get-WSManInstance `
        -ResourceURI winrm/config/Listener `
        -Enumerate
    if ($Listeners) {
        return $Listeners.Where( {$_.Transport -eq $Transport } )
    }

} # Get-Listener

######################################################################################
function Get-DefaultPort
{
    [OutputType([UInt16])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('HTTP','HTTPS')]
        [String]
        $Transport,

        [UInt16]
        $Port
    )

    if (-not $Port) {
        # Set the default port because none was provided
        if ($Transport -eq 'HTTP') {
            $Port = 5985
        } else {
            $Port = 5986
        }
    }
    return $Port
}

######################################################################################
Export-ModuleMember -Function *-TargetResource