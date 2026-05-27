# SentinelCore Design System

> Reconstruct any LAN as a living, technological organism.
> Discover hosts via ARP-scan / nmap, render them as a graph of devices and
> thin connecting lines, and surface vulnerabilities in real time.

SentinelCore is a network discovery + vulnerability management product by
**Dognet Technologies**. Its signature surface — and the centre of this
design system — is the **Network Topology** view: device nodes drawn as
domain-specific icons (router, switch, firewall, database, NAS, etc.)
connected by thin minimal lines on a deep-navy canvas, with cyan as the
primary accent.

The system is intentionally restrained. Lines are hair-thin. Colour is
reserved for status, severity, and the brand cyan. The result reads as
professional infrastructure software — not as a gaming UI.

---

## Sources

This design system was built by reading the **SentinelCore frontend
codebase** directly. Anything ambiguous was resolved by lifting the values
straight out of source.

- **GitHub:** [Dognet-Technologies/sentinelcore](https://github.com/Dognet-Technologies/sentinelcore) @ `main`
- **Path of interest:** `vulnerability-manager-frontend/src/components/`
  - `NetworkTopology.tsx` — the flagship topology surface
  - `icons/DeviceIcons.tsx` — canonical device iconography
  - `network/NetworkTopologyView.tsx` — Cytoscape variant
  - `network/TerminalEmulator.tsx` — xterm.js terminal styling
  - `effects/ParticleBackground.tsx` — ambient motion (cyberpunk variant)
- **Theme files (single source of truth):**
  - `src/theme/entuityTheme.ts` — the primary theme used here (Entuity Dark
    Professional + Midnight Blue + Arctic Blue variants)
  - `src/theme/dognetTheme.ts` — pure-black corporate variant
  - `src/theme/themes.ts` — full theme registry

If you have access to the repository, explore those files directly to
extend or verify anything in this system.

---

## What you'll find in this folder

```
SentinelCore Design System/
├── README.md                ← you are here
├── SKILL.md                 ← agent skill manifest
├── colors_and_type.css      ← all design tokens as CSS vars
├── assets/
│   ├── logo.svg             ← hex mark
│   ├── wordmark.svg         ← lockup with tagline
│   ├── icons/               ← 11 device icons as standalone SVGs
│   └── source/
│       └── DeviceIcons.tsx  ← original React source (reference)
├── preview/                 ← Design System tab cards
└── ui_kits/
    └── network-topology/    ← high-fidelity recreation of the
                              ⌃ flagship NetworkTopology screen
```

---

## Content fundamentals

**Voice.** Italian-first, English UI. The product is built by an Italian
team — copy in the codebase mixes both languages freely. UI labels are
short, English, technical. Comments and longer-form copy lean Italian.
When in doubt, write English UI; preserve Italian only where the brand
voice demands it (e.g. marketing taglines).

**Tone.** Operator-grade. The reader is a SOC analyst or network engineer.
Skip filler. Skip exclamation marks. State facts: *"3 vulnerabilities found"*
not *"⚠️ Oh no! We found 3 issues!"*

**Casing.**
- Buttons & primary actions: **Title Case** — `Start Scan`, `Edit Device`,
  `Generate Remediation Plan`.
- Section headings & labels: **Title Case** — `Network Topology`,
  `Status Legend`, `Bulk Actions`.
- Tags / chip labels: **Title Case** with status counts — `3 Critical`,
  `89/127 Online`.
- Overlines / metadata: **UPPERCASE** with `0.08em` tracking — `STATUS`,
  `LAST SCAN`.
- IPs, ports, CVE IDs: **monospace, lowercase preserved** —
  `192.168.1.42`, `CVE-2024-1234`, `tcp/443`.

**Person.** Second person sparingly. Most copy is impersonal and
declarative: *"Connect via SSH or WinRM."* not *"You should connect…"*.

**Emoji.** Used very sparingly in the source — only as inline status hints
inside developer-facing strings (`📌 Drawing connection...`, `⚠ WARNING`).
**Don't use emoji in production UI.** Use icons or severity colours.

**Numerals.** Always tabular-nums. Always pair with unit:
`87%`, `1.2 Gbps`, `42 ms`, `12/24h`. Severity counts always show the
denominator when meaningful: `89/127 Online`.

**Vibe.** The vocabulary leans technical and slightly cinematic —
*"Sentinel Core Terminal Access"*, *"network discovery"*,
*"remediation plan"*. Avoid marketing slop ("supercharge", "magical").
Names of features are nouns, not verbs.

**Concrete examples from source.**
- `Network Topology` (page title)
- `89/127 Online` · `3 Critical` · `7 Warning` (status chips)
- `Ctrl+click: Multi-select | Drag: Move | Shift+Drag on link: Edit` (help text)
- `Connected to: 192.168.1.42` (terminal welcome)
- `[!] Found 3 vulnerabilities` (terminal output)
- `Generate Remediation Plan` (context menu action)

---

## Visual foundations

### Colour

The system is **dark by default**. The flagship surface is
`#0B1929` (`--sc-bg-default`), a deep desaturated navy. Cards sit one
step lighter at `#1A2B3C`. The single brand accent is **Entuity cyan**,
`#00A3E0` — used for primary actions, selection, focus rings, and the
"network is alive" pulse.

- **Surface stack** (deepest → highest):
  `#050B14` → `#0B1929` → `#102338` → `#1A2B3C` → `#1E3247`
- **Brand cyan:** ramp from `#E6F6FB` (50) through `#00A3E0` (500) to
  `#00455C` (900).
- **Severity** uses the canonical traffic-light palette inherited from the
  `entuityColors` source: Critical `#F44336`, High `#FF9800`, Warning
  `#FFC107`, Medium `#FFEB3B`, Low `#8BC34A`, Info `#2196F3`, Success
  `#4CAF50`.
- **Device status** mirrors severity for online/offline/maintenance, with
  `#757575` for unknown.

There is one light theme (Entuity Light Modern, `#F8FAFC` background, same
cyan primary) but it is **secondary**. Default everything to dark.

### Type

- **Sans (UI):** `Inter`, weights 400/500/600/700. Loaded from Google
  Fonts. Fallback to system stack.
- **Mono (IPs, code, terminal):** `JetBrains Mono` — substituted in this
  system from the codebase's request for `Roboto Mono` / `Menlo` because
  JetBrains Mono renders IPs and CIDR notation more clearly at small
  sizes. **Flag for the user:** swap to Roboto Mono if exact codebase
  parity matters.
- **Scale:** h1 40px / 700 → h6 16px / 600. Body 15.2px / 400. Captions
  12px. IP labels on topology nodes drop to 11px.
- **Tracking:** tight on display (`-0.02em`), wide on overlines
  (`+0.08em`). Never letter-spaced body.
- **Numerals:** `tabular-nums` everywhere — stats, IPs, ports, CVEs,
  percentages all need to align in columns.

### Spacing & rhythm

Strict 4px grid. Card padding is typically `--sc-space-6` (24px). Inline
chip + label rows use `--sc-space-2` (8px) gap. Section gutters are
`--sc-space-8` (32px). Don't free-pick values.

### Backgrounds

- **No gradients** in the primary theme. The Entuity Dark surfaces are
  flat colour fields. The only gradient in source is a subtle
  `linear-gradient(180deg, #1A2B3C, #0E1E2D)` on the navigation Drawer,
  and a `90deg #1A2B3C → #1E3247` on the AppBar — both so faint they
  read as flat surfaces with a directional lift.
- **No imagery.** No photography, no hand-drawn illustration, no
  textures. The product itself draws the topology graph — that *is* the
  imagery.
- **Ambient particles** exist in the optional `cyberpunk` theme only and
  are not used in the primary system. Don't add them.

### Borders

Thin. Almost-invisible. The codebase uses four border weights, all
white-with-alpha over the dark canvas:

- `rgba(255,255,255,0.05)` — card hairlines
- `rgba(255,255,255,0.08)` — drawer/appbar dividers
- `rgba(255,255,255,0.12)` — text-field idle
- `rgba(0,163,224,0.30)` — card hover, focus glow

Topology connecting lines between hosts are **1–2 px** with `opacity: 0.6`.
Dashed lines (`5,5`) indicate an inactive or pending link. This thinness
is non-negotiable per the brief: *"linee sottili minimali."*

### Shadows & glow

Three shadow tiers + a cyan glow used **only** for interactive lift:

- `--sc-shadow-1: 0 2px 8px rgba(0,0,0,0.25)` — resting card
- `--sc-shadow-2: 0 4px 12px rgba(0,0,0,0.30)` — raised card
- `--sc-shadow-3: 0 6px 16px rgba(0,0,0,0.35)` — popovers, dialogs
- `--sc-shadow-modal: 0 25px 50px -12px rgba(0,0,0,0.70)`
- `--sc-glow-cyan: 0 0 20px rgba(0,163,224,0.25)` — focus / selection
- `--sc-glow-critical: 0 0 12px rgba(244,67,54,0.55)` — critical pulse

No inset shadows. No drop shadows on text.

### Radii

- **0** — never (only the abandoned cyberpunk theme uses 0).
- **6px** — buttons, chips.
- **8px** — cards, dialogs, the topology canvas frame.
- **12px** — large hero cards (rare).
- **999px** — pill chips and the topology device-node circles.

### Hover & press states

- **Hover (cards / buttons):** border shifts to
  `rgba(0,163,224,0.30)`, shadow lifts one tier, plus the cyan glow.
  Background brightens by 1 surface step (`#1A2B3C` → `#1E3247`).
- **Hover (icon buttons):** background `rgba(255,255,255,0.04)`,
  no scale.
- **Press:** primary buttons darken to `--sc-cyan-700` (`#007FAD`).
  No scale, no shrink.
- **Active / Selected:** background `rgba(255,255,255,0.08)` for table
  rows; cyan border `2px` for cards; outer pulse ring for topology nodes.

### Focus

`outline: 2px solid var(--sc-primary)` with `outline-offset: 2px` plus
the cyan glow. Visible, never removed.

### Transitions

- Default: `200ms cubic-bezier(0.4, 0, 0.2, 1)` (Material standard).
- Card transforms: `300ms`.
- Zoom on topology SVG: `transform 0.3s ease`.
- **Pulse animation** for critical devices: `2s infinite`, radius
  expands from 20px → 22px, opacity 1 → 0.7 (defined in
  `NetworkTopology.tsx` as `pulse-animation`).
- **Glow animation** for critical icons: `2s infinite`, `drop-shadow`
  varies `4px → 8px`. No bounces. No spring. No exaggeration.

### Transparency & blur

Used only on:
- The AppBar (`backdrop-filter: blur(16px)` over an `alpha 0.85`
  background) — gives a frosted-glass feel on scroll.
- Modal scrims (50% black).
- The `cyberpunk` ambient particle canvas (`opacity: 0.3`) — *not* used
  in the primary system.

### Layout rules

- **Fixed app shell.** Left drawer (sidebar), top AppBar, content fills
  remainder. The shell is fixed; only the content scrolls.
- **Topology canvas** is always full-width inside its card. Toolbar
  pinned to top-right, legend pinned to bottom-right, help text pinned
  to top-left when in edit mode. None of these scroll.
- **Cards.** 1px hairline border + flat fill. No drop shadows by
  default; shadow appears on hover. Header is the card title plus
  status chips inline.

### Imagery & colour vibe

The graph IS the imagery. Where photographic imagery is needed
(rarely — login backgrounds, marketing pages), keep it cool, dark,
and lightly desaturated. No warm tones. No grain. The mood is
operations-centre, not lifestyle.

---

## Iconography

### Device icons (the brand's signature asset)

The codebase ships **eleven** custom SVG device icons in
`src/components/icons/DeviceIcons.tsx`. Each is a 48×48 viewbox,
colour-coded per device type, drawn with a flat-shape style + status
LEDs as small filled circles. These have been extracted into
`assets/icons/` as standalone SVGs:

| Icon | Body colour | Usage |
|------|-------------|-------|
| `router.svg` | `#1565C0` | Routers — 3-antenna form |
| `switch.svg` | `#0D47A1` | L2/L3 switches — port grid |
| `server.svg` | `#37474F` | Generic Linux/Windows server — rack |
| `firewall.svg` | `#D32F2F` | Firewall — shield + lock |
| `database.svg` | `#7B1FA2` | DB server — cylinder stack |
| `wireless.svg` | `#00BCD4` | WiFi AP / access point |
| `endpoint.svg` | `#546E7A` | Desktop / workstation |
| `storage.svg` | `#FF6F00` | NAS / SAN |
| `loadbalancer.svg` | `#6A1B9A` | Load balancer |
| `gateway.svg` | `#0288D1` | Gateway / VPN concentrator |
| `unknown.svg` | `#9E9E9E` | Unrecognised host |

These ARE the brand. Use them wherever a device is depicted.

### UI icons (Material Icons)

The codebase uses **`@mui/icons-material`** for UI affordances —
`ZoomIn`, `ZoomOut`, `Refresh`, `Fullscreen`, `Edit`, `Delete`,
`AccountTree`, `GridView`, `ViewWeek`, `Link`, `PlayArrow`, `Stop`,
`CenterFocusStrong`, etc. **For HTML mocks**, substitute with
[**Lucide**](https://lucide.dev) (`https://cdn.jsdelivr.net/npm/lucide@latest`)
— identical 24px / 1.5-stroke style. Flagged as a substitution.

Stroke icons (Lucide) are reserved for UI chrome. Filled, flat,
multicolour SVG (the device icons above) are reserved for graph
representation. **Don't mix these two languages.**

### Emoji & unicode

Used in source only inside developer-facing strings (terminal
welcome boxes, console help). **Never in production UI.** When you
need a glyph, use a Lucide icon or a coloured dot.

### Logos

- `assets/logo.svg` — 64×64 hex sigil. A hexagonal shield with four
  internal nodes connected by thin lines — visual rhyme with the
  topology graph. Cyan on navy.
- `assets/wordmark.svg` — 320×64 horizontal lockup: sigil + bold
  `SENTINEL` + light-tracked cyan `CORE` + mono tagline
  `NETWORK · DISCOVERY · DEFENSE`.

> **Flag:** the codebase's `public/logo*.png` were just default Create
> React App React-atom logos — the project has no real production
> logo. The mark + wordmark in this system are an original
> placeholder that fits the brief. **Replace with the real Dognet /
> SentinelCore logo when available.**

---

## UI kit index

| Kit | Path | What's in it |
|---|---|---|
| **Network Topology** (flagship) | `ui_kits/network-topology/` | The signature NetworkTopology screen — discovered hosts on a dark canvas, thin connecting lines, custom device icons, severity badges, status chips, side detail panel, scan toolbar |

---

## Known gaps / things to flag

1. **No real logo.** The mark and wordmark in `assets/` are placeholders
   that follow the brief. The codebase's `logo*.png` files are unmodified
   Create React App defaults.
2. **Font substitution.** Mono is `JetBrains Mono` rather than the
   codebase's `Roboto Mono` / `Menlo`. Easy swap if you want exact
   parity.
3. **No screenshots of the live product.** Every visual choice is
   reverse-engineered from theme files and component source. If you
   have screenshots of the deployed UI, drop them in — the system can
   absorb the corrections.
4. **One theme implemented.** The codebase has eight themes
   (`entuityLight`, `entuityDark`, `midnightBlue`, `arcticBlue`,
   `minimal`, `modernTech`, `cyberpunk`, `enterprise`). This system
   commits hard to `entuityDark` because it best matches the
   *"tecnologico, futuristico, professionalità"* brief. The other
   themes are documented in `src/theme/themes.ts` and easy to graft on
   later.

---

## How to use this system

If you're an agent (Claude or otherwise) building a SentinelCore
artifact:

1. Link `colors_and_type.css` and use the `--sc-*` tokens. Never
   hard-code colour or type.
2. For device representations, **always** use the SVG icons in
   `assets/icons/` — don't draw new ones.
3. For UI chrome icons, use Lucide via CDN at 24px stroke 1.5.
4. Open `ui_kits/network-topology/index.html` for a working reference
   of the flagship surface.
5. Read `SKILL.md` for the agent-skill manifest.
