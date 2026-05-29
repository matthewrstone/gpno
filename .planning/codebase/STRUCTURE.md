---
title: Directory Structure
focus: arch
last_mapped: 2026-05-22
---

# Directory Structure

## Overview

`gpno` is a Puppet module following the standard PDK (Puppet Development Kit) layout. Module name: `souldo-gpno` (Forge namespace: `souldo`, module name: `gpno`).

## Root Layout

```
gpno/                          # repo root
├── manifests/                 # Puppet classes
│   └── baseline_management.pp
├── plans/                     # Bolt plans (orchestration)
│   └── create_manifest.pp
├── tasks/                     # Bolt tasks (scripts)
│   ├── create_resources.json  # task metadata
│   ├── create_resources_nix.py
│   ├── create_resources_win.ps1
│   └── export.ps1
├── gpno/                      # nested module copy (legacy artifact)
│   └── tasks/
│       └── export.ps1
├── data/                      # Hiera data
│   └── common.yaml
├── spec/                      # RSpec tests
│   ├── classes/
│   │   └── baseline_management_spec.rb
│   ├── default_facts.yml
│   └── spec_helper.rb
├── metadata.json              # Puppet Forge metadata
├── hiera.yaml                 # Hiera config for module
├── Gemfile                    # Ruby test dependencies
├── Rakefile                   # Rake tasks (test, lint, validate)
├── .fixtures.yml              # Spec fixture dependencies
├── .rubocop.yml               # Ruby linting config
├── .puppet-lint.rc            # Puppet linting config
├── .gitlab-ci.yml             # GitLab CI pipeline
├── .travis.yml                # Travis CI pipeline
└── appveyor.yml               # AppVeyor CI pipeline (Windows)
```

## Key Locations

| Purpose | Location |
|---------|----------|
| Puppet class definitions | `manifests/*.pp` |
| Bolt orchestration plans | `plans/*.pp` |
| Bolt task scripts | `tasks/` |
| Task metadata | `tasks/*.json` |
| RSpec class tests | `spec/classes/` |
| Test helper setup | `spec/spec_helper.rb` |
| Hiera module data | `data/common.yaml` |
| Module metadata | `metadata.json` |

## Naming Conventions

- **Classes:** `gpno::<name>` → `manifests/<name>.pp`
- **Plans:** `gpno::<name>` → `plans/<name>.pp`
- **Tasks:** `gpno::<name>` → `tasks/<name>.{json,py,ps1}`
- **Specs:** `spec/classes/<name>_spec.rb` for class `gpno::<name>`
- **Ruby:** snake_case for files and variables
- **Puppet:** snake_case for resource titles, parameters, and class names

## Where to Add New Code

| Adding... | Put it in... |
|-----------|-------------|
| New Puppet class | `manifests/<class_name>.pp` |
| New Bolt plan | `plans/<plan_name>.pp` |
| New Bolt task (cross-platform) | `tasks/<task_name>.json` + `tasks/<task_name>_nix.py` + `tasks/<task_name>_win.ps1` |
| New task (Windows-only) | `tasks/<task_name>.json` + `tasks/<task_name>.ps1` |
| Class unit tests | `spec/classes/<class_name>_spec.rb` |
| Hiera data | `data/common.yaml` |

## Notable Observations

- **`gpno/tasks/`** nested directory at root mirrors `tasks/` — appears to be a legacy artifact or Git merge artifact; `tasks/export.ps1` is the canonical location
- **`data/common.yaml`** is empty (no Hiera key-values defined yet)
- No `lib/` directory — no custom Puppet functions or providers
- No `files/` or `templates/` directories — no static files or ERB/EPP templates
- Module is PDK-managed (`pdk-version: 1.14.0`), meaning structure follows PDK conventions
