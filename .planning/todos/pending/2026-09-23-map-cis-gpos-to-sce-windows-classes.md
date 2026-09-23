---
created: 2026-09-23T13:26:53.941Z
title: Map CIS GPOs to sce_windows classes
area: general
severity: minor
files: []
---

## Problem

gpno currently parses GPOs into its own IR/Hiera output (registry.pol, GptTmpl.inf,
audit.csv, Preferences XML, etc. — see AGENTS.md "Project context"). Many organizations
importing CIS-benchmark GPOs already have the `puppetlabs/sce_windows` module (or an
equivalent Security Content Engine module implementing CIS/DISA benchmarks as Puppet
classes/params) available in their control repo. For those users, re-emitting raw
security-tier Hiera when a matching `sce_windows` class parameter already exists is
duplicate work and fights the "one canonical source of truth" goal — it would be more
useful to detect that a parsed GPO setting corresponds to a known CIS control already
modeled by `sce_windows`, and map to/declare that class's parameter instead of (or in
addition to) emitting raw provider resources.

Open questions to resolve before scoping this as a real issue:
- Detection: how do we know at parse/compile time whether the target node's module path
  has `sce_windows` available and enabled? (Likely a Puppet fact or a Hiera/environment
  check, not a hard dependency — see AGENTS.md hard rule #1, "No new runtime
  dependencies," which would require schema-owner sign-off for anything beyond an
  *optional*, presence-detected integration.)
- Mapping table: CIS benchmark IDs are versioned per Windows release and per CIS
  benchmark version; `sce_windows` exposes its own class/param names that may not track
  CIS IDs 1:1. Need a maintained mapping (GPO registry/secedit/audit setting → CIS
  control ID → `sce_windows` class param), likely sourced from CIS benchmark GPO backups
  themselves plus `sce_windows`'s own hiera data/metadata.
- Precedence/conflict: if both raw gpno output and an `sce_windows` mapping exist for the
  same setting, which wins? Follow the precedence-contract doc once it exists (see
  AGENTS.md hard rule #7).
- This almost certainly touches security-tier hieradata generation, which requires the
  human security gate (AGENTS.md hard rule #9) — plan for maintainer sign-off before any
  implementation PR.

## Solution

TBD — likely needs its own SPEC/PLAN phase (via gsd-spec-phase / gsd-plan-phase) rather
than being tackled inline, given the open questions above around optional-dependency
detection, CIS-ID-to-class-param mapping data, and the security gate. A reasonable first
step is a small research spike: confirm `sce_windows`'s actual class/param naming
convention and whether it ships a CIS-ID-indexed data file gpno could consume/generate a
mapping table from.
