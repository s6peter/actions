variable "tfe_hostname" {
  description = "HCP Terraform hostname. Keep default for cloud."
  type        = string
  default     = "app.terraform.io"
}

variable "organizations" {
  description = "Map of 20 orgs to create. email = org contact (billing/compliance mail, ideally a team DL). lead_email = team lead to invite as owner + notify on failed runs (optional per org)."
  type = map(object({
    name       = string
    email      = string
    lead_email = optional(string)
  }))

  validation {
    condition     = length(var.organizations) == 20
    error_message = "This example expects exactly 20 organizations."
  }
}
