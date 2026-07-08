#!/usr/bin/env bash

_ecr() {
  case "${FAKE_PARAMS[1]}" in
    get-login-password) echo "my-hash" ;;
    describe-repositories)
      repo_name="${FAKE_PARAMS[3]}"
      if [[ "$repo_name" == "create-ecr-repo" ]]; then
        echo "The repository with name 'create-ecr-repo' does not exist in the registry"
        return 1
      fi

      echo '{"repositories": [ {"repositoryName": "my-repo"}]}'
      ;;
    create-repository) echo '{"repositories": [ {"repositoryName": "my-repo"}]}' ;;
  esac
}
export -f _ecr

_aws() {
  echo "${FAKE_PARAMS[@]}" >> /tmp/aws_fake_params
  case "${FAKE_PARAMS[0]}" in
    ecr) _ecr ;;
    *)
      echo "Invalid command: ${FAKE_PARAMS[0]}"
      echo "Valid commands are: ecr"
      exit 1
    ;;
  esac
}
export -f _aws
