# OpenTofu - Continuous Delivery

Example using AWS S3 Backend state storage:

```yaml
env:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  # more provider environment variables can be set here


name: OpenTofu CD

on:
  push:
    branches:
      - main
  pull_request:

jobs:
  terraform-action:
    runs-on: ubuntu-latest
    steps:
      - name: OpenTofu CD              
        uses: GlueOps/github-actions-opentofu-continuous-delivery@main
        with:
          backend_config: |
            access_key=${{ vars.TF_S3_BACKEND_AWS_ACCESS_KEY }}
            secret_key=${{ secrets.TF_S3_BACKEND_AWS_SECRET_ACCESS_KEY }}
            bucket=${{ vars.TF_S3_BACKEND_BUCKET_NAME }}
            region=${{ vars.TF_S3_BACKEND_BUCKET_REGION }}
            key=${{ github.repository }}/terraform.tfstate
```

This action is an opinionated wrapped around the work of Daniel Flook: https://github.com/dflook/terraform-github-actions



