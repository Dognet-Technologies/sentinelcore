/* NodeVariants.jsx — alternative visual treatments for topology hosts.
   Each renders a different aesthetic; all share the same badge + label layout. */

// ---------------------------------------------------------------------------
//  HEX  — beveled hexagonal tile with glass-shine gradient. Rhymes with the
//  SentinelCore sigil (which is hexagonal). Single most "operations centre".
// ---------------------------------------------------------------------------
function HexNode({ device, selected, isCritical, sev, status, meta }) {
  const c = meta.color;
  // Hex points: pointed-top, ~24px radius
  const HEX = "0,-26 22.5,-13 22.5,13 0,26 -22.5,13 -22.5,-13";
  const HEX_SEL = "0,-32 27.7,-16 27.7,16 0,32 -27.7,16 -27.7,-16";
  const HEX_PULSE = "0,-28 24.2,-14 24.2,14 0,28 -24.2,14 -24.2,-14";
  return (
    <g>
      {/* ground shadow */}
      <polygon points={HEX} fill="#000" opacity="0.55"
               transform="translate(0, 4)" filter="url(#nv-blur)"/>
      {/* color base */}
      <polygon points={HEX} fill={c} fillOpacity="0.78"/>
      {/* glass shine overlay */}
      <polygon points={HEX} fill="url(#nv-glass-shine)"/>
      {/* faint cyan inner border for tech feel */}
      <polygon points={HEX} fill="none" stroke="rgba(255,255,255,0.22)" strokeWidth="0.75"/>
      {/* status outer ring */}
      <polygon points={HEX} fill="none" stroke={status}
               strokeWidth={selected ? 2.5 : 1.5} strokeOpacity="0.9"/>
      {/* selection halo */}
      {selected && (
        <polygon points={HEX_SEL} fill="none"
                 stroke="#00A3E0" strokeWidth="1" opacity="0.55"/>
      )}
      {/* critical pulse */}
      {isCritical && (
        <polygon points={HEX_PULSE} fill="none" stroke={sev}
                 strokeWidth="1" className="node-pulse-poly"/>
      )}
      {/* icon — washed to white silhouette so it reads cleanly on colored hex */}
      <image href={`${ICON_SRC}${device.type}.svg`}
             x="-15" y="-15" width="30" height="30"
             style={{ filter: 'brightness(0) invert(1) drop-shadow(0 1px 1px rgba(0,0,0,0.5))', opacity: 0.95 }}/>
    </g>
  );
}

// ---------------------------------------------------------------------------
//  ORB  — glass sphere with radial highlight + dark rim. Most "3D".
// ---------------------------------------------------------------------------
function OrbNode({ device, selected, isCritical, sev, status, meta }) {
  const c = meta.color;
  return (
    <g>
      {/* contact shadow */}
      <ellipse cy="28" rx="20" ry="4" fill="#000" opacity="0.55"
               filter="url(#nv-blur)"/>
      {/* base color sphere */}
      <circle r="23" fill={c} fillOpacity="0.85"/>
      {/* dark rim (bottom-right falloff) */}
      <circle r="23" fill="url(#nv-orb-rim)"/>
      {/* specular gradient (top-left light source) */}
      <circle r="23" fill="url(#nv-orb-light)"/>
      {/* tight highlight */}
      <ellipse cx="-8" cy="-11" rx="6.5" ry="3.2" fill="#fff" opacity="0.45"/>
      {/* secondary smaller highlight */}
      <ellipse cx="-6" cy="-9" rx="2.5" ry="1.4" fill="#fff" opacity="0.7"/>
      {/* status thin halo (very subtle outside the orb) */}
      <circle r="24.5" fill="none" stroke={status}
              strokeWidth={selected ? 2 : 1.25} strokeOpacity="0.85"/>
      {/* selection halo */}
      {selected && (
        <circle r="30" fill="none" stroke="#00A3E0"
                strokeWidth="1" opacity="0.55"/>
      )}
      {/* critical pulse */}
      {isCritical && (
        <circle r="26" fill="none" stroke={sev}
                strokeWidth="1" className="node-pulse-circle"/>
      )}
      {/* icon — bright white silhouette, sits on the orb */}
      <image href={`${ICON_SRC}${device.type}.svg`}
             x="-13" y="-14" width="26" height="26"
             style={{ filter: 'brightness(0) invert(1) drop-shadow(0 1px 2px rgba(0,0,0,0.6))', opacity: 0.92 }}/>
    </g>
  );
}

// ---------------------------------------------------------------------------
//  TILE — frosted-glass rounded square. Lighter; icon stays natural color.
//  Closest to Datadog / ThousandEyes infrastructure-card style.
// ---------------------------------------------------------------------------
function TileNode({ device, selected, isCritical, sev, status, meta }) {
  const c = meta.color;
  const R = 22;
  return (
    <g>
      {/* drop shadow */}
      <rect x={-R} y={-R+3} width={R*2} height={R*2} rx="11"
            fill="#000" opacity="0.55" filter="url(#nv-blur)"/>
      {/* color wash (low opacity so it reads as glass) */}
      <rect x={-R} y={-R} width={R*2} height={R*2} rx="11"
            fill={c} fillOpacity="0.42"/>
      {/* glass tint (top brighter, bottom darker) */}
      <rect x={-R} y={-R} width={R*2} height={R*2} rx="11"
            fill="url(#nv-tile-grad)"/>
      {/* top edge specular */}
      <rect x={-R+2} y={-R+1} width={R*2-4} height="1.5" rx="0.75"
            fill="#fff" opacity="0.45"/>
      {/* left edge specular */}
      <rect x={-R+1} y={-R+2} width="1.5" height={R*2-4} rx="0.75"
            fill="#fff" opacity="0.18"/>
      {/* border in status color */}
      <rect x={-R} y={-R} width={R*2} height={R*2} rx="11"
            fill="none" stroke={status}
            strokeWidth={selected ? 2 : 1.25} strokeOpacity="0.85"/>
      {/* selection halo */}
      {selected && (
        <rect x={-R-5} y={-R-5} width={(R+5)*2} height={(R+5)*2} rx="15"
              fill="none" stroke="#00A3E0" strokeWidth="1" opacity="0.55"/>
      )}
      {/* critical pulse */}
      {isCritical && (
        <rect x={-R-2} y={-R-2} width={(R+2)*2} height={(R+2)*2} rx="13"
              fill="none" stroke={sev} strokeWidth="1" className="node-pulse-rect"/>
      )}
      {/* icon — natural color (the tile is light enough that multi-color reads fine) */}
      <image href={`${ICON_SRC}${device.type}.svg`}
             x="-15" y="-15" width="30" height="30"
             style={{ filter: 'drop-shadow(0 1px 1px rgba(0,0,0,0.55))' }}/>
    </g>
  );
}

// ---------------------------------------------------------------------------
//  DISC — the original concentric-circle treatment, kept for comparison.
// ---------------------------------------------------------------------------
function DiscNode({ device, selected, isCritical, sev, status }) {
  return (
    <g>
      {isCritical && (
        <circle r="26" fill="none" stroke={sev} strokeWidth="1" className="node-pulse-critical"/>
      )}
      <circle r={selected ? 28 : 25}
              fill={sev} fillOpacity="0.18"
              stroke={sev} strokeWidth={selected ? 3 : 2}/>
      {selected && <circle r="32" fill="none" stroke="#00A3E0" strokeWidth="1" opacity="0.6"/>}
      <circle r="20" fill="#0B1929" stroke={status} strokeWidth="3"/>
      <image href={`${ICON_SRC}${device.type}.svg`}
             x="-17" y="-17" width="34" height="34"
             className={isCritical ? 'node-icon-critical' : ''}/>
    </g>
  );
}

// ---------------------------------------------------------------------------
//  Shared <defs> block — drop into the topology <svg>.
// ---------------------------------------------------------------------------
function NodeDefs() {
  return (
    <defs>
      {/* glass shine for hex — diagonal top-left to bottom-right */}
      <linearGradient id="nv-glass-shine" x1="0.15" y1="0" x2="0.85" y2="1">
        <stop offset="0%"   stopColor="#fff" stopOpacity="0.38"/>
        <stop offset="45%"  stopColor="#fff" stopOpacity="0.06"/>
        <stop offset="100%" stopColor="#000" stopOpacity="0.28"/>
      </linearGradient>
      {/* orb light — top-left specular */}
      <radialGradient id="nv-orb-light" cx="0.3" cy="0.25" r="0.65">
        <stop offset="0%"   stopColor="#fff" stopOpacity="0.55"/>
        <stop offset="45%"  stopColor="#fff" stopOpacity="0.06"/>
        <stop offset="100%" stopColor="#fff" stopOpacity="0"/>
      </radialGradient>
      {/* orb rim — bottom-right shadow */}
      <radialGradient id="nv-orb-rim" cx="0.75" cy="0.78" r="0.55">
        <stop offset="0%"   stopColor="#000" stopOpacity="0"/>
        <stop offset="70%"  stopColor="#000" stopOpacity="0.10"/>
        <stop offset="100%" stopColor="#000" stopOpacity="0.55"/>
      </radialGradient>
      {/* tile gradient — top brighter, bottom darker */}
      <linearGradient id="nv-tile-grad" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0%"   stopColor="#fff" stopOpacity="0.22"/>
        <stop offset="60%"  stopColor="#fff" stopOpacity="0.02"/>
        <stop offset="100%" stopColor="#000" stopOpacity="0.22"/>
      </linearGradient>
      {/* shared blur for shadows */}
      <filter id="nv-blur" x="-50%" y="-50%" width="200%" height="200%">
        <feGaussianBlur stdDeviation="2"/>
      </filter>
    </defs>
  );
}

const NODE_VARIANTS = { hex: HexNode, orb: OrbNode, tile: TileNode, disc: DiscNode };

Object.assign(window, { NODE_VARIANTS, NodeDefs, HexNode, OrbNode, TileNode, DiscNode });
