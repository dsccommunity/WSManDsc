# Change log for WSManDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Changed CI pipeline HQRM Test image to use `windows-2019` Azure DevOps hosted
  image - fixes [issue #69](https://github.com/dsccommunity/WSManDsc/issues/69)
- Changed CI pipeline Unit Test image to use `vs2017-win2016` Azure
  DevOps hosted image - fixes [issue #69](https://github.com/dsccommunity/WSManDsc/issues/69)
- Added CI pipeline stages for running Integration and Unit tests on
  Windows Server 2016 and Windows Server 2019 respectively.

## [3.1.0] - 2020-01-15

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
  - Updated the CI pipeline files to the latest template.
  - Changed unit tests to handle missing DscResource.Test better.
  - Changed `azure-pipeline.yml` to match current pattern ([Issue #59](https://github.com/dsccommunity/WSManDsc/issues/59)).
- Set `testRunTitle` for PublishTestResults steps so that a helpful name is
  displayed in Azure DevOps for each test run.
- Set a display name on all the jobs and tasks in the CI
  pipeline - fixes [issue #63](https://github.com/dsccommunity/WSManDsc/issues/63)

### Deprecated

- None

### Removed

- WSManDsc
  - Removed unused file `.codecov.yml`.
  - Removed the file `Deploy.PSDeploy.ps1` since it is not longer used by
    the build pipeline.

### Fixed

- WSManDsc
  - Added CODE_OF_CONDUCT.md file, and a 'Code of Conduct' section in the
    README.md.
- WSManListener
  - Fix Find-Certificate Verbose Messages [Issue #49](https://github.com/dsccommunity/WSManDsc/issues/49).
- Fixed `GitVersion.yml` feature and fix Regex - fixes
  [issue #62](https://github.com/dsccommunity/WSManDsc/issues/62).
- Fix import statement in all tests, making sure it throws if module
  DscResource.Test cannot be imported - fixes
  [issue #67](https://github.com/dsccommunity/WSManDsc/issues/67).
- Fix deploy stage in CI pipeline to prevent it executing against forks
  of the repository - fixes [issue #66](https://github.com/dsccommunity/WSManDsc/issues/66).

### Security

- None
