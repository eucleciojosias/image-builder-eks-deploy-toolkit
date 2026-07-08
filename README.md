# Image builder/EKS Helm Deploy Toolkit

CI toolkit, packaged as a single Docker image, for building an app's Docker image and
deploying it to an Amazon EKS cluster with Helm.

All scripts are copied flat into `/` in the same image, so each runs as e.g. `docker run
<image> /helm.sh`, make it easy to use into CD pipelines.

## Tests

```sh
curl -s https://raw.githubusercontent.com/pgrange/bash_unit/master/install.sh | bash
./bash_unit tests/test-*
```
