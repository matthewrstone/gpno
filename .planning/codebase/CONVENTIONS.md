---
title: Code Conventions
focus: quality
last_mapped: 2026-05-22
---

# Code Conventions

## Languages in Use

| Language | Where | Style Guide |
|----------|-------|-------------|
| Puppet DSL | `manifests/`, `plans/` | puppet-lint enforced |
| PowerShell | `tasks/*.ps1` | No linter configured |
| Python | `tasks/*.py` | PEP8 (informal, no linter config) |
| Ruby | `spec/`, `Rakefile`, `Gemfile` | RuboCop enforced |

## Puppet Conventions

### Class Structure
- YARD-style documentation comment block before each class
- `@summary` tag on first line
- `@example` block with usage
- Parameters declared after documentation with `@param` tags (none yet in this module)
- Resource declarations use 4-space indentation

```puppet
# @summary Short description.
#
# Longer description.
#
# @example
#   include gpno::my_class
class gpno::my_class {
  resource { 'title':
    param => value,
  }
}
```

### Plan Structure
- Plans typed with `TargetSpec` for node parameters
- `String` and `Boolean` for scalar parameters
- Tasks called via `run_task('gpno::task_name', $target, param => value)`
- Return values passed through with `return`

### Resource Naming
- Resource titles in single quotes
- Parameter alignment with fat arrows (`=>`)
- `ensure` parameter listed first conventionally

## PowerShell Conventions

- `Param()` block at top of script
- Functions defined with `function` keyword, `param()` block inside
- `begin`/`process`/`end` blocks in functions
- `Write-Output` for task output (not `Write-Host`)
- Return with `return` statement
- `ConvertTo-Json -Depth 4` for serializing output
- Hardcoded paths use `C:\Windows\Temp` as working directory

## Python Conventions

- Uses `python_task_helper` framework (Puppet Bolt task helper library)
- `TaskHelper` base class with `task(self, args)` method
- `sys.path.append` for resolving module path relative to script location
- `print()` used for output (task output goes to stdout)
- `if __name__ == '__main__': TaskHelper().run()` pattern

## Ruby Conventions (RSpec/Tests)

RuboCop enforced with these key settings (from `.rubocop.yml`):
- **Line length:** Max 200 (wide screens allowed)
- **Block delimiters:** `braces_for_chaining` style
- **Class/module children:** Compact style
- **Format strings:** `%` format (e.g. `"value: %s" % var`)
- **Regexp literals:** `%r{}` style
- **Trailing commas:** Required on multiline args/literals
- **Symbol arrays:** `[:a, :b]` not `%i[a b]`
- **Word arrays:** `['a', 'b']` not `%w[a b]`
- Target Ruby version: 2.1

Disabled cops: most `Metrics/*` cops, `RSpec/MultipleExpectations`, `RSpec/NestedGroups`.

### RSpec Test Pattern

```ruby
require 'spec_helper'

describe 'gpno::class_name' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end
end
```

## Error Handling

- **Puppet:** Relies on Puppet's built-in catalog compilation errors; no explicit `fail()` calls in current code
- **PowerShell:** No explicit `try/catch`; warnings captured via `-WarningVariable` and returned in output object
- **Python:** No explicit exception handling; relies on `TaskHelper` base class for error propagation
- **Plans:** No explicit `catch_errors` wrapping; task failures propagate as Bolt plan failures

## Configuration Conventions

- Hiera hierarchy defined in `hiera.yaml` with `data/` as datadir
- No module parameters exposed via Hiera yet (`data/common.yaml` is empty)
- CI matrix covers: CentOS 7, OracleLinux 7, RHEL 8, Scientific 7, Debian 9, Ubuntu 18.04, Windows 2019/10
