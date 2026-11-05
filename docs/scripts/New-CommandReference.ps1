#Requires -Version 7.0
# Command reference pages for the documentation site, generated from the module's comment-based
# help (Get-Help), so the site and Get-Help never disagree. Run by .github/workflows/pages.yml;
# the output folder is ignored by git.
#   ./docs/scripts/New-CommandReference.ps1
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$out = Join-Path -Path $repo -ChildPath 'docs\src\content\docs\reference\commands'
Import-Module -Name (Join-Path -Path $repo -ChildPath 'src\WsCreator') -Force

# subcommand -> function, in the order of the sidebar
$commands = [ordered]@{
    'ws-creator' = 'Invoke-WsCreator'
    init         = 'Initialize-WsCreatorMachine'
    new          = 'New-WsCreatorMachine'
    apply        = 'Update-WsCreatorMachine'
    list         = 'Get-WsCreatorMachineList'
    status       = 'Get-WsCreatorStatus'
    code         = 'Open-WsCreatorCode'
    stop         = 'Stop-WsCreatorMachine'
    purge        = 'Remove-WsCreatorMachine'
    image        = 'Build-WsCreatorImage'
    doctor       = 'Test-WsCreatorHost'
}
$missing = @(Get-Command -Module WsCreator -CommandType Function).Name | Where-Object { $_ -notin $commands.Values }
if ($missing) { throw "No page for: $($missing -join ', ') (add them to `$commands)" }

function Format-Text([string]$Text) { $Text.Replace('\', '\\').Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;') }
function Format-Cell([string]$Text) { (Format-Text $Text).Replace('|', '\|') -replace '\s*\r?\n\s*', ' ' }
function Format-Yaml([string]$Text) { "'" + $Text.Replace("'", "''") + "'" }

# Help paragraphs: indented lines become a code block, the rest stays text
function Format-Paragraph([string[]]$Lines) {
    $block = $false
    foreach ($line in $Lines) {
        $indented = $line -match '^\s{2,}\S'
        if ($indented -and -not $block) { '```text'; $block = $true }
        if (-not $indented -and $block) { '```'; ''; $block = $false }
        if ($block) { $line } else { Format-Text $line }
    }
    if ($block) { '```' }
}

New-Item -ItemType Directory -Force -Path $out | Out-Null
Get-ChildItem -Path $out -Filter *.md | Remove-Item
$order = 0
foreach ($sub in $commands.Keys) {
    $fn = $commands[$sub]
    $help = Get-Help -Name $fn -Full
    $title = if ($sub -eq 'ws-creator') { 'ws-creator' } else { "ws-creator $sub" }
    $synopsis = ($help.Synopsis -replace '\s*\r?\n\s*', ' ').Trim()
    $order++
    $md = [Collections.Generic.List[string]]::new()
    $md.AddRange([string[]]@('---', "title: $(Format-Yaml $title)", "description: $(Format-Yaml $synopsis)", 'sidebar:', "  label: $(Format-Yaml $(if ($sub -eq 'ws-creator') { 'Overview' } else { $sub }))", "  order: $order", '---', ''))
    $md.Add("$(Format-Text $synopsis) ``Get-Help $fn -Full``"); $md.Add('')

    $md.Add('## Syntax'); $md.Add(''); $md.Add('```powershell')
    $md.Add((($help.syntax | Out-String -Width 4096).Trim() -replace '\s*\r?\n\s*', "`n" -replace '\[<CommonParameters>\]', '').Trim())
    $md.Add('```'); $md.Add('')

    $description = @($help.description.Text -split '\r?\n')
    if ($description -join '') {
        $md.Add('## Description'); $md.Add('')
        foreach ($line in Format-Paragraph $description) { $md.Add($line) }
        $md.Add('')
    }

    $parameters = @($help.parameters.parameter | Where-Object { $_ })
    if ($parameters) {
        $md.Add('## Parameters'); $md.Add('')
        $md.Add('| Parameter | Type | Required | Position | Description |'); $md.Add('|---|---|---|---|---|')
        foreach ($p in $parameters) {
            $text = ($p.description.Text -join ' ')
            $md.Add("| ``-$($p.name)`` | $($p.type.name) | $($p.required) | $($p.position) | $(Format-Cell $text) |")
        }
        $md.Add('')
    }

    $examples = @($help.examples.example | Where-Object { $_ })
    if ($examples) {
        $md.Add('## Examples'); $md.Add('')
        foreach ($e in $examples) {
            # comment-based help: the first line is the command, the next ones explain it
            $code, $rest = @($e.code.Trim() -split '\r?\n', 2)
            $md.Add('```powershell'); $md.Add($code.Trim()); $md.Add('```')
            $remarks = ((@($rest) + @($e.remarks.Text) | Where-Object { $_ }) -join "`n").Trim()
            if ($remarks) { $md.Add(''); $md.Add((Format-Text $remarks)) }
            $md.Add('')
        }
    }
    $file = Join-Path -Path $out -ChildPath "$(if ($sub -eq 'ws-creator') { 'index' } else { $sub }).md"
    [IO.File]::WriteAllText($file, ($md -join "`n").TrimEnd() + "`n")
}
Write-Host "$($commands.Count) pages in $out"
