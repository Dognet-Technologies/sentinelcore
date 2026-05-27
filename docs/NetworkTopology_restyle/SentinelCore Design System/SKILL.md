---
name: sentinelcore-design
description: Use this skill to generate well-branded interfaces and assets for SentinelCore (the network discovery + vulnerability management product by Dognet Technologies), either for production or throwaway prototypes / mocks / decks. Contains essential design guidelines, colors, type, fonts, assets, and a high-fidelity UI kit for the flagship Network Topology screen.
user-invocable: true
---

# SentinelCore Design Skill

Read `README.md` first — it documents the brand, voice, visual foundations,
iconography, and where every asset lives. Then explore:

- `colors_and_type.css` — every design token as a `--sc-*` CSS variable.
  Link this file in any HTML you produce; never hard-code colour or type.
- `assets/icons/` — 11 device icon SVGs (router, switch, server, firewall,
  database, wireless, endpoint, storage, loadbalancer, gateway, unknown).
  Use these wherever a device is depicted. Don't invent new ones.
- `assets/logo.svg` + `assets/wordmark.svg` — sigil + lockup.
- `ui_kits/network-topology/` — high-fidelity recreation of the flagship
  screen. Open `index.html` for a working reference; read the JSX files
  for component patterns (DeviceNode, DetailPanel, ScanTerminal, AppShell).
- `preview/` — small specimen cards covering type, colour, spacing,
  components, brand.

## When the user invokes this skill

If creating visual artifacts (slides, mocks, throwaway prototypes,
landing pages, status boards, etc): **copy the assets you need out of
`assets/` into the new artifact's folder** and build static HTML against
`colors_and_type.css`. Lean on the patterns in `ui_kits/` rather than
inventing fresh ones.

If working on production code: read the rules in `README.md` (Voice,
Visual Foundations, Iconography sections) and use them as you would a
brand-bible. Component recipes in `ui_kits/network-topology/*.jsx` are
illustrative — port them to the project's actual framework.

If the user invokes the skill without further guidance, ask what they
want to build and what surface (Topology, Dashboard, Reports, Login,
etc.). Ask about audience, fidelity, and whether they want variations.
Then act as an expert designer who outputs HTML artifacts **or**
production code, depending on the need.

## Quick rules to keep in mind

- **Dark by default.** Surface stack: `--sc-bg-deep` → `--sc-bg-default`
  → `--sc-bg-paper`. Light theme exists in source but is secondary.
- **One brand colour.** Cyan `#00A3E0` (`--sc-primary`). Use it for
  primary actions, selection, focus, and the "alive" pulse. Don't add
  purples, pinks, or gradients to the primary surfaces.
- **Severity is canonical.** Critical red, High orange, Warning amber,
  Medium yellow, Low light-green, Info blue, Success green. Use these
  exact hexes (`--sc-critical` etc).
- **Lines are thin.** Topology connections are 1–2 px with 0.6 opacity.
  Card borders are `rgba(255,255,255,0.05–0.12)`. Never thicker.
- **No emoji in production UI.** Use Lucide icons (CDN) for chrome,
  device SVGs for hosts.
- **Tabular nums everywhere** stats, IPs, ports, CVE IDs are involved.
- **Inter for UI, JetBrains Mono for IPs/code.** Load from Google
  Fonts (already linked in `colors_and_type.css`).
- **Subtle motion only.** 200ms standard, 300ms for card transforms.
  The only loops are the 2 s critical-pulse and the dash-flow on
  high-utilization links. No bounces, no springs.

## Voice cheat sheet

- Operator-grade, not marketing-fluffy.
- Title Case for actions, UPPERCASE + tracking for overlines, mono for
  technical identifiers (IPs, CVEs, ports).
- Italian comments in the codebase are fine; UI copy is English.
- Numbers pair with units (`87%`, `1.2 Gbps`, `89/127 Online`).
