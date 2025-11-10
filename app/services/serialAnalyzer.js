/**
 * Serial Communication Service untuk Fire Alarm Panel
 * Menganalisa koneksi COM21 baud rate 38400
 * Note: Serial port communication tidak available di React Native
 * Ini untuk Node.js testing environment
 */

// Mock untuk React Native environment
class SerialAnalyzer {
  constructor() {
    this.port = null;
    this.parser = null;
    this.isConnected = false;
    this.buffer = '';
    this.stats = {
      totalBytes: 0,
      messages: [],
      errors: 0,
      lastMessage: null
    };
  }

  /**
   * Connect ke COM21 dengan baud rate 38400
   */
  async connect() {
    try {
      console.log('🔌 Serial port connection not available in React Native');
      console.log('📌 For testing, use Node.js environment with COM21 @ 38400 baud');
      
      // Simulate connection untuk testing
      setTimeout(() => {
        this.isConnected = true;
        console.log('✅ Simulated COM21 connected at 38400 baud');
      }, 1000);

      return true;
    } catch (error) {
      console.error('❌ Connection error:', error);
      throw error;
    }
  }

  /**
   * Handle incoming data (simulated)
   */
  handleData(data) {
    try {
      const cleanData = data.trim();
      this.buffer += cleanData;
      
      // Log data
      const message = {
        timestamp: Date.now(),
        data: cleanData,
        raw: data,
        length: cleanData.length
      };

      this.stats.messages.push(message);
      this.stats.lastMessage = message;
      this.stats.totalBytes += cleanData.length;

      // Keep only last 1000 messages
      if (this.stats.messages.length > 1000) {
        this.stats.messages = this.stats.messages.slice(-1000);
      }

      // Fire alarm data pattern detection
      this.analyzeFireAlarmData(cleanData);
      
    } catch (error) {
      console.error('❌ Data handling error:', error);
      this.stats.errors++;
    }
  }

  /**
   * Analisa pattern data fire alarm
   */
  analyzeFireAlarmData(data) {
    // Pattern untuk fire alarm hex data
    const fireAlarmPattern = /^[0-9A-Fa-f<STX><ETX>]+$/;
    
    if (fireAlarmPattern.test(data)) {
      console.log('🚨 Fire Alarm Data Detected:', data);
      
      // Parse master status (4 digit pertama)
      if (data.length >= 4) {
        const masterStatus = data.substring(0, 4);
        console.log('📊 Master Status:', masterStatus);
        this.parseMasterStatus(masterStatus);
      }
      
      // Parse slave data
      this.parseSlaveData(data);
    }
  }

  /**
   * Parse master status byte
   */
  parseMasterStatus(masterHex) {
    try {
      const header = masterHex.substring(0, 2); // 40
      const statusByte = masterHex.substring(2, 4); // 5F, 57, dll
      const statusValue = parseInt(statusByte, 16);
      
      const masterStatus = {
        header: header,
        statusByte: statusByte,
        statusValue: statusValue,
        backlight_lcd: (statusValue & 0x80) === 0,      // Bit 7: 0=ON
        ac_power: (statusValue & 0x40) === 0,           // Bit 6: 0=ON
        dc_power: (statusValue & 0x20) === 0,           // Bit 5: 0=ON
        alarm_active: (statusValue & 0x10) === 0,       // Bit 4: 0=ACTIVE
        trouble_active: (statusValue & 0x08) === 0,     // Bit 3: 0=ACTIVE
        supervisory: (statusValue & 0x04) === 0,        // Bit 2: 0=ACTIVE (DRILL)
        silenced: (statusValue & 0x02) === 0,           // Bit 1: 0=ACTIVE
        disabled: (statusValue & 0x01) === 0           // Bit 0: 0=ACTIVE
      };

      console.log('🎛 Parsed Master Status:', masterStatus);
      return masterStatus;
    } catch (error) {
      console.error('❌ Master status parsing error:', error);
      return null;
    }
  }

  /**
   * Parse slave data
   */
  parseSlaveData(fullData) {
    try {
      const segments = fullData.split('<STX>');
      const slaves = [];
      
      for (let i = 1; i < segments.length; i++) {
        const segment = segments[i].replace('<ETX>', '').trim();
        
        if (segment.length === 2) {
          // Slave offline - hanya address
          const address = parseInt(segment, 16);
          slaves.push({
            address: segment,
            addressInt: address,
            online: false,
            status: 'OFFLINE'
          });
        } else if (segment.length === 6) {
          // Slave online - address + status
          const address = segment.substring(0, 2);
          const statusHex = segment.substring(2);
          const statusValue = parseInt(statusHex, 16);
          
          slaves.push({
            address: address,
            addressInt: parseInt(address, 16),
            online: true,
            status: this.getSlaveStatus(statusValue),
            statusHex: statusHex,
            statusValue: statusValue,
            alarm_zones: this.getZones(statusValue & 0x1F),
            trouble_zones: this.getZones((statusValue >> 8) & 0x1F),
            bell_active: (statusValue & 0x20) !== 0
          });
        }
      }
      
      console.log('📡 Parsed Slaves:', slaves);
      return slaves;
    } catch (error) {
      console.error('❌ Slave data parsing error:', error);
      return [];
    }
  }

  /**
   * Get slave status from status value
   */
  getSlaveStatus(statusValue) {
    if (statusValue === 0x0000) return 'NORMAL';
    if ((statusValue & 0xFF00) !== 0x0000) return 'TROUBLE';
    return 'ALARM';
  }

  /**
   * Extract active zones from status bits
   */
  getZones(zoneBits) {
    const zones = [];
    for (let i = 0; i < 5; i++) {
      if (zoneBits & (1 << i)) {
        zones.push(i + 1);
      }
    }
    return zones;
  }

  /**
   * Send command ke fire alarm panel
   */
  async sendCommand(command) {
    if (!this.isConnected) {
      throw new Error('Serial port not connected');
    }

    try {
      console.log('📤 Sending command (simulated):', command);
      
      // Simulate command sending
      setTimeout(() => {
        console.log('✅ Command sent successfully (simulated)');
      }, 500);
      
      return true;
    } catch (error) {
      console.error('❌ Command send error:', error);
      throw error;
    }
  }

  /**
   * Get connection statistics
   */
  getStats() {
    return {
      ...this.stats,
      isConnected: this.isConnected,
      messageCount: this.stats.messages.length,
      averageMessageLength: this.stats.messages.length > 0 
        ? this.stats.totalBytes / this.stats.messages.length 
        : 0
    };
  }

  /**
   * Disconnect
   */
  async disconnect() {
    if (this.isConnected) {
      try {
        this.isConnected = false;
        console.log('🔌 Simulated disconnection from COM21');
      } catch (error) {
        console.error('❌ Disconnect error:', error);
      }
    }
  }
}

module.exports = SerialAnalyzer;