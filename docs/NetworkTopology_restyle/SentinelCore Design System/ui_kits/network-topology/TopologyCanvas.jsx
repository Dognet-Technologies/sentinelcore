/* TopologyCanvas.jsx — SVG-rendered network graph */
const { useState, useRef, useEffect, useMemo } = React;

function DeviceNode({ device, selected, onSelect, onContextMenu, variant = 'hex' }) {
  const sev = severityColor(device.severity);
  const status = statusColor(device.status);
  const isCritical = device.severity === 'critical';
  const isHigh = device.severity === 'high';
  const hasIncidents = device.vulns.crit > 0;
  const meta = DEVICE_META[device.type] || DEVICE_META.unknown;
  const Renderer = NODE_VARIANTS[variant] || NODE_VARIANTS.hex;

  return (
    <g className="node"
       transform={`translate(${device.x}, ${device.y})`}
       onClick={(e) => { e.stopPropagation(); onSelect(device.id); }}
       onContextMenu={onContextMenu}>
      <Renderer device={device}
                selected={selected}
                isCritical={isCritical}
                sev={sev}
                status={status}
                meta={meta}/>

      {/* labels */}
      <text className="node-label" y="42">{device.name}</text>
      <text className="node-ip" y="56">{device.ip}</text>

      {/* incident badge (top-right) */}
      {hasIncidents && (
        <g transform="translate(18, -18)">
          <circle r="10" fill="#F44336" stroke="#0B1929" strokeWidth="2"/>
          <text className="badge-text" dy="3.5">{device.vulns.crit}</text>
        </g>
      )}
      {/* vulnerability badge (bottom-right) */}
      {device.vulns.total > 0 && (
        <g transform="translate(18, 18)">
          <circle r="10" stroke="#0B1929" strokeWidth="2"
                  fill={hasIncidents ? '#F44336' : isHigh ? '#FF9800' : '#2196F3'}/>
          <text className="badge-text" dy="3.5">{device.vulns.total}</text>
        </g>
      )}
      {/* risk score badge (bottom-left) */}
      <g transform="translate(-18, 18)">
        <circle r="10" stroke="#0B1929" strokeWidth="2"
                fill={device.vulns.risk > 70 ? '#F44336' : device.vulns.risk > 40 ? '#FF9800' : '#4CAF50'}/>
        <text className="badge-text" dy="3.5">{device.vulns.risk}</text>
      </g>
    </g>
  );
}

function TopologyCanvas({ selectedId, onSelect, zoom, animateLinks, nodeVariant = 'hex' }) {
  const devices = DEVICES;
  const links = LINKS;
  const subnets = SUBNETS;

  const deviceMap = useMemo(() => {
    const m = {};
    devices.forEach(d => { m[d.id] = d; });
    return m;
  }, [devices]);

  return (
    <svg className="canvas"
         viewBox={`0 0 1400 760`}
         preserveAspectRatio="xMidYMid meet"
         onClick={() => onSelect(null)}>
      <NodeDefs/>
      <defs>
        <filter id="nodeShadow" x="-50%" y="-50%" width="200%" height="200%">
          <feGaussianBlur in="SourceAlpha" stdDeviation="3"/>
          <feOffset dx="0" dy="2" result="o"/>
          <feComponentTransfer><feFuncA type="linear" slope="0.5"/></feComponentTransfer>
          <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
        </filter>
      </defs>

      <g style={{ transform: `scale(${zoom})`, transformOrigin: '50% 50%', transition: 'transform 0.3s ease' }}>

        {/* Subnet group backgrounds */}
        {subnets.map(s => (
          <g key={s.cidr}>
            <rect className="subnet-rect"
                  x={s.x} y={s.y} width={s.w} height={s.h}
                  rx="10"/>
            <text className="subnet-label" x={s.x + 14} y={s.y + 22}>
              {s.label}
            </text>
          </g>
        ))}

        {/* Links — drawn first, beneath nodes */}
        <g>
          {links.map((link, i) => {
            const s = deviceMap[link.source];
            const t = deviceMap[link.target];
            if (!s || !t) return null;
            const color = linkColor(link.util, link.status);
            const isDown = link.status === 'down';
            const utilizationHigh = link.util >= 70 && !isDown;
            return (
              <g key={i} className="link">
                <line
                  x1={s.x} y1={s.y} x2={t.x} y2={t.y}
                  stroke={color}
                  strokeWidth={isDown ? 1 : 1.5}
                  strokeDasharray={isDown ? '4 4' : 'none'}
                  className={`link-line ${isDown ? 'dashed' : ''} ${utilizationHigh && animateLinks ? 'link-flow' : ''}`}
                />
                {utilizationHigh && animateLinks && (
                  <line x1={s.x} y1={s.y} x2={t.x} y2={t.y}
                        stroke={color} strokeWidth="2"
                        strokeDasharray="3 17"
                        opacity="0.9"
                        className="link-flow"/>
                )}
              </g>
            );
          })}
        </g>

        {/* Devices */}
        <g>
          {devices.map(d => (
            <DeviceNode key={d.id}
                        device={d}
                        selected={d.id === selectedId}
                        onSelect={onSelect}
                        variant={nodeVariant}/>
          ))}
        </g>
      </g>
    </svg>
  );
}

Object.assign(window, { TopologyCanvas, DeviceNode });
