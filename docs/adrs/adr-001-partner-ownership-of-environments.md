---
status: proposed
date: 2026-11-26
decision-makers: DEP DLM (WP2)
consulted: RI and e-infrastructure partners (WP2)
informed: WP2
---

# ADR-001: Let partners own their environments without forking the deployment

## Context and Problem Statement

dep-dlm-deployment ships one umbrella chart, promoted from validated testbed
commits and released as tags (see `PROMOTION.md`). Each RI runs its own
instance, with its own cluster, secrets store and upgrade pace, configured
by `environments/<ri>/<stage>/` (`env.yaml`, `values.yaml`).

So far DEP DLM has written every environment. Before RIs or e-infrastructures
adopt the deployment, we need to decide where their configuration lives and
who can change it, without each partner carrying its own copy of the charts.

How do partners own their environment while all of them stay on the same
released charts?

## Decision Drivers

* One chart, one promotion and release process for everyone; fixes reach all
  sites by bumping a tag.
* Partners change their own values and choose their own upgrade timing.
* No partner can change another partner's environment.
* Secrets stay in each partner's own store, never in git.
* Low effort for a first pilot; no change to the release process.

## Considered Options

1. Fork per partner
2. Directories in this repo, owned through CODEOWNERS
3. Partner-owned values repo, pinned to a release tag
4. Options 2 and 3, partner's choice

## Decision Outcome

Proposed option: **4, starting with 2 for the pilot**, because a directory
in this repo needs nothing new (environments already pin `baseRevision` to
a tag), while a separate values repo stays open to partners that need full
control over who can change their configuration. Forks are excluded: they
drift, and every fix has to be merged into each one.

Site-specific needs go into values. Anything that isn't configurable yet is
a change to the shared chart, released like any other.

### Positive Consequences

* One chart and one release process; partners upgrade by bumping a tag.
* The pilot needs only a directory and a CODEOWNERS entry.
* Partners can move to their own repo later without changing the chart.

### Negative Consequences

* Two supported layouts; the separate-repo variant needs a multi-source
  Argo CD application (chart from here, values from the partner).
* Option 2 depends on branch protection and CODEOWNERS being enforced, and
  partners need access to this repo.

## Confirmation

* A pilot partner's environment syncs from its directory, pinned to a
  release tag, and the testbed's end-to-end suite passes against it.
* Branch protection requires the owning partner's review for changes under
  `environments/<ri>/`.
* If a partner chooses option 3, the same suite passes with its values repo.

## Pros and Cons of the Options

### 1. Fork per partner

* Good: full autonomy, no access to a shared repo.
* Bad: charts drift; every fix and promotion is merged per fork; no single
  tested release.

### 2. Directories in this repo, owned through CODEOWNERS

* Good: works today; one place to see every environment; shared review.
* Bad: partners need write access to a shared repo; ownership relies on
  CODEOWNERS.

### 3. Partner-owned values repo, pinned to a release tag

* Good: partners control access and history of their own configuration.
* Bad: needs multi-source applications and a documented values contract;
  environments are spread over several repos.

### 4. Options 2 and 3, partner's choice

* Good: low-effort start, autonomy where it's needed.
* Bad: two layouts to document and test.

## Evidence / Links

* `PROMOTION.md`, README ("Promoting a testbed commit", "Adding an environment")
* [docs/single-node.md](../single-node.md)
* [Argo CD multiple sources](https://argo-cd.readthedocs.io/en/stable/user-guide/multiple_sources/)
* [GitHub CODEOWNERS](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
