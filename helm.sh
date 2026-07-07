#!/usr/bin/env bash
set -e

export ROOT_PATH=${ROOT_PATH:-"/"}
export LOG_TAIL_LINES=${LOG_TAIL_LINES:-50}
export HELM_OUTPUT_FILE="/tmp/logger-helm-output.log"
export POD_OUTPUT_LOG_FILE="/tmp/logger-pod-output.log"

# Required
HELM_REPO=${HELM_REPO:?'HELM_REPO environment variable missing.'}
HELM_REPO_URL=${HELM_REPO_URL:?'HELM_REPO_URL environment variable missing.'}
CHART=${CHART:?'CHART environment variable missing.'}
NAMESPACE=${NAMESPACE:?'NAMESPACE environment variable missing.'}
AWS_REGION=${AWS_REGION:?'AWS_REGION environment variable missing.'}
CLUSTER_NAME=${CLUSTER_NAME:?'CLUSTER_NAME environment variable missing.'}

# shellcheck source=./shared-funcs.sh
source "${ROOT_PATH}shared-funcs.sh"

export RELEASE_NAME="${GITHUB_REPOSITORY##*/}-${GITHUB_REF_NAME}"

set_app_domain
set_kube_config
print_deploy_info

# HELM
echo "Starting deploy..."

helm repo add "$HELM_REPO" "$HELM_REPO_URL"
helm repo update

helm_template_cmd="$(generate_helm_cmd)"
echo "=============================================="
printf "%b\n" "${helm_template_cmd// --/ \\ \\n  --}"
echo "=============================================="
eval "$helm_template_cmd"

helm_cmd="$(generate_helm_cmd upgrade)"
echo "=============================================="
printf "%b\n" "${helm_cmd// --/ \\ \\n  --}"
echo "=============================================="

# shellcheck source=./eks-log-dumper.sh
source "${ROOT_PATH}eks-log-dumper.sh"

touch "$HELM_OUTPUT_FILE"
touch "$POD_OUTPUT_LOG_FILE"

eval "$helm_cmd 2>&1" | tee "$HELM_OUTPUT_FILE" | while read -r line; do logger_check_line "$line" ; done
helm_output=$(cat "$HELM_OUTPUT_FILE")
if [[ ! "$helm_output" == *"STATUS: deployed"* ]]; then
  logger_print
  exit 1
fi
