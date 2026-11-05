function Get-WsCreatorMachineList {
    <#
    .SYNOPSIS
    Templates (with their real source), described machines (with their provenance) and WSL distros.
    .DESCRIPTION
    Templates: from WS_CREATOR_TEMPLATES in order, then the module. A name found again in a
    later catalog is shown as shadowed: init uses the first one. Git catalogs are read from
    their local clone, without network; -Refresh fetches them first.
    Machines: "copied from <source>" when init created them, with "modified since" once their
    files no longer match TemplateHash; "written by hand" otherwise.
    .PARAMETER Refresh
    Fetch the git catalogs before listing.
    .EXAMPLE
    ws-creator list
    .EXAMPLE
    ws-creator list -Refresh
    #>
    param([switch]$Refresh)
    if ($Refresh) { foreach ($source in Get-TemplateSource) { Update-TemplateCatalog $source } }

    $templates = @(Get-Template)
    $names = @(Get-MachineName)
    $labels = @($templates | ForEach-Object { if ($_.Shadowed) { "$($_.Name) (shadowed)" } else { $_.Name } })
    $width = (@(16) + @(($labels + $names) | ForEach-Object { $_.Length + 2 }) | Measure-Object -Maximum).Maximum
    Write-Host 'Templates'
    for ($i = 0; $i -lt $templates.Count; $i++) {
        $t = $templates[$i]
        $description = if ($t.Description) { $t.Description } else { '(no Description in machine.psd1)' }
        Write-Host ('  {0}{1}' -f $labels[$i].PadRight($width), $description)
        Write-Host ('  {0}{1}' -f ''.PadRight($width), $t.Source)
    }
    $missing = @(Get-TemplateSource | Where-Object { $_.Kind -eq 'git' -and -not (Test-Path -Path $_.Dir) })
    foreach ($s in $missing) { Write-Host "  ($($s.Display) not fetched yet: ws-creator list -Refresh)" }

    Write-Host ''
    Write-Host "Machines ($(Format-UserPath $script:MachinesDir))"
    if (-not $names) { Write-Host '  (none: ws-creator init <template> <name>)' }
    foreach ($name in $names) {
        Write-Host ('  {0}{1}' -f $name.PadRight($width), (Get-MachineProvenance (Get-MachineDir $name)))
    }

    Write-Host ''
    Write-Host 'WSL distros'
    wsl --list --verbose
}
