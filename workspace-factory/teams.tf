# 5 teams x 20 orgs = 100 tfe_team resources.
# Teams are org-scoped; short slugs stay unique inside their org.
locals {
  team_map = merge([
    for org in var.organization_names : {
      for team in var.teams : "${org}:${team}" => {
        org  = org
        team = team
      }
    }
  ]...)
}

resource "tfe_team" "this" {
  for_each = local.team_map

  name         = each.value.team
  organization = each.value.org
  visibility   = "organization"

  # Banks on SSO: map the team to its IdP group so membership is automatic.
  # Omit sso_team_ids entirely without SSO — teams are then managed manually/API.
  sso_team_id = lookup(var.sso_team_ids, each.key, null)
}

# Authoritative member lists — only for teams present in team_roster.
# Everyone else stays empty for leads to fill via UI/API.
resource "tfe_team_members" "roster" {
  for_each = {
    for m in flatten([
      for org, teams in var.team_roster : [
        for team, usernames in teams : {
          key       = "${org}:${team}"
          team_id   = tfe_team.this["${org}:${team}"].id
          usernames = usernames
        }
      ]
    ]) : m.key => m
  }

  team_id   = each.value.team_id
  usernames = each.value.usernames
}
