# REDP!NG Website Implementation Guide

**Last Updated: December 20, 2024**  
**Version: 1.0**  
**Status: ✅ COMPREHENSIVE IMPLEMENTATION GUIDE**

---

## 🚀 REDP!NG WEBSITE IMPLEMENTATION OVERVIEW

This guide provides step-by-step implementation instructions for the REDP!NG website with advanced SAR SOS ping dashboard functionality.

---

## 🏗️ PROJECT SETUP AND STRUCTURE

### 1. Project Initialization
```bash
# Create Next.js project with TypeScript
npx create-next-app@latest redping-website --typescript --tailwind --eslint --app

# Navigate to project directory
cd redping-website

# Install additional dependencies
npm install @radix-ui/react-dialog @radix-ui/react-dropdown-menu @radix-ui/react-tabs
npm install @radix-ui/react-toast @radix-ui/react-tooltip @radix-ui/react-select
npm install zustand socket.io-client
npm install @googlemaps/js-api-loader
npm install recharts date-fns
npm install lucide-react

# Install development dependencies
npm install -D @types/node @types/react @types/react-dom
npm install -D prettier eslint-config-prettier
```

### 2. Project Structure
```
redping-website/
├── src/
│   ├── app/                    # Next.js App Router
│   │   ├── (auth)/            # Auth routes
│   │   ├── (dashboard)/       # Dashboard routes
│   │   ├── (public)/          # Public routes
│   │   └── layout.tsx         # Root layout
│   ├── components/            # Reusable components
│   │   ├── ui/               # Base UI components
│   │   ├── dashboard/        # Dashboard components
│   │   ├── forms/            # Form components
│   │   └── layout/           # Layout components
│   ├── lib/                  # Utility functions
│   │   ├── api/              # API utilities
│   │   ├── auth/             # Authentication
│   │   ├── db/               # Database utilities
│   │   └── utils/            # General utilities
│   ├── hooks/                # Custom React hooks
│   ├── stores/               # Zustand stores
│   ├── types/                # TypeScript types
│   └── styles/               # Global styles
├── public/                   # Static assets
├── docs/                     # Documentation
└── tests/                    # Test files
```

---

## 🔧 CORE IMPLEMENTATION

### 1. Database Schema Implementation
```sql
-- PostgreSQL Database Schema
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'user',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- SOS Pings table
CREATE TABLE sos_pings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    user_name VARCHAR(255) NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    accuracy DECIMAL(8, 2),
    address TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    type VARCHAR(20) NOT NULL,
    priority VARCHAR(10) NOT NULL DEFAULT 'medium',
    user_message TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    resolved_at TIMESTAMP,
    assigned_team_id UUID
);

-- SAR Teams table
CREATE TABLE sar_teams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    type VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'available',
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    max_response_distance INTEGER DEFAULT 50,
    capabilities TEXT[],
    equipment TEXT[],
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- SAR Members table
CREATE TABLE sar_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID REFERENCES sar_teams(id),
    user_id UUID REFERENCES users(id),
    name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'available',
    location_latitude DECIMAL(10, 8),
    location_longitude DECIMAL(11, 8),
    last_seen TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Emergency Contacts table
CREATE TABLE emergency_contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    type VARCHAR(20) NOT NULL,
    priority INTEGER NOT NULL DEFAULT 1,
    is_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Response Logs table
CREATE TABLE response_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sos_ping_id UUID REFERENCES sos_pings(id),
    team_id UUID REFERENCES sar_teams(id),
    member_id UUID REFERENCES sar_members(id),
    action VARCHAR(50) NOT NULL,
    details TEXT,
    timestamp TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_sos_pings_status ON sos_pings(status);
CREATE INDEX idx_sos_pings_created_at ON sos_pings(created_at);
CREATE INDEX idx_sar_teams_status ON sar_teams(status);
CREATE INDEX idx_sar_members_team_id ON sar_members(team_id);
CREATE INDEX idx_response_logs_sos_ping_id ON response_logs(sos_ping_id);
```

### 2. API Routes Implementation
```typescript
// src/app/api/sos-pings/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { z } from 'zod';

const CreateSOSPingSchema = z.object({
  userId: z.string().uuid(),
  userName: z.string().min(1),
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  accuracy: z.number().optional(),
  address: z.string().optional(),
  type: z.enum(['manual', 'automatic', 'crash', 'fall']),
  priority: z.enum(['low', 'medium', 'high', 'critical']).default('medium'),
  userMessage: z.string().optional(),
});

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const validatedData = CreateSOSPingSchema.parse(body);
    
    const sosPing = await db.sosPing.create({
      data: {
        userId: validatedData.userId,
        userName: validatedData.userName,
        latitude: validatedData.latitude,
        longitude: validatedData.longitude,
        accuracy: validatedData.accuracy,
        address: validatedData.address,
        type: validatedData.type,
        priority: validatedData.priority,
        userMessage: validatedData.userMessage,
        status: 'active',
      },
    });
    
    // Emit real-time update via WebSocket
    await emitWebSocketUpdate('sos_ping', {
      action: 'created',
      ping: sosPing,
    });
    
    return NextResponse.json(sosPing, { status: 201 });
  } catch (error) {
    console.error('Error creating SOS ping:', error);
    return NextResponse.json(
      { error: 'Failed to create SOS ping' },
      { status: 500 }
    );
  }
}

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const status = searchParams.get('status');
    const priority = searchParams.get('priority');
    const limit = parseInt(searchParams.get('limit') || '50');
    
    const sosPings = await db.sosPing.findMany({
      where: {
        ...(status && { status }),
        ...(priority && { priority }),
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
    
    return NextResponse.json(sosPings);
  } catch (error) {
    console.error('Error fetching SOS pings:', error);
    return NextResponse.json(
      { error: 'Failed to fetch SOS pings' },
      { status: 500 }
    );
  }
}
```

### 3. WebSocket Implementation
```typescript
// src/lib/websocket.ts
import { Server } from 'socket.io';
import { NextApiRequest, NextApiResponse } from 'next';

interface ServerToClientEvents {
  sos_ping: (data: { action: string; ping: any }) => void;
  team_update: (data: { action: string; team: any }) => void;
  location_update: (data: { teamId: string; location: any }) => void;
}

interface ClientToServerEvents {
  join_room: (room: string) => void;
  leave_room: (room: string) => void;
  subscribe_to_pings: () => void;
  subscribe_to_teams: () => void;
}

const io = new Server<ClientToServerEvents, ServerToClientEvents>({
  cors: {
    origin: process.env.NEXT_PUBLIC_APP_URL,
    methods: ['GET', 'POST'],
  },
});

io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);
  
  socket.on('join_room', (room) => {
    socket.join(room);
    console.log(`Client ${socket.id} joined room ${room}`);
  });
  
  socket.on('leave_room', (room) => {
    socket.leave(room);
    console.log(`Client ${socket.id} left room ${room}`);
  });
  
  socket.on('subscribe_to_pings', () => {
    socket.join('sos_pings');
    console.log(`Client ${socket.id} subscribed to SOS pings`);
  });
  
  socket.on('subscribe_to_teams', () => {
    socket.join('sar_teams');
    console.log(`Client ${socket.id} subscribed to SAR teams`);
  });
  
  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });
});

export const emitWebSocketUpdate = async (
  type: string,
  data: any
) => {
  switch (type) {
    case 'sos_ping':
      io.to('sos_pings').emit('sos_ping', data);
      break;
    case 'team_update':
      io.to('sar_teams').emit('team_update', data);
      break;
    case 'location_update':
      io.to('sar_teams').emit('location_update', data);
      break;
  }
};

export default io;
```

---

## 🎨 FRONTEND COMPONENTS IMPLEMENTATION

### 1. Dashboard Layout Component
```tsx
// src/components/layout/DashboardLayout.tsx
'use client';

import React, { useState } from 'react';
import { DashboardHeader } from './DashboardHeader';
import { DashboardSidebar } from './DashboardSidebar';
import { DashboardMain } from './DashboardMain';
import { DashboardRightbar } from './DashboardRightbar';
import { DashboardFooter } from './DashboardFooter';

interface DashboardLayoutProps {
  children: React.ReactNode;
}

export const DashboardLayout: React.FC<DashboardLayoutProps> = ({ children }) => {
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [rightbarOpen, setRightbarOpen] = useState(true);
  
  return (
    <div className="dashboard-layout">
      <DashboardHeader 
        onMenuClick={() => setSidebarOpen(!sidebarOpen)}
        onNotificationsClick={() => setRightbarOpen(!rightbarOpen)}
      />
      
      <div className="dashboard-content">
        <DashboardSidebar 
          isOpen={sidebarOpen}
          onClose={() => setSidebarOpen(false)}
        />
        
        <DashboardMain>
          {children}
        </DashboardMain>
        
        <DashboardRightbar 
          isOpen={rightbarOpen}
          onClose={() => setRightbarOpen(false)}
        />
      </div>
      
      <DashboardFooter />
    </div>
  );
};
```

### 2. SOS Ping Card Component
```tsx
// src/components/dashboard/SOSPingCard.tsx
'use client';

import React from 'react';
import { SOSPing } from '@/types';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { TimeAgo } from '@/components/ui/TimeAgo';
import { Button } from '@/components/ui/Button';
import { MapPin, User, MessageSquare, Clock } from 'lucide-react';

interface SOSPingCardProps {
  ping: SOSPing;
  onSelect: (ping: SOSPing) => void;
  onAssign: (ping: SOSPing) => void;
  onUpdate: (ping: SOSPing, status: string) => void;
}

export const SOSPingCard: React.FC<SOSPingCardProps> = ({
  ping,
  onSelect,
  onAssign,
  onUpdate,
}) => {
  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'critical': return 'text-red-600 bg-red-50 border-red-200';
      case 'high': return 'text-orange-600 bg-orange-50 border-orange-200';
      case 'medium': return 'text-yellow-600 bg-yellow-50 border-yellow-200';
      case 'low': return 'text-green-600 bg-green-50 border-green-200';
      default: return 'text-gray-600 bg-gray-50 border-gray-200';
    }
  };

  return (
    <div className={`sos-ping-card border rounded-lg p-4 mb-4 ${getPriorityColor(ping.priority)}`}>
      {/* Header */}
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center space-x-2">
          <span className="text-2xl">🔴</span>
          <span className="font-semibold text-lg">SOS #{ping.id.slice(-6)}</span>
        </div>
        <div className="flex items-center space-x-2">
          <StatusBadge status={ping.status} />
          <TimeAgo timestamp={new Date(ping.createdAt)} />
        </div>
      </div>
      
      {/* Content */}
      <div className="space-y-2 mb-4">
        <div className="flex items-center space-x-2">
          <MapPin className="w-4 h-4 text-gray-500" />
          <span className="text-sm text-gray-700">{ping.address}</span>
        </div>
        
        <div className="flex items-center space-x-2">
          <User className="w-4 h-4 text-gray-500" />
          <span className="text-sm text-gray-700">{ping.userName}</span>
        </div>
        
        {ping.userMessage && (
          <div className="flex items-start space-x-2">
            <MessageSquare className="w-4 h-4 text-gray-500 mt-0.5" />
            <span className="text-sm text-gray-700">{ping.userMessage}</span>
          </div>
        )}
        
        <div className="flex items-center space-x-2">
          <Clock className="w-4 h-4 text-gray-500" />
          <span className="text-sm text-gray-700">
            {ping.type.charAt(0).toUpperCase() + ping.type.slice(1)} SOS
          </span>
        </div>
      </div>
      
      {/* Actions */}
      <div className="flex space-x-2">
        <Button 
          variant="primary" 
          size="sm"
          onClick={() => onSelect(ping)}
        >
          View Details
        </Button>
        <Button 
          variant="secondary" 
          size="sm"
          onClick={() => onAssign(ping)}
        >
          Assign Team
        </Button>
        <Button 
          variant="outline" 
          size="sm"
          onClick={() => onUpdate(ping, 'resolved')}
        >
          Resolve
        </Button>
      </div>
    </div>
  );
};
```

### 3. Interactive Map Component
```tsx
// src/components/dashboard/InteractiveMap.tsx
'use client';

import React, { useCallback, useRef, useEffect } from 'react';
import { GoogleMap, Marker, InfoWindow, useJsApiLoader } from '@react-google-maps/api';
import { SOSPing, SARTeam } from '@/types';

interface InteractiveMapProps {
  sosPings: SOSPing[];
  sarTeams: SARTeam[];
  center: { lat: number; lng: number };
  zoom: number;
  onPingClick: (ping: SOSPing) => void;
  onTeamClick: (team: SARTeam) => void;
}

const mapContainerStyle = {
  width: '100%',
  height: '500px',
};

const libraries: ('places' | 'geometry')[] = ['places', 'geometry'];

export const InteractiveMap: React.FC<InteractiveMapProps> = ({
  sosPings,
  sarTeams,
  center,
  zoom,
  onPingClick,
  onTeamClick,
}) => {
  const { isLoaded } = useJsApiLoader({
    id: 'google-map-script',
    googleMapsApiKey: process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY!,
    libraries,
  });

  const [selectedPing, setSelectedPing] = React.useState<SOSPing | null>(null);
  const [selectedTeam, setSelectedTeam] = React.useState<SARTeam | null>(null);

  const getSOSPingIcon = (priority: string) => {
    const baseUrl = '/icons/sos-ping';
    switch (priority) {
      case 'critical': return `${baseUrl}-critical.png`;
      case 'high': return `${baseUrl}-high.png`;
      case 'medium': return `${baseUrl}-medium.png`;
      case 'low': return `${baseUrl}-low.png`;
      default: return `${baseUrl}-default.png`;
    }
  };

  const getTeamIcon = (status: string) => {
    const baseUrl = '/icons/team';
    switch (status) {
      case 'available': return `${baseUrl}-available.png`;
      case 'busy': return `${baseUrl}-busy.png`;
      case 'enroute': return `${baseUrl}-enroute.png`;
      case 'onscene': return `${baseUrl}-onscene.png`;
      default: return `${baseUrl}-offline.png`;
    }
  };

  if (!isLoaded) {
    return <div className="flex items-center justify-center h-96">Loading map...</div>;
  }

  return (
    <div className="interactive-map">
      <GoogleMap
        mapContainerStyle={mapContainerStyle}
        center={center}
        zoom={zoom}
        options={{
          styles: [
            {
              featureType: 'poi',
              elementType: 'labels',
              stylers: [{ visibility: 'off' }],
            },
          ],
        }}
      >
        {/* SOS Ping Markers */}
        {sosPings.map((ping) => (
          <Marker
            key={ping.id}
            position={{ lat: ping.latitude, lng: ping.longitude }}
            icon={{
              url: getSOSPingIcon(ping.priority),
              scaledSize: new google.maps.Size(32, 32),
            }}
            onClick={() => {
              setSelectedPing(ping);
              onPingClick(ping);
            }}
          >
            {selectedPing?.id === ping.id && (
              <InfoWindow onCloseClick={() => setSelectedPing(null)}>
                <div className="p-2">
                  <h3 className="font-semibold text-lg">SOS #{ping.id.slice(-6)}</h3>
                  <p className="text-sm text-gray-600">{ping.userName}</p>
                  <p className="text-sm text-gray-600">{ping.address}</p>
                  <div className="mt-2">
                    <span className={`inline-block px-2 py-1 rounded text-xs font-medium ${
                      ping.priority === 'critical' ? 'bg-red-100 text-red-800' :
                      ping.priority === 'high' ? 'bg-orange-100 text-orange-800' :
                      ping.priority === 'medium' ? 'bg-yellow-100 text-yellow-800' :
                      'bg-green-100 text-green-800'
                    }`}>
                      {ping.priority.toUpperCase()}
                    </span>
                  </div>
                </div>
              </InfoWindow>
            )}
          </Marker>
        ))}

        {/* SAR Team Markers */}
        {sarTeams.map((team) => (
          <Marker
            key={team.id}
            position={{ lat: team.latitude!, lng: team.longitude! }}
            icon={{
              url: getTeamIcon(team.status),
              scaledSize: new google.maps.Size(24, 24),
            }}
            onClick={() => {
              setSelectedTeam(team);
              onTeamClick(team);
            }}
          >
            {selectedTeam?.id === team.id && (
              <InfoWindow onCloseClick={() => setSelectedTeam(null)}>
                <div className="p-2">
                  <h3 className="font-semibold text-lg">{team.name}</h3>
                  <p className="text-sm text-gray-600">Status: {team.status}</p>
                  <p className="text-sm text-gray-600">Members: {team.members?.length || 0}</p>
                </div>
              </InfoWindow>
            )}
          </Marker>
        ))}
      </GoogleMap>
    </div>
  );
};
```

---

## 🔄 REAL-TIME IMPLEMENTATION

### 1. WebSocket Hook
```tsx
// src/hooks/useWebSocket.ts
import { useEffect, useRef, useState } from 'react';
import { io, Socket } from 'socket.io-client';

interface WebSocketMessage {
  type: string;
  data: any;
  timestamp: Date;
}

export const useWebSocket = (url: string) => {
  const [socket, setSocket] = useState<Socket | null>(null);
  const [isConnected, setIsConnected] = useState(false);
  const [lastMessage, setLastMessage] = useState<WebSocketMessage | null>(null);

  useEffect(() => {
    const newSocket = io(url, {
      transports: ['websocket'],
      upgrade: true,
    });

    newSocket.on('connect', () => {
      console.log('Connected to WebSocket');
      setIsConnected(true);
    });

    newSocket.on('disconnect', () => {
      console.log('Disconnected from WebSocket');
      setIsConnected(false);
    });

    newSocket.on('sos_ping', (data) => {
      setLastMessage({
        type: 'sos_ping',
        data,
        timestamp: new Date(),
      });
    });

    newSocket.on('team_update', (data) => {
      setLastMessage({
        type: 'team_update',
        data,
        timestamp: new Date(),
      });
    });

    newSocket.on('location_update', (data) => {
      setLastMessage({
        type: 'location_update',
        data,
        timestamp: new Date(),
      });
    });

    setSocket(newSocket);

    return () => {
      newSocket.close();
    };
  }, [url]);

  const subscribeToPings = () => {
    if (socket) {
      socket.emit('subscribe_to_pings');
    }
  };

  const subscribeToTeams = () => {
    if (socket) {
      socket.emit('subscribe_to_teams');
    }
  };

  const joinRoom = (room: string) => {
    if (socket) {
      socket.emit('join_room', room);
    }
  };

  const leaveRoom = (room: string) => {
    if (socket) {
      socket.emit('leave_room', room);
    }
  };

  return {
    socket,
    isConnected,
    lastMessage,
    subscribeToPings,
    subscribeToTeams,
    joinRoom,
    leaveRoom,
  };
};
```

### 2. Real-Time Dashboard Hook
```tsx
// src/hooks/useRealtimeDashboard.ts
import { useEffect, useState } from 'react';
import { useWebSocket } from './useWebSocket';
import { SOSPing, SARTeam } from '@/types';

export const useRealtimeDashboard = () => {
  const [sosPings, setSosPings] = useState<SOSPing[]>([]);
  const [sarTeams, setSarTeams] = useState<SARTeam[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const { socket, isConnected, lastMessage, subscribeToPings, subscribeToTeams } = useWebSocket(
    process.env.NEXT_PUBLIC_WEBSOCKET_URL || 'ws://localhost:3001'
  );

  // Subscribe to real-time updates
  useEffect(() => {
    if (isConnected) {
      subscribeToPings();
      subscribeToTeams();
    }
  }, [isConnected, subscribeToPings, subscribeToTeams]);

  // Handle real-time messages
  useEffect(() => {
    if (lastMessage) {
      switch (lastMessage.type) {
        case 'sos_ping':
          handleSOSPingUpdate(lastMessage.data);
          break;
        case 'team_update':
          handleTeamUpdate(lastMessage.data);
          break;
        case 'location_update':
          handleLocationUpdate(lastMessage.data);
          break;
      }
    }
  }, [lastMessage]);

  const handleSOSPingUpdate = (data: any) => {
    const { action, ping } = data;
    
    switch (action) {
      case 'created':
        setSosPings(prev => [ping, ...prev]);
        break;
      case 'updated':
        setSosPings(prev => prev.map(p => p.id === ping.id ? ping : p));
        break;
      case 'resolved':
        setSosPings(prev => prev.map(p => p.id === ping.id ? { ...p, status: 'resolved' } : p));
        break;
    }
  };

  const handleTeamUpdate = (data: any) => {
    const { action, team } = data;
    
    switch (action) {
      case 'status_change':
        setSarTeams(prev => prev.map(t => t.id === team.id ? { ...t, status: team.status } : t));
        break;
      case 'location_update':
        setSarTeams(prev => prev.map(t => t.id === team.id ? { ...t, latitude: team.latitude, longitude: team.longitude } : t));
        break;
    }
  };

  const handleLocationUpdate = (data: any) => {
    const { teamId, location } = data;
    setSarTeams(prev => prev.map(t => 
      t.id === teamId 
        ? { ...t, latitude: location.latitude, longitude: location.longitude }
        : t
    ));
  };

  // Load initial data
  useEffect(() => {
    const loadInitialData = async () => {
      try {
        const [pingsResponse, teamsResponse] = await Promise.all([
          fetch('/api/sos-pings'),
          fetch('/api/sar-teams'),
        ]);
        
        const pings = await pingsResponse.json();
        const teams = await teamsResponse.json();
        
        setSosPings(pings);
        setSarTeams(teams);
        setIsLoading(false);
      } catch (error) {
        console.error('Error loading initial data:', error);
        setIsLoading(false);
      }
    };

    loadInitialData();
  }, []);

  return {
    sosPings,
    sarTeams,
    isLoading,
    isConnected,
    socket,
  };
};
```

---

## 🎨 STYLING IMPLEMENTATION

### 1. Tailwind CSS Configuration
```javascript
// tailwind.config.js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        'redping-red': '#E53E3E',
        'redping-green': '#38A169',
        'redping-orange': '#ED8936',
        'redping-blue': '#3182CE',
        'redping-purple': '#805AD5',
        'status-critical': '#C53030',
        'status-high': '#E53E3E',
        'status-medium': '#ED8936',
        'status-low': '#38A169',
        'status-resolved': '#68D391',
        'team-available': '#38A169',
        'team-busy': '#ED8936',
        'team-offline': '#A0AEC0',
        'team-enroute': '#3182CE',
        'team-onscene': '#805AD5',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
      animation: {
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'bounce-slow': 'bounce 2s infinite',
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
};
```

### 2. Global Styles
```css
/* src/styles/globals.css */
@import 'tailwindcss/base';
@import 'tailwindcss/components';
@import 'tailwindcss/utilities';

@layer base {
  :root {
    --redping-red: #E53E3E;
    --redping-green: #38A169;
    --redping-orange: #ED8936;
    --redping-blue: #3182CE;
    --redping-purple: #805AD5;
  }
  
  * {
    @apply border-border;
  }
  
  body {
    @apply bg-background text-foreground;
  }
}

@layer components {
  .dashboard-layout {
    @apply min-h-screen bg-gray-50;
  }
  
  .dashboard-header {
    @apply bg-white shadow-sm border-b border-gray-200;
  }
  
  .dashboard-sidebar {
    @apply bg-white shadow-sm border-r border-gray-200;
  }
  
  .dashboard-main {
    @apply flex-1 p-6;
  }
  
  .dashboard-rightbar {
    @apply bg-white shadow-sm border-l border-gray-200;
  }
  
  .sos-ping-card {
    @apply bg-white rounded-lg shadow-sm border border-gray-200 p-4 mb-4;
  }
  
  .sos-ping-card--critical {
    @apply border-red-200 bg-red-50;
  }
  
  .sos-ping-card--high {
    @apply border-orange-200 bg-orange-50;
  }
  
  .sos-ping-card--medium {
    @apply border-yellow-200 bg-yellow-50;
  }
  
  .sos-ping-card--low {
    @apply border-green-200 bg-green-50;
  }
  
  .status-badge {
    @apply inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium;
  }
  
  .status-badge--critical {
    @apply bg-red-100 text-red-800;
  }
  
  .status-badge--high {
    @apply bg-orange-100 text-orange-800;
  }
  
  .status-badge--medium {
    @apply bg-yellow-100 text-yellow-800;
  }
  
  .status-badge--low {
    @apply bg-green-100 text-green-800;
  }
  
  .status-badge--resolved {
    @apply bg-green-100 text-green-800;
  }
  
  .interactive-map {
    @apply w-full h-96 rounded-lg overflow-hidden border border-gray-200;
  }
}

@layer utilities {
  .text-balance {
    text-wrap: balance;
  }
}
```

---

## 🚀 DEPLOYMENT CONFIGURATION

### 1. Environment Variables
```bash
# .env.local
NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXT_PUBLIC_WEBSOCKET_URL=ws://localhost:3001
NEXT_PUBLIC_GOOGLE_MAPS_API_KEY=your_google_maps_api_key

DATABASE_URL=postgresql://username:password@localhost:5432/redping_website
REDIS_URL=redis://localhost:6379

NEXTAUTH_SECRET=your_nextauth_secret
NEXTAUTH_URL=http://localhost:3000

FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_PRIVATE_KEY=your_firebase_private_key
FIREBASE_CLIENT_EMAIL=your_firebase_client_email
```

### 2. Docker Configuration
```dockerfile
# Dockerfile
FROM node:18-alpine AS base

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN npm run build

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public

# Set the correct permission for prerender cache
RUN mkdir .next
RUN chown nextjs:nodejs .next

# Automatically leverage output traces to reduce image size
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

CMD ["node", "server.js"]
```

### 3. Docker Compose
```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://postgres:password@db:5432/redping_website
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis
    volumes:
      - ./uploads:/app/uploads

  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=redping_website
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - app

volumes:
  postgres_data:
  redis_data:
```

---

## 📊 MONITORING AND ANALYTICS

### 1. Performance Monitoring
```typescript
// src/lib/analytics.ts
import { Analytics } from '@vercel/analytics/react';

export const trackEvent = (eventName: string, properties?: Record<string, any>) => {
  if (typeof window !== 'undefined') {
    // Google Analytics
    gtag('event', eventName, properties);
    
    // Custom analytics
    fetch('/api/analytics', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ event: eventName, properties }),
    });
  }
};

export const trackSOSPing = (ping: SOSPing) => {
  trackEvent('sos_ping_created', {
    ping_id: ping.id,
    priority: ping.priority,
    type: ping.type,
    location: `${ping.latitude},${ping.longitude}`,
  });
};

export const trackTeamResponse = (team: SARTeam, ping: SOSPing) => {
  trackEvent('team_response', {
    team_id: team.id,
    ping_id: ping.id,
    response_time: Date.now() - new Date(ping.createdAt).getTime(),
  });
};
```

### 2. Error Tracking
```typescript
// src/lib/error-tracking.ts
export const logError = (error: Error, context?: Record<string, any>) => {
  console.error('Error:', error);
  
  // Send to error tracking service
  fetch('/api/errors', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      message: error.message,
      stack: error.stack,
      context,
      timestamp: new Date().toISOString(),
    }),
  });
};

export const withErrorTracking = (fn: Function) => {
  return (...args: any[]) => {
    try {
      return fn(...args);
    } catch (error) {
      logError(error as Error, { function: fn.name, args });
      throw error;
    }
  };
};
```

---

**IMPLEMENTATION STATUS**: ✅ **COMPREHENSIVE IMPLEMENTATION GUIDE COMPLETE**

**The REDP!NG Website Implementation Guide provides complete, production-ready implementation instructions for the website with advanced SAR SOS ping dashboard functionality, real-time communication, and comprehensive monitoring. The implementation is designed for scalability, reliability, and real-time emergency response coordination.**
