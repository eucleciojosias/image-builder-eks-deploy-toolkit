#!/usr/bin/env bash

set_kube_config() {
  aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"
}

set_app_domain() {
  local sub_domain
  sub_domain=$(echo "${DEPLOYMENT_ENVIRONMENT,,}") # lowercase
  if [[ "$sub_domain" == "production" ]]; then sub_domain="prod"; fi

  APP_DOMAIN=${APP_DOMAIN:-"${GITHUB_REPOSITORY##*/}.${sub_domain}.${BASE_DOMAIN}"}
  export APP_DOMAIN
}

set_release_name() {
  local suffix
  case "$GITHUB_REF_NAME" in
    master|main|staging|develop|test|redesign) suffix="${GITHUB_REF_NAME}" ;;
    *) suffix="staging" ;;
  esac

  RELEASE_NAME="${GITHUB_REPOSITORY##*/}-${suffix}"

  export RELEASE_NAME
}

print_deploy_info() {
  echo "HELM_REPO: $HELM_REPO"
  echo "HELM_REPO_URL: $HELM_REPO_URL"
  echo "CHART: $CHART"
  echo "NAMESPACE: $NAMESPACE"
  echo "APP_DOMAIN: $APP_DOMAIN"
  echo "RELEASE_NAME: $RELEASE_NAME"
  echo "CLUSTER: $(kubectl config current-context)"
  echo "SERVER: $(kubectl config view --minify -o jsonpath='{.clusters[].cluster.server}')"
}

get_value_files_list() {
  value_files_list=""

  if [[ -d "chart" ]]; then
    if [[ -f "chart/values.yaml" ]]; then
      value_files_list="$value_files_list --values ./chart/values.yaml"
    fi
    if [[ -f "chart/values-$DEPLOYMENT_ENVIRONMENT.yaml" ]]; then
      value_files_list="$value_files_list --values ./chart/values-$DEPLOYMENT_ENVIRONMENT.yaml"
    fi
  fi

  echo "$value_files_list"
}

generate_helm_cmd() {
  action=${1:-"template"}
  helm_cmd="helm ${action} ${RELEASE_NAME} ${CHART}"

  if [[ "${action}" == "upgrade" ]]; then
    helm_cmd="${helm_cmd} --install --atomic --cleanup-on-fail --debug --devel --timeout=5m"
  fi

  value_files_list="$(get_value_files_list)"
  custom_values_list="$(${ROOT_PATH}helm-values.sh)"
  custom_values_list="${custom_values_list} --set siteDomain=${APP_DOMAIN}"

  helm_cmd="${helm_cmd} --namespace ${NAMESPACE}"
  helm_cmd="${helm_cmd} ${value_files_list}"
  helm_cmd="${helm_cmd} ${custom_values_list}"

  echo "$helm_cmd"
}
