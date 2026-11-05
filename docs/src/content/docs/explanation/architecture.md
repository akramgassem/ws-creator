---
title: Architecture
description: How a folder becomes a machine.
sidebar:
  order: 1
---

![ws-creator architecture](../../../assets/architecture.svg)

| Part | Role |
|---|---|
| machine folder | **who**: one machine, yours |
| `cloud-config/` fragments | **how**: shared, no variables |
| `files/` | **what**: copied as is |
| `modules/` | what cloud-init cannot express |
| `templates/` | starting points for `init` |

## A run

1. Copy `files/`, write `/etc/ws-creator-profile`.
2. Validate each fragment and `user-data.yaml`, assemble a NoCloud seed.
3. `cloud-init clean`, restart, wait; any status but `done` stops.
4. Run modules, write the SSH alias, stop the distro.

cloud-init adds and never removes, so ws-creator rebuilds instead of repairing. Updating
the module never touches your machines. Design record: [Catalog design](../catalog-design/).
