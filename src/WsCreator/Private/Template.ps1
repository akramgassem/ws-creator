# Template catalogs (docs/src/content/docs/explanation/catalog-design.md). A template is a valid machine with a Description
# key; a catalog is a folder of templates. WS_CREATOR_TEMPLATES lists catalogs separated by ';':
# local paths or git repos (optionally #<branch|tag>), then the module's own templates\ comes last.

# Path shown to the user: ~ instead of the home folder
function Format-UserPath([string]$Path) {
    if ($Path.StartsWith($HOME, [StringComparison]::OrdinalIgnoreCase)) { '~' + $Path.Substring($HOME.Length) } else { $Path }
}

function Get-ModuleVersion { (Import-PowerShellDataFile -Path (Join-Path -Path $script:Root -ChildPath 'WsCreator.psd1')).ModuleVersion }

# One entry per catalog, in resolution order: Kind (local, git, module), Dir, Display (base of
# the source shown by list), and for git: Url, Ref.
function Get-TemplateSource {
    $entries = @(($env:WS_CREATOR_TEMPLATES -split ';') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    foreach ($entry in $entries) {
        if ($entry -match '^(https://|ssh://|git@)') {
            $url, $ref = $entry -split '#', 2
            if ($url -notmatch '^(?:https://|ssh://(?:[^@/]+@)?|git@)([^/:]+)[/:](.+?)(?:\.git)?/?$') { throw "WS_CREATOR_TEMPLATES: cannot read git URL '$url'" }
            $hostName, $repoPath = $Matches[1], $Matches[2]
            [pscustomobject]@{
                Kind    = 'git'
                Url     = $url
                Ref     = $ref
                Dir     = Join-Path -Path $script:CatalogsDir -ChildPath (Join-Path -Path $hostName -ChildPath ($repoPath -replace '/', '\'))
                Display = "$hostName/$repoPath"
            }
        }
        else {
            $dir = [IO.Path]::GetFullPath($entry)
            [pscustomobject]@{ Kind = 'local'; Url = $null; Ref = $null; Dir = $dir; Display = $dir }
        }
    }
    $dir = Join-Path -Path $script:Root -ChildPath 'templates'
    [pscustomobject]@{ Kind = 'module'; Url = $null; Ref = $null; Dir = $dir; Display = (Format-UserPath $dir) }
}

# Clones a git catalog into the cache, or fetches it again (the cache is ws-creator's: reset --hard)
function Update-TemplateCatalog($Source) {
    if ($Source.Kind -ne 'git') { return }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw "git not found in PATH: needed for the catalog $($Source.Url)" }
    $PSNativeCommandUseErrorActionPreference = $false
    $ref = if ($Source.Ref) { $Source.Ref } else { 'HEAD' }
    if (-not (Test-Path -Path (Join-Path -Path $Source.Dir -ChildPath '.git'))) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Path $Source.Dir -Parent) | Out-Null
        $branch = if ($Source.Ref) { @('--branch', $Source.Ref) } else { @() }
        git clone --quiet --depth 1 @branch $Source.Url $Source.Dir 2>&1 | ForEach-Object { Write-Warning "$_" }
        if ($LASTEXITCODE) { throw "git clone $($Source.Url) failed" }
        return
    }
    git -C $Source.Dir fetch --quiet --depth 1 origin $ref 2>&1 | ForEach-Object { Write-Warning "$_" }
    if ($LASTEXITCODE) { throw "git fetch $($Source.Url) failed" }
    git -C $Source.Dir reset --quiet --hard FETCH_HEAD
    if ($LASTEXITCODE) { throw "git reset in $($Source.Dir) failed" }
}

# Templates of all catalogs, in resolution order. A name found again in a later catalog is
# Shadowed. Version: the catalog's commit (git), the module version (module), none (local).
function Get-Template {
    $seen = @{}
    foreach ($source in Get-TemplateSource) {
        if (-not (Test-Path -Path $source.Dir)) {
            if ($source.Kind -eq 'local') { Write-Warning "WS_CREATOR_TEMPLATES: $($source.Dir) not found" }
            continue
        }
        $version = switch ($source.Kind) {
            'git' { git -C $source.Dir rev-parse --short HEAD }
            'module' { Get-ModuleVersion }
            default { $null }
        }
        foreach ($dir in Get-ChildItem -Path $source.Dir -Directory | Sort-Object -Property Name) {
            $psd1 = Join-Path -Path $dir.FullName -ChildPath 'machine.psd1'
            if (-not (Test-Path -Path $psd1)) { continue }
            $data = Import-PowerShellDataFile -Path $psd1
            $display = if ($source.Kind -eq 'git') { "$($source.Display)/$($dir.Name)" } else { Format-UserPath $dir.FullName }
            [pscustomobject]@{
                Name        = $dir.Name
                Description = $data.Description
                Dir         = $dir.FullName
                Source      = $display
                Version     = $version
                Catalog     = $source
                Shadowed    = $seen.ContainsKey($dir.Name)
            }
            $seen[$dir.Name] = $true
        }
    }
}

# Hash of a machine's files, as init wrote them: sorted relative paths and contents, line
# endings ignored (git may check machine.psd1 out with CRLF), provenance keys left out.
function Get-MachineHash([string]$Dir) {
    $sha = [Security.Cryptography.SHA256]::Create()
    $lines = foreach ($file in Get-ChildItem -Path $Dir -Recurse -File | Sort-Object -Property FullName) {
        $rel = [IO.Path]::GetRelativePath($Dir, $file.FullName) -replace '\\', '/'
        $text = [IO.File]::ReadAllText($file.FullName) -replace "`r", ''
        if ($rel -eq 'machine.psd1') { $text = $text -replace '(?m)^\s*Template(Source|Version|Hash)?\s*=.*\n', '' }
        $hash = [Convert]::ToHexString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($text))).ToLower()
        "$rel $hash"
    }
    'sha256:' + [Convert]::ToHexString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes(($lines -join "`n")))).ToLower()
}

# Provenance line of a machine for list
function Get-MachineProvenance([string]$Dir) {
    $data = Import-PowerShellDataFile -Path (Join-Path -Path $Dir -ChildPath 'machine.psd1')
    if (-not $data.TemplateSource) { return 'written by hand' }
    $text = "copied from $($data.TemplateSource)"
    if ($data.TemplateVersion) { $text += " @ $($data.TemplateVersion)" }
    if ($data.TemplateHash -and $data.TemplateHash -ne (Get-MachineHash $Dir)) { $text += ', modified since' }
    return $text
}
