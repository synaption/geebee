#!/bin/bash
# Build and start the geebee Docker container, then provision it with Ansible.
#
# Prerequisites on the host:
#   - docker (with compose plugin)
#   - ansible (pip install ansible  OR  apt install ansible)
#
# Usage:
#   ./docker-provision.sh                   # full provision
#   ./docker-provision.sh --tags voctomix   # only voctomix role
#   ./docker-provision.sh --check           # dry-run
#   ./docker-provision.sh --step            # step through tasks
#
# After provisioning:
#   docker exec -it geebee bash
#   docker exec geebee systemctl status videoteam-voctocore
#   docker compose logs -f
#   docker compose down     # stop and remove

set -euo pipefail
trap 'echo "ERROR: docker provisioning failed (line ${LINENO})." >&2' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> Building and starting geebee container..."
docker compose up -d --build

echo "==> Waiting for systemd to initialize..."
# Wait until systemd reaches 'running' or 'degraded'.  Degraded is expected
# because several units are masked (e.g. systemd-udevd) and some hardware
# services will not start inside a container.
ready=false
for i in $(seq 1 12); do
    state=$(docker exec geebee systemctl is-system-running 2>/dev/null || true)
    if [ "$state" = "running" ] || [ "$state" = "degraded" ]; then
        echo "    systemd is ${state}"
        ready=true
        break
    fi
    sleep 5
done

if [ "$ready" != "true" ]; then
    echo "ERROR: systemd did not reach running/degraded state in time."
    docker compose ps
    docker compose logs --no-color || true
    exit 1
fi

echo "==> Running Ansible provisioning (limit: gbdocker)..."
ansible-playbook \
    ansible/docker.yml \
    --inventory inventory/docker/hosts \
    --limit gbdocker \
    "$@"

echo ""
echo "==> Provisioning complete!  Container 'geebee' is running."
echo ""
echo "Useful commands:"
echo "  docker exec -it geebee bash"
echo "  docker exec geebee systemctl status videoteam-voctocore"
echo "  docker compose logs -f"
echo "  docker compose down"
