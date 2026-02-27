#!/usr/bin/env bash

# Unofficial bash strict mode: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

GIT_ROOT=$(git rev-parse --show-toplevel)
pushd "$GIT_ROOT" >/dev/null

mkdir -p target
tar \
  --exclude='.git' \
  --exclude='target' \
  --exclude='tests' \
  --exclude='scripts' \
  --exclude='.github' \
  --exclude='examples' \
  -czf target/module.tar.gz .
