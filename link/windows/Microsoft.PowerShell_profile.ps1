using namespace System.Management.Automation
using namespace System.Management.Automation.Language

# include sensitive stuff
. "${Env:HOMEPATH}\.private-env.ps1"

# oh-my-posh init pwsh --config 'C:\Users\gene.liverman\AppData\Local\Programs\oh-my-posh\themes\paradox.omp.json' | Invoke-Expression
# oh-my-posh init pwsh --config 'C:\Users\gene.liverman\AppData\Local\Programs\oh-my-posh\themes\illusi0n.omp.json' | Invoke-Expression
oh-my-posh init pwsh --config 'C:\Users\gene.liverman\repos\my-oh-my-posh-themes\beanbag.omp.json' | Invoke-Expression

# Searching for commands with up/down arrow is really handy.  The
# option "moves to end" is useful if you want the cursor at the end
# of the line while cycling through history like it does w/o searching,
# without that option, the cursor will remain at the position it was
# when you used up arrow, which can be useful if you forget the exact
# string you started the search on.
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# Make Ctrl+u clear the currently entered text like it does on Linux and macOS
# This is mapped to Ctrl+ Home by default also
Set-PSReadLineKeyHandler -Key Ctrl+u -Function BackwardDeleteLine

# Make Ctrl+d exit the shell if the line is empty or delete the char infront of the cursor
# like it does on Linux and macOS
Set-PSReadlineKeyHandler -Key Ctrl+d -Function DeleteCharOrExit

# Aliases and functions used to simulate Linux shell aliases
Function gsw { & "git switch ${args}" }
Function gswc { & "git switch -c ${args}" }
Function hubpr { & "hub pull-request --browse --push ${args}" }


### SSH autocompletion
Function Get-Hosts($configFile) {
    Get-Content $configFile `
    | Select-String -Pattern "^Host " `
    | ForEach-Object { $_ -replace "host ", "" } `
    | Sort-Object -Unique `
}

function Get-SSHKnownHost($sshKnownHostsPath) {
    Get-Content -Path $sshKnownHostsPath `
    | ForEach-Object { $_.split(' ')[0] } `
    | Sort-Object -Unique
}

# sft in the list of commands is OktaASA's wrapper around the ssh command
Register-ArgumentCompleter -CommandName ssh, scp, sftp, sft -Native -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    $sshDir = "${Env:HOMEPATH}\.ssh"

    $hosts = Get-SSHKnownHost "$sshDir\known_hosts" `
        | ForEach-Object { ([string]$_).Split(' ')[0] } `
        | ForEach-Object { $_.Split(',') } `
        | Sort-Object -Unique

    if(Test-Path "$sshDir\config") {
        $hosts += Get-Content "$sshDir\config" `
            | Select-String -Pattern "^Include " `
            | ForEach-Object { $_ -replace "include ", "" } `
            | ForEach-Object { Get-Hosts "$sshDir/$_" } `
    }

    $hosts += Get-Hosts "$sshDir\config"
    
    $hosts = $hosts | Sort-Object -Unique

    # For now just assume it's a hostname.
    $textToComplete = $wordToComplete
    $generateCompletionText = {
        param($x)
        $x
    }
    if ($wordToComplete -match "^(?<user>[-\w/\\]+)@(?<host>[-.\w]+)$") {
        $textToComplete = $Matches["host"]
        $generateCompletionText = {
            param($hostname)
            $Matches["user"] + "@" + $hostname
        }
    }

    $hosts `
    | Where-Object { $_ -like "${textToComplete}*" } `
    | ForEach-Object { [CompletionResult]::new((&$generateCompletionText($_)), $_, [CompletionResultType]::ParameterValue, $_) }
}
### end SSH autocompletion
