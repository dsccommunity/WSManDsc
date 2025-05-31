# Change log for WSManDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `WSManReason`
  - Used in Class Resources.
- `WSManSubjectFormat` Enum.
- `WSManTransport` Enum.
- `RequiredModules`
  - Added `DscResource.Base` class.

### Changed

- `DSC_WSManListener`
  - Converted to Class Resource.
  - Extracted private functions to individual files.
  - BREAKING: Renamed parameter `DN` to `BaseDN` - fixes [Issue #89](https://github.com/dsccommunity/WSManDsc/issues/89).
- `DSC_WSManConfig`
  - Removed Export-ModuleMember.
- `DSC_WSManServiceConfig`
  - Removed Export-ModuleMember.
- `azure-pipelines.yml`
  - Remove windows 2019 image add windows 2025 fixes [#112](https://github.com/dsccommunity/WSManDsc/issues/112).

### Removed

- `CommonTestHelper`
  - This is now provided by `DscResource.Test`

## [3.2.0] - 2025-01-19

### Added

- Added build task `Generate_Conceptual_Help` to generate conceptual help
  for the DSC resource.
- Added build task `Generate_Wiki_Content` to generate the wiki content
  that can be used to update the GitHub Wiki.

### Changed

- Updated CI pipeline files.
- No longer run integration tests when running the build task `test`, e.g.
  `.\build.ps1 -Task test`. To manually run integration tests, run the
  following:
  ```powershell
  .\build.ps1 -Tasks test -PesterScript 'tests/Integration' -CodeCoverageThreshold 0
  ```
- Change Azure DevOps Pipeline definition to include `source/*` - fixes [Issue #75](https://github.com/dsccommunity/WSManDsc/issues/75).
- Updated pipeline to use `latest` version of `ModuleBuilder` - fixes [Issue #75](https://github.com/dsccommunity/WSManDsc/issues/75).
- Merge `HISTORIC_CHANGELOG.md` into `CHANGELOG.md` - fixes [Issue #76](https://github.com/dsccommunity/WSManDsc/issues/76).
- WSManDsc
  - Updated to use the common module _DscResource.Common_ - Fixes [Issue #78](https://github.com/dsccommunity/WSManDsc/issues/78).
  - Fixed build failures caused by changes in `ModuleBuilder` module v1.7.0
    by changing `CopyDirectories` to `CopyPaths` - Fixes [Issue #79](https://github.com/dsccommunity/WSManDsc/issues/79).
  - Pin `Pester` module to 4.10.1 because Pester 5.0 is missing code
    coverage - Fixes [Issue #78](https://github.com/dsccommunity/WSManDsc/issues/78).
  - Automatically publish documentation to GitHub Wiki - Fixes [Issue #82](https://github.com/dsccommunity/WSManDsc/issues/82).
  - Fix build pipeline so it uses the build image `windows-latest`.
- Renamed `master` branch to `main` - Fixes [Issue #82](https://github.com/dsccommunity/WSManDsc/issues/82).
- Minor corrections to pipeline files and examples after renaming `master`
  branch to `main`.
- Updated `GitVersion.yml` to latest pattern - Fixes [Issue #87](https://github.com/dsccommunity/WSManDsc/issues/87).
- Updated build to use `Sampler.GitHubTasks` - Fixes [Issue #90](https://github.com/dsccommunity/WSManDsc/issues/90).
- Added support for publishing code coverage to `CodeCov.io` and
  Azure Pipelines - Fixes [Issue #91](https://github.com/dsccommunity/WSManDsc/issues/91).
- Build pipeline: Removed unused `dscBuildVariable` tasks.
- Updated .github issue templates to standard - Fixes [Issue #97](https://github.com/dsccommunity/WSManDsc/issues/97).
- Added Create_ChangeLog_GitHub_PR task to publish stage of build pipeline.
- Added SECURITY.md.
- Updated pipeline Deploy_Module anb Code_Coverage jobs to use ubuntu-latest
  images - Fixes [Issue #96](https://github.com/dsccommunity/WSManDsc/issues/96).
- Updated pipeline unit tests and integration tests to use Windows Server 2019 and
  Windows Server 2022 images - Fixes [Issue #96](https://github.com/dsccommunity/WSManDsc/issues/96).
- CI Pipeline
  - Updated pipeline files to match current DSC Community patterns - fixes [Issue #103](https://github.com/dsccommunity/WSManDsc/issues/103).
  - Updated HQRM and build steps to use windows-latest image.
  - Pin gitversion to V5.
- WSManDsc
  - Added support for changing the hostname and/or certificate thumbprint on the listener fixes [Issue #23](https://github.com/dsccommunity/WSManDsc/issues/23).
  - Converted tests to Pester 5 - fixes [#99](https://github.com/dsccommunity/WSManDsc/issues/99).
- `DSC_WSManConfig`
  - Refactor `Test-TargetResource` to use `Test-DscParameterState`.
  - Remove unused strings.
- `DSC_WSManServiceConfig`
  - Refactor `Test-TargetResource` to use `Test-DscParameterState`.
  - Remove unused strings

### Fixed

- Fixed pipeline by replacing the GitVersion task in the `azure-pipelines.yml`
  with a script.

## [3.1.1] - 2020-01-31

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
