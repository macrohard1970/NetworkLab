# Routing: OSPF Underlay, BGP Overlay, BFD

## Control Plane Layers

```mermaid
flowchart TB
    subgraph OSPF["OSPF area 0 — underlay"]
        O1["All /31 links (point-to-point)"]
        O2["Loopbacks 10.255.0.0/24<br/>(ip ospf passive on lo)"]
    end
    subgraph BGP["BGP — overlay between loopbacks"]
        B1["spine1 ⇄ spine2: iBGP AS 65001"]
        B2["each leaf ⇄ both spines: eBGP<br/>ebgp-multihop 2, update-source lo"]
    end
    subgraph BFD["BFD — profile FABRIC"]
        F1["one session per BGP neighbor<br/>300 ms × 3 = 900 ms detection<br/>multihop (loopback peers)"]
    end
    OSPF -->|"loopback reachability"| BGP
    BGP -->|"neighbor X bfd profile FABRIC"| BFD
```

## BGP Peering

```mermaid
graph TB
    S1["spine1<br/>AS 65001"] ===|"iBGP"| S2["spine2<br/>AS 65001"]
    S1 -->|"eBGP"| L1["leaf1 · AS 65101<br/>10.10.1.0/24"]
    S1 -->|"eBGP"| L2["leaf2 · AS 65102<br/>10.10.2.0/24"]
    S1 -->|"eBGP"| L3["leaf3 · AS 65103<br/>10.10.3.0/24"]
    S1 -->|"eBGP"| L4["leaf4 · AS 65104<br/>10.10.4.0/24"]
    S2 -->|"eBGP"| L1
    S2 -->|"eBGP"| L2
    S2 -->|"eBGP"| L3
    S2 -->|"eBGP"| L4

    style S1 fill:#4a90d9,color:#fff
    style S2 fill:#4a90d9,color:#fff
```

Spines peer with leaves over eBGP, which re-advertises routes by itself, so no route reflection is needed. Each leaf advertises its host /24 and its loopback; spines set `next-hop-self`.

## Packet Path: host-a → host-c

```mermaid
sequenceDiagram
    participant A as host-a 10.10.1.1
    participant L1 as leaf1
    participant S as spine1 / spine2
    participant L3 as leaf3
    participant C as host-c 10.10.3.1

    A->>L1: default route via 10.10.1.254
    Note over L1: 10.10.3.0/24 learned from both spines (eBGP, ECMP)
    L1->>S: /31 uplink, next hop = spine loopback (resolved by OSPF)
    S->>L3: 10.10.3.0/24 learned from leaf3
    L3->>C: connected 10.10.3.0/24 on eth3
```

## Failure Handling

| Failure | Detection | Result |
|---------|-----------|--------|
| One spine | BFD ~900 ms on every leaf | Leaves use the remaining spine |
| One spine-leaf link | OSPF + BFD | Traffic to that leaf goes via the other spine |
| One leaf | BFD on both spines | Its host /24 is withdrawn (hosts are single-homed) |
