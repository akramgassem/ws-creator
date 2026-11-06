function Invoke-WsCreator {
    <#
    .SYNOPSIS
    The ws-creator command (alias): one subcommand = one module function.
    .DESCRIPTION
    Subcommands, and the function that does the work (Get-Help <function> for details):
      init <template> <name>   Initialize-WsCreatorMachine   machine folder from a template
      new <machine>            New-WsCreatorMachine          creates the distro and applies everything
      apply <machine>          Update-WsCreatorMachine       reapplies fragments and modules
      purge <machine>          Remove-WsCreatorMachine       deletes the distro
      stop <machine>           Stop-WsCreatorMachine         stops containers, then the distro
      image <machine>          Build-WsCreatorImage          builds the base image
      status <machine>         Get-WsCreatorStatus           distro, disk, cloud-init, unpushed work
      code <machine>           Open-WsCreatorCode            VS Code on the machine's ~/src
      list                     Get-WsCreatorMachineList      templates, machines, distros
      doctor                   Test-WsCreatorHost            workstation check
      help                     Get-Help ws-creator           this help (also --help, or no subcommand)
    Commands that change something only show what they would do unless -Apply is given.
    Machines are read from WS_CREATOR_MACHINES, or %APPDATA%\ws-creator\machines when it is not set.
    .PARAMETER Command
    The subcommand. Without one, shows this help.
    .PARAMETER Machine
    The machine (folder <WS_CREATOR_MACHINES>\<name>); for init, the template.
    .PARAMETER Name
    init only: the name of the new machine.
    .PARAMETER Only
    apply only: just these fragments or modules, e.g. -Only mise,ssh.
    .PARAMETER Apply
    Do it. Without it, dry run.
    .PARAMETER Force
    purge only: purge despite unpushed work.
    .PARAMETER Refresh
    list only: fetch the git catalogs first.
    .PARAMETER User
    init only: Linux user (see Get-Help Initialize-WsCreatorMachine).
    .PARAMETER PublicKey
    init only: public key file in ~\.ssh.
    .PARAMETER Port
    init only: SSH port.
    .PARAMETER Subnet
    init only: podman subnet.
    .PARAMETER Location
    init only: folder of the virtual disk.
    .EXAMPLE
    ws-creator init dev my-machine -Apply
    .EXAMPLE
    ws-creator new my-machine -Apply
    .EXAMPLE
    ws-creator apply my-machine -Only mise -Apply
    .LINK
    https://github.com/akramgassem/ws-creator
    #>
    [CmdletBinding()]
    param (
        # completion only: an unknown command gets a message pointing to help (below), not a ValidateSet error
        [Parameter(Position = 0)]
        [ArgumentCompletions('init', 'new', 'apply', 'list', 'status', 'code', 'stop', 'purge', 'image', 'doctor', 'help')]
        [string]$Command,

        [Parameter(Position = 1)]
        [string]$Machine,

        [Parameter(Position = 2)]
        [string]$Name,

        [string[]]$Only,
        [switch]$Apply,
        [switch]$Force,
        [switch]$Refresh,

        [string]$User,
        [string]$PublicKey,
        [int]$Port,
        [string]$Subnet,
        [string]$Location
    )
    $commands = 'init', 'new', 'apply', 'list', 'status', 'code', 'stop', 'purge', 'image', 'doctor'
    if (-not $Command -or $Command -in 'help', '--help', '/?') { return Get-Help -Name Invoke-WsCreator }
    if ($Command -notin $commands) {
        throw "Unknown command '$Command'. Commands: $($commands -join ', '). Help: ws-creator help"
    }
    $timer = [Diagnostics.Stopwatch]::StartNew()

    switch ($Command) {
        'init' {
            $init = @{ Template = $Machine; Name = $Name; Apply = $Apply }
            foreach ($key in 'User', 'PublicKey', 'Port', 'Subnet', 'Location') {
                if ($PSBoundParameters.ContainsKey($key)) { $init[$key] = $PSBoundParameters[$key] }
            }
            Initialize-WsCreatorMachine @init
        }
        'new' { New-WsCreatorMachine -Name $Machine -Apply:$Apply }
        'apply' { Update-WsCreatorMachine -Name $Machine -Only $Only -Apply:$Apply }
        'purge' { if ($Only) { throw 'purge has no -Only: purge the machine, then new' }
                  Remove-WsCreatorMachine -Name $Machine -Apply:$Apply -Force:$Force }
        'stop' { Stop-WsCreatorMachine -Name $Machine -Apply:$Apply }
        'status' { Get-WsCreatorStatus -Name $Machine }
        'code' { Open-WsCreatorCode -Name $Machine }
        'image' { Build-WsCreatorImage -Name $Machine -Apply:$Apply }
        'list' { Get-WsCreatorMachineList -Refresh:$Refresh }
        'doctor' { Test-WsCreatorHost }
    }

    if ($Apply -and $Command -in 'new', 'apply', 'image') {
        Write-Host ('Duration: {0:mm\:ss}' -f $timer.Elapsed)
    }
}
