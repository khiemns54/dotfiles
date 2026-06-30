#!/usr/bin/env bash

set -euo pipefail

if [[ -z "${TMUX:-}" ]]; then
  printf "Not inside tmux.\n"
  exit 1
fi

found=0
while IFS= read -r line; do
  session_name="${line%%:*}"
  rest="${line#*:}"
  window_index="${rest%%:*}"
  rest="${rest#*:}"
  window_name="${rest%%:*}"
  attention="${rest#*:}"

  if [[ "${attention}" == "1" ]]; then
    printf "%s:%s  %s\n" "${session_name}" "${window_index}" "${window_name}"
    found=1
  fi
done < <(tmux list-windows -a -F "#{session_name}:#{window_index}:#{window_name}:#{@opencode_attention}")

if [[ ${found} -eq 0 ]]; then
  printf "No windows currently require action.\n"
fi
