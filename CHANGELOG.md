# Versions

## 2.4.0.0

- Added .VSCode settings for applying DSC PSSA rules - fixes [Issue #32](https://github.com/PlagueHO/WSManDsc/issues/32).
- Fix minor style issues in hashtable layout.
- Added .gitattributes file to fix bug publishing examples - Fixes [Issue #34](https://github.com/PlagueHO/WSManDsc/issues/34).
- WSManConfig:
  - Added new resource to allow configuration of core WS-Man
    settings - Fixes [Issue #40](https://github.com/PlagueHO/WSManDsc/issues/40).
- WSManServiceConfig:
  - Updated integration tests to latest version of template.

## 2.3.0.0

- Enabled PSSA rule violations to fail build - Fixes [Issue #14](https://github.com/PlagueHO/WSManDsc/issues/14).
- Added Open Code of Conduct.
- Refactored module folder structure to move resource
  to root folder of repository and remove test harness - Fixes [Issue #19](https://github.com/PlagueHO/WSManDsc/issues/19).
- Converted Examples to support format for publishing to PowerShell
  Gallery.
- Change `Find-Certificate` in `WSManListener` to return entire certificate
  instead of just thumbprint.
- Fix `Get-TargetResource` in `WSManListener` to ensure all MOF parameters are
  returned - Fixes [Issue #21](https://github.com/PlagueHO/WSManDsc/issues/21).
- Minor style corrections to comment based help.
- Correct configuration names in Examples - fixes [Issue #24](https://github.com/PlagueHO/WSManDsc/issues/24).
- Opt-in to common tests:
  - Common Tests - Validate Example Files To Be Published
  - Common Tests - Validate Markdown Links
  - Common Tests - Relative Path Length
- Opt-in to example publishing.
- Update to new format LICENSE.

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
