# OpenTofu - Continuous Delivery

## Introduction

This action is an opinionated wrapper around the work of Daniel Flook: https://github.com/dflook/terraform-github-actions and leverages https://github.com/trstringer/manual-approval as the approval step before applying.

## Usage

To use this action in your workflow, add the following to your `.github/workflows/tofu.yml` file:

Example:

```yaml
env:
  TERRAFORM_ACTIONS_GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  OPENTOFU_VERSION: "1.6.2"
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
  *  Pull requests only plan and (by default) post a sticky comment to the PR linking to the full plan. See [Viewing the plan](#viewing-the-plan).

## Job Configuration
- **Concurrency**: Limits concurrent runs to prevent overlapping runs.

## Viewing the plan

GitHub comments are capped at ~64 KB, so posting the plan inline truncates large plans. Instead, the full plan is always made available without that limit, and every surface just **links** to it consistently:

- The full, human-readable plan is rendered to the run's **job summary** page (browser-viewable, searchable, no download). The summary has a ~1 MiB limit (16× the comment limit).
- The full plan is always uploaded as a downloadable **artifact** named `tofu-plan` (no practical size limit), so it is accessible even for plans larger than the summary limit.
- On pull requests, a single sticky comment is posted (and updated in place on each push) linking to the run summary page (where the plan is rendered) and to the artifact. This is enabled by default and controlled by `add_github_comment` (set it to `false` to disable). The upstream dflook plan comment is always disabled, since it truncates large plans.
- On an apply to `main` that requires manual approval, the approval issue created by [manual-approval](https://github.com/trstringer/manual-approval) links to the same plan.

Because the plan is published before the approval gate, you can review the complete plan and then approve or deny — no need to cancel and re-run.

## Permissions

Most repositories run with the default `GITHUB_TOKEN` permissions, which are sufficient. If you restrict permissions in your workflow, the action needs:

- `issues: write` — required for the manual approval gate on `main` (creates and reads the approval issue).
- `pull-requests: write` — required only when `add_github_comment` is enabled (default), to post the sticky PR comment.

The job summary and the `tofu-plan` artifact require **no** `GITHUB_TOKEN` permissions (the artifact uses the runner's separate token).

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
| `add_github_comment` | Post a sticky comment on the PR linking to the full plan (job summary / artifact). | ❌ | `true` |
| `enable_slack_notification_for_approval` | **Deprecated and ignored.** Slack notifications have been removed; retained only for backward compatibility. | ❌ | `true` |
| `ENABLE_DANGEROUS_AUTO_APPLY_MODE` | If enabled, any changes including Destroy, Apply, and Replace will be automatically approved (skips the manual approval step). | ❌ | `false` |

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


