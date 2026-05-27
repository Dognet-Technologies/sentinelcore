// DeviceIcons.tsx - Entuity-style SVG device icons
// Professional network device icons matching Entuity's visual style

import React from 'react';

interface DeviceIconProps {
  size?: number;
  color?: string;
}

// Router Icon - Entuity style
export const RouterIcon: React.FC<DeviceIconProps> = ({ size = 40, color = '#1565C0' }) => (
  <svg width={size} height={size} viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
    {/* Router body */}
    <rect x="6" y="20" width="36" height="20" rx="2" fill={color} />
    <rect x="8" y="22" width="32" height="16" rx="1" fill="#fff" opacity="0.2" />

    {/* Antennas */}
    <line x1="12" y1="20" x2="12" y2="10" stroke={color} strokeWidth="2" strokeLinecap="round" />
    <line x1="24" y1="20" x2="24" y2="8" stroke={color} strokeWidth="2" strokeLinecap="round" />
    <line x1="36" y1="20" x2="36" y2="10" stroke={color} strokeWidth="2" strokeLinecap="round" />

    {/* Antenna tips */}
    <circle cx="12" cy="10" r="2" fill={color} />
    <circle cx="24" cy="8" r="2" fill={color} />
    <circle cx="36" cy="10" r="2" fill={color} />

    {/* Port LEDs */}
    <circle cx="14" cy="30" r="1.5" fill="#4CAF50" />
    <circle cx="20" cy="30" r="1.5" fill="#4CAF50" />
    <circle cx="26" cy="30" r="1.5" fill="#4CAF50" />
    <circle cx="32" cy="30" r="1.5" fill="#FFC107" />
  </svg>
);

// Switch Icon - Entuity style
export const SwitchIcon: React.FC<DeviceIconProps> = ({ size = 40, color = '#0D47A1' }) => (
  <svg width={size} height={size} viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
    {/* Switch body */}
    <rect x="4" y="16" width="40" height="16" rx="2" fill={color} />
    <rect x="6" y="18" width="36" height="12" rx="1" fill="#fff" opacity="0.15" />

    {/* Port grid - 8 ports */}
    {[0, 1, 2, 3, 4, 5, 6, 7].map((i) => (
      <rect
        key={i}
        x={8 + i * 4}
        y="20"
        width="2.5"
        height="8"
        rx="0.5"
        fill="#fff"
        opacity="0.6"
      />
    ))}

    {/* Status LEDs */}
    <circle cx="38" cy="20" r="1.5" fill="#4CAF50" />
    <circle cx="38" cy="24" r="1.5" fill="#2196F3" />
    <circle cx="38" cy="28" r="1.5" fill="#4CAF50" />
  </svg>
);

// Server Icon - Entuity style
export const ServerIcon: React.FC<DeviceIconProps> = ({ size = 40, color = '#37474F' }) => (
  <svg width={size} height={size} viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
    {/* Server rack - 3 units */}
    {[0, 1, 2].map((i) => (
      <g key={i}>
        <rect x="8" y={12 + i * 10} width="32" height="8" rx="1" fill={color} />
        <rect x="10" y={14 + i * 10} width="28" height="4" rx="0.5" fill="#fff" opacity="0.15" />

        {/* Drive bay indicators */}
        <circle cx="14" cy={16 + i * 10} r="1" fill="#4CAF50" />
        <circle cx="18" cy={16 + i * 10} r="1" fill="#4CAF50" />
        <circle cx="22" cy={16 + i * 10} r="1" fill="#FFC107" />

        {/* Power LED */}
        <circle cx="35" cy={16 + i * 10} r="1.5" fill="#4CAF50" />
      </g>
    ))}
  </svg>
);

// Firewall Icon - Entuity style
export const FirewallIcon: React.FC<DeviceIconProps> = ({ size = 40, color = '#D32F2F' }) => (
  <svg width={size} height={size} viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
    {/* Shield shape */}
    <path
      d="M24 6L10 12V22C10 30 16 36 24 42C32 36 38 30 38 22V12L24 6Z"
      fill={color}
    />
    <path
      d="M24 8L12 13V22C12 29 17 34 24 39C31 34 36 29 36 22V13L24 8Z"
      fill="#fff"
      opacity="0.2"
    />

    {/* Lock symbol */}
    <rect x="20" y="22" width="8" height="8" rx="1" fill="#fff" />
    <path
      d="M22 22V19C22 17.9 22.9 17 24 17C25.1 17 26 17.9 26 19V22"
      stroke="#fff"
      strokeWidth="2"
      fill="none"
    />

    {/* Warning indicator */}
    <circle cx="24" cy="12" r="1.5" fill="#FFC107" />
  </svg>
);

// Database Icon - Entuity style
export const DatabaseIcon: React.FC<DeviceIconProps> = ({ size = 40, color = '#7B1FA2' }) => (
  <svg width={size} height={size} viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
    {/* Database cylinder - 3 layers */}
    {[0, 1, 2].map((i) => (
      <g key={i}>
        <ellipse cx="24" cy={14 + i * 10} rx="14" ry="4" fill={color} />
        <rect x="10" y={14 + i * 10} width="28" height="10" fill={color} />
        <ellipse cx="24" cy={24 + i * 10} rx="14" ry="4" fill={color} opacity="0.8" />

        {/* Highlight */}
        <ellipse cx="24" cy={14 + i * 10} rx="12" ry="3" fill="#fff" opacity="0.2" />
      </g>
    ))}

    {/* Activity indicator */}
    <circle cx="36" cy="20" r="2" fill="#4CAF50" />
  </svg>
);

// Wireless AP Icon - Entuity style
export const WirelessIcon: React.FC<DeviceIconProps> = ({ size = 40, color = '#00BCD4' }) => (
  <svg width={size} height={size} viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
    {/* AP body */}
    <circle cx="24" cy="28" r="6" fill={color} />
    <circle cx="24" cy="28" r="4" fill="#fff" opacity="0.3" />

    {/* WiFi waves */}
    <path
      d="M24 20C18 20 13 22 10 26"
      stroke={color}
      strokeWidth="2"
      strokeLinecap="round"
      fill="none"
    />
    <path
      d="M24 16C16 16 9 19 4 25"
      stroke={color}
      strokeWidth="2"
      strokeLinecap="round"
      fill="none"
      opacity="0.6"
    />
    <path
      d="M24 20C30 20 35 22 38 26"
      stroke={color}
      strokeWidth="2"
      strokeLinecap="round"
      fill="none"
    />
    <path
      d="M24 16C32 16 39 19 44 25"
      stroke={color}
      strokeWidth="2"
      strokeLinecap="round"
      fill="none"
      opacity="0.6"
    />

    {/* Status LED */}
    <circle cx="24" cy="28" r="2" fill="#4CAF50" />
  </svg>
);

// Endpoint/Desktop Icon - Entuity style
export const EndpointIcon: React.FC<DeviceIconProps> = ({ size = 40, color = '#546E7A' }) => (
  <svg width={size} height={size} viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
    {/* Monitor */}
    <rect x="8" y="10" width="32" height="22" rx="2" fill={color} />
    <rect x="10" y="12" width="28" height="18" rx="1" fill="#fff" opacity="0.9" />

    {/* Screen content */}
    <rect x="12" y="14" width="24" height="14" fill={color} opacity="0.1" />

    {/* Stand */}
    <rect x="20" y="32" width="8" height="2" fill={color} />
    <rect x="16" y="34" width="16" height="2" rx="1" fill={color} />

    {/* Power LED */}
    <circle cx="24" cy="30" r="1" fill="#4CAF50" />
  </svg>
);

// Storage Icon - Entuity style
export const StorageIcon: React.FC<DeviceIconProps> = ({ size = 40, color = '#FF6F00' }) => (
  <svg width={size} height={size} viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
    {/* NAS/SAN box */}
    <rect x="10" y="12" width="28" height="24" rx="2" fill={color} />
    <rect x="12" y="14" width="24" height="20" rx="1" fill="#fff" opacity="0.15" />

    {/* Drive bays - 4x2 grid */}
    {[0, 1].map((row) =>
      [0, 1, 2, 3].map((col) => (
        <rect
          key={`${row}-${col}`}
          x={14 + col * 5.5}
          y={16 + row * 9}
          width="4"
          height="7"
          rx="0.5"
          fill="#fff"
          opacity="0.6"
        />
      ))
    )}

    {/* Status LEDs */}
    <circle cx="15" cy="32" r="1" fill="#4CAF50" />
    <circle cx="20" cy="32" r="1" fill="#4CAF50" />
    <circle cx="25" cy="32" r="1" fill="#2196F3" />
  </svg>
);

// Load Balancer Icon - Entuity style
export const LoadBalancerIcon: React.FC<DeviceIconProps> = ({ size = 40, color = '#6A1B9A' }) => (
  <svg width={size} height={size} viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
    {/* Main unit */}
    <rect x="8" y="18" width="32" height="12" rx="2" fill={color} />
    <rect x="10" y="20" width="28" height="8" rx="1" fill="#fff" opacity="0.15" />

    {/* Distribution arrows */}
    <path d="M24 12V18" stroke={color} strokeWidth="2" strokeLinecap="round" />
    <path d="M24 30V36" stroke={color} strokeWidth="2" strokeLinecap="round" />
    <path d="M16 36L20 32L16 28" stroke={color} strokeWidth="2" strokeLinecap="round" fill="none" />
    <path d="M32 36L28 32L32 28" stroke={color} strokeWidth="2" strokeLinecap="round" fill="none" />

    {/* Activity LEDs */}
    {[0, 1, 2, 3].map((i) => (
      <circle key={i} cx={16 + i * 5} cy="24" r="1.5" fill={i % 2 === 0 ? '#4CAF50' : '#2196F3'} />
    ))}
  </svg>
);

// Gateway Icon - Entuity style
export const GatewayIcon: React.FC<DeviceIconProps> = ({ size = 40, color = '#0288D1' }) => (
  <svg width={size} height={size} viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
    {/* Gateway box */}
    <rect x="12" y="16" width="24" height="16" rx="2" fill={color} />
    <rect x="14" y="18" width="20" height="12" rx="1" fill="#fff" opacity="0.15" />

    {/* Input/Output connectors */}
    <circle cx="8" cy="24" r="3" fill={color} />
    <circle cx="40" cy="24" r="3" fill={color} />
    <line x1="11" y1="24" x2="12" y2="24" stroke={color} strokeWidth="2" />
    <line x1="36" y1="24" x2="37" y2="24" stroke={color} strokeWidth="2" />

    {/* Processing indicator */}
    <path
      d="M20 24L24 20L28 24L24 28Z"
      fill="#fff"
      opacity="0.6"
    />

    {/* Status LEDs */}
    <circle cx="18" cy="28" r="1" fill="#4CAF50" />
    <circle cx="24" cy="28" r="1" fill="#2196F3" />
    <circle cx="30" cy="28" r="1" fill="#4CAF50" />
  </svg>
);

// Unknown/Generic Device Icon
export const UnknownDeviceIcon: React.FC<DeviceIconProps> = ({ size = 40, color = '#9E9E9E' }) => (
  <svg width={size} height={size} viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
    <rect x="12" y="12" width="24" height="24" rx="2" fill={color} />
    <rect x="14" y="14" width="20" height="20" rx="1" fill="#fff" opacity="0.2" />
    <text
      x="24"
      y="28"
      textAnchor="middle"
      fill="#fff"
      fontSize="16"
      fontWeight="bold"
    >
      ?
    </text>
  </svg>
);

// Helper function to get the appropriate icon component
export const getDeviceIcon = (
  type: string,
  size?: number,
  color?: string
): React.ReactElement => {
  const props = { size, color };

  switch (type.toLowerCase()) {
    case 'router':
      return <RouterIcon {...props} />;
    case 'switch':
      return <SwitchIcon {...props} />;
    case 'server':
      return <ServerIcon {...props} />;
    case 'firewall':
      return <FirewallIcon {...props} />;
    case 'database':
      return <DatabaseIcon {...props} />;
    case 'wireless':
      return <WirelessIcon {...props} />;
    case 'endpoint':
      return <EndpointIcon {...props} />;
    case 'storage':
      return <StorageIcon {...props} />;
    case 'loadbalancer':
      return <LoadBalancerIcon {...props} />;
    case 'gateway':
      return <GatewayIcon {...props} />;
    default:
      return <UnknownDeviceIcon {...props} />;
  }
};
