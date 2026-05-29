---
title: Testing
focus: quality
last_mapped: 2026-05-22
---

# Testing

## Framework

- **Unit tests:** RSpec-Puppet via `puppetlabs_spec_helper`
- **Test runner:** Rake (`rake spec` or `rake test`)
- **Fixtures:** `.fixtures.yml` pulls Forge modules for unit test compilation
- **Facts:** `rspec-puppet-facts` + `facterdb` for cross-OS test matrix
- **Linting:** `puppet-lint` (Puppet DSL), `rubocop` (Ruby)

## Test Structure

```
spec/
├── classes/
│   └── baseline_management_spec.rb   # Unit test for gpno::baseline_management
├── default_facts.yml                 # Custom fact overrides
└── spec_helper.rb                    # Global RSpec + Puppet configuration
```

## Running Tests

```bash
# Install gems
bundle install

# Run all tests
bundle exec rake test

# Run only spec (unit) tests
bundle exec rake spec

# Run lint only
bundle exec rake lint

# Run puppet-lint
bundle exec puppet-lint manifests/

# Run rubocop
bundle exec rubocop
```

## Test Coverage

### Classes Tested

| Class | Test File | Coverage |
|-------|-----------|----------|
| `gpno::baseline_management` | `spec/classes/baseline_management_spec.rb` | Compile-only |

### Not Tested

- `gpno::create_manifest` plan — no plan unit tests exist
- `gpno::export` task — no task unit tests exist
- `gpno::create_resources` task — no task unit tests exist
- Cross-platform PowerShell logic in `tasks/export.ps1` — requires Windows acceptance test

## Test Patterns

### Current Pattern: Compile-only
All existing tests only verify that the catalog compiles without errors across the supported OS matrix:

```ruby
it { is_expected.to compile }
```

No resource-level assertions exist (e.g. `contain_package`, `contain_file`).

### Fixture Dependencies
`.fixtures.yml` installs `hbuckle-powershellmodule` (the `pspackageprovider` type dependency) for compilation to succeed during unit tests.

## CI Configuration

### GitLab CI (`.gitlab-ci.yml`)
- Runs test matrix against supported OS list
- Uses Docker-based Puppet test image

### Travis CI (`.travis.yml`)
- Linux-based CI for unit tests
- Bolt tests conditionally gated with `GEM_BOLT=1` env var

### AppVeyor (`appveyor.yml`)
- Windows CI for PowerShell task testing

## Gaps and Limitations

- **No acceptance tests** — no `spec/acceptance/` directory or Beaker/Litmus setup
- **Compile-only assertions** — tests confirm no compilation errors but don't assert resource states
- **No plan tests** — Bolt plans have no automated test coverage
- **No task tests** — PowerShell and Python task scripts have no automated test coverage
- **Spec helper filter:** `c.filter_run_excluding(bolt: true) unless ENV['GEM_BOLT']` — Bolt-specific tests excluded by default
