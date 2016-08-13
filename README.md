[![Build status](https://ci.appveyor.com/api/projects/status/lppuhbyqkwoect24/branch/master?svg=true)](https://ci.appveyor.com/project/PlagueHO/wsmandsc/branch/master)

# WSManDsc

The **WSManDsc** module contains DSC resources for configuring WS-Management and PowerShell Remoting.

## Resources

* **WSManListener** create, edit or remove WS-Management HTTP/HTTPS listeners.
* **WSManServiceConfig** Configure the WS-Man Service.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Contributing
Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).

### WSManListener
#### Parameters
* **Transport**: The transport type of the WS-Man listener. Can be HTTP or HTTPS. Defaults to HTTPS.
* **Ensure**: Ensures that Listener is either Absent or Present. Required.
* **Port**: The port of the listener. This optional parameter defaults to 5985 for HTTP listeners and 5986 for HTTPS listeners.
* **Address**: The address the listener is bound to. This optional parameter defaults to * (any address).
*The following parameters are only required if Transport is HTTPS:*
* **Issuer**: The full name of the certificate issuer to use for the HTTPS WS-Man Listener.
* **SubjectFormat**: The format of the computer name that will be matched against the certificate subjects to identify the certificate to use for an SSL Listener. Only required if SSL is true. Defaults to Both. Must be one of the following values:
    * **Both**: Look for a certificate with a subject matching the computer FQDN. If one can't be found the flat computer name will be used. If neither can be found then the listener will not be created.
    * **FQDN**: Look for a certificate with a subject matching the computer FQDN only. If one can't be found then the listener will not be created.
    * **ComputerName**: Look for a certificate with a subject matching the computer FQDN only. If one can't be found then the listener will not be created.
* **MatchAlternate**: Also match the certificate alternate subject name. { True | _False_ }

#### Examples
Create an HTTP Listener on port 5985:
```powershell
configuration Sample_WSManListener_HTTP
{
    Import-DscResource -Module WSManDsc

    Node $NodeName
    {
        WSManListener HTTP
        {
            Transport = 'HTTP'
            Ensure    = 'Present'
        } # End of WSManListener Resource
    } # End of Node
} # End of Configuration

Sample_WSManListener_HTTP
Start-DscConfiguration -Path Sample_WSManListener_HTTP -Wait -Verbose -Force
```

Create an HTTPS Listener using a LocalMachine certificate that is installed and issued by 'CN=CONTOSO.COM Issuing CA, DC=CONTOSO, DC=COM' on port 5986:
```powershell
configuration Sample_WSManListener_HTTPS
{
    Import-DscResource -Module WSManDsc

    Node $NodeName
    {
        WSManListener HTTPS
        {
            Transport = 'HTTPS'
            Ensure    = 'Present'
            Issuer    = 'CN=CONTOSO.COM Issuing CA, DC=CONTOSO, DC=COM'
        } # End of WSManListener Resource
    } # End of Node
} # End of Configuration

Sample_WSManListener_HTTPS
Start-DscConfiguration -Path Sample_WSManListener_HTTPS -Wait -Verbose -Force
```

### WSManServiceConfig
#### Parameters
* **RootSDDL**: Specifies the security descriptor that controls remote access to the listener. Default _"O:NSG:BAD:P(A;;GA;;;BA)(A;;GR;;;ER)S:P(AU;FA;GA;;;WD)(AU;SA;GWGX;;;WD)"_.
* **MaxConnections**: Specifies the maximum number of active requests that the service can process simultaneously. Default _300_.
* **MaxConcurrentOperationsPerUser**: Specifies the maximum number of concurrent operations that any user can remotely open on the same system. Default _1500_.
* **EnumerationTimeoutms**: Specifies the idle time-out in milliseconds between Pull messages. Default _60000_.
* **MaxPacketRetrievalTimeSeconds**: Specifies the maximum length of time, in seconds, the WinRM service takes to retrieve a packet. Default _120_.
* **AllowUnencrypted**: Allows the client computer to request unencrypted traffic. { True | _False_ }
* **AuthBasic**: Allows the WinRM service to use Basic authentication. { True | _False_ }
* **AuthKerberos**: Allows the WinRM service to use Kerberos authentication. { _True_ | False }
* **AuthNegotiate**: Allows the WinRM service to use Negotiate authentication. { _True_ | False }
* **AuthCertificate**: Allows the WinRM service to use client certificate-based authentication. { True | _False_ }
* **AuthCredSSP**: Allows the WinRM service to use Credential Security Support Provider (CredSSP) authentication. { True | _False_ }
* **AuthCbtHardeningLevel**: Sets the policy for channel-binding token requirements in authentication requests. { Strict | _Relaxed_ | None }
* **EnableCompatibilityHttpListener**: Specifies whether the compatibility HTTP listener is enabled. { True | _False_ }
* **EnableCompatibilityHttpsListener**: Specifies whether the compatibility HTTPS listener is enabled. { True | _False_ }

#### Examples
Enable compatibility HTTP and HTTPS listeners, set maximum connections to 100, allow CredSSP (not recommended) and allow unecrypted WS-Man Sessions (not recommended):
```powershell
configuration Sample_WSManServiceConfig
{
    Import-DscResource -Module WSManDsc

    Node $NodeName
    {
        WSManServiceConfig ServiceConfig
        {
            MaxConnections                   = 100
            AllowUnencrypted                 = $False
            AuthCredSSP                      = $True
            EnableCompatibilityHttpListener  = $True
            EnableCompatibilityHttpsListener = $True
        } # End of WSManServiceConfig Resource
    } # End of Node
} # End of Configuration

Sample_WSManServiceConfig
Start-DscConfiguration -Path Sample_WSManServiceConfig -Wait -Verbose -Force
```

## Versions

### Unreleased
* Added WSManServiceConfig resource.
* Prepare module for moving over to DSC community resources.
* Fixes WSManListener when Compatibility Listeners are enabled.

### 1.0.1.0
* Documentation and Module Manifest Update only.

### 1.0.0.0
* Initial release containing cWSManListener resource.
