terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = ">= 0.59.0, < 1.0.0"
    }
  }

  # Separate state from org-factory on purpose: orgs first, teams/workspaces
  # second. Same bootstrap style — local state, uploaded as a CI artifact.
}

provider "tfe" {
  hostname = var.tfe_hostname
  # Token ONLY from env TFE_TOKEN (Actions secret TFE_TOKEN). Never in code.
}
