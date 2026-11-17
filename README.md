# Networking Lab

A fully declarative, version-controlled networking lab built entirely with free and open-source tools. Containerlab orchestrates FRR (FRRouting) containers in a spine-leaf topology with endpoint hosts and a monitoring/observability stack.

## Architecture

```
                ┌─────────┐         ┌─────────┐
                │ spine1  │═════════│ spine2  │    FRR routers
                │ 10.255.0.1 │      │ 10.255.0.2 │   OSPF + iBGP
                └────┬────┘         └────┬────┘
           ┌─────────┼─────────┐    ┌─────┼─────────┐
       ┌───┴───┐ ┌──┴───┐ ┌───┴──┐ ┌──┴───┐
       │ leaf1 │ │ leaf2│ │leaf3 │ │ leaf4│      FRR routers
       └───┬───┘ └───┬──┘ └──┬───┘ └──┬───┘
           │         │        │        │
       ┌───┴──┐ ┌──┴───┐ ┌──┴──┐ ┌──┴───┐
       │host-a│ │host-b│ │host-c│ │host-d│    Alpine hosts
       └──────┘ └──────┘ └──────┘ └──────┘
```

## Components

| Component | Tool | License |
|-----------|------|---------|
| Topology orchestration | Containerlab | BSD-3-Clause |
| Routers | FRRouting (FRR) | GPL-2.0 |
| Endpoint hosts | Alpine Linux | MIT |
| Automation | Ansible | GPL-3.0 |
| Metrics | Prometheus + Grafana | Apache-2.0 / AGPL-3.0 |
| Observability | Suzieq | Apache-2.0 |
| Config validation | Batfish | Apache-2.0 |
| Telemetry | gNMIc | BSD-3-Clause |
| DNS/DHCP | dnsmasq | GPL-2.0 |

## Quick Start

```bash
# Deploy the lab
containerlab deploy -t topology.clab.yml

# Verify connectivity
docker exec -it clab-netlab-host-a ping 10.10.3.1

# Start monitoring
cd monitoring && docker compose up -d

# Tear down
containerlab destroy -t topology.clab.yml --cleanup
```

See [docs/ip-addressing-plan.md](docs/ip-addressing-plan.md) for the full IP allocation and [docs/cost-estimate.md](docs/cost-estimate.md) for deployment costs.

## Requirements

- Linux host (Ubuntu 22.04+ / Debian 12)
- Docker Engine 24.0+
- Containerlab 0.55+
- 4+ vCPU, 16+ GB RAM, 50 GB disk

## License

MIT — see repository contents. All bundled tools retain their own licenses.
