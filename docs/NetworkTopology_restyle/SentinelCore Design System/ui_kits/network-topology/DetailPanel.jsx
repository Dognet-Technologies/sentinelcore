/* DetailPanel.jsx — slide-in right panel for selected device */

function DetailRow({ k, v, mono }) {
  return (
    <div className="detail-row">
      <span className="k">{k}</span>
      <span className={`v ${mono ? 'mono-num' : ''}`}>{v}</span>
    </div>
  );
}

function RiskMeter({ score }) {
  const color = score > 70 ? '#F44336' : score > 40 ? '#FF9800' : '#4CAF50';
  return (
    <div>
      <div className="risk-meter">
        <span style={{ width: `${score}%`, background: color }}/>
      </div>
      <div style={{ display:'flex', justifyContent:'space-between', marginTop:6, fontFamily:'var(--sc-font-mono)', fontSize:11, color:'var(--sc-fg-tertiary)' }}>
        <span>0</span>
        <span style={{ color, fontWeight:700 }}>{score} / 100</span>
        <span>100</span>
      </div>
    </div>
  );
}

function VulnRow({ cve }) {
  const cls = { crit:'crit', high:'high', med:'med' }[cve.sev] || '';
  return (
    <div className={`vuln-row ${cls}`}>
      <span className="vuln-id">{cve.id}</span>
      <span className="vuln-desc">{cve.desc}</span>
      <span className="vuln-score">{cve.score}</span>
    </div>
  );
}

function DetailPanel({ device, onClose }) {
  if (!device) return null;
  const meta = DEVICE_META[device.type] || DEVICE_META.unknown;
  const cves = SAMPLE_CVES[device.id] || [];

  return (
    <aside className="detail-panel">
      <div className="detail-header">
        <div className="detail-icon-wrap" style={{ borderColor: meta.color }}>
          <img src={`${ICON_SRC}${device.type}.svg`} width="32" height="32" alt=""/>
        </div>
        <div style={{ flex:1, minWidth:0 }}>
          <h3 className="detail-name">{device.name}</h3>
          <div className="detail-ip">{device.ip}</div>
          <div style={{ display:'flex', gap:6, marginTop:8, flexWrap:'wrap' }}>
            <span className="chip chip-outline"><span className="chip-dot" style={{ background: statusColor(device.status) }}/>{device.status}</span>
            <span className="chip chip-outline">{meta.label}</span>
          </div>
        </div>
        <button className="icon-btn detail-close" onClick={onClose} title="Close"><Icon name="x" size={16}/></button>
      </div>

      <div className="detail-body">
        <section className="detail-section">
          <div className="detail-section-title">Identity</div>
          <DetailRow k="Hostname" v={device.name}/>
          <DetailRow k="IPv4"     v={device.ip} mono/>
          <DetailRow k="OS"       v={device.os}/>
          <DetailRow k="Subnet"   v={device.subnet} mono/>
        </section>

        <section className="detail-section">
          <div className="detail-section-title">Risk score</div>
          <RiskMeter score={device.vulns.risk}/>
        </section>

        <section className="detail-section">
          <div className="detail-section-title">Vulnerabilities · {device.vulns.total}</div>
          <div style={{ display:'flex', gap:8, marginBottom:6 }}>
            <span className="chip chip-critical">{device.vulns.crit} Critical</span>
            <span className="chip chip-warning">{device.vulns.high} High</span>
            <span className="chip chip-outline">{device.vulns.med} Medium</span>
          </div>
          {cves.length > 0 ? (
            <div style={{ display:'flex', flexDirection:'column', gap:6 }}>
              {cves.map(c => <VulnRow key={c.id} cve={c}/>)}
            </div>
          ) : (
            <div style={{ fontSize:12, color:'var(--sc-fg-tertiary)', padding:'8px 0' }}>
              No tracked CVEs for this host.
            </div>
          )}
        </section>

        <section className="detail-section">
          <div className="detail-section-title">Open ports</div>
          <div style={{ display:'flex', gap:6, flexWrap:'wrap' }}>
            {device.ports.length === 0
              ? <span style={{ fontSize:12, color:'var(--sc-fg-tertiary)' }}>None observed</span>
              : device.ports.map(p => (
                  <span key={p} className="chip chip-outline" style={{ fontFamily:'var(--sc-font-mono)' }}>tcp/{p}</span>
                ))}
          </div>
        </section>

        <section className="detail-section">
          <div className="detail-section-title">Last scan</div>
          <DetailRow k="Time"  v={device.lastScan}/>
          <DetailRow k="Method" v="arp-scan + nmap -sV" mono/>
        </section>
      </div>

      <div className="detail-actions">
        <button className="btn btn-primary"><Icon name="terminal" size={14}/>Connect</button>
        <button className="btn btn-secondary"><Icon name="shield" size={14}/>Remediate</button>
        <button className="btn btn-ghost" title="Edit"><Icon name="edit" size={14}/></button>
      </div>
    </aside>
  );
}

Object.assign(window, { DetailPanel, DetailRow, RiskMeter, VulnRow });
