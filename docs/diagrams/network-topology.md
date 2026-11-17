# Network Topology

One Containerlab lab (`topology.clab.yml`, lab name `netlab`): 2 spines, 4 leaves, 4 Alpine hosts. Containers are named `clab-netlab-<node>`.

## Spine-Leaf Fabric

```mermaid
graph TB
    subgraph SPINES["Spines — AS 65001"]
        S1["spine1<br/>Lo 10.255.0.1<br/>mgmt .11"]
        S2["spine2<br/>Lo 10.255.0.2<br/>mgmt .12"]
    end

    subgraph LEAVES["Leaves — one ASN each"]
        L1["leaf1<br/>AS 65101 · Lo 10.255.0.11"]
        L2["leaf2<br/>AS 65102 · Lo 10.255.0.12"]
        L3["leaf3<br/>AS 65103 · Lo 10.255.0.13"]
        L4["leaf4<br/>AS 65104 · Lo 10.255.0.14"]
    end

    subgraph HOSTS["Alpine hosts"]
        HA["host-a<br/>10.10.1.1/24"]
        HB["host-b<br/>10.10.2.1/24"]
        HC["host-c<br/>10.10.3.1/24"]
        HD["host-d<br/>10.10.4.1/24"]
    end

    S1 ===|"eth5 · 10.99.0.16/31"| S2
    S1 --- L1 & L2 & L3 & L4
    S2 --- L1 & L2 & L3 & L4
    L1 ---|"eth3 · gw .254"| HA
    L2 ---|"eth3 · gw .254"| HB
    L3 ---|"eth3 · gw .254"| HC
    L4 ---|"eth3 · gw .254"| HD

    style S1 fill:#4a90d9,color:#fff
    style S2 fill:#4a90d9,color:#fff
    style L1 fill:#5cb85c,color:#fff
    style L2 fill:#5cb85c,color:#fff
    style L3 fill:#5cb85c,color:#fff
    style L4 fill:#5cb85c,color:#fff
```

## Underlay /31 Links — 10.99.0.0/24

| Link | Spine side | Leaf side |
|------|-----------|-----------|
| spine1 eth1 ↔ leaf1 eth1 | 10.99.0.0/31 | 10.99.0.1/31 |
| spine1 eth2 ↔ leaf2 eth1 | 10.99.0.2/31 | 10.99.0.3/31 |
| spine1 eth3 ↔ leaf3 eth1 | 10.99.0.4/31 | 10.99.0.5/31 |
| spine1 eth4 ↔ leaf4 eth1 | 10.99.0.6/31 | 10.99.0.7/31 |
| spine2 eth1 ↔ leaf1 eth2 | 10.99.0.8/31 | 10.99.0.9/31 |
| spine2 eth2 ↔ leaf2 eth2 | 10.99.0.10/31 | 10.99.0.11/31 |
| spine2 eth3 ↔ leaf3 eth2 | 10.99.0.12/31 | 10.99.0.13/31 |
| spine2 eth4 ↔ leaf4 eth2 | 10.99.0.14/31 | 10.99.0.15/31 |
| spine1 eth5 ↔ spine2 eth5 | 10.99.0.16/31 | 10.99.0.17/31 |

## Networks on the Host

```mermaid
graph LR
    subgraph HOST["Containerlab host (Docker)"]
        MGMT["clab-netlab-mgmt<br/>10.255.255.0/24<br/>(created by Containerlab)"]
        SVC["netlab-services<br/>10.20.0.0/24<br/>(created by docker compose)"]
        DATA["Point-to-point veth links<br/>underlay 10.99.0.0/24<br/>hosts 10.10.0.0/16"]
    end

    MGMT --- R["spines .11 .12<br/>leaves .21–.24<br/>hosts .31–.34"]
    MGMT --- M["prometheus .41 · grafana .42<br/>suzieq .43 · dnsmasq .46"]
    SVC --- M
    DATA --- R

    style MGMT fill:#4a90d9,color:#fff
    style SVC fill:#e27d3a,color:#fff
    style DATA fill:#5cb85c,color:#fff
```
