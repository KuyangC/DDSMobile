# Fire Alarm Command Implementation

## Overview
Implementation of fire alarm panel commands (System Reset, Acknowledge, Drill, Silenced) connected to Firebase backend.

## Architecture

### 1. Fire Alarm Service (`app/services/fireAlarmService.js`)
- **generateMasterStatusCommand()**: Convert operations to hex commands based on master status byte
- **sendFireAlarmCommand()**: Send commands to Firebase path `fire_alarm_commands`
- **updateMasterStatus()**: Direct status update for immediate UI changes
- **fireAlarmCommands**: Exported functions for easy usage

### 2. Updated Navbar (`app/pages/mainPage/navbar.tsx`)
- **handleFireAlarmCommand()**: Command handler with confirmation dialogs
- **TouchableOpacity**: Convert static buttons to interactive
- **Alert**: User feedback for successful/failed operations

## Command Logic

### Master Status Byte Structure (Active Low Logic)
```
Bit 7 (0x80): Backlight LCD    - 0=ON, 1=OFF
Bit 6 (0x40): AC Power         - 0=ON, 1=OFF
Bit 5 (0x20): DC Power         - 0=ON, 1=OFF
Bit 4 (0x10): Alarm Active     - 0=ACTIVE, 1=INACTIVE
Bit 3 (0x08): Trouble Active   - 0=ACTIVE, 1=INACTIVE
Bit 2 (0x04): Supervisory      - 0=ACTIVE, 1=INACTIVE (DRILL mode)
Bit 1 (0x02): Silenced         - 0=ACTIVE, 1=INACTIVE
Bit 0 (0x01): Disabled         - 0=ACTIVE, 1=INACTIVE
```

### Command Behaviors

1. **SYSTEM_RESET**
   - Reset semua status ke normal
   - Confirmation dialog required
   - Bell dimatikan, alarm di-clear
   - Mengubah master status di backend

2. **ACKNOWLEDGE**
   - Matikan alarm status
   - Aktifkan silenced mode di backend
   - Status tetap tersimpan di history

3. **DRILL**
   - Toggle supervisory bit (Bit 2)
   - Mode latihan kebakaran
   - Non-emergency mode
   - Mengubah master status di backend

4. **SILENCED** (App-Only)
   - Toggle silence state aplikasi saja
   - **TIDAK** mengubah master status backend
   - Hanya membisukan notifikasi/suara di app
   - Fire alarm panel tetap aktif
   - Data tersimpan di `app_state/silence`

## Firebase Structure

### Commands Path: `fire_alarm_commands/{timestamp}`
```javascript
{
  operation: "SYSTEM_RESET",
  statusByte: "FF",
  newStatus: { /* full status object */ },
  timestamp: 1699123456789,
  status: "pending"
}
```

### Status Update Path: `all_slave_data`
```javascript
{
  raw_data: "40FF<STX>...", // Updated master status byte
  master_command: true,      // Mark as master command
  last_updated: 1699123456789
}
```

### App State Path: `app_state/silence`
```javascript
{
  silenced: true,            // App-only silence state
  timestamp: 1699123456789,
  type: "app_only"          // Mark as local app change
}
```

## Backend Integration

Backend/ESP32 should:
1. Listen to `fire_alarm_commands` path
2. Process command and control physical fire alarm panel
3. Update `all_slave_data` with new status
4. Mark command as `completed` or `failed`

## Usage Examples

```javascript
// System reset with confirmation
await fireAlarmCommands.systemReset(masterStatus);

// Acknowledge alarm
await fireAlarmCommands.acknowledge(masterStatus);

// Toggle drill mode
await fireAlarmCommands.drill(masterStatus);

// Toggle bell silence (backend)
await fireAlarmCommands.silenced(masterStatus);

// Toggle app silence (local only)
await appCommands.toggleSilence(isAppSilenced);
```

## Error Handling

- Firebase connection errors
- Invalid operations
- Command execution failures
- User confirmation required for critical operations

## Security Considerations

- Commands should be authenticated
- Audit trail in command history
- Confirmation for destructive operations
- Role-based access control (future enhancement)