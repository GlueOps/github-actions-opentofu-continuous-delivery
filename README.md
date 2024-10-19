# OpenTofu - Continuous Delivery

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
  schedule:
    - cron: '0 16 * * *' # Used for drift detection.

jobs:
  terraform-action:
    runs-on: ubuntu-latest
    concurrency:
      group: limit-concurrency-do-not-remove-this
      cancel-in-progress: false
    steps:
      - name: OpenTofu CD              
        uses: GlueOps/github-actions-opentofu-continuous-delivery@v0.0.5
        with:
          enable_slack_notification_for_approval: "false"
          backend_config: |
            access_key=${{ vars.TF_S3_BACKEND_AWS_ACCESS_KEY }}
            secret_key=${{ secrets.TF_S3_BACKEND_AWS_SECRET_ACCESS_KEY }}
            bucket=${{ vars.TF_S3_BACKEND_BUCKET_NAME }}
            region=${{ vars.TF_S3_BACKEND_BUCKET_REGION }}
            key=${{ github.repository }}/terraform.tfstate
```

This action is an opinionated wrapper around the work of Daniel Flook: https://github.com/dflook/terraform-github-actions and leverages https://github.com/trstringer/manual-approval as the approval step before applying. Slack notifications are also enabled by default.


If you have a security issue you would like to report please use security@glueops.dev to contact us. For all other matters please submit a PR or a github issue.


