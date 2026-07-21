# AGENTS.md — rules for all coding agents (Claude, Codex, Gemini)

You are contributing to **gpno 2.0**: a Puppet module that transforms Microsoft GPOs into
Puppet-native resources and Hiera data, with **no DSC** and no runtime PowerShell-module
dependencies. Read `docs/plan-v2.md` before starting any issue. Your issue brief defines
scope; this file defines standing rules. When they conflict, the issue brief wins only if
it explicitly says so.

## Hard rules (violations will be closed unmerged)

1. **No new runtime dependencies.** Allowed: `puppetlabs-registry`, `puppetlabs-stdlib`,
   Ruby stdlib. Anything else requires schema-owner sign-off *before* you write code
   against it. This includes gems, Forge modules, PSGallery modules, and vendored code.
2. **Absence is tri-state.** Everything that models a setting distinguishes
   *unmanaged / present / explicitly-revoke*. PReg delete directives (`**Del.`,
   `**DelVals.`, `**DeleteValues`, `**DeleteKeys`) are first-class operations, never
   literal value names. An empty parse result must never be interpretable as
   "revoke everything."
3. **Computer Configuration only.** User-scope entries (User\registry.pol, user-side
   Preferences) are presence-detected and routed to the warnings report. Never enforced.
4. **Secrets never reach output.** GPP `cpassword` and likely-credential values are
   detected and refused (redact + warning). Never in fixtures, never in emitted YAML,
   never in test output.
5. **Unmappable settings go to the warnings report.** Never silently dropped.
6. **Identity rules:** principals compared as SIDs (never names), audit subcategories
   keyed by GUID (never localized names), case preserved everywhere (no `.downcase`
   on names, values, or data — the 0.x module died of this).
7. **Precedence:** Hiera data uses deep merge with whole-value overwrite. Array union
   on privilege lists is forbidden (it is silent privilege escalation). Follow
   `docs/precedence-contract.md` once it exists.
8. **Schema is a contract.** `schemas/gpno-ir.schema.json` changes go through a PR to the
   schema itself — never a workaround in your code. Changes touching absence/removal,
   scope, or principal semantics additionally require the human security gate.
9. **Security gate:** provider code for `security_policy`, `user_rights`, `audit_policy`,
   and anything generating security-tier hieradata, requires human (maintainer) sign-off.
   Model review does not substitute.

## Workflow

- One issue = one branch (`issue-<n>-<slug>`) = one PR. Reference the issue number.
- CI must be green before requesting human review. Do not ask the maintainer to look at
  red CI.
- Every PR includes tests: Linux-runnable for parsers/emitters (fixtures in
  `spec/fixtures/gpo_backups/`), mocked-command unit tests for providers.
- Do not modify fixtures or expected-IR files to make your code pass. If you believe a
  fixture is wrong, open an issue and stop.
- Do not touch files outside your issue's stated scope. Drive-by refactors will be
  rejected regardless of quality.
- Cross-vendor review: your PR will be reviewed by a different vendor's model. Respond to
  review comments in the PR, not by force-pushing silent rewrites.

## Project context

- Formats parsed (all frozen/stable): registry.pol (MS-GPREG binary PReg), GptTmpl.inf
  (secedit INF dialect, UTF-16LE, `7,`-encoded multi-line values), audit.csv
  (GUID-keyed), GP Preferences XML, Backup.xml / GPT.INI metadata.
- Enforcement: native Ruby types/providers over `secedit`, `auditpol`, and the registry
  (via puppetlabs-registry). Prefetch/flush: one export per agent run, batched writes.
- Classification: `ad_ou` fact → OU-depth Hiera tiers; security-carrying tiers require
  the explicit opt-in flag or the trusted-external LDAP path.
- Platform: Puppet >= 8.0 < 9.0 (incl. OpenVox 8), Windows Server 2016–2025, Win 10/11.
