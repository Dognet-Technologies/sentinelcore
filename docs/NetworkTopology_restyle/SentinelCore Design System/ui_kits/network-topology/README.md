# Network Topology — UI kit

The flagship SentinelCore screen, recreated as a clickable React prototype.
Mirrors `src/components/NetworkTopology.tsx` from the source codebase, with
the visual system locked to **Entuity Dark Professional**.

## What this kit demonstrates

- **Full app shell** — top AppBar (logo, breadcrumb, search, scan, alerts,
  user) + collapsed icon-rail Sidebar.
- **Topology canvas** — SVG renderer with:
  - subnet group boxes (192.168.1.0/24 DMZ, 10.0.0.0/24 DATA, 172.16.0.0/24 CLIENTS)
  - thin connecting lines coloured by link utilization (≥90 % red, ≥70 % orange, < 70 % green, down dashed grey)
  - animated dash-flow on high-utilization links
  - custom SVG device icons (router, switch, server, firewall, database, wireless, endpoint, storage, load balancer, gateway, unknown) over a white inner disc + severity halo
  - critical-pulse animation on hosts with critical vulns
  - vulnerability + incident + risk-score badges per node
  - selection highlight with cyan halo
- **Detail panel** — slides in on the right when a device is clicked.
  Shows identity, risk meter, CVE list with severity-coded left border,
  open ports, last scan, and action buttons.
- **Toolbar** — view-mode toggle (grid / hierarchical / circular), zoom,
  fit, terminal, run-scan, refresh, export, fullscreen.
- **Scan terminal** — bottom overlay xterm-style log that streams scan
  output in real time when "Run scan" is clicked.
- **HUD overlays** — help text, live stats, status legend, zoom indicator
  on the canvas itself.

## How to interact

| Try | What happens |
|-----|--------------|
| Click any device | Detail panel slides in on the right |
| Click empty canvas | Detail panel closes |
| Click the play icon in the toolbar | Scan terminal streams in fake output |
| Click the terminal icon | Toggle terminal overlay |
| Click zoom in / out / fit | Canvas scales smoothly |
| Click `web-prod-01`, `db-master`, or `fw-edge` | Detail panel shows real-looking CVE data |

## Files

```
network-topology/
├── index.html          ← entry point — open this
├── app.css             ← all styling, uses --sc-* tokens from the system
├── data.jsx            ← mock LAN (16 devices, 18 links, 3 subnets)
├── AppShell.jsx        ← AppBar, Sidebar, inline Lucide-style Icon component
├── TopologyCanvas.jsx  ← the SVG renderer + DeviceNode
├── DetailPanel.jsx     ← right slide-in panel + RiskMeter + VulnRow
└── ScanTerminal.jsx    ← bottom overlay terminal
```

All JSX is plain React 18 + Babel standalone — no build step.

## What's intentionally simplified

This is a **visual recreation**, not a working scanner:

- No real ARP / nmap probing — the data is static in `data.jsx`.
- No drag-to-rearrange of nodes (the layout is laid out manually for a
  clean topology shape).
- No persistent custom connections.
- No multi-select / bulk-action dialogs (the source has these — easy
  to graft on; the visual primitives are in the design system).
- The view-mode toggle is wired but only the `grid` layout is computed;
  swapping to hierarchical / circular would just re-position the
  existing nodes.

## Source reference

Lifted from `Dognet-Technologies/sentinelcore @ main`:
- `vulnerability-manager-frontend/src/components/NetworkTopology.tsx`
- `vulnerability-manager-frontend/src/components/icons/DeviceIcons.tsx`
- `vulnerability-manager-frontend/src/theme/entuityTheme.ts`
