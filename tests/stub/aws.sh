#!/usr/bin/env bash

_aws() {
  echo "${FAKE_PARAMS[@]}" >> /tmp/aws_fake_params
  case "${FAKE_PARAMS[0]}" in
    eks)
      case "${FAKE_PARAMS[1]}" in
        update-kubeconfig) echo "Updated context in ~/.kube/config" ;;
        *)
          echo "Invalid eks command: ${FAKE_PARAMS[1]}"
          exit 1
          ;;
      esac
      ;;
    *)
      echo "Invalid command: ${FAKE_PARAMS[0]}"
      echo "Valid commands are: eks"
      exit 1
      ;;
  esac
}
export -f _aws
