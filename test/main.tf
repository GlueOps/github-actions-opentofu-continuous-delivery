terraform {
  required_version = ">= 1.6.0"

  # Local backend keeps state on the runner only — throwaway, no credentials,
  # so the integration test is fully isolated per run.
  backend "local" {}
}

# A no-op resource (no cloud provider / credentials needed). Because the local
# state never persists across runs, every run plans "1 to add".
resource "null_resource" "integration_test" {}

output "ok" {
  value = "integration-test"
}
