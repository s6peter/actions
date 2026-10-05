# hcp.workspace-automate
1. `org-factory/` — bootstrap 20 HCP Terraform organizations from scratch with GitHub Actions. No parent org needed — runs with a user API token stored as Actions secret `TFE_TOKEN`. Start here: `org-factory/README.md`
2. `workspace-factory/` — 5 teams + 5 workspaces + least-privilege access per org (runs AFTER org-factory). Start here: `workspace-factory/README.md`
