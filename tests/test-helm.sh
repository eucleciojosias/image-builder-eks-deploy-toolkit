#!/usr/bin/env bash

# shellcheck disable=SC1091
setup_suite() {
  source ./stub/aws.sh
  source ./stub/helm.sh
  source ./stub/kubectl.sh
  source ./utils.sh

  export ROOT_PATH="../scripts/"
}

setup() {
  export GITHUB_REPOSITORY="acme/my-repo"
  export GITHUB_REF_NAME="staging"
  export GITHUB_SHA="11ccc333"
  export GITHUB_RUN_NUMBER="111"
  export DEPLOYMENT_ENVIRONMENT="staging"
  export BASE_DOMAIN="example.com"
  export AWS_ACCOUNT_ID="123456789012"
  export AWS_REGION="us-east-1"
  export CLUSTER_NAME="my-cluster"
  export HELM_REPO="my-charts"
  export HELM_REPO_URL="https://charts.example.com"
  export CHART="my-charts/app-chart"
  export NAMESPACE="apps"
  unset APP_DOMAIN
  unset HELM_FAKE_UPGRADE_FAIL

  rm -f /tmp/helm_fake_params.json
  rm -f /tmp/aws_fake_params
  rm -f /tmp/kubectl_fake_params

  fake aws _aws
  fake helm _helm
  fake kubectl _kubectl
}

test_helm_missing_required_envvars() {
  assert_matches "HELM_REPO environment variable missing" "$(unset HELM_REPO; "../scripts/helm.sh" 2>&1)"
  assert_matches "HELM_REPO_URL environment variable missing" "$(unset HELM_REPO_URL; "../scripts/helm.sh" 2>&1)"
  assert_matches "CHART environment variable missing" "$(unset CHART; "../scripts/helm.sh" 2>&1)"
  assert_matches "NAMESPACE environment variable missing" "$(unset NAMESPACE; "../scripts/helm.sh" 2>&1)"
  assert_matches "AWS_REGION environment variable missing" "$(unset AWS_REGION; "../scripts/helm.sh" 2>&1)"
  assert_matches "CLUSTER_NAME environment variable missing" "$(unset CLUSTER_NAME; "../scripts/helm.sh" 2>&1)"
}

assert_aws_eks_params() {
  read -r -a aws_fake_params <<< "$(head -n1 /tmp/aws_fake_params)"
  assert_equals "eks" "${aws_fake_params[0]}"
  assert_equals "update-kubeconfig" "${aws_fake_params[1]}"
  assert_equals "--region" "${aws_fake_params[2]}"
  assert_equals "us-east-1" "${aws_fake_params[3]}"
  assert_equals "--name" "${aws_fake_params[4]}"
  assert_equals "my-cluster" "${aws_fake_params[5]}"
}

assert_helm_repo_params() {
  set_nth_call_to_helm_params 1
  assert_equals "repo add" "$(join_helm_params 0 1)"
  assert_equals "my-charts" "$(get_helm_param 2)"
  assert_equals "https://charts.example.com" "$(get_helm_param 3)"

  set_nth_call_to_helm_params 2
  assert_equals "repo update" "$(join_helm_params 0 1)"
}

test_helm_deploy() {
  "../scripts/helm.sh" > /dev/null

  assert_aws_eks_params
  assert_helm_repo_params

  set_nth_call_to_helm_params 3
  assert_equals "template" "$(get_helm_param 0)"
  assert_equals "my-repo-staging" "$(get_helm_param 1)"
  assert_equals "my-charts/app-chart" "$(get_helm_param 2)"
  assert_equals "--namespace apps" "$(join_helm_params 3 4)"
  assert_equals "--set siteCommit=11ccc333-111" "$(join_helm_params 5 6)"
  assert_equals "--set image.repository=123456789012.dkr.ecr.us-east-1.amazonaws.com/my-repo" "$(join_helm_params 7 8)"
  assert_equals "--set image.tag=staging" "$(join_helm_params 9 10)"
  assert_equals "--set siteDomain=my-repo.staging.example.com" "$(join_helm_params 11 12)"

  set_last_call_to_helm_params
  assert_equals "upgrade" "$(get_helm_param 0)"
  assert_equals "my-repo-staging" "$(get_helm_param 1)"
  assert_equals "my-charts/app-chart" "$(get_helm_param 2)"
  assert_equals "--install" "$(get_helm_param 3)"
  assert_equals "--atomic" "$(get_helm_param 4)"
  assert_equals "--cleanup-on-fail" "$(get_helm_param 5)"
  assert_equals "--debug" "$(get_helm_param 6)"
  assert_equals "--devel" "$(get_helm_param 7)"
  assert_equals "--timeout=5m" "$(get_helm_param 8)"
  assert_equals "--namespace apps" "$(join_helm_params 9 10)"
  assert_equals "--set siteCommit=11ccc333-111" "$(join_helm_params 11 12)"
  assert_equals "--set image.repository=123456789012.dkr.ecr.us-east-1.amazonaws.com/my-repo" "$(join_helm_params 13 14)"
  assert_equals "--set image.tag=staging" "$(join_helm_params 15 16)"
  assert_equals "--set siteDomain=my-repo.staging.example.com" "$(join_helm_params 17 18)"
}

test_helm_deploy_with_custom_values_files() {
  mkdir -p chart
  echo "replicas: 2" > chart/values.yaml
  echo "replicas: 1" > chart/values-staging.yaml

  "../scripts/helm.sh" > /dev/null

  set_last_call_to_helm_params
  assert_equals "upgrade" "$(get_helm_param 0)"
  assert_equals "--namespace apps" "$(join_helm_params 9 10)"
  assert_equals "--values ./chart/values.yaml" "$(join_helm_params 11 12)"
  assert_equals "--values ./chart/values-staging.yaml" "$(join_helm_params 13 14)"
  assert_equals "--set siteCommit=11ccc333-111" "$(join_helm_params 15 16)"

  rm -r chart
}

test_helm_deploy_skips_values_file_of_other_environment() {
  mkdir -p chart
  echo "replicas: 2" > chart/values-production.yaml

  "../scripts/helm.sh" > /dev/null

  set_last_call_to_helm_params
  assert_equals "upgrade" "$(get_helm_param 0)"
  assert_equals "--namespace apps" "$(join_helm_params 9 10)"
  assert_equals "--set siteCommit=11ccc333-111" "$(join_helm_params 11 12)"

  rm -r chart
}

test_helm_deploy_with_custom_app_domain() {
  export APP_DOMAIN="custom.domain.com"

  "../scripts/helm.sh" > /dev/null

  set_last_call_to_helm_params
  assert_equals "--set siteDomain=custom.domain.com" "$(join_helm_params 17 18)"
}

test_helm_deploy_fails_when_release_is_not_deployed() {
  export HELM_FAKE_UPGRADE_FAIL="1"

  assert_fails "'../scripts/helm.sh' > /dev/null 2>&1"

  set_last_call_to_helm_params
  assert_equals "upgrade" "$(get_helm_param 0)"
}
