# GPNO

**Transform Microsoft Group Policy into Puppet-native resources and Hiera data. No DSC.**

> **⚠ 2.0 is under active development on this branch (`2.x`).**
> The 0.x releases (BaselineManagement/DSC-based) are unsupported and depended on
> Microsoft modules that were archived in 2022. The last 0.x state is preserved at the
> `0.1.1` tag. Do not use 0.x for new work.

## What 2.0 does

GPO backups (and SYSVOL policy folders) are a small set of frozen, documented file
formats. gpno 2.0 parses them directly — `registry.pol` (MS-GPREG), `GptTmpl.inf`
(secedit), `audit.csv`, GP Preferences XML — and emits **Hiera data** consumed by a
generic profile class plus three native types (`security_policy`, `user_rights`,
`audit_policy`), with registry policy handled via `puppetlabs-registry`.

No BaselineManagement. No DSC. No PSGallery dependencies. No PowerShell at runtime.

- **Scope (2.0.0):** Computer Configuration only; user-side settings are reported, not
  enforced. Unmappable settings land in a warnings report — never silently dropped.
- **Classification:** an `ad_ou` fact maps machines to OU-depth Hiera tiers mirroring
  GPO inheritance (enforced links included); security-carrying tiers require an explicit
  opt-in flag or the bundled trusted-external LDAP script.
- **Requirements:** Puppet >= 8.0 < 9.0 (incl. OpenVox 8), Windows Server 2016–2025,
  Windows 10/11.

Full design: [docs/plan-v2.md](docs/plan-v2.md).

## Status

Milestone M1 in progress: IR schema, fixture corpus, lab automation, and the
registry.pol / GptTmpl.inf parsers. See the issue tracker — work items are labeled by
workstream (`ws:*`) and assigned coding agent (`agent:*`).

## Contributing

This project is developed by a mix of human review and coding agents (Claude, Codex,
Gemini) under [AGENTS.md](AGENTS.md) rules: one issue per PR, CI green before review,
tests required, and a human security gate on all enforcement-path code. Human
contributions are welcome under the same rules — pick an unassigned issue or open one
using the agent-task template.

## License

Apache-2.0. Author: Matthew Stone (souldo).
