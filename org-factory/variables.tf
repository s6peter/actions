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
    condition     = length(var.organizations) == 20
    error_message = "This example expects exactly 20 organizations."
  }
}
