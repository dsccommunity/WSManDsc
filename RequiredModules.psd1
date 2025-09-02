@{
    PSDependOptions                = @{
        AddToPath  = $true
        Target     = 'output\RequiredModules'
        Parameters = @{
            Repository = ''
        }
    }

    InvokeBuild                    = 'latest'
    PSScriptAnalyzer               = 'latest'
    Pester                         = 'latest'
    Plaster                        = 'latest'
    ModuleBuilder                  = 'latest'
    ChangelogManagement            = 'latest'
    Sampler                        = 'latest'
    'Sampler.GitHubTasks'          = 'latest'
    MarkdownLinkCheck              = 'latest'
    'DscResource.Test'             = 'latest'
    xDscResourceDesigner           = 'latest'

    # Build dependencies needed for using the module
    'DscResource.Common'           = @{
        Version    = 'latest'
        Parameters = @{
            AllowPrerelease = $true
        }
    }
    'DscResource.Base'             = @{
        Version    = 'latest'
        Parameters = @{
            AllowPrerelease = $true
        }
    }

    # Analyzer rules
    'DscResource.AnalyzerRules'    = 'latest'
    'Indented.ScriptAnalyzerRules' = 'latest'

    # Prerequisite modules for documentation.
    'DscResource.DocGenerator'     = @{
        Version    = 'latest'
        Parameters = @{
            AllowPrerelease = $true
        }
    }
    PlatyPS                        = 'latest'
}
