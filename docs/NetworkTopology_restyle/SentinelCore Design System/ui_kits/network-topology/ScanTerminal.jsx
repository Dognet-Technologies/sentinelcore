/* ScanTerminal.jsx — bottom overlay terminal showing scan output */
const { useEffect: useEffectST, useRef: useRefST, useState: useStateST } = React;

const TERMINAL_LINES = [
  { d:0,    type:'cmd',  text:'sentinel-scan --target 192.168.1.0/24 --method arp-scan --probe nmap -sV' },
  { d:300,  type:'info', text:'[+] Initializing discovery engine v2.4.1' },
  { d:600,  type:'info', text:'[+] ARP probe → 192.168.1.0/24 (254 hosts)' },
  { d:1200, type:'ok',   text:'[✓] 16 hosts responded · 4.2s · 100% coverage' },
  { d:1500, type:'info', text:'[+] Fingerprinting OS + service banners…' },
  { d:2200, type:'ok',   text:'[✓] Identified: 2× firewall · 1× router · 2× switch · 6× server · 2× wireless · 2× endpoint · 1× storage' },
  { d:2600, type:'warn', text:'[!] web-prod-01 (192.168.1.20) — 2 critical vulnerabilities' },
  { d:2800, type:'warn', text:'    └─ CVE-2024-3094 · CVSS 10.0 · xz-utils backdoor (sshd)' },
  { d:3000, type:'warn', text:'    └─ CVE-2024-6387 · CVSS 8.1 · OpenSSH regreSSHion RCE' },
  { d:3300, type:'err',  text:'[!] db-master (10.0.0.10) — risk score 91/100 · escalating to remediation queue' },
  { d:3700, type:'info', text:'[+] Computing topology · 18 active links · 2 down · avg utilization 38%' },
  { d:4100, type:'ok',   text:'[✓] Scan complete · 4.1s · results streamed to /var/log/sentinel/scan-2026-05-21T11-42.json' },
];

function ScanTerminal({ open, onClose }) {
  const bodyRef = useRefST(null);
  const [visible, setVisible] = useStateST([]);

  useEffectST(() => {
    if (!open) { setVisible([]); return; }
    setVisible([]);
    const timeouts = TERMINAL_LINES.map((line, i) => setTimeout(() => {
      setVisible(prev => [...prev, line]);
      requestAnimationFrame(() => {
        if (bodyRef.current) bodyRef.current.scrollTop = bodyRef.current.scrollHeight;
      });
    }, line.d));
    return () => timeouts.forEach(clearTimeout);
  }, [open]);

  if (!open) return null;

  const classFor = t => ({
    cmd:'',
    info:'t-info',
    ok:'t-ok',
    warn:'t-warn',
    err:'t-err',
  }[t] || '');

  const done = visible.length === TERMINAL_LINES.length;

  return (
    <div className="terminal-overlay">
      <div className="terminal-header">
        <span className="terminal-dot" style={{ background:'#FF5F57' }}/>
        <span className="terminal-dot" style={{ background:'#FEBC2E' }}/>
        <span className="terminal-dot" style={{ background:'#28C840' }}/>
        <span className="terminal-title" style={{ marginLeft:8 }}>
          sentinel · scan-session-4f8c · {done ? 'idle' : 'running…'}
        </span>
        <div style={{ flex:1 }}/>
        <button className="icon-btn" onClick={onClose} title="Close"><Icon name="x" size={14}/></button>
      </div>
      <div className="terminal-body" ref={bodyRef}>
        {visible.map((line, i) => (
          <div key={i}>
            {line.type === 'cmd' && (
              <><span className="t-prompt">sentinel@core</span>:<span className="t-host">~</span>$ <span>{line.text}</span></>
            )}
            {line.type !== 'cmd' && (
              <span className={classFor(line.type)}>{line.text}</span>
            )}
          </div>
        ))}
        {!done && <div className="cursor"></div>}
      </div>
    </div>
  );
}

Object.assign(window, { ScanTerminal });
