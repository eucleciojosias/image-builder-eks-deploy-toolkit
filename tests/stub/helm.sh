#!/usr/bin/env bash

_helm() {
  jq -c -n '$ARGS.positional' --args -- "${FAKE_PARAMS[@]}" >> /tmp/helm_fake_params.json
  case "${FAKE_PARAMS[0]}" in
    repo)
      case "${FAKE_PARAMS[1]}" in
        add) echo "\"${FAKE_PARAMS[2]}\" has been added to your repositories" ;;
        update) echo "Update Complete. Happy Helming!" ;;
      esac
      ;;
    template)
      echo "---"
      echo "# Source: templates/deployment.yaml"
      ;;
    upgrade)
      if [[ "$HELM_FAKE_UPGRADE_FAIL" == "1" ]]; then
        echo "Error: UPGRADE FAILED: context deadline exceeded"
      else
        echo "Release \"${FAKE_PARAMS[1]}\" has been upgraded. Happy Helming!"
        echo "STATUS: deployed"
      fi
      ;;
    *)
      echo "Invalid command: ${FAKE_PARAMS[0]}"
      echo "Valid commands are: repo, template, upgrade"
      exit 1
      ;;
  esac
}
export -f _helm
