output "team_count" {
  description = "Teams created (5 per org)."
  value       = length(tfe_team.this)
}

output "workspace_count" {
  description = "Workspaces created (5 per org)."
  value       = length(tfe_workspace.this)
}

output "access_binding_count" {
  description = "Team-access bindings from the matrix (25 per org by default)."
  value       = length(tfe_team_access.this)
}

output "workspaces_by_org" {
  description = "Workspace names per org."
  value = {
    for org in var.organization_names :
    org => [for env in var.environments : "${org}-${env}"]
  }
}
