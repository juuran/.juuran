#!/bin/bash
function error() {
  >&2 echo -e "$(basename "$0"): $*"
}
