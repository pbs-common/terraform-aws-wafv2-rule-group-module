#!/usr/bin/env bash

# Unofficial bash strict mode: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY must be set. e.g. owner/repo}"

gh api -X GET "repos/$GITHUB_REPOSITORY/tags" -f 'per_page=1' --jq '.[0].name'
