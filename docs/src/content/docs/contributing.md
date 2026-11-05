---
title: Contributing
tableOfContents: false
description: Tests, docs, releases.
---

Everything is in English.

```powershell
Invoke-Pester -Path tests
Invoke-ScriptAnalyzer -Path src -Recurse -Settings PSScriptAnalyzerSettings.psd1
```

Docs (Starlight, `docs/`); the command reference is generated from `Get-Help`:

```powershell
./docs/scripts/New-CommandReference.ps1
cd docs; npm ci; npm run dev
```

Release: bump `ModuleVersion`, merge, push tag `v<version>`.
