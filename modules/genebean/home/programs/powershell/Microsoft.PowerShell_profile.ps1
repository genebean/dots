# With PowerCLI installed via ps-get this isn't needed anymore
#Get-Module -ListAvailable PowerCLI.* | Import-Module

oh-my-posh init pwsh --config ~/.config/oh-my-posh/config.json | Invoke-Expression
