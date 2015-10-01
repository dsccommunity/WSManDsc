[![Build status](https://ci.appveyor.com/api/projects/status/cw3o6pnn7l26m1h5/branch/master?svg=true)](https://ci.appveyor.com/project/PlagueHO/cwsman/branch/master)

# cWSMan

The **cWSMan** module contains a DSC resources for configuring WS-Management and PowerShell Remoting. It currently only contains a single resource - cWSManListener - for creating WS-Management HTTP/HTTPS listeners, but other resources may be added. 


## Contributing
Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).


### cWSManListener

#### Parameters
* **Port**: The port of the listener. This should usually be set to 5968 for an HTTPS listener or 5985 for an HTTP listener. This parameter is required.
* **Ensure**: Required.
* **Transport**: The transport type of the WS-Man listener. Can be HTTP or HTTPS. Defaults to HTTPS.
*The following parameters are only required is Transport is HTTPS:*
* **Issuer**: The full name of the certificate issuer to use for the HTTPS WS-Man Listener.
* **SubjectFormat**: The format of the computer name that will be matched against the certificate subjects to identify the certificate to use for an SSL Listener. Only required if SSL is true. Defaults to Both. Must be one of the following values:
	* **Both**: Look for a certificate with a subject matching the computer FQDN. If one can't be found the flat computer name will be used. If neither can be found then the listener will not be created.
	* **FQDN**: Look for a certificate with a subject matching the computer FQDN only. If one can't be found then the listener will not be created.
	* **ComputerName**: Look for a certificate with a subject matching the computer FQDN only. If one can't be found then the listener will not be created.
* **MatchAlternate**: Also match the certificate alternate subject name. Defaults to False.

#### Examples
Create an HTTP Listener on port 5985:
```powershell
configuration Sample_cWSManListener_HTTP
{
    Import-DscResource -Module cWSManListener

    Node $NodeName
    {
        cWSManListener HTTP
        {
            Port = 5985
            Ensure = 'Present'
            Type = 'HTTP'
        } # End of cWSManListener Resource
    } # End of Node
} # End of Configuration
```

Create an HTTPS Listener with a certificate issued by 'CN=CONTOSO.COM Issuing CA, DC=CONTOSO, DC=COM' on port 5986:
```powershell
configuration Sample_cWSManListener_HTTPS
{
    Import-DscResource -Module cWSManListener

    Node $NodeName
    {
        cWSManListener HTTP
        {
            Port = 5986
            Ensure = 'Present'
            Type = 'HTTPS'
            Issuer = 'CN=CONTOSO.COM Issuing CA, DC=CONTOSO, DC=COM'
        } # End of cWSManListener Resource
    } # End of Node
} # End of Configuration
```

## Versions

### 1.0.0.0

* Initial release containing cWSManListener resource.



