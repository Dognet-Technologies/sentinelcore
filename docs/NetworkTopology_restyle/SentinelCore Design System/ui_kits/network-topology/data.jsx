/* mock data + icon helpers */
const ICON_SRC = '../../assets/icons/';

const DEVICE_META = {
  firewall:     { color: '#D32F2F', label: 'Firewall' },
  router:       { color: '#1565C0', label: 'Router' },
  switch:       { color: '#0D47A1', label: 'Switch' },
  server:       { color: '#37474F', label: 'Server' },
  database:     { color: '#7B1FA2', label: 'Database' },
  wireless:     { color: '#00BCD4', label: 'Wireless AP' },
  endpoint:     { color: '#546E7A', label: 'Endpoint' },
  storage:      { color: '#FF6F00', label: 'Storage' },
  loadbalancer: { color: '#6A1B9A', label: 'Load Balancer' },
  gateway:      { color: '#0288D1', label: 'Gateway' },
  unknown:      { color: '#9E9E9E', label: 'Unknown' },
};

// Realistic discovered LAN — placed manually for a clean topology.
const DEVICES = [
  // 192.168.1.0/24 — DMZ / edge
  { id:'fw-edge',  name:'fw-edge',     type:'firewall',     ip:'192.168.1.1',  os:'pfSense 2.7', status:'online', severity:'high',     vulns:{crit:0, high:2, med:3, total:5,  risk:62}, ports:[22,80,443], lastScan:'4m ago', x: 720, y: 110, subnet:'192.168.1.0/24' },
  { id:'gw-vpn',   name:'gw-vpn-01',   type:'gateway',      ip:'192.168.1.5',  os:'OpenVPN AS',  status:'online', severity:'none',     vulns:{crit:0, high:0, med:1, total:1,  risk:18}, ports:[1194,443],  lastScan:'4m ago', x: 540, y: 220, subnet:'192.168.1.0/24' },
  { id:'rt-core',  name:'rt-core',     type:'router',       ip:'192.168.1.2',  os:'Cisco IOS XE',status:'online', severity:'medium',   vulns:{crit:0, high:1, med:4, total:5,  risk:48}, ports:[22,161],    lastScan:'4m ago', x: 720, y: 240, subnet:'192.168.1.0/24' },
  { id:'sw-a',     name:'sw-distro-a', type:'switch',       ip:'192.168.1.10', os:'NX-OS 10.2',  status:'online', severity:'none',     vulns:{crit:0, high:0, med:0, total:0,  risk:8},  ports:[22,161,830],lastScan:'4m ago', x: 540, y: 360, subnet:'192.168.1.0/24' },
  { id:'sw-b',     name:'sw-distro-b', type:'switch',       ip:'192.168.1.11', os:'NX-OS 10.2',  status:'online', severity:'none',     vulns:{crit:0, high:0, med:1, total:1,  risk:12}, ports:[22,161,830],lastScan:'4m ago', x: 900, y: 360, subnet:'192.168.1.0/24' },
  { id:'lb-app',   name:'lb-app-01',   type:'loadbalancer', ip:'192.168.1.40', os:'HAProxy 2.8', status:'online', severity:'none',     vulns:{crit:0, high:0, med:0, total:0,  risk:4},  ports:[80,443,8404],lastScan:'4m ago',x:1080, y: 240, subnet:'192.168.1.0/24' },
  { id:'web-1',    name:'web-prod-01', type:'server',       ip:'192.168.1.20', os:'Ubuntu 22.04',status:'online', severity:'critical', vulns:{crit:2, high:3, med:4, total:9,  risk:88}, ports:[22,80,443], lastScan:'4m ago', x: 420, y: 480, subnet:'192.168.1.0/24' },
  { id:'web-2',    name:'web-prod-02', type:'server',       ip:'192.168.1.21', os:'Ubuntu 22.04',status:'online', severity:'high',     vulns:{crit:0, high:3, med:2, total:5,  risk:64}, ports:[22,80,443], lastScan:'4m ago', x: 560, y: 480, subnet:'192.168.1.0/24' },
  { id:'ap-1',     name:'ap-floor-1',  type:'wireless',     ip:'192.168.1.30', os:'UniFi 7.5',   status:'online', severity:'none',     vulns:{crit:0, high:0, med:0, total:0,  risk:6},  ports:[22,8443],   lastScan:'4m ago', x: 870, y: 480, subnet:'192.168.1.0/24' },
  { id:'ap-2',     name:'ap-floor-2',  type:'wireless',     ip:'192.168.1.31', os:'UniFi 7.5',   status:'maintenance', severity:'medium', vulns:{crit:0, high:0, med:2, total:2,  risk:28}, ports:[22,8443],   lastScan:'1h ago', x:1010, y: 480, subnet:'192.168.1.0/24' },

  // 10.0.0.0/24 — backend / data tier
  { id:'db-1',     name:'db-master',   type:'database',     ip:'10.0.0.10',    os:'PostgreSQL 15',status:'online', severity:'critical', vulns:{crit:1, high:2, med:1, total:4,  risk:91}, ports:[22,5432],   lastScan:'4m ago', x: 240, y: 620, subnet:'10.0.0.0/24' },
  { id:'db-2',     name:'db-replica',  type:'database',     ip:'10.0.0.11',    os:'PostgreSQL 15',status:'online', severity:'high',     vulns:{crit:0, high:1, med:1, total:2,  risk:54}, ports:[22,5432],   lastScan:'4m ago', x: 400, y: 620, subnet:'10.0.0.0/24' },
  { id:'nas-1',    name:'nas-storage', type:'storage',      ip:'10.0.0.20',    os:'TrueNAS 13',  status:'online', severity:'none',     vulns:{crit:0, high:0, med:0, total:0,  risk:10}, ports:[22,445,2049],lastScan:'4m ago', x: 580, y: 620, subnet:'10.0.0.0/24' },

  // 172.16.0.0/24 — workstations
  { id:'ws-1',     name:'ws-eng-01',   type:'endpoint',     ip:'172.16.0.10',  os:'macOS 14.4',  status:'online', severity:'none',     vulns:{crit:0, high:0, med:0, total:0,  risk:5},  ports:[],          lastScan:'4m ago', x: 900, y: 620, subnet:'172.16.0.0/24' },
  { id:'ws-2',     name:'ws-eng-02',   type:'endpoint',     ip:'172.16.0.11',  os:'Win 11',      status:'online', severity:'medium',   vulns:{crit:0, high:0, med:3, total:3,  risk:34}, ports:[3389],      lastScan:'4m ago', x:1020, y: 620, subnet:'172.16.0.0/24' },
  { id:'prn-1',    name:'prn-mfp-1',   type:'unknown',      ip:'172.16.0.50',  os:'—',           status:'offline',severity:'none',     vulns:{crit:0, high:0, med:0, total:0,  risk:0},  ports:[9100],      lastScan:'2h ago', x:1140, y: 620, subnet:'172.16.0.0/24' },
];

// Subnet group boxes (computed bounding boxes)
const SUBNETS = [
  { cidr:'192.168.1.0/24', label:'DMZ · 192.168.1.0/24',    x: 200, y: 80,  w: 990, h: 440 },
  { cidr:'10.0.0.0/24',    label:'DATA · 10.0.0.0/24',      x: 200, y: 555, w: 470, h: 130 },
  { cidr:'172.16.0.0/24',  label:'CLIENTS · 172.16.0.0/24', x: 830, y: 555, w: 360, h: 130 },
];

// Links — source, target, utilization, status
const LINKS = [
  { source:'fw-edge', target:'gw-vpn',   util:32, status:'active' },
  { source:'fw-edge', target:'rt-core',  util:78, status:'active' },
  { source:'rt-core', target:'sw-a',     util:45, status:'active' },
  { source:'rt-core', target:'sw-b',     util:62, status:'active' },
  { source:'rt-core', target:'lb-app',   util:55, status:'active' },
  { source:'sw-a',    target:'web-1',    util:88, status:'active' },
  { source:'sw-a',    target:'web-2',    util:41, status:'active' },
  { source:'sw-b',    target:'ap-1',     util:22, status:'active' },
  { source:'sw-b',    target:'ap-2',     util:0,  status:'down' },
  { source:'lb-app',  target:'web-1',    util:71, status:'active' },
  { source:'lb-app',  target:'web-2',    util:38, status:'active' },
  { source:'sw-a',    target:'db-1',     util:54, status:'active' },
  { source:'sw-a',    target:'db-2',     util:24, status:'active' },
  { source:'db-1',    target:'db-2',     util:18, status:'active' },
  { source:'sw-a',    target:'nas-1',    util:33, status:'active' },
  { source:'sw-b',    target:'ws-1',     util:12, status:'active' },
  { source:'sw-b',    target:'ws-2',     util:8,  status:'active' },
  { source:'sw-b',    target:'prn-1',    util:0,  status:'down' },
];

// CVE samples for the detail panel
const SAMPLE_CVES = {
  'web-1': [
    { id:'CVE-2024-3094',  desc:'xz-utils backdoor — code execution via SSH', sev:'crit', score:'10.0' },
    { id:'CVE-2024-6387',  desc:'OpenSSH regreSSHion remote code execution',  sev:'crit', score:'8.1'  },
    { id:'CVE-2024-12798', desc:'nginx HTTP/3 path-traversal',                 sev:'high', score:'7.5'  },
  ],
  'db-1': [
    { id:'CVE-2024-10979', desc:'PostgreSQL env-var injection via PL/Perl',    sev:'crit', score:'9.8'  },
    { id:'CVE-2024-10978', desc:'SET ROLE/SESSION privilege escalation',       sev:'high', score:'7.8'  },
  ],
  'fw-edge': [
    { id:'CVE-2024-21762', desc:'FortiOS out-of-bounds write (sslvpnd)',       sev:'high', score:'7.5'  },
    { id:'CVE-2024-23113', desc:'Format-string in fgfmd daemon',                sev:'high', score:'7.5'  },
  ],
};

function linkColor(util, status) {
  if (status === 'down') return '#757575';
  if (util >= 90) return '#F44336';
  if (util >= 70) return '#FF9800';
  return '#4CAF50';
}
function severityColor(sev) {
  return { critical:'#F44336', high:'#FF9800', medium:'#FFC107', low:'#8BC34A', none:'#4CAF50' }[sev] || '#4CAF50';
}
function statusColor(s) {
  return { online:'#4CAF50', offline:'#F44336', maintenance:'#FF9800', unknown:'#757575' }[s] || '#757575';
}

Object.assign(window, { DEVICES, LINKS, SUBNETS, DEVICE_META, SAMPLE_CVES, ICON_SRC, linkColor, severityColor, statusColor });
