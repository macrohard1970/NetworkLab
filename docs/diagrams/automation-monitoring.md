# Automation and Monitoring

## Deploy and Configure

```mermaid
flowchart TB
    subgraph REPO["Repository"]
        TOPO["topology.clab.yml"]
        FRR["configs/frr/&lt;node&gt;/<br/>frr.conf · daemons · vtysh.conf"]
        HOSTS["configs/hosts/host-*.init.sh"]
        BIN["bin/frr_exporter<br/>(scripts/fetch-frr-exporter.sh)"]
        INV["automation/ansible/inventory.yml"]
        MON["monitoring/docker-compose.yml"]
    end

    SCRIPT["scripts/deploy.sh<br/>deploy | destroy | status"]

    subgraph RUNTIME["Containerlab host"]
        CLAB["clab-netlab-* containers<br/>mgmt network clab-netlab-mgmt"]
        STACK["netlab-prometheus + netlab-grafana<br/>(+ optional profiles)"]
    end

    ANS["ansible-playbook playbooks/deploy-configs.yml"]

    SCRIPT -->|"1. containerlab deploy --reconfigure"| CLAB
    TOPO --> CLAB
    FRR -->|"bind-mounted"| CLAB
    HOSTS -->|"exec at start"| CLAB
    BIN -->|"bind-mounted, started by exec"| CLAB
    SCRIPT -->|"2. docker compose up -d"| STACK
    MON --> STACK
    INV --> ANS
    FRR --> ANS
    ANS -->|"later edits: docker exec,<br/>copy + frr-reload.py, verify"| CLAB
```

## Ansible Plays

```mermaid
sequenceDiagram
    participant A as Ansible (community.docker.docker)
    participant R as routers (clab-netlab-spine*/leaf*)
    participant S as spines
    participant H as hosts_group (Alpine, raw)

    A->>R: vtysh "show version"
    A->>R: copy frr.conf + daemons (unsafe_writes: bind mounts)
    R-->>A: frr.conf changed → frr-reload.py --reload (node stays up)
    A->>S: vtysh "show ip bgp summary"
    A->>R: vtysh "show ip ospf neighbor"
    A->>H: ping gateway, ping host-c 10.10.3.1
```

## Monitoring Data Flow

```mermaid
flowchart LR
    subgraph FABRIC["FRR nodes (mgmt 10.255.255.0/24)"]
        EXP["frr_exporter :9342<br/>in spine1/2, leaf1–4"]
    end
    TGT[("prometheus/targets/frr.yml")]
    PROM["netlab-prometheus<br/>15 s scrape · 7 d retention<br/>127.0.0.1:9090"]
    GRAF["netlab-grafana<br/>127.0.0.1:3000"]
    SUZ["netlab-suzieq<br/>--profile suzieq<br/>(needs sshd on nodes)"]
    BAT["netlab-batfish<br/>--profile batfish<br/>offline config analysis"]
    DNS["netlab-dnsmasq<br/>--profile dns<br/>*.lab.internal"]

    TGT -->|"file_sd"| PROM
    EXP -->|"/metrics"| PROM
    PROM --> GRAF
    FABRIC -.->|"SSH"| SUZ
    DNS -.-> FABRIC

    style PROM fill:#d9534f,color:#fff
    style GRAF fill:#e27d3a,color:#fff
    style EXP fill:#f0ad4e,color:#fff
```

Only Prometheus and Grafana start by default. Ports bind to 127.0.0.1; from another machine use `ssh -L 3000:localhost:3000 -L 9090:localhost:9090 <lab-host>`.
