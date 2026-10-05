# workspace-factory — teams + workspaces + access for the 20 orgs
Runs AFTER org-factory. Same secret-only auth (`TFE_TOKEN`), separate state.

## What it creates (per org, x20)
* **5 teams**: `security`, `dev`, `qa`, `preprod`, `production` (org-scoped, `visibility = organization`)
* **5 workspaces**: `<org>-dev|qa|preprod|prod|security`, pinned Terraform version, `global_remote_state = false`, tagged `env:*`
* **25 access bindings** from `access_matrix` (least privilege: each team writes its own env, reads the rest; security reads all + admins `security`)

~700 resources total via `for_each` — one `plan` shows everything.

## Enterprise notes (built in)
1. **Matrix as data, not code.** Change who-can-do-what by editing `access_matrix` in tfvars; `"none"` skips a binding. No `.tf` edits for policy changes.
2. **Roster is optional.** `team_roster` seeds members (usernames must already be accepted org members — same two-pass rule as leads). Omit it and teams are created empty for leads to fill. `tfe_team_membership` is authoritative per team, so only listed teams are touched.
3. **SSO-ready.** Banks with SSO set `sso_team_ids` (`"<org>:<team>" = "<idp-group>"`) and membership becomes automatic. Without SSO, omit it.
4. **State separation.** This directory has its own local state + CI artifact. Org renames must match `org-factory` outputs — names are the contract between the two factories.
5. **Day-2 suggestion:** move each env workspace to VCS-driven runs (connect the app repo) and add `tfe_policy_set` bindings on `prod` once teams settle.

## Run
```bash
cd workspace-factory
cp terraform.tfvars.example terraform.tfvars  # names must match your 20 orgs
read -r -s -p "User API token: " TFE_TOKEN; export TFE_TOKEN; printf '\n'
terraform init
terraform plan   # expect 700 to add on first run
# terraform apply
```
Actions: workflow `Create workspaces for 20 orgs` — push/PR = plan-only, `workflow_dispatch` + `apply=true` = apply. Real tfvars go in secret `WORKSPACE_TFVARS` (same pattern as `ORG_TFVARS`); falls back to the example file.
