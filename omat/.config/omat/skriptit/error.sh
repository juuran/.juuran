#!/bin/bash
function error() {
  [ -z "$*" ] && return
  >&2 echo -e "$(basename "$0"): $*"
}
