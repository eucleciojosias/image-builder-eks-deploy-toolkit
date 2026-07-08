# EKS Helm Deploy

Docker image with scripts to build and deploy apps to an Amazon EKS cluster from CI. All
scripts are copied flat into `/` in the same image, so each runs as e.g. `docker run <image>
/helm.sh`.

`helm.sh` sets the kubeconfig with `aws eks update-kubeconfig`, resolves the release name and
app domain from the repository and branch, picks up the app's `chart/values*.yaml` files when
present, and runs `helm upgrade --install --atomic` — dumping the pod logs if the deploy fails.

Required variables: `CHART`, `NAMESPACE`, `AWS_REGION`, `CLUSTER_NAME`, `HELM_REPO`,
`HELM_REPO_URL`. Optional: `DEPLOYMENT_ENVIRONMENT`, `BASE_DOMAIN`, `APP_DOMAIN`,
`AWS_ACCOUNT_ID`.

`build.sh` builds and pushes an app's own image to ECR. It's generic: any repo with a
`Dockerfile` in its root works, no per-framework configuration needed. It creates the ECR repo
if it doesn't exist yet, logs in, then tags the image as
`<account>.dkr.ecr.<region>.amazonaws.com/<repo>:<ref>` (both overridable via `IMAGE`/`TAG`) and
builds it with `COMMIT_HASH`/`COMMIT_DATE`/`COMMIT_AUTHOR` build-args from `git`.

Required variables: `AWS_ACCOUNT_ID`, `AWS_REGION`. `GITHUB_REPOSITORY` and `GITHUB_REF_NAME`
are provided automatically in GitHub Actions. Optional: `IMAGE`, `TAG`.

## Layout

- `scripts/` — `helm.sh`, `shared-funcs.sh`, `eks-log-dumper.sh`, `helm-values.sh` (deploy);
  `build.sh`, `build-app.sh`, `ecr.sh`, `get-image-name.sh` (image build); and
  `cleanup-preview-apps.sh`, which runs directly from a checkout in the cleanup workflow and is
  never baked into the image.
- `policies/` — `preview-apps-ecr-lifecycle-policy.json`, the ECR lifecycle policy applied to
  preview app repositories by `cleanup-preview-apps.sh`.

## Tests

```sh
curl -s https://raw.githubusercontent.com/pgrange/bash_unit/master/install.sh | bash
./bash_unit tests/test-*
```
