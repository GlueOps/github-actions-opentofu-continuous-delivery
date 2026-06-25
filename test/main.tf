terraform {
  required_version = ">= 1.6.0"

  # Local backend keeps state on the runner only — throwaway, no credentials,
  # so the integration test is fully isolated per run.
  backend "local" {}

  # Pin the provider so the fixture is deterministic and a new major release
  # can't change its behavior unexpectedly.
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# A no-op resource (no cloud provider / credentials needed). Because the local
# state never persists across runs, every run plans "1 to add".
resource "null_resource" "integration_test" {}

output "ok" {
  value = "integration-test"
}
