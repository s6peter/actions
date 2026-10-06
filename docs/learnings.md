# HCP automation learnings — orgs & workspaces from scratch
What this project proved, what broke, and the enterprise pattern that falls out of it.

## 1. You need NO existing org to create orgs
A user API token (Account settings → Tokens, account-level page) can create
organizations via `tfe_organization` from an empty directory with no
`cloud {}` block and no backend. We created 20 orgs this way. An existing org
is only required if you want HCP itself to execute the run.

## 2. Creating is easy — remembering is the real problem
GitHub Actions runners are disposable VMs. `terraform.tfstate` written to a
runner's disk dies with the VM; the uploaded `*-state` artifact is a souvenir
no future run ever reads back. Consequences we hit:
- Re-running apply with a fresh (empty) state plans **N to add** for orgs
  that already exist → HCP rejects them with **"name must be unique"** errors.
- It looks like a naming bug. It is a state bug. Proof: plan says "21 to add"
  when you expected "1 to add".

## 3. Recommendation: one admin org + state workspaces before automating
- Keep (or pick) one admin org — here `BankAZ-landing`.
- Create one CLI-driven, **Local** execution-mode workspace per factory
  (`org-factory`, later `workspace-factory`) to hold its state.
- Point each factory at its workspace via a `cloud {}` block.
- One-time handoff: `terraform init -migrate-state` with the existing state
  file (or fresh `apply` if starting clean), verify `plan` = "No changes".
- From then on every run shares state: incremental adds (`org21`) plan as
  `Plan: 1 to add`. The artifact upload stays as backup only.
- Local execution mode matters: Remote mode would run plans/applies on HCP
  infra and break the local plan-file + manual-apply-gate flow.
- Remote state sharing stays off (share-with-nobody) for factory state.

## 4. Factory design rules learned
- **Validation must allow growth.** `length == 20` blocked adding org21.
  Use `>= 1` and document growth as the normal operation.
- **Org `email` is contact/billing mail only** (ideally a team DL). It invites
  nobody and notifies nobody. Membership = `tfe_organization_membership`
  (sends the invite); user management = `owners` team via `tfe_team_members`;
  run alerts = `tfe_notification_configuration`, which attaches to a
  **workspace**, not an org (hence one `admin` workspace per lead-owned org).
- **Two-pass invite rule.** Owners wiring needs the HCP username, known after
  the invite is accepted. Existing HCP users resolve immediately; brand-new
  users: apply invites → they accept → re-run completes owners/alerts.
- **Permissions as data.** The workspace-factory `access_matrix`
  (team ⇒ env ⇒ read|plan|write|admin|none) lets policy change via tfvars,
  no `.tf` edits. Each team writes only its env, reads the rest; security
  reads all + admins `security`. `"none"` skips a binding.
- **SSO-ready, roster-optional.** `sso_team_ids` maps teams to IdP groups;
  `team_roster` seeds members (usernames must already be org members).
  Omit both and teams are created empty for leads to fill.
- **State separation.** org-factory and workspace-factory keep separate
  states/workspaces. Org names are the contract between them.

## 5. CI patterns that survived contact with reality
- Token NEVER in code: `TFE_TOKEN` repo secret only, passed via `env:`.
- `secrets.*` is **illegal in `if:`** (GitHub rejects the workflow file).
  Read secrets via `env:` and branch in shell. Real tfvars come from an
  optional `*_TFVARS` secret, with the committed `.example` as fallback.
- With a `cloud {}` backend, `terraform init` authenticates too — it needs
  `TFE_TOKEN` in its env, not just plan/apply. See "Why init needs its own
  token" below — `env:` alone was NOT sufficient.
- Push/PR = plan-only; `workflow_dispatch` + `apply=true` = the only apply.
  Speculative plans on PRs give reviewable diffs with zero blast radius.
- `.gitignore` must cover `terraform.tfvars`, `terraform.tfstate*`,
  `.terraform/`, `.terraform.lock.hcl`, `tfplan` — verified with
  `git check-ignore` and `git status`, not by assumption.
- Queued ≠ broken: during the Oct 5 2026 Actions runner incident, jobs sat at
  "Waiting for a runner" and one was cancelled. Check
  https://www.githubstatus.com before "fixing" the workflow.

## 6. Known limits (not automatable)
- **Billing**: plan tier, payment, seats are UI/sales per org. Proven Oct 2026:
  fresh orgs could create workspaces but `tfe_team` failed with "missing
  entitlements to create teams" until an **Essentials** plan was enabled —
  teams for the two billed orgs then created with zero code changes. Upgrade
  per org in Plan & billing, or one enterprise agreement for all.
- **VCS OAuth handshake** for VCS-driven workspaces needs a human click.
- Deleted org names are held invisibly after delete ("already been taken"
  with nothing in the UI). We renamed to `bank-landing-v2-*` instead of
  waiting out the hold.

## 7. Why init needs its own token (two guards, one secret)
Failure seen: `terraform init` with a `cloud {}` backend died with
"Required token could not be found" while the log showed `TFE_TOKEN: ***`
present in the step's environment. Cause: **two different consumers**:
- the **tfe provider** (plan/apply API calls) reads `TFE_TOKEN` env — that
  path always worked, including all of phase 1 with local state;
- the **Terraform CLI** (`init` with a cloud backend) ignores env and only
  reads CLI credentials (`~/.terraformrc`, what `terraform login` writes).
Fix (4 lines, both workflows): `hashicorp/setup-terraform` with
`cli_config_credentials_token: ${{ secrets.TFE_TOKEN }}` writes the CLI
credentials file from the same secret. Rule: `TFE_TOKEN` env feeds the
provider; the `cli_config_credentials_token` input feeds init. Same secret,
no new secrets.

## 8. Open follow-ups in this repo
- Lead wiring (membership + owners + admin workspace + alerts) was built but
  merged past — re-open as its own PR to `main`.
- Consider `tfe_project` per env, org-level `tfe_variable_set`, and
  `tfe_policy_set` on prod (needs Standard/Premium tier — see billing).
