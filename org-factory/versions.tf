terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = ">= 0.59.0, < 1.0.0"
    }
  }

  # Phase 2: state lives in HCP. Every run (laptop or Actions) reads/writes
  # the same copy, so adding org21 plans as "1 to add" instead of recreating.
  # Workspace `org-factory` in org `BankAZ-landing` must exist first (created
  # once in the UI, CLI-driven workflow, execution mode LOCAL).
  cloud {
    organization = "BankAZ-landing"
    workspaces {
      name = "org-factory"
    }
  }
}

provider "tfe" {
  hostname = var.tfe_hostname
  # Token comes ONLY from env TFE_TOKEN.
  # Never hardcode it. In Actions: ${{ secrets.TFE_TOKEN }}.
}
