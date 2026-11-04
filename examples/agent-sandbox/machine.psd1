@{
    # Côté Windows d'agent-sandbox ; la machine elle-même est décrite dans user-data.yaml.
    BaseDistribution  = 'Ubuntu-24.04'
    Location          = 'C:\WSL'   # disque virtuel dans <Location>\<nom>, hors du dépôt

    CloudConfig       = @('base', 'mise', 'guard', 'podman', 'ssh')   # cloud-config\<nom>.yaml, puis user-data.yaml
    Modules           = @('agent')                                    # modules\<nom>.sh, joués ensuite

    # uniques par machine (pile réseau WSL partagée) : ws-creator les contrôle entre machines, et
    # vérifie qu'ils concordent avec user-data.yaml (default_subnet, Port, ssh_authorized_keys)
    PodmanSubnet      = '10.89.23.0/24'
    Ssh               = @{ Port = 2223; PublicKey = 'id_ed25519.pub' }   # clé dans ~\.ssh
    AgentInstructions = 'AGENTS.md'   # dans ce dossier -> ~/.claude/CLAUDE.md (lu par Claude Code)
}
