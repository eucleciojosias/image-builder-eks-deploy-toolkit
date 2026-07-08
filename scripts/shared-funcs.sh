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

create_ecr_repo_if_not_exists() {
  ecr_repo=${1:-${GITHUB_REPOSITORY##*/}}
  retval=$(aws ecr describe-repositories --repository-names "${ecr_repo}" 2>&1 || true)
  if [[ $retval == *"does not exist"* ]]; then
    aws ecr create-repository --repository-name "${ecr_repo}"
  fi
}

docker_login_ecr() {
  aws ecr get-login-password --region "${AWS_REGION}" | docker login \
    --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
}

get_image_name() {
  image=${IMAGE:-${GITHUB_REPOSITORY##*/}}
  tag=${TAG:-$GITHUB_REF_NAME}

  if [[ -n "$PR_NUMBER" ]]; then
    # Preview App
    tag="preview-${PR_NUMBER}"
  fi

  echo "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${image}:${tag}"
}
