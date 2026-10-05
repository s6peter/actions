# org-factory — create 20 HCP Terraform organizations from scratch
No existing org required. Runs from your laptop or GitHub Actions.
Token is NEVER in code — only env `TFE_TOKEN` / Actions secret `TFE_TOKEN`.

## 1. One-time: store your new user token as a GitHub secret
Repo → Settings → Secrets and variables → Actions → New repository secret:
- Name: `TFE_TOKEN`
- Value: your new user API token (Account settings → Tokens)

Generate it at: user icon → Account settings → Tokens → Create an API token.
No org needs to exist first — that page is account-level.

## 2. Local dry run (optional)
```bash
cd org-factory
cp terraform.tfvars.example terraform.tfvars  # edit names/emails
read -r -s -p "User API token: " TFE_TOKEN; export TFE_TOKEN; printf '\n'
terraform init
terraform plan
# terraform apply  # creates the 20 orgs
```
`terraform.tfvars` is gitignored. Keep `terraform.tfstate` — it tracks the orgs.

## 3. Actions (recommended for the 20)
Workflow: `.github/workflows/create-orgs.yml`
- `push` to main touching `org-factory/**` → plan only
- `workflow_dispatch` with `apply=true` → plan + apply
- State uploaded as workflow artifact `org-factory-state`

To run:
1. Push these files to `s6peter/actions`
2. Add secret `TFE_TOKEN` as above
3. Actions tab → "Create 20 HCP orgs" → Run workflow → `apply=true`
4. Download `org-factory-state` artifact after apply and store it safely

## 4. Wiring team leads (membership + owners + alerts)
Orgs with `lead_email` set get, in the same apply:
1. `tfe_organization_membership` — invites the lead by email (the org `email` alone never does this; it is contact/billing mail only, ideally a team DL).
2. `tfe_team_members` on the pre-existing `owners` team — lead can then manage users/teams in their org.
3. An `admin` workspace + `tfe_notification_configuration` (`lead-run-alerts`, email on `run:needs_attention` / `run:errored`) — notification configs attach to workspaces, not orgs, hence the workspace.

Two-pass caveat: the owners wiring needs the lead's HCP username, known once they accept the invite. Existing HCP users resolve immediately; brand-new users stay pending — they accept the email invite, then re-run apply to complete owners + alerts.

Orgs without `lead_email` are org-only (no invites, no workspace).

## 5. After bootstrap
Point future automation at org #1 (e.g. an admin workspace) instead of
re-running this. This factory is one-shot; day-2 org management belongs
in that admin workspace with a remote backend.
