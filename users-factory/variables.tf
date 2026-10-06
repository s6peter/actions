variable "tfe_hostname" {
  description = "HCP Terraform hostname. app.terraform.io for cloud, own host for Terraform Enterprise."
  type        = string
  default     = "app.terraform.io"
}

variable "managed_scope" {
  description = "Org => teams this factory manages. Only billed orgs with teams go here."
  type        = map(list(string))
  default = {
    "bank-landing-v2-01" = ["security", "qa", "dev"]
    "bank-landing-v2-03" = ["qa", "dev", "production"]
  }
}

variable "roster" {
  description = <<-EOT
    Org => team => members. email invites the user to the org;
    username binds them to the team (usernames exist after signup/accept —
    same two-pass rule as leads: apply invites, they join, re-run binds).
    HCP has NO user-creation API: accounts come from signup or SSO/SCIM;
    this factory only invites + assigns. Guarded to managed_scope.
  EOT
  type = map(map(list(object({
    email    = string
    username = string
  }))))
  default = {}

  validation {
    condition = alltrue(flatten([
      for org, teams in var.roster : [
        contains(keys(var.managed_scope), org) ? alltrue([
          for team in keys(teams) : contains(var.managed_scope[org], team)
        ]) : false
      ]
    ]))
    error_message = "Roster is limited to managed_scope: v2-01 (security/qa/dev), v2-03 (qa/dev/production)."
  }
}
