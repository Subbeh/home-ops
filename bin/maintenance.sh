#!/usr/bin/env bash

ROUTE_ID="$(cd "$HOMELAB_DIR/terraform/cloudflare" && terraform output -raw maintenance_route_id)"
ROUTE_PATTERN_ENABLED='*.sbbh.cloud/*'
ROUTE_PATTERN_DISABLED='maintenance.sbbh.cloud/*'
WORKER='maintenance-sbbh-cloud'

case "$1" in
  enable) route_pattern=${ROUTE_PATTERN_ENABLED:?not set} ;;
  disable) route_pattern=${ROUTE_PATTERN_DISABLED:?not set} ;;
  *)
    echo "usage: ./maintenance.sh [enable|disable]"
    exit 1
    ;;
esac

curl -X PUT "https://api.cloudflare.com/client/v4/zones/${CF_API_ZONE_ID:?not set}/workers/routes/${ROUTE_ID:?not set}" \
  -H "Authorization: Bearer ${CF_API_TOKEN:?not set}" \
  -H "Content-Type: application/json" \
  --data '{"pattern":"'"${route_pattern:?not set}"'","script":"'"${WORKER:?not set}"'"}'
