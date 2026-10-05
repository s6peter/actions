variable "tfe_hostname" {
  description = "HCP Terraform hostname. Keep default for cloud."
  type        = string
  default     = "app.terraform.io"
}

variable "organizations" {
  description = "Map of 20 orgs to create. Key = terraform key, value = org name + admin email."
  type = map(object({
    name  = string
    email = string
  }))

  validation {
    condition     = length(var.organizations) >= 1
    error_message = "Define at least one organization. Add more (org21, ...) to grow the factory."
  }
}
