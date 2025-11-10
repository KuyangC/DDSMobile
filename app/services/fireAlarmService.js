import { db } from '../config/firebaseConfig';
import { ref, set, update, get } from 'firebase/database';
import logService from './logService';

/**
 * Service for controlling fire alarm panel commands via Firebase
 * These commands will be picked up by the backend/ESP32 to control the actual fire alarm panel
 */

// Path untuk command ke fire alarm panel
const COMMAND_PATH = 'fire_alarm_commands';
const STATUS_PATH = 'all_slave_data';

/**
 * Generate hex command for different fire alarm operations
 * Based on the master status byte structure from hexa_slave.md
 * Active Low logic: 0 = ON/ACTIVE, 1 = OFF/INACTIVE
 */
const generateMasterStatusCommand = (currentStatus, operation) => {
  let newStatus = { ...currentStatus };
  
  switch (operation) {
    case 'SYSTEM_RESET':
      // Reset semua status ke normal (semua bits = 1 = OFF/INACTIVE)
      newStatus = {
        backlight_lcd: false,    // Bit 7 = OFF
        ac_power: true,          // Bit 6 = ON
        dc_power: true,          // Bit 5 = ON
        alarm_active: false,     // Bit 4 = OFF
        trouble_active: false,   // Bit 3 = OFF
        supervisory: false,      // Bit 2 = OFF (DRILL mode)
        silenced: false,         // Bit 1 = OFF
        disabled: false,         // Bit 0 = OFF
      };
      break;
      
    case 'ACKNOWLEDGE':
      // Matikan alarm tapi tandai sudah di-ack
      newStatus.alarm_active = false;
      newStatus.silenced = true;  // Bell dimatikan setelah acknowledge
      break;
      
    case 'DRILL':
      // Toggle drill mode (supervisory)
      newStatus.supervisory = !newStatus.supervisory;
      break;
      
    case 'SILENCED':
      // Toggle silenced status (bell on/off)
      newStatus.silenced = !newStatus.silenced;
      break;
      
    default:
      return null;
  }
  
  // Convert status object to hex byte
  let statusByte = 0x40; // Header (40 hex)
  
  if (!newStatus.backlight_lcd) statusByte |= 0x80;    // Bit 7
  if (!newStatus.ac_power) statusByte |= 0x40;        // Bit 6
  if (!newStatus.dc_power) statusByte |= 0x20;        // Bit 5
  if (!newStatus.alarm_active) statusByte |= 0x10;   // Bit 4
  if (!newStatus.trouble_active) statusByte |= 0x08; // Bit 3
  if (!newStatus.supervisory) statusByte |= 0x04;     // Bit 2
  if (!newStatus.silenced) statusByte |= 0x02;       // Bit 1
  if (!newStatus.disabled) statusByte |= 0x01;       // Bit 0
  
  return {
    hexCommand: statusByte.toString(16).toUpperCase().padStart(2, '0'),
    newStatus: newStatus
  };
};

/**
 * Send command to fire alarm panel via Firebase
 */
export const sendFireAlarmCommand = async (operation, currentMasterStatus) => {
  if (!db) {
    throw new Error('Firebase not available');
  }
  
  try {
    // Generate command based on operation
    const commandData = generateMasterStatusCommand(currentMasterStatus, operation);
    
    if (!commandData) {
      throw new Error(`Unknown operation: ${operation}`);
    }
    
    // Create command object
    const command = {
      operation: operation,
      statusByte: commandData.hexCommand,
      newStatus: commandData.newStatus,
      timestamp: Date.now(),
      status: 'pending' // pending -> processing -> completed/failed
    };
    
    // Write command to Firebase
    const commandRef = ref(db, `${COMMAND_PATH}/${Date.now()}`);
    await set(commandRef, command);
    
    // Log command event
    try {
      await logService.logEvent('COMMAND', `${operation} executed`, null, null, { 
        operation, 
        statusByte: commandData.hexCommand 
      });
    } catch (logError) {
      console.warn('Failed to log command:', logError);
    }
    
    console.log(`✅ Fire alarm command sent: ${operation}`, command);
    return {
      success: true,
      command: command,
      message: `Command ${operation} sent successfully`
    };
    
  } catch (error) {
    console.error(`❌ Failed to send fire alarm command:`, error);
    throw error;
  }
};

/**
 * Update master status directly in Firebase (for immediate UI updates)
 */
export const updateMasterStatus = async (newStatus) => {
  if (!db) {
    throw new Error('Firebase not available');
  }
  
  try {
    const statusRef = ref(db, STATUS_PATH);
    
    // Get current data first
    const snapshot = await get(statusRef);
    const currentData = snapshot.val() || {};
    
    // Update only the master status portion
    // Format: [HEADER][STATUS_BYTE][<STX>SLAVE_DATA]...
    let currentRawData = currentData.raw_data || '40FF'; // Default value
    
    // Extract and replace the master status byte (digits 2-4)
    const newData = currentRawData.substring(0, 2) + newStatus.statusByte + currentRawData.substring(4);
    
    const updatedData = {
      ...currentData,
      raw_data: newData,
      master_command: true, // Mark as master command
      last_updated: Date.now()
    };
    
    await update(statusRef, updatedData);
    
    console.log(`✅ Master status updated:`, newStatus);
    return {
      success: true,
      message: 'Master status updated successfully'
    };
    
  } catch (error) {
    console.error(`❌ Failed to update master status:`, error);
    throw error;
  }
};

/**
 * Get command history from Firebase
 */
export const getCommandHistory = async () => {
  if (!db) {
    throw new Error('Firebase not available');
  }
  
  try {
    const commandRef = ref(db, COMMAND_PATH);
    const snapshot = await get(commandRef);
    return snapshot.val() || {};
  } catch (error) {
    console.error('❌ Failed to get command history:', error);
    throw error;
  }
};

// Export individual command functions for easier usage
export const fireAlarmCommands = {
  systemReset: (currentStatus) => sendFireAlarmCommand('SYSTEM_RESET', currentStatus),
  acknowledge: (currentStatus) => sendFireAlarmCommand('ACKNOWLEDGE', currentStatus),
  drill: (currentStatus) => sendFireAlarmCommand('DRILL', currentStatus),
  silenced: (currentStatus) => sendFireAlarmCommand('SILENCED', currentStatus),
  updateStatus: (newStatus) => updateMasterStatus(newStatus)
};

export default {
  sendFireAlarmCommand,
  updateMasterStatus,
  getCommandHistory,
  fireAlarmCommands
};