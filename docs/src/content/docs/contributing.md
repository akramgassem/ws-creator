---
title: Contributing
description: Run the tests, the lint and this documentation site locally.
---

The code is on [GitHub](https://github.com/akramgassem/ws-creator). Everything is in
English: code, messages, docs, commits and pull requests.

## Tests and lint

```powershell
Invoke-Pester -Path tests                                                        # Pester 5+
Invoke-ScriptAnalyzer -Path src -Recurse -Settings PSScriptAnalyzerSettings.psd1
```

The tests cover what does not touch WSL: reading and validating machines, `-Only`,
conflicts, SSH config, templates, catalogs, `init` and provenance, and structure rules (no
template syntax, Linux line endings in `files/`, nothing under `/home`). The rest is tried on
a throwaway machine. From a clone, without installing: `.\ws-creator.ps1 <command>`.

## Documentation

The site is [Astro Starlight](https://starlight.astro.build/) in `docs/`, published to GitHub
Pages by `.github/workflows/pages.yml` on every push to `main`. The command reference is
generated from `Get-Help` and is not committed:

```powershell
./docs/scripts/New-CommandReference.ps1
cd docs
npm ci
npm run dev        # http://localhost:4321/ws-creator/
```

Pages follow [Diátaxis](https://diataxis.fr/): a tutorial, guides, reference and
explanation. Broken internal links fail the build.

## Releases

Bump `ModuleVersion` in `src/WsCreator/WsCreator.psd1`, merge, then push the tag
`v<version>`: `.github/workflows/release.yml` publishes to the PowerShell Gallery.
