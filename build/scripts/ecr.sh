#!/usr/bin/env bash

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
