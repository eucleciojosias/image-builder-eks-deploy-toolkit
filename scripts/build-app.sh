#!/usr/bin/env bash
set -e

# shellcheck source=./shared-funcs.sh
source "${ROOT_PATH}shared-funcs.sh"

commit_hash=$(git describe --long --always --abbrev=8)
commit_author=$(git log -1 --pretty=format:%an)
commit_date=$(git show -s --format=%ci)

image_name=$(get_image_name)
cmd="docker build --no-cache"
cmd="${cmd} --tag ${image_name}"
cmd="${cmd} --build-arg 'COMMIT_HASH=\"${commit_hash}\"'"
cmd="${cmd} --build-arg 'COMMIT_DATE=\"${commit_date}\"'"
cmd="${cmd} --build-arg 'COMMIT_AUTHOR=\"${commit_author}\"'"
cmd="${cmd} ."

echo "$cmd"
