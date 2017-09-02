# WSManDsc

[![Build status](https://ci.appveyor.com/api/projects/status/lppuhbyqkwoect24/branch/master?svg=true)](https://ci.appveyor.com/project/PlagueHO/wsmandsc/branch/master)

The **WSManDsc** module contains DSC resources for configuring WS-Management and PowerShell Remoting.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## How to Contribute

If you would like to contribute to this repository, please read the DSC Resource Kit [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).

## Resources

- **WSManListener**: Create, edit or remove WS-Management HTTP/HTTPS listeners.
- **WSManServiceConfig**: Configure the WS-Man Service.

### WSManListener

- **`[String]` Transport**  (_Key_): The transport type of the WS-Man listener. Can be HTTP or HTTPS. Defaults to _HTTPS_.
- **`[String]` Ensure** (_Required_): Specifies whether the WS-Man Listener should exist. { Present | Absent }.
- **`[Uint16]` Port**  (_Write_): The port of the listener. Defaults to 5985 for HTTP listeners and 5986 for HTTPS listeners.
- **`[String]` Address** (_Write_): The address the listener is bound to. Defatuls to '*' (any address).
  *The following parameters are only required if Transport is HTTPS:*
- **`[String]` Issuer** (_Write_): The full name of the certificate issuer to use for the HTTPS WS-Man Listener.
- **`[String]` SubjectFormat** (_Write_): The format of the computer name that will be matched against the certificate subjects to identify the certificate to use for an SSL Listener. Only required if SSL is true. { _Both_ | FQDNOnly | NameOnly }. Defaults to Both.
- **`[Boolean]` MatchAlternate** (_Write_): Also match the certificate alternate subject name. { True | _False_ }.
- **`[String]` DN** (_Write_): This is a Distinguished Name component that will be used to identify the certificate to use for the HTTPS WS-Man Listener.

#### SubjectFormat Parameter

The subject format is used to determine how the certificate for the listener will be identified.
It must be one of the following:

- **Both**: Look for a certificate with a subject matching the computer FQDN. If one can't be found the flat computer name will be used. If neither can be found then the listener will not be created.
- **FQDN**: Look for a certificate with a subject matching the computer FQDN only. If one can't be found then the listener will not be created.
- **ComputerName**: Look for a certificate with a subject matching the computer FQDN only. If one can't be found then the listener will not be created.

### WSManServiceConfig

- **`[String]` IsSingleInstance** (_Key_): Specifies the resource is a single instance, the value must be 'Yes'. { _Yes_ }
- **`[String]` RootSDDL** (_Write_): Specifies the security descriptor that controls remote access to the listener. Defaults to _"O:NSG:BAD:P(A;;GA;;;BA)(A;;GR;;;ER)S:P(AU;FA;GA;;;WD)(AU;SA;GWGX;;;WD)"_.
- **`[String]` MaxConnections** (_Write_): Specifies the maximum number of active requests that the service can process simultaneously. Defaults to _300_.
- **`[Uint32]` MaxConcurrentOperationsPerUser** (_Write_): Specifies the maximum number of concurrent operations that any user can remotely open on the same system. Defaults to _1500_.
- **`[Uint32]` EnumerationTimeoutMS** (_Write_): Specifies the idle time-out in milliseconds between Pull messages. Defaults to _60000_.
- **`[Uint32]` MaxPacketRetrievalTimeSeconds** (_Write_): Specifies the maximum length of time, in seconds, the WinRM service takes to retrieve a packet. Defaults to _120_.
- **`[Boolean]` AllowUnencrypted** (_Write_): Allows the client computer to request unencrypted traffic. { True | _False_ }
- **`[Boolean]` AuthBasic** (_Write_): Allows the WinRM service to use Basic authentication. { True | _False_ }
- **`[Boolean]` AuthKerberos** (_Write_): Allows the WinRM service to use Kerberos authentication. { _True_ | False }
- **`[Boolean]` AuthNegotiate** (_Write_): Allows the WinRM service to use Negotiate authentication. { _True_ | False }
- **`[Boolean]` AuthCertificate** (_Write_): Allows the WinRM service to use client certificate-based authentication. { True | _False_ }
- **`[Boolean]` AuthCredSSP** (_Write_): Allows the WinRM service to use Credential Security Support Provider (CredSSP) authentication. { True | _False_ }
- **`[String]` AuthCbtHardeningLevel** (_Write_): Sets the policy for channel-binding token requirements in authentication requests. { Strict | _Relaxed_ | None }
- **`[String]` EnableCompatibilityHttpListener** (_Write_): Specifies whether the compatibility HTTP listener is enabled. { True | _False_ }
- **`[String]` EnableCompatibilityHttpsListener** (_Write_): Specifies whether the compatibility HTTPS listener is enabled. { True | _False_ }

## Versions

### Unreleased

- Added WSManServiceConfig resource.
- Prepare module for moving over to DSC community resources.
- Fixes WSManListener when Compatibility Listeners are enabled.
- Updated readme.md to follow standard layout defined in DSCResources.
- MSFT_WSManListener:
  - Refactored to move certificate lookup to Find-Certificate cmdlet.
  - Improved unit test coverage.
  - Exception now thrown if certificate can't be found for HTTPS listener.
  - Added integration tests for WS-Man HTTPS listener.
  - Additional logging information added for certificate detection for HTTPS listener.

### 1.0.1.0

- Documentation and Module Manifest Update only.

### 1.0.0.0

- Initial release containing cWSManListener resource.

### Examples

#### Example 1: Create an HTTP Listener

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

#### Example 2: Create an HTTPS Listener

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

#### Example 3: Create an HTTPS Listener with a Certificate containing a DN

Create an HTTPS Listener using a LocalMachine certificate containing a DN that is installed and issued by 'CN=CONTOSO.COM Issuing CA, DC=CONTOSO, DC=COM' on port 5986:

```powershell
configuration Sample_WSManListener_HTTPS_DN
{
    Import-DscResource -Module WSManDsc

    Node $NodeName
    {
        WSManListener HTTPS
        {
            Transport = 'HTTPS'
            Ensure    = 'Present'
            Issuer    = 'CN=CONTOSO.COM Issuing CA, DC=CONTOSO, DC=COM'
            DN        = 'O=Contoso Inc, S=Pennsylvania, C=US'
        } # End of WSManListener Resource
    } # End of Node
} # End of Configuration

Sample_WSManListener_HTTPS_DN
Start-DscConfiguration -Path Sample_WSManListener_HTTPS_DN -Wait -Verbose -Force
```

#### Example 4: Enable HTTP and HTTPS compatibility listeners

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
