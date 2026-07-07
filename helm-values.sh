#!/usr/bin/env bash
set -e

repo_slug="${GITHUB_REPOSITORY##*/}"
image_name="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${repo_slug}"

custom_values_list=""

custom_values_list="${custom_values_list} --set siteCommit=$GITHUB_SHA-$GITHUB_RUN_NUMBER"
custom_values_list="${custom_values_list} --set image.repository=$image_name"
custom_values_list="${custom_values_list} --set image.tag=$GITHUB_REF_NAME"

echo "$custom_values_list"
