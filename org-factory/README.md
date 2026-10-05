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

## 4. One-time state migration (do this once, locally)
The workspace `org-factory` in org `BankAZ-landing` must be CLI-driven with
execution mode **Local** (Settings → General → Execution mode). Then:
```bash
cd org-factory
# 1. download the terraform.tfstate artifact from your successful apply run
#    and place it here as ./terraform.tfstate (same dir as main.tf)
# 2. point the config at the workspace (already in versions.tf: cloud{} block)
read -r -s -p "User API token: " TFE_TOKEN; export TFE_TOKEN; printf '\n'
terraform init -migrate-state   # answer yes: local state -> HCP workspace
terraform plan                  # expect "No changes" (proves state attached)
rm -f terraform.tfstate terraform.tfstate.backup  # local copy no longer needed
```
From now on every Actions run shares that state: adding `org21` to tfvars
plans as `Plan: 1 to add`. The state artifact upload stays as a backup only.

## 5. After bootstrap
Point future automation at org #1 (e.g. an admin workspace) instead of
re-running this. This factory is one-shot; day-2 org management belongs
in that admin workspace with a remote backend.
