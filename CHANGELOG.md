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
  - Pinned `ModuleBuilder` to v1.0.0.
  - Updated build badges in README.MD.
  - Remove unused localization strings.
  - Adopt DSC Community Code of Conduct.
  - Fix Code Coverage generation.

### Deprecated

- None

### Removed

- WSManDsc
  - Removed unused file `.codecov.yml`.

### Fixed

- None

### Security

- None
