# With PowerCLI installed via ps-get this isn't needed anymore
#Get-Module -ListAvailable PowerCLI.* | Import-Module

# PowerShellGet\Install-Module posh-git -Scope CurrentUser -AllowPrerelease -Force
#Import-Module '/Users/gene.liverman/.local/share/powershell/Modules/posh-git/1.0.0/posh-git.psd1'
Import-Module posh-git

# Install-Module -Name oh-my-posh
Import-module oh-my-posh
#Set-Theme Paradox
Set-Theme beantest
