terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = ">= 0.59.0, < 1.0.0"
    }
  }

  # State lives in HCP: workspace `workspace-factory` in org `BankAZ-landing`
  # (created once in the UI, CLI-driven, execution mode LOCAL). Every run
  # shares it — no local-state drift like org-factory had in phase 1.
  cloud {
    organization = "BankAZ-landing"
    workspaces {
      name = "workspace-factory"
    }
  }
}

provider "tfe" {
  hostname = var.tfe_hostname
  # Token ONLY from env TFE_TOKEN (Actions secret TFE_TOKEN). Never in code.
}
