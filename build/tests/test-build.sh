#!/usr/bin/env bash

# shellcheck disable=SC1091
setup_suite() {
  source ./stub/git.sh
  source ./stub/aws.sh
  source ./stub/docker.sh
  source ./utils.sh

  export ROOT_PATH="../scripts/"
}

setup() {
  export GITHUB_REPOSITORY="acme/my-repo"
  export GITHUB_REF_NAME="staging"
  export AWS_ACCOUNT_ID="123456789012"
  export AWS_REGION="us-east-1"

  rm -f /tmp/git_fake_params
  rm -f /tmp/aws_fake_params
  rm -f /tmp/docker_fake_params.json
  export docker_fake_params=""

  fake git _git
  fake aws _aws
  fake docker _docker
}

assert_git_params() {
  local git_config_called=false
  local git_describe_called=false
  local git_log_called=false
  local git_show_called=false

  while read -r call
  do
    read -a git_fake_params <<< "$call"
    case "${git_fake_params[0]}" in
      config)
        git_config_called=true
        assert_equals "--global" "${git_fake_params[1]}"
        assert_equals "--add" "${git_fake_params[2]}"
        assert_equals "safe.directory" "${git_fake_params[3]}"
        assert_equals "*" "${git_fake_params[4]}"
        ;;
      describe)
        git_describe_called=true
        assert_equals "--long" "${git_fake_params[1]}"
        assert_equals "--always" "${git_fake_params[2]}"
        assert_equals "--abbrev=8" "${git_fake_params[3]}"
        ;;
      log)
        git_log_called=true
        assert_equals "-1" "${git_fake_params[1]}"
        assert_equals "--pretty=format:%an" "${git_fake_params[2]}"
        ;;
      show)
        git_show_called=true
        assert_equals "-s" "${git_fake_params[1]}"
        assert_equals "--format=%ci" "${git_fake_params[2]}"
        ;;
      *)
        fail "Unexpected call: git ${git_fake_params[*]}"
      ;;
    esac
  done < /tmp/git_fake_params

  assert_equals true "$git_config_called"
  assert_equals true "$git_describe_called"
  assert_equals true "$git_log_called"
  assert_equals true "$git_show_called"
}

assert_ecr_params() {
  local ecr_describe_repo_called=false
  local ecr_create_repo_called=false
  local ecr_get_login_password_called=false
  local repo_slug="${GITHUB_REPOSITORY##*/}"

  while read -r call
  do
    read -a aws_fake_params <<< "$call"
    assert_equals "ecr" "${aws_fake_params[0]}"

    case "${aws_fake_params[1]}" in
      describe-repositories)
        ecr_describe_repo_called=true
        assert_equals "--repository-names" "${aws_fake_params[2]}"
        assert_equals "$repo_slug" "${aws_fake_params[3]}"
        ;;
      create-repository)
        ecr_create_repo_called=true
        assert_equals "--repository-name" "${aws_fake_params[2]}"
        assert_equals "$repo_slug" "${aws_fake_params[3]}"
        ;;
      get-login-password)
        ecr_get_login_password_called=true
        assert_equals "--region" "${aws_fake_params[2]}"
        assert_equals "us-east-1" "${aws_fake_params[3]}"
        ;;
      *)
        fail "Unexpected call: aws ${aws_fake_params[*]}"
        ;;
    esac
  done < /tmp/aws_fake_params

  assert_equals true "$ecr_describe_repo_called"
  assert_equals true "$ecr_get_login_password_called"
  # Should match tests/stub/aws.sh
  if [[ "$repo_slug" == "create-ecr-repo" ]]; then
    assert_equals true "$ecr_create_repo_called"
  fi
}

assert_docker_login_params() {
  set_first_call_to_docker_params
  assert_equals "login" "$(get_docker_param 0)"
  assert_equals "--username AWS" "$(join_docker_params 1 2)"
  assert_equals "--password-stdin" "$(get_docker_param 3)"
  assert_equals "123456789012.dkr.ecr.us-east-1.amazonaws.com" "$(get_docker_param 4)"
}

test_build_missing_required_envvars() {
  assert_matches "AWS_ACCOUNT_ID environment variable missing" "$(unset AWS_ACCOUNT_ID; "../scripts/build.sh" 2>&1)"
  assert_matches "AWS_REGION environment variable missing" "$(unset AWS_REGION; "../scripts/build.sh" 2>&1)"
}

test_build_app() {
  echo "FROM node:22" > Dockerfile

  "../scripts/build.sh" > /dev/null

  assert_git_params
  assert_ecr_params
  assert_docker_login_params

  set_last_call_to_docker_params
  assert_equals "build" "$(get_docker_param 0)"
  assert_equals "--no-cache" "$(get_docker_param 1)"
  assert_equals "--tag" "$(get_docker_param 2)"
  assert_equals "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-repo:staging" "$(get_docker_param 3)"
  # Should match tests/stub/git.sh
  assert_equals "--build-arg COMMIT_HASH=\"11ccc333\"" "$(join_docker_params 4 5)"
  assert_equals "--build-arg COMMIT_DATE=\"2025-05-21 18:07:33 -0300\"" "$(join_docker_params 6 7)"
  assert_equals "--build-arg COMMIT_AUTHOR=\"Acme Tester\"" "$(join_docker_params 8 9)"
  assert_equals "." "$(get_docker_param 10)"

  rm Dockerfile
}

test_build_creates_ecr_repo_when_missing() {
  # Should match tests/stub/aws.sh
  export GITHUB_REPOSITORY="acme/create-ecr-repo"

  echo "FROM node:22" > Dockerfile

  "../scripts/build.sh" > /dev/null

  assert_ecr_params

  rm Dockerfile
}
