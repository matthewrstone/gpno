# External Integrations

**Analysis Date:** 2026-05-22

## APIs & External Services

**PowerShell Gallery (PSGallery):**
- Service: PowerShell Gallery package repository
- Used for: Installing the `BaselineManagement` PowerShell module on domain controllers
- Invocation: `package { 'BaselineManagement': provider => 'windowspowershell', source => 'PSGallery' }` in `manifests/baseline_management.pp`
- Auth: None (public registry)

**Puppet Forge:**
- Service: Puppet module registry (https://forge.puppet.com)
- Used for: Publishing module releases and consuming the `hbuckle-powershellmodule` dependency
- Publishing tool: `puppet-blacksmith` Rake tasks (conditionally loaded in `Rakefile`)
- Auth: Puppet Forge API key (not present in repo; expected as environment secret for deploy stage)
- Dependency fixture: `hbuckle-powershellmodule` installed for tests via `.fixtures.yml`

**GitHub:**
- Service: GitHub source hosting and changelog generation
- Used for: Source repository at `https://github.com/matthewrstone/gpno`; automated changelog via `github_changelog_generator`
- Auth: `CHANGELOG_GITHUB_TOKEN` environment variable (required when running `bundle exec rake changelog`)

## Data Storage

**Databases:**
- Not applicable — this is a Puppet module with no application database.

**File Storage:**
- Local filesystem on target Windows nodes: GPO backup written to `C:\Windows\Temp\{backupId}\` by `tasks/export.ps1` during export; DSC conversion output (`DSCfromGPO.ps1`) written to the same temp path and read back before cleanup.
- Hiera data: YAML files in `data/` directory; loaded by Puppet agent at classification time per `hiera.yaml` hierarchy.

**Caching:**
- None

## Authentication & Identity

**Auth Provider:**
- Active Directory / Group Policy — target Windows nodes must be domain-joined with sufficient permissions for `Backup-GPO` (GroupPolicy PowerShell cmdlet). No auth configuration lives in this module; the operator's Puppet/Bolt credentials govern node access.
- Puppet Bolt transport — handles SSH (POSIX) and WinRM (Windows) connections to target nodes when running plans.

## Monitoring & Observability

**Error Tracking:**
- None

**Logs:**
- Puppet agent logs on managed nodes (standard Puppet logging)
- Task output is returned as structured JSON (from `tasks/export.ps1` via `ConvertTo-Json`) and surfaced through Bolt plan results
- Warnings from `BaselineManagement` module's `ConvertFrom-GPO` are collected into the result object and optionally printed when `show_warnings` is `true` (`tasks/create_resources_win.ps1`, `tasks/create_resources_nix.py`)

## CI/CD & Deployment

**Hosting:**
- Puppet Forge — module published via `puppet-blacksmith` on tagged releases (`DEPLOY_TO_FORGE=yes` stage in `.travis.yml`)
- No application server; this is a Puppet module distributed via Forge.

**CI Pipeline:**
- Travis CI (`.travis.yml`) — primary Linux CI; runs static checks, parallel spec (Puppet 5 + Ruby 2.4, Puppet 6 + Ruby 2.5), and deploys to Puppet Forge on version tags
- AppVeyor (`appveyor.yml`) — Windows CI; runs lint/rubocop and parallel spec across Ruby 2.4/2.5 x86/x64 with Puppet 5 and 6
- GitLab CI (`.gitlab-ci.yml`) — alternative pipeline; runs syntax/lint stage then parallel_spec unit stage using Docker `ruby:2.5.3` and `ruby:2.4.5` images

**Pipeline Stages (Travis):**
1. `static` — `rubocop`, `syntax`, `lint`, `metadata_lint`, symlink/git checks
2. `spec` — `parallel_spec` unit tests
3. `acceptance` — defined but no acceptance jobs configured
4. `deploy` — publish to Puppet Forge when `tag =~ ^v\d`

## Environment Configuration

**Required env vars:**
- `PUPPET_GEM_VERSION` — specifies which Puppet gem version to test against (e.g., `~> 5.0`, `~> 6.0`)
- `CHANGELOG_GITHUB_TOKEN` — GitHub API token for changelog generation
- `DEPLOY_TO_FORGE=yes` — signals Travis deploy stage to publish to Puppet Forge

**Optional env vars:**
- `FACTER_GEM_VERSION` — pins Facter gem
- `HIERA_GEM_VERSION` — pins Hiera gem
- `RUBYGEMS_VERSION` — pins RubyGems version in CI
- `GEM_SOURCE` — alternate RubyGems source mirror
- `GEM_BOLT` — enables Bolt-specific RSpec examples

**Secrets location:**
- Puppet Forge credentials and GitHub tokens are expected as CI-provider secret environment variables; no secrets are stored in the repository.

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- Puppet Bolt plan (`plans/create_manifest.pp`) runs two tasks against remote nodes using Bolt's task runner — this is orchestrated outbound execution, not a webhook. Tasks communicate results back to the Bolt controller via structured JSON over the Bolt transport (WinRM/SSH).

---

*Integration audit: 2026-05-22*
