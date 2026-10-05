# One resource, 20 instances via for_each.
# Org names must be globally unique, lowercase, letters/numbers/dashes.
resource "tfe_organization" "this" {
  for_each = var.organizations

  name  = each.value.name
  email = each.value.email
}

locals {
  # Only orgs with a lead_email get membership + owners + alerts.
  orgs_with_lead = {
    for k, o in var.organizations : k => o
    if o.lead_email != null
  }
}

# Invite the team lead by email. NOTE: the org `email` above does NOT do
# this — it is contact/billing mail only. This resource sends the invite.
resource "tfe_organization_membership" "lead" {
  for_each = local.orgs_with_lead

  organization = tfe_organization.this[each.key].name
  email        = each.value.lead_email
}

# Pre-existing `owners` system team — members can manage users/teams.
data "tfe_team" "owners" {
  for_each = local.orgs_with_lead

  organization = tfe_organization.this[each.key].name
  name         = "owners"
}

# Make the lead an owner so they can manage users in their org.
# Requires the lead's HCP username, which is known once the invite is
# accepted (immediate for existing HCP users). For brand-new users:
# apply invites them, they accept, re-run to complete owners wiring.
resource "tfe_team_members" "lead_owner" {
  for_each = local.orgs_with_lead

  team_id   = data.tfe_team.owners[each.key].id
  usernames = [tfe_organization_membership.lead[each.key].username]
}

# One admin workspace per lead-owned org — notification configs attach
# to workspaces, not orgs, so this gives the lead somewhere to be notified from.
resource "tfe_workspace" "admin" {
  for_each = local.orgs_with_lead

  organization = tfe_organization.this[each.key].name
  name         = "admin"
  description  = "Platform admin workspace for ${each.value.name}. Managed by org-factory."
}

# Email the lead on runs needing attention or erroring in their admin workspace.
resource "tfe_notification_configuration" "lead_email" {
  for_each = local.orgs_with_lead

  name             = "lead-run-alerts"
  enabled          = true
  destination_type = "email"
  email_addresses  = [each.value.lead_email]
  triggers         = ["run:needs_attention", "run:errored"]
  workspace_id     = tfe_workspace.admin[each.key].id
}

output "organization_names" {
  description = "Created org names."
  value       = { for k, o in tfe_organization.this : k => o.name }
}

output "orgs_with_lead" {
  description = "Orgs where a lead was invited, made owner, and subscribed to run alerts."
  value       = { for k, o in local.orgs_with_lead : k => o.name }
}
