# Changelog

Fixes from the November 2026 review. Each was checked against FRR 10.2.1 and Alpine 3.20 containers in Docker. A full Containerlab deployment with veth links was not run (see "Not verified").

## Configs and topology — `4bc88d2`

| Problem | Impact | Fix |
|---------|--------|-----|
| Image `frrouting/frr:10.2.1` does not exist on Docker Hub | `containerlab deploy` failed on the first router | `quay.io/frrouting/frr:10.2.1` |
| Underlay 10.0.0.0/24 | Overlaps the usual VPC range 10.0.0.0/16, including this lab's EC2 VPC | Moved to 10.99.0.0/24 |
| `neighbor X route-reflector-client` on eBGP sessions | FRR rejects it (route reflection is iBGP-only) | Removed; eBGP re-advertises without it |
| BFD `peer X` / `minimum-ttl 1` for loopback peers | Rejected; no BFD sessions existed | `bfd profile FABRIC` bound to every BGP neighbor (multihop) |
| Router-level `passive-interface lo` | Rejected by FRR 10 | `ip ospf passive` on `interface lo` |
| `exec: frrinit.sh start` | FRR already runs from the image entrypoint; the extra start errored | Removed; optional frr_exporter start instead |
| Host init `apk add ... ping bash` | `ping` is not an Alpine package, so the install failed | `apk add iproute2 iputils` |
| Topology comment and docs listed a VyOS firewall `fw1` | No such node | Removed |

Verification: all 6 configs booted with no rejected lines (`frr-reload.py --test`); host init applied 10.10.1.1/24 and the default route.

## Ansible and monitoring — `9ecbc03`

| Problem | Impact | Fix |
|---------|--------|-----|
| Ansible used SSH | FRR and Alpine images have no sshd | `community.docker.docker` to `clab-netlab-<node>`; `requirements.yml` |
| Paths `$PWD/../configs/...` | Broke from the documented working directory | `playbook_dir`-relative |
| `copy` onto bind-mounted `frr.conf` | Failed with `EBUSY` | `unsafe_writes: true` |
| Handler `frrinit.sh reload` | Restarted watchfrr (PID 1's child), stopping the node | `frr-reload.py --reload` |
| Host pings used `command` | Alpine has no Python | `raw` module |
| gNMIc collector | FRR has no gNMI server; no metrics | frr_exporter on every router + Prometheus `file_sd` targets |
| Compose used external `clab-netlab-services`; deploy.sh created `clab-netlab-mgmt` without a subnet | Stack failed or Containerlab could not assign mgmt IPs | Compose creates `netlab-services`; Containerlab creates the mgmt network |
| Images `netenglabs/suzieq:0.22.1`, `astridyu/dnsmasq` missing | Pull failures | SuzieQ 0.25.0; dnsmasq on `alpine:3.20` |
| SuzieQ inventory in pre-0.16 format; Grafana `suzieq` datasource | Poller would not start; datasource plugin does not exist | Current format; datasource removed |
| All services always on, ports on 0.0.0.0, dnsmasq on host :53 | Wasted resources, exposed ports, resolver clash | Default Prometheus + Grafana; others are profiles; ports on 127.0.0.1 |

Verification: playbook run against FRR + Alpine containers named `clab-netlab-*` (stale config pushed and applied, node stayed up, rerun `changed=0`); `docker compose config`; Prometheus scraped frr_exporter on spine1 and leaf1.

## Documentation

README (Mermaid architecture replaces a misaligned ASCII sketch, working commands), IP plan (10.99.0.0/24, no RR, no VLAN IDs that the config never used, current service list), cost estimate, and new diagrams in `docs/diagrams/`.

## Not verified

Needs a real `containerlab deploy`: OSPF/BGP/BFD adjacencies over the veth links and host-to-host pings.
