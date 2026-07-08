#!/usr/bin/env bash
set -e

logger_check_line() {
  line=$1
  echo "$line"

  if [[ "$line" == *"Deployment is not ready"* ]]; then
    touch /tmp/pod-output.log
    kubectl logs -l "app.kubernetes.io/instance=$RELEASE_NAME" \
      --all-containers=true \
      --namespace "$NAMESPACE" \
      --tail="$LOG_TAIL_LINES" > /tmp/pod-output.log 2>&1 || true
  fi
}

logger_print() {
  helm_output=$(cat "$HELM_OUTPUT_FILE")

  # Print error when container fails to start
  status_check_error="Error received when checking status of resource ${RELEASE_NAME}-${CHART##*/}."
  if [[ "$helm_output" == *"$status_check_error"* ]]; then
    cp /tmp/pod-output.log "$POD_OUTPUT_LOG_FILE"
    group_start "--- 🐛 Container Startup Failure Logs ---"
    echo "Detected container startup failure. Check the container logs:"
    cat "$POD_OUTPUT_LOG_FILE"
    group_end
  fi
}
