# Versions

## Unreleased

- Enabled PSSA rule violations to fail build - Fixes [Issue #14](https://github.com/PlagueHO/WSManDsc/issues/14).
- Added Open Code of Conduct.

## 2.2.0.0

- WSManListener:
  - Added support for setting the Hostname of the listener will if the
    subject of the certificate does not match the machine name - Fixes [Issue #11](https://github.com/PlagueHO/WSManDsc/issues/11).

## 2.1.0.0

- Updated tests to meet Pester v4 standard.
- Removed DSCResourceKit tag from manifest tags.
- Added support for selecting a certificate to use by Thumbprint.

## 2.0.0.0

- Added WSManServiceConfig resource.
- Prepare module for moving over to DSC community resources.
- Fixes WSManListener when Compatibility Listeners are enabled.
- Updated readme.md to follow standard layout defined in DSCResources.
- WSManListener:
  - Refactored to move certificate lookup to Find-Certificate cmdlet.
  - Improved unit test coverage.
  - Exception now thrown if certificate can't be found for HTTPS listener.
  - Added integration tests for WS-Man HTTPS listener.
  - Additional logging information added for certificate detection for HTTPS listener.

## 1.0.1.0

- Documentation and Module Manifest Update only.

## 1.0.0.0

- Initial release containing cWSManListener resource.
