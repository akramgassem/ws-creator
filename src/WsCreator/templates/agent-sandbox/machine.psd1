@{
    Description       = 'Sandbox for an agent: no sudo, no Windows disk'

    # Windows side of the machine; the machine itself is described in user-data.yaml.
    BaseDistribution  = 'Ubuntu-24.04'
    Location          = 'C:\WSL'   # virtual disk in <Location>\<name>

    CloudConfig       = @('base', 'mise', 'guard', 'podman', 'ssh')   # cloud-config\<name>.yaml, then user-data.yaml
    Modules           = @('agent')                                    # modules\<name>.sh, run afterwards

    # unique per machine (shared WSL network stack): ws-creator checks them across machines, and
    # checks they match user-data.yaml (default_subnet, Port, ssh_authorized_keys)
    PodmanSubnet      = '10.89.23.0/24'
    Ssh               = @{ Port = 2223; PublicKey = 'id_ed25519.pub' }   # key in ~\.ssh
    AgentInstructions = 'AGENTS.md'   # in this folder -> ~/.claude/CLAUDE.md (read by Claude Code)
}
