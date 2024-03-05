# OpenTofu - Continuous Delivery


```yaml
env:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

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
