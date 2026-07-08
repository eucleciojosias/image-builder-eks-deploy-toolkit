#!/usr/bin/env bash

# shellcheck disable=SC1091
setup_suite() {
  source ../scripts/shared-funcs.sh
  source ./stub/aws.sh
  source ./stub/docker.sh
  source ./utils.sh
}

setup() {
  export AWS_ACCOUNT_ID="123456789012"
  export AWS_REGION="us-east-1"
  export GITHUB_REPOSITORY="acme/my-repo"
  export GITHUB_REF_NAME="staging"
  unset IMAGE
  unset TAG
  unset PR_NUMBER

  rm -f /tmp/aws_fake_params
  rm -f /tmp/docker_fake_params.json
  export docker_fake_params=""
}

test_get_image_name() {
  export TAG="my-custom-tag"
  assert_equals "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-repo:my-custom-tag" "$(get_image_name)"

  export IMAGE="my-custom-image-name"
  assert_equals "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-custom-image-name:my-custom-tag" "$(get_image_name)"

  unset TAG
  assert_equals "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-custom-image-name:staging" "$(get_image_name)"

  unset IMAGE
  assert_equals "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-repo:staging" "$(get_image_name)"
}

test_get_image_name_preview_app_by_pr_number() {
  export PR_NUMBER="42"
  assert_equals "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-repo:preview-42" "$(get_image_name)"

  # Preview tag takes precedence even when TAG is explicitly set
  export TAG="my-custom-tag"
  assert_equals "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-repo:preview-42" "$(get_image_name)"
}

test_get_image_name_without_pr_number_uses_ref() {
  unset PR_NUMBER
  assert_equals "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-repo:staging" "$(get_image_name)"
}

test_create_ecr_repo_if_not_exists_when_repo_exists() {
  fake aws _aws

  create_ecr_repo_if_not_exists

  read -r call < /tmp/aws_fake_params
  read -a aws_fake_params <<< "$call"
  assert_equals "ecr" "${aws_fake_params[0]}"
  assert_equals "describe-repositories" "${aws_fake_params[1]}"
  assert_equals "my-repo" "${aws_fake_params[3]}"

  # Should match tests/stub/aws.sh: only describe-repositories is called
  assert_equals "1" "$(wc -l < /tmp/aws_fake_params | tr -d ' ')"
}

test_create_ecr_repo_if_not_exists_when_repo_missing() {
  fake aws _aws

  # Should match tests/stub/aws.sh
  create_ecr_repo_if_not_exists "create-ecr-repo"

  assert_matches "create-repository" "$(cat /tmp/aws_fake_params)"
}

test_docker_login_ecr() {
  fake aws _aws
  fake docker _docker

  docker_login_ecr

  set_first_call_to_docker_params
  assert_equals "login" "$(get_docker_param 0)"
  assert_equals "--username AWS" "$(join_docker_params 1 2)"
  assert_equals "--password-stdin" "$(get_docker_param 3)"
  assert_equals "123456789012.dkr.ecr.us-east-1.amazonaws.com" "$(get_docker_param 4)"
}
