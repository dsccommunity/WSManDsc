# Change log for WSManDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- WSManDsc
  - Added automatic release with a new CI pipeline.

### Changed

- WSManDsc
  - Transferred ownership to DSCCommunity.org.
  - Added missing resource to README.MD.
  - BREAKING CHANGE: Changed resource prefix from DSR to DSC.
  - Renamed module `WSManDsc.ResourceHelper` to `WSManDsc.Common` and updated
    to use standard functions.

### Deprecated

- None

### Removed

- None

### Fixed

- None

### Security

- None

## [2.4.1.0] - 2019-10-25

### Changed

- Changes to WSManDsc
  - Added .VSCode settings for applying DSC PSSA rules - fixes [Issue #32](https://github.com/dsccommunity/WSManDsc/issues/32).
  - Fix minor style issues in hashtable layout.
  - Added .gitattributes file to fix bug publishing examples - Fixes [Issue #34](https://github.com/dsccommunity/WSManDsc/issues/34).
  - WSManConfig:
    - Added new resource to allow configuration of core WS-Man
      settings - Fixes [Issue #40](https://github.com/dsccommunity/WSManDsc/issues/40).
  - WSManServiceConfig:
    - Updated integration tests to latest version of template.

## [2.4.0.0] - 2019-10-15

### Changed

- Changes to WSManDsc
  - Enabled PSSA rule violations to fail build - Fixes [Issue #14](https://github.com/dsccommunity/WSManDsc/issues/14).
  - Added Open Code of Conduct.
  - Refactored module folder structure to move resource
    to root folder of repository and remove test harness - Fixes [Issue #19](https://github.com/dsccommunity/WSManDsc/issues/19).
  - Converted Examples to support format for publishing to PowerShell
    Gallery.
  - Change `Find-Certificate` in `WSManListener` to return entire certificate
    instead of just thumbprint.
  - Fix `Get-TargetResource` in `WSManListener` to ensure all MOF parameters are
    returned - Fixes [Issue #21](https://github.com/dsccommunity/WSManDsc/issues/21).
  - Minor style corrections to comment based help.
  - Correct configuration names in Examples - fixes [Issue #24](https://github.com/dsccommunity/WSManDsc/issues/24).
  - Opt-in to common tests:
    - Common Tests - Validate Example Files To Be Published
    - Common Tests - Validate Markdown Links
    - Common Tests - Relative Path Length
  - Opt-in to example publishing.
  - Update to new format LICENSE.

## [2.2.0.0] - 2018-01-13

### Changed

- Changes to WSManDsc
  - WSManListener:
    - Added support for setting the Hostname of the listener will if the
      subject of the certificate does not match the machine name - Fixes [Issue #11](https://github.com/dsccommunity/WSManDsc/issues/11).

## [2.1.0.0] - 2018-01-02

### Changed

- Changes to WSManDsc
  - Updated tests to meet Pester v4 standard.
  - Removed DSCResourceKit tag from manifest tags.
  - Added support for selecting a certificate to use by Thumbprint.

## [2.0.0.0] - 2017-09-02

### Changed

- Changes to WSManDsc
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
