function Open-WsCreatorCode {
    <#
    .SYNOPSIS
    Opens VS Code (Remote-SSH) on the machine's ~/src.
    #>
    param([Parameter(Mandatory)][string]$Name)
    $m = Get-Machine $Name
    if (-not $m.Ssh) { throw "Machine '$($m.Name)' has no Ssh: VS Code connects through the ssh fragment" }
    if (-not (Get-Command code -ErrorAction SilentlyContinue)) { throw "VS Code command 'code' not found in PATH" }
    code --folder-uri "vscode-remote://ssh-remote+$($m.Name)/home/$($m.User)/src"
}
