# Description

This resource is used to create, edit or remove WS-Management HTTP/HTTPS listeners.

## SubjectFormat Parameter Notes

The subject format is used to determine how the certificate for the listener
will be identified. It must be one of the following:

- **Both**: Look for a certificate with a subject matching the computer FQDN.
  If one can't be found the flat computer name will be used. If neither
  can be found then the listener will not be created.
- **FQDN**: Look for a certificate with a subject matching the computer FQDN
  only. If one can't be found then the listener will not be created.
- **ComputerName**: Look for a certificate with a subject matching the computer
  FQDN only. If one can't be found then the listener will not be created.
