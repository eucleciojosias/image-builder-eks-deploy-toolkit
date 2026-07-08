#!/usr/bin/env bash
set -e

export ROOT_PATH=${ROOT_PATH:-"/"}

AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID:?'AWS_ACCOUNT_ID environment variable missing.'}
AWS_REGION=${AWS_REGION:?'AWS_REGION environment variable missing.'}

git config --global --add safe.directory '*'

# shellcheck source=./ecr.sh
source "${ROOT_PATH}ecr.sh"

create_ecr_repo_if_not_exists
docker_login_ecr

echo "Building image..."

cmd="$(${ROOT_PATH}build-app.sh)"

echo "::group::--- 📄 Docker Build Command ---"
cat Dockerfile
printf "%b\n" "${cmd// --/ \\ \\n --}"
echo "::endgroup::"

eval "$cmd"
