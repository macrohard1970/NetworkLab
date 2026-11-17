# Monitoring

Start after `topology.clab.yml` is deployed (Containerlab creates the
`clab-netlab-mgmt` network the stack joins):

```bash
cd monitoring
docker compose up -d
```

| Service | Default | Container | Mgmt IP | Services IP | Host port (127.0.0.1) |
|---------|---------|-----------|---------|-------------|-----------------------|
| Prometheus | on | `netlab-prometheus` | 10.255.255.41 | 10.20.0.10 | 9090 |
| Grafana | on | `netlab-grafana` | 10.255.255.42 | 10.20.0.11 | 3000 |
| SuzieQ poller | `--profile suzieq` | `netlab-suzieq` | 10.255.255.43 | 10.20.0.12 | — |
| Batfish | `--profile batfish` | `netlab-batfish` | — | 10.20.0.13 | 9996 |
| dnsmasq | `--profile dns` | `netlab-dnsmasq` | 10.255.255.46 | 10.20.0.15 | — (not published) |

Grafana login is `admin` / `admin` unless `GRAFANA_ADMIN_PASSWORD` is exported
before `docker compose up`.

## Metrics: frr_exporter

Every FRR node runs [frr_exporter](https://github.com/tynany/frr_exporter) on
`:9342` if `bin/frr_exporter` exists when the topology is deployed:

```bash
scripts/fetch-frr-exporter.sh      # once, before containerlab deploy
```

Prometheus reads its targets from `prometheus/targets/frr.yml` (6 FRR nodes,
labelled `device` and `role`). Metrics include BGP peer state and prefixes,
OSPF neighbors, BFD peer state and route counts. A ready-made Grafana
dashboard is published as ID
[22943](https://grafana.com/grafana/dashboards/22943-frr-exporter-bgp/)
(Dashboards → Import).

This replaces gNMIc: FRR has no OpenConfig gNMI server, so gNMIc had nothing
to subscribe to.

## Batfish (optional)

```bash
mkdir -p batfish/snapshots/netlab/configs
for d in ../configs/frr/*/; do cp "$d/frr.conf" "batfish/snapshots/netlab/configs/$(basename "$d").cfg"; done
docker compose --profile batfish up -d
pip install pybatfish
python3 - <<'PY'
from pybatfish.client.session import Session
bf = Session(host="localhost")
bf.set_network("netlab")
bf.init_snapshot("batfish/snapshots/netlab", name="netlab", overwrite=True)
print(bf.q.initIssues().answer().frame())
print(bf.q.bgpSessionCompatibility().answer().frame())
PY
```

## SuzieQ (optional)

SuzieQ polls over SSH, and the FRR image has no SSH server. To use it:

1. Put a key pair in `suzieq/ssh/` (`id_ed25519`, git-ignored).
2. On each FRR node: `apk add openssh`, add the public key to
   `/root/.ssh/authorized_keys`, run `ssh-keygen -A && /usr/sbin/sshd`.
3. `docker compose --profile suzieq up -d`
