output "invited_count" {
  description = "Org memberships (invites) managed."
  value       = length(tfe_organization_membership.user)
}

output "teams_wired" {
  description = "Teams with managed member lists (org:team)."
  value       = keys(tfe_team_members.team)
}
