# One resource, 20 instances via for_each.
# Org names must be globally unique, lowercase, letters/numbers/dashes.
resource "tfe_organization" "this" {
  for_each = var.organizations

  name  = each.value.name
  email = each.value.email
}

output "organization_names" {
  description = "Created org names."
  value       = { for k, o in tfe_organization.this : k => o.name }
}
