#!/usr/bin/env bash

_kubectl() {
  echo "${FAKE_PARAMS[@]}" >> /tmp/kubectl_fake_params
  case "${FAKE_PARAMS[0]}" in
    config)
      case "${FAKE_PARAMS[1]}" in
        current-context) echo "my-cluster" ;;
        view) echo "https://eks.example.com" ;;
      esac
      ;;
    logs) echo "pod log line" ;;
    *)
      echo "Invalid command: ${FAKE_PARAMS[0]}"
      echo "Valid commands are: config, logs"
      exit 1
      ;;
  esac
}
export -f _kubectl
