#!/usr/bin/env bash

_git() {
  echo "${FAKE_PARAMS[@]}" >> /tmp/git_fake_params
  case "${FAKE_PARAMS[0]}" in
    config) echo "Safe directory added" ;;
    describe) echo "11ccc333" ;;
    log) echo "Acme Tester" ;;
    show) echo "2025-05-21 18:07:33 -0300" ;;
    *)
      echo "Invalid command: ${FAKE_PARAMS[0]}"
      echo "Valid commands are: config, describe, log, show"
      exit 1
    ;;
  esac
}
export -f _git
