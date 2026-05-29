---
title: Concerns & Technical Debt
focus: concerns
last_mapped: 2026-05-22
---

# Concerns & Technical Debt

## High Severity

### Hardcoded Paths in export.ps1
**File:** `tasks/export.ps1`
**Issue:** `C:\Windows\Temp` is hardcoded as the working directory for GPO backup and DSC conversion. If the target system restricts write access to `C:\Windows\Temp` or uses a different temp path, the task silently fails.
**Risk:** Task failures in hardened environments.
**Fix:** Accept `$TempPath` as an optional parameter with `C:\Windows\Temp` as default.

### Fragile DSC Output Parsing (export.ps1)
**File:** `tasks/export.ps1` lines 29–45
**Issue:** DSC script output is parsed by matching indentation patterns (e.g. `"^         [A-Z]"` for 9-space indent). This regex is tightly coupled to the exact output format of `ConvertFrom-GPO`. Any change in the BaselineManagement module's output format silently produces empty/wrong results.
**Risk:** Silent data loss — task returns empty resources without error if format changes.
**Fix:** Parse structured output (e.g. JSON or object) from `ConvertFrom-GPO` instead of screen-scraping text.

### No Error Handling in Plans
**File:** `plans/create_manifest.pp`
**Issue:** No `catch_errors` or result checking around `run_task` calls. If `gpno::export` fails on a node, the plan continues to `gpno::create_resources` with bad data.
**Risk:** Silent failures or misleading output when running against multiple nodes.

## Medium Severity

### Nested `gpno/tasks/` Directory
**File:** `gpno/tasks/export.ps1`
**Issue:** A `gpno/` subdirectory exists at the repo root containing a duplicate `tasks/export.ps1`. This appears to be a Git merge artifact or accidental nesting. Having two copies creates confusion about which is canonical.
**Risk:** Developers may edit the wrong file.
**Fix:** Remove `gpno/` subdirectory if it's a leftover artifact.

### Python Task Lacks Error Handling
**File:** `tasks/create_resources_nix.py`
**Issue:** No exception handling around `args['data'][0]['result']` dict access. If the upstream task returns unexpected structure (e.g. empty array, missing keys), this raises an unhandled `KeyError`/`IndexError`.
**Risk:** Unhelpful error messages for operators debugging task failures.

### Outdated PDK Version
**File:** `metadata.json`
**Issue:** PDK version `1.14.0` (released ~2020). Current PDK is 3.x. Older PDK templates may not follow current Puppet best practices.
**Risk:** Missing security patches, outdated test helpers, deprecated patterns.

### Outdated CI Matrix
**Files:** `.travis.yml`, `.gitlab-ci.yml`
**Issue:** CI matrix covers Ubuntu 18.04 (EOL), Debian 9 (EOL), CentOS 7 (EOL June 2024). No Windows testing in GitLab/Travis for PowerShell tasks.
**Risk:** Module may not work on current OS versions; outdated test targets provide false confidence.

### Puppet Version Ceiling
**File:** `metadata.json`
**Issue:** `version_requirement: ">= 4.10.0 < 7.0.0"` — excludes Puppet 7 and 8.
**Risk:** Users on current Puppet versions see dependency resolution failures on Puppet Forge.

## Low Severity

### No Parameter Validation
**Files:** `manifests/baseline_management.pp`, `plans/create_manifest.pp`
**Issue:** The class has no configurable parameters. The plan parameters are typed but not validated (e.g. `$policyname` could be empty string).
**Risk:** Silent failures or confusing behavior with bad inputs.

### Empty Hiera Data
**File:** `data/common.yaml`
**Issue:** `common.yaml` contains only `---` (empty). The Hiera hierarchy is configured but unused.
**Risk:** Low — just dead config, but signals the module was scaffolded but not fully built out.

### No Acceptance Tests
**Issue:** No `spec/acceptance/` directory, no Beaker/Litmus setup. Functionality is untested end-to-end.
**Risk:** Regressions in GPO export/conversion logic won't be caught by CI.

### Missing `gpno::export` Task Metadata
**Issue:** `tasks/export.ps1` has no corresponding `.json` metadata file defining parameters (`$PolicyName`). The task relies on the caller passing the right parameter name.
**Risk:** Bolt task parameter documentation missing from `bolt task show gpno::export`.

## Security Notes

- `tasks/export.ps1` imports `GPRegistryPolicyParser` and `BaselineManagement` PowerShell modules — these are third-party modules running with the permissions of the Puppet agent/Bolt runner on domain controllers
- No input sanitization on `$PolicyName` before it's passed to `Backup-GPO` — a malformed policy name could cause unexpected behavior
- GPO backup written to `C:\Windows\Temp` — temp files are not cleaned up after task completion
