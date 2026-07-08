#!/usr/bin/env bash

setup() {
  export AWS_ACCOUNT_ID="123456789012"
  export AWS_REGION="us-east-1"
  export GITHUB_REPOSITORY="acme/my-repo"
  export GITHUB_REF_NAME="staging"
  unset IMAGE
  unset TAG
}

test_get_image_name() {
  export TAG="my-custom-tag"
  assert_matches "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-repo:my-custom-tag" "$(../scripts/get-image-name.sh)"

  export IMAGE="my-custom-image-name"
  assert_matches "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-custom-image-name:my-custom-tag" "$(../scripts/get-image-name.sh)"

  unset TAG
  assert_matches "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-custom-image-name:staging" "$(../scripts/get-image-name.sh)"

  unset IMAGE
  assert_matches "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-repo:staging" "$(../scripts/get-image-name.sh)"
}
