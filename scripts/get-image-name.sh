#!/usr/bin/env bash
set -e

image=${IMAGE:-${GITHUB_REPOSITORY##*/}}
tag=${TAG:-$GITHUB_REF_NAME}

echo "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${image}:${tag}"
