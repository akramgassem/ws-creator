# Changelog

All notable changes to this project. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and versions follow [Semantic Versioning](https://semver.org/). Each release on the
PowerShell Gallery has a matching GitHub Release, whose notes are the section below.

## [0.2.2] - 2026-11-06

### Added

- `ws-creator help` (also `--help`, or no subcommand) shows the command's help.

### Changed

- An unknown subcommand says so, lists the commands and points to `ws-creator help`, instead
  of a ValidateSet error.
- A machine that is not found says which folder was searched, whether `WS_CREATOR_MACHINES` is
  set, and which machines are there.

### Fixed

- `WS_CREATOR_MACHINES` and `WS_CREATOR_IMAGES` set after the module is loaded now take effect
  (they were read once, at import).

## [0.2.1] - 2026-11-05

### Added

- Documentation site: https://akramgassem.github.io/ws-creator/, with a command reference
  generated from `Get-Help`.
- This changelog; GitHub Releases created from it on each tag.
- Dependabot for GitHub Actions and the documentation site's npm packages, with a 14-day
  cooldown.

### Changed

- ws-creator is presented as a workspace creator for developers on Windows (module
  description, README).
- The Gallery's project link points to the documentation site.

## [0.2.0] - 2026-11-05

### Added

- Template catalog: `dev` and `agent-sandbox` templates in the module; personal and team
  catalogs (local folders or git repos) through `WS_CREATOR_TEMPLATES`.
- `ws-creator init <template> <name>`: a machine folder from a template, with your user,
  SSH key, a free port and subnet, and its provenance.
- `ws-creator list` shows each template's real source and whether a machine was copied from
  a template and modified since.
- Full `Get-Help` for every command.

### Changed

- The whole project is in English; the `/menage` skill is now `/tidy`.

### Removed

- `examples/`: replaced by the module's templates.

### Fixed

- The `pre-commit` hook no longer refuses commits made only of deletions.

## [0.1.0] - 2026-11-04

First release on the PowerShell Gallery.

[0.2.1]: https://github.com/akramgassem/ws-creator/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/akramgassem/ws-creator/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/akramgassem/ws-creator/releases/tag/v0.1.0
