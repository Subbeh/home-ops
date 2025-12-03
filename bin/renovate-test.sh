#!/usr/bin/env bash

set -eo pipefail

export LOG_LEVEL=debug
export RENOVATE_TOKEN=${GITHUB_TOKEN:?not set}
renovate --dry-run Subbeh/home-ops 2>&1 | tee "${HOMELAB_DIR:?not set}/.temp/renovate-test.log"
