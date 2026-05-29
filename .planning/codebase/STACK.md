# Technology Stack

**Analysis Date:** 2026-05-22

## Languages

**Primary:**
- Puppet DSL - Module manifests, class definitions, and Bolt plans (`manifests/`, `plans/`)
- PowerShell - Windows task implementation for GPO export and resource generation (`tasks/export.ps1`, `tasks/create_resources_win.ps1`)

**Secondary:**
- Python 3 - Cross-platform (Linux/Unix) task implementation (`tasks/create_resources_nix.py`)
- Ruby - Development tooling, test specs, Rakefile, and Gemfile (`spec/`, `Rakefile`, `Gemfile`)

## Runtime

**Environment:**
- Puppet >= 4.10.0, < 7.0.0 (declared in `metadata.json`)
- Ruby 2.4.x–2.5.x (used in CI pipelines per `appveyor.yml`, `.travis.yml`, `.gitlab-ci.yml`)
- PowerShell (Windows targets) — required by `tasks/export.ps1` and `tasks/create_resources_win.ps1`
- Python (POSIX targets) — required by `tasks/create_resources_nix.py`

**Package Manager:**
- Bundler — manages Ruby gem dependencies (`Gemfile`)
- Lockfile: Not committed (`.travis.yml` removes `Gemfile.lock` before install)

## Frameworks

**Core:**
- Puppet Module — standard module layout with manifests, tasks, plans, and data directories
- Puppet Bolt — orchestration via tasks (`tasks/`) and plans (`plans/`)

**Testing:**
- RSpec (via `puppetlabs_spec_helper`) - unit test runner (`spec/`)
- rspec-puppet — Puppet-specific RSpec matchers
- rspec-puppet-facts — cross-OS fact injection for unit tests
- puppet_litmus — acceptance testing framework (conditionally loaded in `Rakefile`)

**Build/Dev:**
- Rake — task runner for lint, spec, and metadata checks (`Rakefile`)
- PDK 1.14.0 — Puppet Development Kit used for module scaffolding (declared in `metadata.json`)
- RuboCop — Ruby linting with `rubocop-rspec` and `rubocop-i18n` plugins (`.rubocop.yml`)
- puppet-syntax — Puppet manifest syntax checking (loaded in `Rakefile`)
- puppet-strings — documentation generation (conditionally loaded in `Rakefile`)
- puppet-blacksmith — Puppet Forge publishing (conditionally loaded in `Rakefile`)
- github_changelog_generator — automated changelog generation (conditionally loaded in `Rakefile`)

## Key Dependencies

**Critical:**
- `hbuckle-powershellmodule` >= 2.0.1 — Puppet Forge module dependency for managing PowerShell packages; declared in `metadata.json` and installed as a spec fixture via `.fixtures.yml`
- `python_task_helper` — provides `task_helper.py` base class for the Python task (`tasks/create_resources_nix.py` references `python_task_helper/files/task_helper.py`)

**PowerShell Modules (runtime, installed on target nodes):**
- `BaselineManagement` — PSGallery module installed by `gpno::baseline_management` class; converts GPO backups to DSC format (`manifests/baseline_management.pp`)
- `GPRegistryPolicyParser` — imported in `tasks/export.ps1` for policy parsing
- `Nuget` — PSPackageProvider bootstrapped by the `gpno::baseline_management` class

**Infrastructure:**
- `puppetlabs_spec_helper` — spec setup and Rake task integration
- `parallel_tests` — parallel spec execution (referenced as `parallel_spec` Rake task in CI)
- `fast_gettext` — i18n support for Ruby tooling (version-conditional in `Gemfile`)

## Configuration

**Environment:**
- `PUPPET_GEM_VERSION` — selects Puppet gem version during testing (e.g., `~> 5.0`, `~> 6.0`)
- `FACTER_GEM_VERSION` — optionally pins Facter gem version
- `HIERA_GEM_VERSION` — optionally pins Hiera gem version
- `RUBYGEMS_VERSION` — controls RubyGems version in Travis CI
- `GEM_BOLT` — gates Bolt-specific RSpec examples in `spec/spec_helper.rb`
- `GEM_SOURCE` — overrides RubyGems source URL in `Gemfile`
- `CHANGELOG_GITHUB_TOKEN` — required for changelog generation Rake task

**Build:**
- `metadata.json` — module name, version, author, dependencies, OS support, Puppet version requirements
- `hiera.yaml` (version 5) — Hiera data hierarchy using YAML backend; resolves per OS family/release then common (`data/common.yaml`)
- `.fixtures.yml` — declares Puppet Forge module fixtures for unit testing
- `.rubocop.yml` — RuboCop style configuration targeting Ruby 2.1+

## Platform Requirements

**Development:**
- Ruby 2.4+ with Bundler
- Puppet gem (`PUPPET_GEM_VERSION` ~> 5.0 or ~> 6.0)
- PDK 1.14.0 (used for module scaffolding)

**Production:**
- Puppet agent >= 4.10.0 < 7.0.0 on managed nodes
- Windows Server 2019 or Windows 10 nodes for GPO export tasks (require PowerShell and Active Directory/Group Policy access)
- Puppet Bolt for running plans (`plans/create_manifest.pp`)
- `BaselineManagement` PowerShell module on domain controller targets (installed via `gpno::baseline_management` class)

---

*Stack analysis: 2026-05-22*
