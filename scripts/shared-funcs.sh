#!/usr/bin/env bash

set_kube_config() {
  aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"
}

set_app_domain() {
  APP_DOMAIN=${APP_DOMAIN:-"${GITHUB_REPOSITORY##*/}.${DEPLOYMENT_ENVIRONMENT}.${BASE_DOMAIN}"}
  export APP_DOMAIN
}

group_start() {
  echo "::group::$1"
}

group_end() {
  echo "::endgroup::"
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

gen_helm_cmd() {
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
