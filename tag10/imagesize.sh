#!/usr/bin/env bash
# imagesize.sh <repo> <tag> – komprimierte Größe eines ghcr.io-Images je Plattform,
# gelesen aus dem Registry-Manifest (nichts wird heruntergeladen).
set -euo pipefail
REPO="${1:-renovatebot/renovate}"; TAG="${2:-44.153.1}"
TOKEN=$(curl -s "https://ghcr.io/token?scope=repository:$REPO:pull" | jq -r .token)
get() { curl -s -H "Authorization: Bearer $TOKEN" -H "Accept: $1" \
  "https://ghcr.io/v2/$REPO/manifests/$2"; }
get application/vnd.oci.image.index.v1+json "$TAG" \
  | jq -r '.manifests[] | select(.platform.os == "linux")
           | "\(.platform.architecture) \(.digest)"' \
  | while read -r arch digest; do
      mb=$(get application/vnd.oci.image.manifest.v1+json "$digest" \
        | jq '[.layers[].size] | add / 1048576 | floor')
      echo "$REPO:$TAG $arch ${mb} MB (komprimiert)"
    done
