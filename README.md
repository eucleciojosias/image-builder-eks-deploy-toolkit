# EKS Helm Deploy

Scripts and a Docker image to deploy Helm charts to an Amazon EKS cluster from CI, plus a
GitHub Actions workflow to build and publish the image and to clean up preview apps.

## How it works

`helm.sh` is the deploy entry point. It:

1. Configures kubeconfig via `aws eks update-kubeconfig`.
2. Resolves the Helm release name and app domain from the repository and branch.
3. Collects values files (`chart/values.yaml` and `chart/values-<environment>.yaml` from the
   app repository, when present) and custom `--set` values from `helm-values.sh`.
4. Runs `helm template` first, then `helm upgrade --install --atomic`.
5. On failure, dumps the pod logs of the release (`eks-log-dumper.sh`).

## Environment variables

| Variable                 | Description                                                          |
|--------------------------|----------------------------------------------------------------------|
| `CHART` (required)       | Helm chart to deploy, e.g. `myrepo/app-chart`.                       |
| `NAMESPACE` (required)   | Kubernetes namespace to deploy into.                                 |
| `AWS_REGION` (required)  | AWS region of the EKS cluster.                                       |
| `CLUSTER_NAME` (required)| Name of the EKS cluster.                                             |
| `HELM_REPO` (required)   | Helm repository name to add.                                         |
| `HELM_REPO_URL` (required)| Helm repository URL.                                                |
| `DEPLOYMENT_ENVIRONMENT` | Deployment environment (e.g. `staging`, `production`).               |
| `BASE_DOMAIN`            | Base domain used to build the default `APP_DOMAIN`.                  |
| `APP_DOMAIN`             | App domain. Default: `<repo>.<environment>.<BASE_DOMAIN>`.           |
| `AWS_ACCOUNT_ID`         | AWS account that hosts the private ECR image repository.             |

## Tests

Tests use [bash_unit](https://github.com/pgrange/bash_unit) with fakes for the `helm`, `aws`
and `kubectl` commands (`tests/stub/`), asserting the exact parameters each command receives:

```sh
curl -s https://raw.githubusercontent.com/pgrange/bash_unit/master/install.sh | bash
./bash_unit tests/test-*
```

## Workflows

- **Lint & Test** (`.github/workflows/lint.yml`): runs ShellCheck and the bash_unit tests on
  every push.
- **Build and Push** (`.github/workflows/build-push.yml`): builds the Docker image and pushes
  it to Amazon ECR Public when the image inputs change. Uses OIDC (`AWS_ROLE_ARN` secret).
- **Cleanup Preview Apps** (`.github/workflows/cleanup-preview-apps.yml`): manually triggered;
  uninstalls Helm releases of preview apps whose pull requests are closed, and ensures an ECR
  lifecycle policy (`preview-apps-ecr-lifecycle-policy.json`) so stale preview tags expire.
