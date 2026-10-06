# hcp.workspace-automate
1. `org-factory/` — bootstrap 20 HCP Terraform organizations from scratch with GitHub Actions. No parent org needed — runs with a user API token stored as Actions secret `TFE_TOKEN`. Start here: `org-factory/README.md`
2. `workspace-factory/` — 5 teams + 5 workspaces + least-privilege access per org (runs AFTER org-factory). Start here: `workspace-factory/README.md`
3. `users-factory/` — invite users + bind to teams in v2-01/v2-03 only (runs AFTER workspace-factory). Start here: `users-factory/README.md`
3. `docs/learnings.md` — what we learned: bootstrap without an org, the state problem, the admin-org pattern, and CI rules.
