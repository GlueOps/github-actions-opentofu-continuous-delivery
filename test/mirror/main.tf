# Fixture for mirror-e2e.yml: providers from both registries (GitHub release files and
# releases.hashicorp.com, including a partner provider) and modules from GitHub (via both
# registries, and git:: sources with a subdir and tag, a commit and the default branch).
terraform {
  backend "local" {}
  required_providers {
    random = { source = "hashicorp/random", version = "3.9.1" }
    null   = { source = "registry.terraform.io/hashicorp/null", version = "3.2.4" }
    # Installed only; no resources use it, so it needs no credentials.
    github = { source = "integrations/github", version = "6.13.0" }
  }
}

module "label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"
  name    = "mirror-e2e"
}

module "files" {
  source   = "registry.terraform.io/hashicorp/dir/template"
  version  = "1.0.2"
  base_dir = "${path.module}/static"
}

module "subdir" {
  source = "git::https://github.com/cloudposse/terraform-null-label.git//exports?ref=0.25.0"
  name   = "mirror-e2e-subdir"
}

module "commit" {
  source          = "git::https://github.com/hashicorp/terraform-cidr-subnets.git?ref=2a772a83e15feb5f224a9d814c36948769d3146b"
  base_cidr_block = "10.1.0.0/16"
  networks        = [{ name = "b", new_bits = 8 }]
}

module "default_branch" {
  source   = "git::https://github.com/hashicorp/terraform-template-dir.git"
  base_dir = "${path.module}/static"
}

resource "random_pet" "test" {}

resource "null_resource" "test" {
  triggers = {
    label  = module.label.id
    commit = module.commit.network_cidr_blocks["b"]
    pet    = random_pet.test.id
  }
}
