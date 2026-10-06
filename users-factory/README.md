# users-factory — invite users, bind them to teams (v2-01, v2-03 only)
Same secret-only auth (`TFE_TOKEN`), own state workspace (`users-factory`
in `BankAZ-landing`, CLI-driven, Local). Runs AFTER workspace-factory.

## Hard limit: HCP cannot create user accounts
No API creates logins — accounts come from user signup or SSO/SCIM
(auto-provisioned on first login in SSO orgs). This factory does the two
things the API allows per roster entry:
1. `tfe_organization_membership` — invites by **email** (invite mail sent).
2. `tfe_team_members` — binds by **username** to the team (usernames exist
   after signup/accept — the familiar two-pass rule: apply invites, they
   join, re-run binds).

## Scope guard
`managed_scope` defaults to exactly the billed orgs and their teams:
v2-01 (security/qa/dev), v2-03 (qa/dev/production). Roster entries outside
it fail validation — unbilled orgs have no teams, so lookups there would
fail anyway. Widen the scope only after enabling billing there.

## Run
```bash
cd users-factory
cp terraform.tfvars.example terraform.tfvars  # fill roster, keep it gitignored
read -r -s -p "User API token: " TFE_TOKEN; export TFE_TOKEN; printf '\n'
terraform init
terraform plan   # invites + bindings only; no users/orgs/teams created
# terraform apply
```
Actions: workflow `Invite users and bind teams` — push/PR = plan-only,
`workflow_dispatch` + `apply=true` = apply. Real roster goes in secret
`USERS_TFVARS` (same pattern as `ORG_TFVARS`); falls back to the example
(empty roster = plan shows nothing to do).
