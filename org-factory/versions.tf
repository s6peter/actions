terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = ">= 0.59.0, < 1.0.0"
    }
  }

  # Bootstrap note: NO cloud{} / remote backend here on purpose.
  # You have no parent org yet, so state stays local for the first run.
  # Actions uploads terraform.tfstate as a workflow artifact.
  # After org #1 exists, move this state into an admin workspace if you want.
}

provider "tfe" {
  hostname = var.tfe_hostname
  # Token comes ONLY from env TFE_TOKEN.
  # Never hardcode it. In Actions: ${{ secrets.TFE_TOKEN }}.
}
