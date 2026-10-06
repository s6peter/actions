# Invite by email, bind by username. Scoped to managed orgs/teams only —
# unbilled orgs have no teams, so any lookup there would fail by design.
#
# KEY DESIGN: memberships are keyed by ORG+EMAIL (one per human per org),
# never by username. Usernames get corrected as people are identified, and a
# username change must only touch team bindings — never destroy/recreate the
# membership. Keying by username caused destroy/create churn on every
# correction, and team binds fired mid-churn hit "already a member" / 400s.
locals {
  roster_flat = flatten([
    for org, teams in var.roster : [
      for team, members in teams : [
        for m in members : {
          org      = org
          team     = team
          email    = m.email
          username = m.username
        }
      ]
    ]
  ])

  person_keys = distinct([for m in local.roster_flat : "${m.org}|${m.email}"])
  memberships = {
    for k in local.person_keys : k => {
      org   = split("|", k)[0]
      email = split("|", k)[1]
    }
  }

  roster_team_keys = distinct([for m in local.roster_flat : "${m.org}:${m.team}"])
  roster_teams = {
    for k in local.roster_team_keys : k => {
      org  = split(":", k)[0]
      team = split(":", k)[1]
    }
  }
}

# Org invite (email). New addresses get an invite mail; existing users join.
resource "tfe_organization_membership" "user" {
  for_each = local.memberships

  organization = each.value.org
  email        = each.value.email
}

# Teams already exist (workspace-factory, billed orgs). Look up, don't create.
data "tfe_team" "scoped" {
  for_each = local.roster_teams

  organization = each.value.org
  name         = each.value.team
}

# Team binding (username). Authoritative per team — only rostered teams are
# touched; everything else stays as leads left it. Requires accepted members:
# brand-new users bind on the re-run after they accept the invite.
resource "tfe_team_members" "team" {
  for_each = local.roster_teams

  team_id   = data.tfe_team.scoped[each.key].id
  usernames = [for m in local.roster_flat : m.username if "${m.org}:${m.team}" == each.key]
}
