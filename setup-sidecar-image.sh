#!/usr/bin/env bash
# A local registry is needed because miniflare unconditionally `docker pull`s the egress
# image, so a local-only tag is rejected ("pull access denied").
#
# Consumers point at the result with:
#   MINIFLARE_CONTAINER_EGRESS_IMAGE=localhost:5000/proxy-everything:transparent-divert
set -euo pipefail

cd "$(dirname "$0")"

IMAGE=${IMAGE:-localhost:5000/proxy-everything:transparent-divert}
REGISTRY_NAME=${REGISTRY_NAME:-cf-local-registry}

if ! docker ps --format '{{.Names}}' | grep -qx "$REGISTRY_NAME"; then
  echo "==> starting local registry ($REGISTRY_NAME)"
  docker rm -f "$REGISTRY_NAME" >/dev/null 2>&1 || true
  docker run -d --restart unless-stopped -p 5000:5000 --name "$REGISTRY_NAME" registry:2 >/dev/null
  sleep 2
fi

echo "==> building $IMAGE from $(git rev-parse --abbrev-ref HEAD)"
docker build -t "$IMAGE" .
docker push "$IMAGE"
echo "==> done"
