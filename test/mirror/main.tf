# Fixture for mirror-e2e.yml: providers from both registries (GitHub release files and
# releases.hashicorp.com) and modules from GitHub (via the registry and a git:: source).
terraform {
  backend "local" {}
  required_providers {
    random = { source = "hashicorp/random", version = "3.9.1" }
    null   = { source = "registry.terraform.io/hashicorp/null", version = "3.2.4" }
  }
}

module "label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"
  name    = "mirror-e2e"
}

module "subnets" {
  source          = "git::https://github.com/hashicorp/terraform-cidr-subnets.git?ref=v1.0.0"
  base_cidr_block = "10.0.0.0/16"
  networks        = [{ name = "a", new_bits = 8 }]
}

resource "random_pet" "test" {}

resource "null_resource" "test" {
  triggers = {
    label  = module.label.id
    subnet = module.subnets.network_cidr_blocks["a"]
    pet    = random_pet.test.id
  }
}
