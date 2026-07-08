#!/usr/bin/env bash

file_exists() {
  [ -f "$1" ] && echo "true" || echo "false"
}

dir_exists() {
  [ -d "$1" ] && echo "true" || echo "false"
}

first_call() {
  echo "$1" | head -n1
}

last_call() {
  echo "$1" | tail -n1
}

set_first_call_to_helm_params() {
  helm_fake_params=$(first_call "$(cat /tmp/helm_fake_params.json)")
  export helm_fake_params
}

set_last_call_to_helm_params() {
  helm_fake_params=$(last_call "$(cat /tmp/helm_fake_params.json)")
  export helm_fake_params
}

set_nth_call_to_helm_params() {
  if [[ -z "$1" ]]; then fail "First param can't be empty"; fi
  helm_fake_params=$(sed -n "$1p" /tmp/helm_fake_params.json)
  export helm_fake_params
}

get_helm_param() {
  if [[ -z "$helm_fake_params" ]]; then fail "helm_fake_params is not set"; fi
  if [[ -z "$1" ]]; then fail "First param can't be empty"; fi
  printf '%s' "$helm_fake_params" | jq -r ".[$1]"
}

join_helm_params() {
  if [[ -z "$helm_fake_params" ]]; then fail "helm_fake_params is not set"; fi
  if [[ -z "$1" ]] || [[ -z "$2" ]]; then fail "The first two params can't be empty"; fi
  printf '%s %s' "$(echo "$helm_fake_params" | jq -r ".[$1]")" "$(echo "$helm_fake_params" | jq -r ".[$2]")"
}

set_first_call_to_docker_params() {
  docker_fake_params=$(first_call "$(cat /tmp/docker_fake_params.json)")
  export docker_fake_params
}

set_last_call_to_docker_params() {
  docker_fake_params=$(last_call "$(cat /tmp/docker_fake_params.json)")
  export docker_fake_params
}

get_docker_param() {
  if [[ -z "$docker_fake_params" ]]; then fail "docker_fake_params is not set"; fi
  if [[ -z "$1" ]]; then fail "First param can't be empty"; fi
  printf '%s' "$docker_fake_params" | jq -r ".[$1]"
}

join_docker_params() {
  if [[ -z "$docker_fake_params" ]]; then fail "docker_fake_params is not set"; fi
  if [[ -z "$1" ]] || [[ -z "$2" ]]; then fail "The first two params can't be empty"; fi
  printf '%s %s' "$(echo "$docker_fake_params" | jq -r ".[$1]")" "$(echo "$docker_fake_params" | jq -r ".[$2]")"
}
