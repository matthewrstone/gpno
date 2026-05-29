<!-- refreshed: 2026-05-22 -->
# Architecture

**Analysis Date:** 2026-05-22

## System Overview

```text
┌─────────────────────────────────────────────────────────────┐
│                    Bolt Orchestration Layer                  │
│              `plans/create_manifest.pp`                      │
└────────────┬────────────────────────────┬───────────────────┘
             │ run_task('gpno::export')    │ run_task('gpno::create_resources')
             ▼                            ▼
┌────────────────────────┐   ┌────────────────────────────────┐
│   Windows DC (remote)  │   │   Localhost (conversion)        │
│  `gpno/tasks/export.ps1`│   │  `tasks/create_resources_nix.py`│
│  `tasks/export.ps1`    │   │  `tasks/create_resources_win.ps1`│
└────────────┬───────────┘   └───────────────┬────────────────┘
             │ JSON (resources + warnings)    │
             │ ◄──────────────────────────────┘
             ▼
┌─────────────────────────────────────────────────────────────┐
│              Puppet DSC Resource Manifest Output             │
│           (dsc_* resource blocks printed to stdout)          │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              Prerequisite Class (applied separately)         │
│           `manifests/baseline_management.pp`                 │
│   Installs Nuget + BaselineManagement on domain controller   │
└─────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| `gpno::baseline_management` | Installs PowerShell prerequisites on Windows DC | `manifests/baseline_management.pp` |
| `gpno::create_manifest` | Bolt plan orchestrating the full GPO export pipeline | `plans/create_manifest.pp` |
| `gpno::export` (remote task) | Backs up GPO and converts to DSC via PowerShell | `gpno/tasks/export.ps1` |
| `gpno::export` (non-strict) | Alternate export task (no warning capture) | `tasks/export.ps1` |
| `gpno::create_resources` | Converts JSON DSC data into Puppet resource syntax | `tasks/create_resources_nix.py`, `tasks/create_resources_win.ps1` |
| Hiera data | Module-level data hierarchy configuration | `hiera.yaml`, `data/common.yaml` |

## Pattern Overview

**Overall:** Bolt task/plan pipeline with cross-platform Puppet module

**Key Characteristics:**
- Two-phase design: (1) remote GPO export on a Windows domain controller, (2) local conversion to Puppet manifest syntax
- Cross-platform task implementations: Python for Unix/shell environments, PowerShell for Windows environments
- The Puppet class (`manifests/`) handles prerequisites; Bolt tasks/plans handle the export workflow
- Output is printed to stdout as Puppet DSC resource blocks, not written to disk by the module itself
- Two copies of `export.ps1` exist: `gpno/tasks/export.ps1` (the Bolt-registered task with `#Requires` guards) and `tasks/export.ps1` (slightly different version without full warning capture)

## Layers

**Prerequisite Layer:**
- Purpose: Ensure the Windows domain controller has required PowerShell modules installed
- Location: `manifests/baseline_management.pp`
- Contains: Puppet class managing `Nuget` package provider and `BaselineManagement` PS module
- Depends on: `hbuckle-powershellmodule` Puppet module (declared in `metadata.json`)
- Used by: Applied independently to domain controller nodes before running the plan

**Orchestration Layer (Bolt Plan):**
- Purpose: Coordinate task execution across remote and local targets
- Location: `plans/create_manifest.pp`
- Contains: Single plan that sequences `gpno::export` on remote nodes then `gpno::create_resources` on localhost
- Depends on: Both task implementations below
- Used by: Operators invoking `bolt plan run gpno::create_manifest`

**Export Task Layer:**
- Purpose: Backup a named GPO and convert it to DSC configuration using BaselineManagement
- Location: `gpno/tasks/export.ps1` (primary), `tasks/export.ps1` (secondary)
- Contains: Two PowerShell functions — `Backup-Policy` (calls `Backup-GPO`) and `Convert-DSC` (parses DSCfromGPO.ps1 output)
- Depends on: `GPRegistryPolicyParser`, `BaselineManagement`, `GroupPolicy` PowerShell modules
- Used by: `gpno::create_manifest` plan via `run_task('gpno::export', $nodes, ...)`

**Resource Conversion Layer:**
- Purpose: Transform the JSON export result into Puppet `dsc_*` resource block syntax
- Location: `tasks/create_resources_nix.py` (Unix), `tasks/create_resources_win.ps1` (Windows)
- Contains: Task implementations that iterate resources/parameters and print Puppet syntax
- Depends on: `python_task_helper` (Unix path), no external deps on Windows
- Used by: `gpno::create_manifest` plan via `run_task('gpno::create_resources', localhost, ...)`

## Data Flow

### Primary GPO Export Pipeline

1. Operator runs `bolt plan run gpno::create_manifest nodes=<dc> policyname=<name> show_warnings=<bool>` — entry point is `plans/create_manifest.pp`
2. Plan invokes `gpno::export` task on remote Windows DC (`gpno/tasks/export.ps1`)
3. `Backup-Policy` calls `Backup-GPO` to create a GPO backup at `C:\Windows\Temp\<guid>\`
4. `Convert-DSC` calls `ConvertFrom-GPO` then parses the resulting `DSCfromGPO.ps1` file line by line, building a JSON object of `{ resources: [...], warnings: [...] }`
5. JSON returned to Bolt orchestrator from remote task
6. Plan passes JSON data to `gpno::create_resources` task running on `localhost`
7. Conversion task iterates resources, printing `dsc_<type> { '<name>' : dsc_<param> => '<value>', }` blocks to stdout
8. If `show_warnings` is true, conversion task also prints warning messages from the BaselineManagement module

### Prerequisite Setup Flow

1. Apply `include gpno::baseline_management` to Windows DC node via Puppet agent
2. Class installs `Nuget` package provider via `windowspowershell` provider
3. Class installs `BaselineManagement` module from PSGallery

**State Management:**
- No persistent state is maintained by the module; all data flows through Bolt task results in memory
- GPO backup files are written to `C:\Windows\Temp\<guid>\` on the remote DC (not cleaned up by the module)

## Key Abstractions

**Bolt Task with Cross-Platform Implementations:**
- Purpose: The `create_resources` task declares two implementations in its metadata, selected at runtime based on target capabilities
- Examples: `tasks/create_resources.json`, `tasks/create_resources_nix.py`, `tasks/create_resources_win.ps1`
- Pattern: `tasks/<name>.json` metadata selects `<name>_nix.py` (requires `shell`) or `<name>_win.ps1` (requires `powershell`)

**DSC-to-Puppet Resource Mapping:**
- Purpose: Each DSC resource block from the GPO export becomes a `dsc_<type>` Puppet resource
- Pattern: `dsc_{resource.resource} { '{resource.name}' : dsc_{param.key} => '{param.value}', }`

## Entry Points

**Bolt Plan:**
- Location: `plans/create_manifest.pp`
- Triggers: `bolt plan run gpno::create_manifest nodes=<TargetSpec> policyname=<String> show_warnings=<Boolean>`
- Responsibilities: Sequences remote export task and local conversion task, returns manifest data

**Puppet Class:**
- Location: `manifests/baseline_management.pp`
- Triggers: `include gpno::baseline_management` in a node manifest or via `puppet apply`
- Responsibilities: Ensures PowerShell prerequisites are installed on the domain controller

## Architectural Constraints

- **Target OS:** Export tasks require Windows domain controller with `GPRegistryPolicyParser`, `BaselineManagement`, and `GroupPolicy` PowerShell modules
- **Bolt dependency:** The plan workflow requires Puppet Bolt; it cannot be run with the Puppet agent alone
- **Temp file coupling:** Export writes to `C:\Windows\Temp\<guid>\` — hardcoded path, no cleanup
- **Stdout output:** `create_resources` tasks print to stdout rather than writing a file; the caller must capture or redirect output
- **Duplicate task files:** `gpno/tasks/export.ps1` and `tasks/export.ps1` differ (warning capture logic); only `gpno/tasks/export.ps1` has `#Requires` module guards

## Anti-Patterns

### Duplicate export task files

**What happens:** Two versions of `export.ps1` exist at `gpno/tasks/export.ps1` and `tasks/export.ps1` with divergent logic (warning capture present in `tasks/export.ps1`, absent in `gpno/tasks/export.ps1`)
**Why it's wrong:** Creates ambiguity about which is canonical; bugs fixed in one will not be fixed in the other
**Do this instead:** Consolidate to a single implementation under `tasks/` with the `#Requires` guards from `gpno/tasks/export.ps1` and the warning capture from `tasks/export.ps1`

### Hardcoded temp path

**What happens:** `C:\Windows\Temp` is hardcoded in both `export.ps1` files
**Why it's wrong:** Makes the task non-portable and leaves temp files on the DC after each run
**Do this instead:** Accept an optional `OutputPath` parameter with a default, and add cleanup logic in an `end` block

## Error Handling

**Strategy:** Minimal — errors surface as Bolt task failures; no explicit try/catch in task scripts

**Patterns:**
- PowerShell output is redirected to `$null` during DSC conversion (`*>$null`), suppressing errors silently
- Warnings are collected via `-WarningVariable` in `tasks/export.ps1` but not in `gpno/tasks/export.ps1`
- Python task uses `TaskHelper` base class from `python_task_helper`, which provides structured error output

## Cross-Cutting Concerns

**Logging:** No structured logging; warnings optionally printed to stdout if `show_warnings=true`
**Validation:** No input validation beyond Bolt plan parameter types (`TargetSpec`, `String`, `Boolean`)
**Authentication:** Delegated entirely to Bolt transport configuration (WinRM/SSH); no auth logic in module

---

*Architecture analysis: 2026-05-22*
