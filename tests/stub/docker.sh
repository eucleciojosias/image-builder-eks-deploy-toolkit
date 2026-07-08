#!/usr/bin/env bash

_docker() {
  jq -c -n '$ARGS.positional' --args -- "${FAKE_PARAMS[@]}" >> /tmp/docker_fake_params.json
  case "${FAKE_PARAMS[0]}" in
    build)
      echo "[+] Building 1.2s"
    ;;
    login) echo "Login Succeeded" ;;
    *)
      echo "Invalid command: ${FAKE_PARAMS[0]}"
      echo "Valid commands are: build, login"
      exit 1
    ;;
  esac
}
export -f _docker
