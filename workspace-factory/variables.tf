variable "tfe_hostname" {
  description = "HCP Terraform hostname. app.terraform.io for cloud, own host for Terraform Enterprise."
  type        = string
  default     = "app.terraform.io"
}

variable "organization_names" {
  description = "The 20 org names created by org-factory. Must match exactly — this factory never creates orgs."
  type        = list(string)

  validation {
    condition     = length(var.organization_names) >= 1
    error_message = "Define at least one organization. Must match org-factory output names."
  }
}

variable "teams" {
  description = "Team slug per org. Rename only — teams are org-scoped, so short names are fine."
  type        = list(string)
  default     = ["security", "dev", "qa", "preprod", "production"]
}

variable "environments" {
  description = "One workspace per environment per org. Workspace name becomes <org>-<env>."
  type        = list(string)
  default     = ["dev", "qa", "preprod", "prod", "security"]
}

variable "access_matrix" {
  description = <<-EOT
    Least-privilege matrix: team => workspace-env => access (read|plan|write|admin|none).
    Each team writes only its own env, reads the rest; security reads everything
    and admins the security workspace (audit/policies). "none" skips the binding.
    Customize per bank policy without touching code.
  EOT
  type        = map(map(string))
  default = {
    dev        = { dev = "write", qa = "read", preprod = "read", prod = "read", security = "read" }
    qa         = { dev = "read", qa = "write", preprod = "read", prod = "read", security = "read" }
    preprod    = { dev = "read", qa = "read", preprod = "write", prod = "read", security = "read" }
    production = { dev = "read", qa = "read", preprod = "read", prod = "write", security = "read" }
    security   = { dev = "read", qa = "read", preprod = "read", prod = "read", security = "admin" }
  }

  validation {
    condition = alltrue(flatten([
      for team, perms in var.access_matrix : [
        for env, level in perms :
        contains(["read", "plan", "write", "admin", "none"], level)
      ]
    ]))
    error_message = "access_matrix levels must be read|plan|write|admin|none."
  }
}

variable "team_roster" {
  description = <<-EOT
    Optional usernames per org team: { "<org>" = { "<team>" = ["username", ...] } }.
    Omit teams to create them empty — leads populate via UI. Usernames must be
    accepted org members already (invite first, same two-pass rule as leads:
    apply adds teams, members join after accepting, re-run to bind them).
    NOTE: tfe_team_members is authoritative — it owns the whole member list.
  EOT
  type        = map(map(list(string)))
  default     = {}
}

variable "terraform_version" {
  description = "Pinned Terraform version for every created workspace."
  type        = string
  default     = "1.9.8"
}

variable "sso_team_ids" {
  description = "Optional IdP group mapping for SSO-enforced orgs: { \"<org>:<team>\" = \"<sso-group-id>\" }. Omit entirely without SSO."
  type        = map(string)
  default     = {}
}
