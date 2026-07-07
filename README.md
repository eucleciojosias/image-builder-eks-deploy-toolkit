# EKS Helm Deploy

Docker image with scripts to deploy Helm charts to an Amazon EKS cluster from CI.

`helm.sh` sets the kubeconfig with `aws eks update-kubeconfig`, resolves the release name and
app domain from the repository and branch, picks up the app's `chart/values*.yaml` files when
present, and runs `helm upgrade --install --atomic` — dumping the pod logs if the deploy fails.

Required variables: `CHART`, `NAMESPACE`, `AWS_REGION`, `CLUSTER_NAME`, `HELM_REPO`,
`HELM_REPO_URL`. Optional: `DEPLOYMENT_ENVIRONMENT`, `BASE_DOMAIN`, `APP_DOMAIN`,
`AWS_ACCOUNT_ID`.

## Tests

```sh
curl -s https://raw.githubusercontent.com/pgrange/bash_unit/master/install.sh | bash
./bash_unit tests/test-*
```
