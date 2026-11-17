#!/usr/bin/env bash
# NetworkLab deploy/destroy helpers.
#
# Usage:
#   scripts/deploy.sh [deploy]   lab + Prometheus/Grafana
#   scripts/deploy.sh destroy    lab + all monitoring containers
#   scripts/deploy.sh status
#
# Extra monitoring: MON_PROFILES="batfish dns" scripts/deploy.sh deploy

set -euo pipefail

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TOPO="${LAB_DIR}/topology.clab.yml"

compose() {
  local profiles=()
  for p in ${MON_PROFILES:-}; do profiles+=(--profile "$p"); done
  (cd "${LAB_DIR}/monitoring" && docker compose "${profiles[@]}" "$@")
}

case "${1:-deploy}" in
  deploy)
    [[ -x "${LAB_DIR}/bin/frr_exporter" ]] || echo "note: run scripts/fetch-frr-exporter.sh for FRR metrics"
    # Containerlab creates clab-netlab-mgmt (10.255.255.0/24) itself.
    sudo containerlab deploy -t "$TOPO" --reconfigure
    compose up -d
    echo "Grafana http://localhost:3000 (admin/admin)  Prometheus http://localhost:9090"
    sudo containerlab inspect -t "$TOPO"
    ;;
  destroy)
    MON_PROFILES="suzieq batfish dns" compose down || true
    sudo containerlab destroy -t "$TOPO" --cleanup
    ;;
  status)
    sudo containerlab inspect -t "$TOPO" || true
    MON_PROFILES="suzieq batfish dns" compose ps
    ;;
  *) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
