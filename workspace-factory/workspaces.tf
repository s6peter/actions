# 5 workspaces x 20 orgs = 100 tfe_workspace resources, plus one
# tfe_team_access binding per matrix cell (25 per org, "none" skipped).
locals {
  workspace_map = merge([
    for org in var.organization_names : {
      for env in var.environments : "${org}:${env}" => {
        org = org
        env = env
      }
    }
  ]...)

  access_list = flatten([
    for org in var.organization_names : [
      for team, perms in var.access_matrix : [
        for env, level in perms : {
          key   = "${org}:${team}:${env}"
          org   = org
          team  = team
          env   = env
          level = level
        } if level != "none" && contains(var.teams, team) && contains(var.environments, env)
      ]
    ]
  ])

  access_bindings = { for b in local.access_list : b.key => b }
}

resource "tfe_workspace" "this" {
  for_each = local.workspace_map

  organization = each.value.org
  name         = "${each.value.org}-${each.value.env}"
  description  = "${each.value.env} workspace for ${each.value.org}. Managed by workspace-factory."

  terraform_version = var.terraform_version

  # Least privilege: no cross-workspace state reads unless explicitly granted later.
  global_remote_state = false

  tag_names = ["env:${each.value.env}", "managed-by:workspace-factory"]
}

resource "tfe_team_access" "this" {
  for_each = local.access_bindings

  team_id      = tfe_team.this["${each.value.org}:${each.value.team}"].id
  workspace_id = tfe_workspace.this["${each.value.org}:${each.value.env}"].id
  access       = each.value.level
}
