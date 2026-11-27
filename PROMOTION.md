# Promotion record

Each release (`vX.Y.Z`, pinned as `baseRevision`) records what it was promoted from:
a `- Testbed:`, a `- Components:` and an `- Evidence:` line (E2E run links) under its heading. The
Release workflow checks all three lines and publishes them as the release notes.

## Unreleased
- Testbed: dep-dlm-testbed `c4e6ca37584bd470608978f2315e5bcdc72a1be6` (`make sync`)
- Components: dep-dlm-containers v0.1.0, dep-dlm-helm-charts v0.1.0, dep-dlm-usage-reporter v0.4.1
- Evidence: <!-- on-premise E2E run links, added after the manual runs -->

## v0.1.0
- Testbed: dep-dlm-testbed `a5af379b7c47d353e7b1ff30700ad26c7b5105c1` (`make sync`)
- Evidence: [on-premise E2E, ls-aai-dev/managed](https://github.com/RI-SCALE/dep-dlm-deployment/actions/runs/44286400053) · [ls-aai-dev/unmanaged](https://github.com/RI-SCALE/dep-dlm-deployment/actions/runs/44280835550) · [egi-dev/unmanaged](https://github.com/RI-SCALE/dep-dlm-deployment/actions/runs/44261580715)
