# OpenTofu - Continuous Delivery

## Introduction

This action is an opinionated wrapper around the work of Daniel Flook: https://github.com/dflook/terraform-github-actions and leverages https://github.com/trstringer/manual-approval as the approval step before applying. Slack notifications are also enabled by default.

## Usage

To use this action in your workflow, add the following to your `.github/workflows/tofu.yml` file:

Example:

```yaml
env:
  TERRAFORM_ACTIONS_GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  OPENTOFU_VERSION: "1.6.2"
  SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
  # more provider environment variables can be set here


name: OpenTofu CD

on:
  push:
    branches:
      - main # This action has defaults that assume it will only apply off of main. It will not apply unless you "approve" the github issue per manual-approval GHA.
  pull_request:
    types: [opened, synchronize, reopened] # If you open a PR it'll run a plan and comment the plan on a PR
  workflow_dispatch:
  # schedule:
  #   - cron: '0 16 * * *' # Used for drift detection. However with the manual approval, if drift is found you may burn through your CI requirements while the manual approval actions waits for you to approve or deny the apply.

jobs:
  terraform-action:
    runs-on: ubuntu-latest
    concurrency:
      group: limit-concurrency-do-not-remove-this
      cancel-in-progress: false
    steps:
      - name: OpenTofu CD              
        uses: GlueOps/github-actions-opentofu-continuous-delivery@v0.0.9
        with:
          enable_slack_notification_for_approval: "true"
          backend_config: |
            access_key=${{ vars.TF_S3_BACKEND_AWS_ACCESS_KEY }}
            secret_key=${{ secrets.TF_S3_BACKEND_AWS_SECRET_ACCESS_KEY }}
            bucket=${{ vars.TF_S3_BACKEND_BUCKET_NAME }}
            region=${{ vars.TF_S3_BACKEND_BUCKET_REGION }}
            key=${{ github.repository }}/terraform.tfstate
```

# Workflow Breakdown

## Triggers
- **Push** to `main` branch.
  * Will trigger an apply that will require a manual approval via github issues.
- **Pull Request** events: opened, synchronized, reopened.
  *  Pull requests only plan and will post a comment to the PR with the plan results.

## Job Configuration
- **Concurrency**: Limits concurrent runs to prevent overlapping runs.


## Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `path` | Path to the OpenTofu configuration | ❌ | `.` |
| `workspace` | Name of the OpenTofu workspace | ❌ | `default` |
| `backend_config` | List of backend config values to set, one per line | ❌ | `""` |
| `backend_config_file` | Path to a backend config file | ❌ | `""` |
| `variables` | Variable definitions | ❌ | `""` |
| `var_file` | List of var file paths, one per line | ❌ | `""` |
| `parallelism` | Limit the number of concurrent operations | ❌ | `0` |
| `label` | A friendly name for this plan | ❌ | `""` |
| `target` | List of resources to target for the apply, one per line | ❌ | `""` |
| `replace` | List of resources to replace if an update is required, one per line | ❌ | `""` |
| `destroy` | Create and apply a plan to destroy all resources | ❌ | `false` |
| `backend_type` | The backend plugin name | ✅ | _None_ |
| `add_github_comment` | Add the plan to a GitHub PR | ❌ | `true` |
| `enable_slack_notification_for_approval` | Enable or Disable Slack notifications | ❌ | `true` |

## Outputs

| Name | Description |
|------|-------------|
| `tofu` | The OpenTofu version used by the configuration |
| `changes` | Indicates if the generated plan would update any resources or outputs (`true` or `false`) |
| `failure-reason` | The reason for the build failure (`apply-failed` or `plan-changed`) |
| `to_add` | The number of resources that would be added by this plan |
| `to_change` | The number of resources that would be changed by this plan |
| `to_destroy` | The number of resources that would be destroyed by this plan |
| `plan_path` | Path to the file containing the generated plan in an opaque binary format |
| `text_plan_path` | Path to the file containing the generated plan in human-readable format |
| `json_plan_path` | Path to the file containing the generated plan in JSON format |
| `run_id` | The remote run ID if using `remote` or `cloud` backend in remote execution mode |

## Secrets and Environment Variables

### Secrets

Add the following secrets to your GitHub repository under `Settings > Secrets and variables > Actions`:

- `TF_S3_BACKEND_AWS_ACCESS_KEY`: AWS access key for the S3 backend.
- `TF_S3_BACKEND_AWS_SECRET_ACCESS_KEY`: AWS secret access key for the S3 backend.

### Environment Variables

Set the following environment variables in your workflow:

- `TERRAFORM_ACTIONS_GITHUB_TOKEN`: Typically set to `${{ secrets.GITHUB_TOKEN }}`.
- `OPENTOFU_VERSION`: Version of OpenTofu to use (e.g., `1.6.2`).

Example:

```yaml
env:
  TERRAFORM_ACTIONS_GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  OPENTOFU_VERSION: "1.6.2"
  # Additional environment variables can be added here
```

## Error Handling
Formatting Errors: The action checks for proper formatting using tofu fmt. If formatting issues are detected, the workflow will fail with a prompt to run tofu fmt.



If you have a security issue you would like to report please use security@glueops.dev to contact us. For all other matters please submit a PR or a github issue.


