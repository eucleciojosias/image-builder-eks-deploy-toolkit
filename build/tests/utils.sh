#!/usr/bin/env bash

first_call() {
  echo "$1" | head -n1
}

last_call() {
  echo "$1" | tail -n1
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
