# Script modules (modules\<m>.sh): what cloud-init cannot express yet. They receive the
# machine.psd1 values as WS_CREATOR_* variables (no secrets: visible in ps).
function Get-ModuleVariable($m) {
    $vars = @("WS_CREATOR_NAME=$($m.Name)", "WS_CREATOR_USER=$($m.User)")
    if ($m.AgentInstructions) {
        $bytes = [IO.File]::ReadAllBytes((Join-Path -Path $m.Dir -ChildPath $m.AgentInstructions))
        $vars += "WS_CREATOR_AGENT_MD_B64=$([Convert]::ToBase64String($bytes))"
    }
    return $vars
}

# The module goes over stdin, preceded by modules\lib.sh (shared functions)
function Invoke-Module($m, [string]$Script) {
    $vars = Get-ModuleVariable $m
    $lib = Get-Content -Path (Join-Path -Path $script:Root -ChildPath 'modules\lib.sh') -Raw
    ($lib + "`n" + (Get-Content -Path $Script -Raw)) |
        wsl -d $m.Name -u root --exec env @vars bash -c "tr -d '\r' | bash -s"
}

# Fragments through cloud-init, then modules, then the Windows SSH alias; the distro is stopped at the end
function Invoke-Machine($m, [string[]]$Only) {
    $parts = Select-MachinePart $m $Only
    if ($parts.CloudConfig) {
        Invoke-Step "cloud-init in $($m.Name): $($parts.CloudConfig -join ', ') + user-data.yaml" {
            Invoke-CloudInit $m $parts.CloudConfig
        }
    }
    foreach ($s in $parts.Modules) {
        $script = Join-Path -Path $script:Root -ChildPath "modules\$s.sh"
        Invoke-Step "Applying module $s in $($m.Name)" { Invoke-Module $m $script }
    }
    if ('ssh' -in $parts.CloudConfig) {
        Invoke-Step "Windows ssh config: Host $($m.Name) in ~\.ssh\ws-creator\$($m.Name).conf" { Set-SshHost $m }
    }
    Invoke-Step "stop containers + wsl --terminate $($m.Name)" { Stop-Distro $m }
}
