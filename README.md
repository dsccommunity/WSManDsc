# WSManDsc

The **WSManDsc** module contains DSC resources for configuring WS-Management and
PowerShell Remoting.

- **WSManListener**: Create, edit or remove WS-Management HTTP/HTTPS listeners.
- **WSManServiceConfig**: Configure the WS-Man Service.

**This project is not maintained or supported by Microsoft.**

It has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/).

This module should meet the [PowerShell DSC Resource Kit High Quality Resource
Module Guidelines](https://github.com/PowerShell/DscResources/blob/master/HighQualityModuleGuidelines.md).

## Documentation and Examples

For a full list of resources in WSManDsc and examples on their use, check out
the [iSCSIDsc wiki](https://github.com/PlagueHO/WSManDsc/wiki).

## Branches

### master

[![Build status](https://ci.appveyor.com/api/projects/status/lppuhbyqkwoect24/branch/master?svg=true)](https://ci.appveyor.com/project/PlagueHO/wsmandsc/branch/master)
[![codecov](https://codecov.io/gh/PowerShell/WSManDsc/branch/master/graph/badge.svg)](https://codecov.io/gh/PlagueHO/WSManDsc/branch/master)

This is the branch containing the latest release - no contributions should be made
directly to this branch.

### dev

[![Build status](https://ci.appveyor.com/api/projects/status/lppuhbyqkwoect24/branch/dev?svg=true)](https://ci.appveyor.com/project/PlagueHO/wsmandsc/branch/dev)
[![codecov](https://codecov.io/gh/PlagueHO/WSManDsc/branch/dev/graph/badge.svg)](https://codecov.io/gh/PowerShell/WSManDsc/branch/dev)

This is the development branch to which contributions should be proposed by contributors
as pull requests. This development branch will periodically be merged to the master
branch, and be released to [PowerShell Gallery](https://www.powershellgallery.com/).
