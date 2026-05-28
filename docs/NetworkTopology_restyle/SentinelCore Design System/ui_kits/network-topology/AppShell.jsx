/* AppShell.jsx — sidebar + top app bar */
const { useState } = React;

// Lucide-style inline SVG icons (24×24, 1.5 stroke)
const Icon = ({ name, size = 18 }) => {
  const paths = {
    network: <><circle cx="12" cy="12" r="2.5"/><circle cx="4"  cy="6"  r="2"/><circle cx="20" cy="6"  r="2"/><circle cx="4"  cy="18" r="2"/><circle cx="20" cy="18" r="2"/><path d="M6 6l4 4M18 6l-4 4M6 18l4-4M18 18l-4-4"/></>,
    dashboard: <><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/></>,
    shield:    <><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></>,
    bug:       <><rect x="8" y="6" width="8" height="14" rx="4"/><path d="M8 10l-3-2M16 10l3-2M8 14H4M16 14h4M8 18l-3 2M16 18l3 2M12 6V3"/></>,
    users:     <><circle cx="9" cy="8" r="3"/><circle cx="17" cy="9" r="2.5"/><path d="M3 20c0-3 3-5 6-5s6 2 6 5M14 20c0-2 2-4 5-4"/></>,
    file:      <><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></>,
    settings:  <><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9c.36.15.67.41.9.73.23.32.37.7.42 1.09V12c0 .39-.05.77-.18 1.14"/></>,
    terminal:  <><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></>,
    bell:      <><path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.7 21a2 2 0 0 1-3.4 0"/></>,
    search:    <><circle cx="11" cy="11" r="7"/><path d="m21 21-4.3-4.3"/></>,
    play:      <><polygon points="5 3 19 12 5 21 5 3"/></>,
    refresh:   <><polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></>,
    zoomIn:    <><circle cx="11" cy="11" r="7"/><path d="m21 21-4.3-4.3"/><line x1="11" y1="8" x2="11" y2="14"/><line x1="8" y1="11" x2="14" y2="11"/></>,
    zoomOut:   <><circle cx="11" cy="11" r="7"/><path d="m21 21-4.3-4.3"/><line x1="8" y1="11" x2="14" y2="11"/></>,
    fit:       <><path d="M3 7V5a2 2 0 0 1 2-2h2"/><path d="M17 3h2a2 2 0 0 1 2 2v2"/><path d="M21 17v2a2 2 0 0 1-2 2h-2"/><path d="M7 21H5a2 2 0 0 1-2-2v-2"/></>,
    grid:      <><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/></>,
    tree:      <><circle cx="12" cy="4" r="2"/><circle cx="6" cy="12" r="2"/><circle cx="18" cy="12" r="2"/><circle cx="4" cy="20" r="2"/><circle cx="12" cy="20" r="2"/><circle cx="20" cy="20" r="2"/><path d="M12 6v4M6 14v4M18 14v4M10.5 5.5l-3 5M13.5 5.5l3 5"/></>,
    circle:    <><circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="3"/></>,
    full:      <><polyline points="4 14 4 20 10 20"/><polyline points="20 10 20 4 14 4"/><line x1="14" y1="10" x2="21" y2="3"/><line x1="3" y1="21" x2="10" y2="14"/></>,
    x:         <><path d="M18 6 6 18M6 6l12 12"/></>,
    chev:      <><polyline points="6 9 12 15 18 9"/></>,
    edit:      <><path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5L17 3z"/></>,
    trash:     <><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6M14 11v6"/></>,
    link:      <><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 1 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 1 0 7.07 7.07l1.71-1.71"/></>,
    download:  <><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></>,
    plus:      <><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></>,
  };
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none"
         stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      {paths[name] || null}
    </svg>
  );
};

function AppBar() {
  return (
    <header className="appbar">
      <div className="appbar-brand">
        <img src="../../assets/logo.svg" alt="SentinelCore"/>
        <div className="appbar-title">SENTINEL<span className="cyan">CORE</span></div>
      </div>
      <div className="appbar-breadcrumb">
        <span>Network</span>
        <span className="sep">/</span>
        <span className="current">Topology</span>
      </div>
      <div className="appbar-spacer"></div>
      <div className="appbar-actions">
        <button className="icon-btn" title="Search"><Icon name="search"/></button>
        <button className="icon-btn" title="Run scan"><Icon name="play"/></button>
        <div className="icon-btn-wrap">
          <button className="icon-btn" title="Alerts"><Icon name="bell"/></button>
          <span className="dot-indicator"></span>
        </div>
        <button className="icon-btn" title="Settings"><Icon name="settings"/></button>
        <div className="user-chip">
          <div className="user-chip-avatar">MR</div>
          <div className="user-chip-name">m.rossi</div>
        </div>
      </div>
    </header>
  );
}

function Sidebar() {
  const [active, setActive] = useState('network');
  const items = [
    ['dashboard', 'dashboard',  'Dashboard'],
    ['network',   'network',    'Network Topology'],
    ['bug',       'vulns',      'Vulnerabilities'],
    ['shield',    'remediation','Remediation'],
    ['users',     'teams',      'Teams'],
    ['file',      'reports',    'Reports'],
  ];
  return (
    <nav className="sidebar">
      {items.map(([icon, key, title]) => (
        <div key={key}
             className={`sidebar-item ${active===key ? 'active' : ''}`}
             title={title}
             onClick={() => setActive(key)}>
          <Icon name={icon} size={20}/>
        </div>
      ))}
      <div className="sidebar-divider"/>
      <div className="sidebar-bottom">
        <div className="sidebar-item" title="Terminal"><Icon name="terminal" size={20}/></div>
        <div className="sidebar-item" title="Settings"><Icon name="settings" size={20}/></div>
      </div>
    </nav>
  );
}

Object.assign(window, { AppBar, Sidebar, Icon });
