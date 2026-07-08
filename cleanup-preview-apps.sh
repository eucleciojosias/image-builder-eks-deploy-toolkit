#!/usr/bin/env bash

export ROOT_PATH=${ROOT_PATH:-"./"}

NAMESPACE=${NAMESPACE:?'NAMESPACE environment variable missing.'}

# shellcheck source=./shared-funcs.sh
source "${ROOT_PATH}shared-funcs.sh"

host=https://api.github.com
owner="${GITHUB_REPOSITORY_OWNER}"
preview_apps=$(helm list -n "$NAMESPACE" --short --filter '-pr-')

get_pr_data() {
  repo_slug=$1
  pr_id=$2

  url="$host/repos/$owner/$repo_slug/pulls/$pr_id"
  response=$(curl -s "$url" \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github+json")

  echo "$response"
}

assure_ecr_lifecycle_policy() {
  repo_slug=$1

  check_policy=$(aws ecr get-lifecycle-policy --repository-name "$repo_slug" 2> /dev/null)
  if [[ -z "$check_policy" ]]
  then
    policy=$(cat ./preview-apps-ecr-lifecycle-policy.json)
    aws ecr put-lifecycle-policy --repository-name "$repo_slug" --lifecycle-policy-text "$policy"

    expire_days=$(echo "$policy" | jq -r '.rules[0].selection.countNumber')
    echo "Created: ECR lifecycle policy to remove $repo_slug preview apps tags after $expire_days days."
  fi
}

# Cleanup execution
for release_name in $preview_apps; do
  repo_slug=${release_name%%-*}
  pr_id=${release_name##*-}
  pr_data=$(get_pr_data "$repo_slug" "$pr_id")
  pr_state=$(echo "$pr_data" | jq -r .state)
  pr_branch=$(echo "$pr_data" | jq -r .head.ref)

  group_start "--- 🧹 Cleaning up $release_name ---"
  echo "HELM RELEASE: $release_name"
  echo "REPO SLUG: $repo_slug"
  echo "PR BRANCH: $pr_branch"
  echo "PR STATE: $pr_state"
  echo "PR ID: $pr_id"

  if [[ "$pr_state" != "null" ]] && [[ "$pr_state" != "open" ]]; then
    echo "Uninstalling $release_name..."

    assure_ecr_lifecycle_policy "$repo_slug"

    helm uninstall "$release_name" --wait --namespace "$NAMESPACE"
  fi
  group_end
done
