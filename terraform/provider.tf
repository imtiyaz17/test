# Assigns AWS as the provider and configures default tags via the CCP-NEXT-LABELS-MODULE
# https://southwest.gitlab-dedicated.com/swa-common/devplat/ccp-next/ccp-next-modules/ccp-next-labels-module

provider "aws" {
  region = var.region

  # adds these common tags to all supported resources
  default_tags {
    tags = module.root_labels.tags
  }
}
