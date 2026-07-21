# GPNO Modernization: Project Plan v2.1

**Module:** `souldo-gpno` → 2.0.0 · https://github.com/matthewrstone/gpno
**Plan date:** 2026-07-21 (v2.1 — v2 + Proxmox lab target + same-repo release strategy)
**Provenance:** v1 assessment + council review (4-seat adversarial review, `gpno-council-report.md`) + maintainer rulings: **Puppet ≥ 8.0 < 9.0 only** (X3) · **opt-in flag for client-fact security binding** (X1) · **Antigravity dropped; platforms are Claude, Codex, Gemini** (X2) · **lab on Proxmox** · **2.0 developed in the existing repo, 0.x preserved by tag**.

---

## Part 1 — Assessment (summary; full detail in v1)

gpno 0.1.1 is an export toolchain built on Microsoft's BaselineManagement (archived Oct 2022), regex-scraping generated DSC script text, emitting `dsc_*` declarations for a dead consumer, metadata pinned to Puppet < 7. Not patchable; rebuild. The idea (GPO → Puppet) remains sound and underserved.

## Part 2 — Target architecture (amended)

Core: parse the stable GPO backup/SYSVOL file formats directly in pure Ruby, emit **Hiera data, not code**, enforce with native Ruby types/providers over OS-native tools (`secedit`, `auditpol`, registry API). No DSC, no PSGallery, no runtime PowerShell-module dependencies.

Council amendments baked in:

1. **Computer Configuration only for 2.0.0** [R3]. IR carries a Machine/User scope field; user-side entries are presence-detected and routed to the warnings report, never enforced. Declared in schema, README, coverage matrix.
2. **Absence is first-class** [R1]. PReg delete directives (`**Del.`, `**DelVals.`, `**DeleteValues`, `**DeleteKeys`) parse to explicit operations; the pipeline carries tri-state *unmanaged / present / explicitly-revoke*. Stale-value drift on re-export documented as unsupported in 2.0 (diff-generated knockouts ship with `gpno::diff` in 2.1).
3. **Secrets never reach YAML** [R5]. Translator detects GPP `cpassword` and likely-credential values, refuses plaintext emission (redact + loud warning); hiera-eyaml documented; fixtures scrubbed.
4. **Precedence & merge is a contract — primitive P6** [R6]. Deep merge with whole-value overwrite (never array union — privilege-list union is silent escalation); generated `lookup_options` with knockout convention; same-OU link order pre-resolved by the translator; **enforced-link GPOs get a dedicated hierarchy layer above all OU tiers**; security-filtered/WMI-filtered GPOs produce warnings.
5. **Providers locale-proof and batched** [R4]. Audit subcategories keyed on GUIDs (`auditpol /get /r`), principals compared as SIDs, UTF-16LE INF with `7,`-encoded values handled; one `secedit /export` + one `auditpol` read per run via `self.instances`/`prefetch`. Shared, fixtured SID/GUID resolution component. User-rights mechanism: secedit or LSA `LsaAddAccountRights` FFI, decided in the P4 design note.
6. **Fail-closed classification** [R10]. Unresolved classification → refuse to compile / no-op with alert. Never auto-apply any tier, including the strictest.
7. **Provenance & input validation** [R10]. Emitted YAML carries translator provenance stamp; SYSVOL-direct reads validated against GPT.INI/AD metadata. Repo controls (protected branches, CODEOWNERS, signed commits) are documented deployment hardening, not module code.
8. **Overlap canonicalization**: GptTmpl.inf `[Registry Values]` deduped against registry.pol entries in the IR.
9. **Account policy scoped consciously**: domain-account password/lockout is domain-governed on members (translator warns); local SAM accounts remain locally governed — supported with documented local-only semantics.

### Classification (ruling X1)

- `ad_ou` structured fact (local ADSI read of own DN, non-domain fallback) drives OU-depth Hiera tiers. Every DN/OU segment charset-allowlisted and separator-rejected before Hiera interpolation [R7].
- **Opt-in gate:** security-carrying tiers (`user_rights`/`security_policy`/`audit_policy` data) do not bind to the client-side fact unless `gpno::allow_fact_based_security_tiers: true` is set. The **trusted-external LDAP script ships in 2.0** as the recommended production path: read-only least-privilege bind, no plaintext credentials, rotation guidance, defined AD-unreachable failure mode.
- Full ENC: cut entirely.

### Packaging (rulings X3 + repo strategy)

- Existing repo `matthewrstone/gpno`: tag current head as `0.1.1-final` (0.x preserved), develop 2.0 on branch `2.x`, make it default when WS0 merges. Forge namespace `souldo-gpno`, 2.0.0 as a clean major release; 0.x marked unsupported.
- **`puppet >= 8.0 < 9.0`** (Puppet 8 / OpenVox 8; verify OpenVox bounds at WS0).
- Windows Server 2016/2019/2022/2025, Windows 10/11.
- Runtime deps: `puppetlabs-registry`, `puppetlabs-stdlib` only; anything else needs schema-owner sign-off. (Preferences→scheduled_task contradiction resolved by MVP cut: ScheduledTasks/Groups → warnings report.)

## Part 3 — Primitives (six)

- **P1. IR schema** (`gpno-ir.schema.json`): scope field, tri-state absence, delete-directive operations, principals-by-SID, provenance stamp, DN-segment constraints. Co-developed with the two hard parsers during M1 [R9]; v1 tags when both green; then 48-hour minor-rev process, security-semantics revisions also pass the R7 gate.
- **P2. Fixture corpus**: sanitized `Backup-GPO` output + expected-IR JSON. Must include Disabled-policy (delete-directive), explicit-revoke, UTF-16LE, `7,`-encoded, dummy-`cpassword` (refusal test), multi-string/binary, non-ASCII, empty GPO. Oracle-validated: gpreport.xml spot-check primary; LGPO.exe `/parse` secondary (registry.pol only); method recorded per fixture. Capture is maintainer-owned, script-driven on the P2a lab.
- **P3. Parser library**: registry.pol (incl. delete directives), GptTmpl.inf, audit.csv, preferences XML (presence + Registry items), backup metadata with two paths (Backup.xml; GPT.INI+LDAP for SYSVOL-direct).
- **P4. Provider base**: prefetch/flush, GUID/SID keying, UTF-16LE read-back, `insync?` normalization rules, shared SID/GUID resolution with fixtures (orphaned/well-known/localized).
- **P5. `ad_ou` fact + Hiera layout**: sanitization + X1 opt-in gate.
- **P6. Precedence & merge contract**: design note per Part 2 item 4; contract-grade; precedes WS4 code.

## Part 4 — MVP, workstreams, assignments

### 2.0.0 MVP [R2]

**In:** registry.pol + GptTmpl.inf + audit.csv + metadata parsers; Preferences Registry-item mapping; Hiera emitter with `lookup_options`/knockout; warnings report; `security_policy`/`user_rights`/`audit_policy` types+providers; `ad_ou` fact + sanitization + opt-in gate; trusted-external LDAP script; `gpno::export` / `gpno::export_all` (conflict flagging, no dedup); provenance stamps; secrets refusal.

**Post-2.0:** `gpno::diff` + re-export knockouts; `.pp` emitter; Preferences beyond Registry (Groups.xml stays export-and-warn); `export_all` dedup; local registry.pol (LGPO-style) tattoo-free mode.

### Platforms (ruling X2)

**Claude** (GitHub App / Claude Code), **Codex** (Codex cloud + codex-action), **Gemini** (run-gemini-cli Action and/or Jules) — all dispatched via GitHub labels/mentions. Cross-vendor PR review standing policy; Matt is sole merge authority; R7 human security gate on enforcement-path code.

### Workstreams

| WS | Scope | Assigned | Notes |
|---|---|---|---|
| WS0 | PDK 3.x re-scaffold, metadata (≥8 <9), legacy cleanup, GHA CI + dispatch workflows, AGENTS.md/CLAUDE.md, issue template + labels | Claude (with Matt) | In progress in-session |
| WS1 | P1 schema (co-dev) + P2 expected-IR | Claude Opus-class; Matt reviews | Oracle validation breaks circularity |
| WS1a | **Proxmox lab, Packer+Terraform only**: Packer `proxmox-iso` templates from ISO (Autounattend + VirtIO + cloudbase-init baked in — Windows' cloud-image equivalent) → Terraform `bpg/proxmox` declares the lab (clones, per-VM cloudbase-init config, snapshots as resources): 1× Server 2022 DC (`gpno.test`), 1× member, 1× Win11 client; in-guest PowerShell only as provisioners (DC promote, OU tree, headless GPO authoring, `Backup-GPO` export) | Claude authors, **Matt owns/runs** | True critical path; starts immediately |
| WS2 | Three security types/providers + P4 base | Claude Opus-class | + R7 human sign-off; revoke/absent fixtures required before "done" |
| WS3 | registry.pol → **Claude**; GptTmpl.inf → **Claude**; audit.csv/preferences/metadata → **Codex**; Hiera emitter → **Codex + human-reviewed absence/injection tests**; warnings report → **Claude** | mixed | |
| WS4 | P6 contract + precedence resolver → **Claude**; LDAP/GPMC link-walker plumbing → **Codex**; trusted-external script → **Claude, security-reviewed, in 2.0** | mixed | C8 tests: enforced inversion, block inheritance |
| WS5 | Bolt plans, SYSVOL-direct mode, CLI UX | Codex + Claude review gate | |
| WS6 | Acceptance: mechanical round-trip (apply → OS re-export → re-parse → IR diff empty, projected onto IR-managed keys); coexistence rehearsal (enforce-while-linked → unlink → verify CSE-cleanup corrected); adversarial cases (spoofed fact, forged DN, missing tier, stopped agent, revoke) | **Claude authors harness; Gemini executes** on the Proxmox lab runner | All scripted; snapshots enable per-cycle resets |
| WS7 | Docs: README, REFERENCE.md, migration guide, coverage matrix, deployment-hardening guide | Claude (single assignee) | |

### Milestones

| M | Contents | Exit criteria |
|---|---|---|
| M1 | WS0 + WS1a + WS1 + two hard parsers | Proxmox lab reproducible from clean node; schema v1 tagged after registry.pol + GptTmpl.inf green vs oracle-validated fixtures on Linux CI; secrets-refusal fixture in place; P6 contract signed off |
| M2 | WS2 + rest of WS3 | All fixtures → expected IR; providers pass unit tests **and** real-Windows GHA `windows-latest` round-trips (non-domain scope) [B7]; first Gemini lab cycle executed |
| M3 | WS4 + WS5 | `export_all` → working Hiera tree from lab domain incl. enforced layer + link-order pre-resolution; `ad_ou` + sanitization + opt-in gate working; C8 tests green |
| M4 | WS6 | Round-trip green on 2019/2022/2025 + Win10/11; coexistence + adversarial cases pass; idempotent second runs |
| M5 | WS7 + release | Forge 2.0.0; 0.x deprecation notice; honest coverage matrix |

### Cross-cutting rules

Linux CI for parsers/emitters; mocked-Windows + M2 real-Windows job for providers; domain semantics only in WS6. No new runtime deps without schema-owner sign-off. Unmappable → warnings report, never dropped. Case preservation; principals by SID; subcategories by GUID. R7 human security sign-off on WS2 code + security hieradata. One issue = one branch = one PR; CI green before human review; ≤6 concurrent open agent PRs.

## Part 5 — Risk register

1. GPP breadth: Registry items only; Groups export-and-warn. 2. Tattooing: continuous enforcement documented; LGPO-style mode parked 2.1+. 3. Fact spoofing: X1 opt-in + trusted-external; residual documented. 4. DC-targeted GPOs: export-only. 5. Scale: conflict flagging; dedup deferred. 6. Migration coexistence: WS6 rehearsal. 7. Solo review bandwidth: MVP cut + PR cap + two-parser M1.

## Appendix — decisions log

X1 opt-in flag (trusted-external ships in 2.0, recommended for production security tiers). X2 Antigravity dropped → Claude/Codex/Gemini. X3 Puppet ≥8 <9 only. Lab: Proxmox. Repo: existing `matthewrstone/gpno`, 0.x tagged, 2.0 on `2.x` branch. Killed in council: "most restrictive tier" fail-safe (→ refuse-to-compile), NtRights, Puppet 7, full ENC, `.pp` emitter (deferred), schema-freeze-before-contact (→ co-dev).
