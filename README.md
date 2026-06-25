# OpenTofu - Continuous Delivery

[![Integration Test](https://github.com/GlueOps/github-actions-opentofu-continuous-delivery/actions/workflows/integration-test.yml/badge.svg)](https://github.com/GlueOps/github-actions-opentofu-continuous-delivery/actions/workflows/integration-test.yml)

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
    types: [opened, synchronize, reopened] # If you open a PR it'll run a plan and post a sticky comment linking to the full plan
  workflow_dispatch:
  # schedule:
  #   - cron: '0 16 * * *' # Used for drift detection. However with the manual approval, if drift is found you may burn through your CI requirements while the manual approval actions waits for you to approve or deny the apply.

jobs:
  terraform-action:
    runs-on: ubuntu-latest
    permissions:
      contents: read        # checkout
      issues: write         # manual approval gate on main
      pull-requests: write  # sticky plan comment on PRs (add_github_comment)
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

GitHub issue and comment bodies are capped at **65,536 characters**, so a large plan can't always be posted inline. The action handles this as follows:

- The full plan is **always** uploaded as a downloadable **artifact** named `tofu-plan.txt`. It is uploaded uncompressed (`archive: false`), so it downloads as a single `.txt` file with no zip to extract, and has no practical size limit.
- On pull requests, a single sticky comment is posted (and updated in place on each push) that **always** has a one-click link to download the artifact, and **also inlines the full plan** (in a collapsible block) **when the whole comment fits** under the 65,536-character limit. If the plan is too large to fit, the comment is link-only — it never includes a partial plan. Controlled by `add_github_comment` (default `true`; set `false` to disable). The upstream dflook plan comment is always disabled, since it truncates large plans.
- On an apply to `main` that requires manual approval, the approval issue created by [manual-approval](https://github.com/trstringer/manual-approval) does the same: always a one-click artifact download link, plus the inlined plan when it fits.

> **Note:** Both surfaces depend on a human-readable plan being produced. For `remote`/`cloud` backends running in auto-approve mode, OpenTofu emits no text plan (`text_plan_path` is unset), so the artifact and the inline plan are skipped. Non-PR runs (`push` to `main`, `workflow_dispatch`) post no PR comment; the plan is on the artifact, and on `main` the approval issue links to it.

> **⚠️ Sensitive data:** A plan can contain secrets in cleartext — any provider/resource attribute not explicitly marked `sensitive` (connection strings, IAM policy documents, tokens, etc.) is rendered verbatim. The `tofu-plan.txt` artifact — and the plan inlined in the PR comment / approval issue when small enough — are visible to anyone with read/Actions access to the repository, and the artifact is kept per your repository's default artifact retention. Treat them accordingly: restrict repository access and/or lower the artifact retention if your plans can expose sensitive values.

Because the artifact and the comment/issue are produced before the approval gate, you can review the plan and then approve or deny — no need to cancel and re-run.

## Permissions

Most repositories run with the default `GITHUB_TOKEN` permissions, which are sufficient. If you restrict permissions in your workflow, the action needs:

- `contents: read` — required for `actions/checkout` to fetch your configuration.
- `issues: write` — required for the manual approval gate on `main` (creates and reads the approval issue).
- `pull-requests: write` — required only when `add_github_comment` is enabled (default), to post the sticky PR comment. Note that PRs opened from forks always receive a read-only token regardless of this setting; in that case the comment is skipped with a warning (the plan is still on the artifact).

Beyond `contents: read` for checkout, the `tofu-plan.txt` artifact needs no `GITHUB_TOKEN` write permissions (the artifact upload uses the runner's separate token).

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
| `enable_slack_notification_for_approval` | **Deprecated and ignored.** Slack notifications have been removed; retained only for backward compatibility. | ❌ | `""` |
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
| `text_plan_path` | Path to the file containing the generated plan in human-readable format. Not set if the backend is `remote` and `auto_approve` is `true` |
| `json_plan_path` | Path to the file containing the generated plan in JSON format. Not set if the backend is `remote` |
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


