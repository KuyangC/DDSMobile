/**
 * ESP32 HTTP Communication Service for React Native
 * Menganalisa koneksi ke http://192.168.43.246
 */

import axios from 'axios';

class ESP32Analyzer {
  constructor() {
    this.baseUrl = 'http://192.168.43.246';
    this.isConnected = false;
    this.stats = {
      requests: 0,
      errors: 0,
      lastResponse: null,
      responseTime: []
    };
  }

  /**
   * Test koneksi ke ESP32
   */
  async testConnection() {
    const startTime = Date.now();
    
    try {
      console.log('🌐 Testing connection to ESP32...');
      
      // Test basic endpoint
      const response = await axios.get(`${this.baseUrl}/status`, {
        timeout: 5000,
        headers: {
          'User-Agent': 'FireAlarm-App/1.0'
        }
      });

      const endTime = Date.now();
      const responseTime = endTime - startTime;
      
      this.isConnected = true;
      this.stats.requests++;
      this.stats.lastResponse = {
        timestamp: Date.now(),
        status: response.status,
        responseTime: responseTime,
        data: response.data
      };
      this.stats.responseTime.push(responseTime);
      
      // Keep only last 50 response times
      if (this.stats.responseTime.length > 50) {
        this.stats.responseTime = this.stats.responseTime.slice(-50);
      }

      console.log('✅ ESP32 Connected!', {
        status: response.status,
        responseTime: `${responseTime}ms`,
        data: response.data
      });

      return {
        success: true,
        status: response.status,
        responseTime: responseTime,
        data: response.data
      };

    } catch (error) {
      this.isConnected = false;
      this.stats.errors++;
      
      console.error('❌ ESP32 Connection failed:', {
        message: error.message,
        code: error.code,
        url: `${this.baseUrl}/status`
      });

      return {
        success: false,
        error: error.message,
        code: error.code
      };
    }
  }

  /**
   * Get fire alarm data dari ESP32
   */
  async getFireAlarmData() {
    const startTime = Date.now();
    
    try {
      console.log('📊 Fetching fire alarm data from ESP32...');
      
      const response = await axios.get(`${this.baseUrl}/fire-alarm/data`, {
        timeout: 10000,
        headers: {
          'User-Agent': 'FireAlarm-App/1.0'
        }
      });

      const endTime = Date.now();
      const responseTime = endTime - startTime;
      
      this.stats.requests++;
      this.stats.lastResponse = {
        timestamp: Date.now(),
        status: response.status,
        responseTime: responseTime,
        data: response.data
      };
      this.stats.responseTime.push(responseTime);

      console.log('✅ Fire alarm data received:', {
        responseTime: `${responseTime}ms`,
        data: response.data
      });

      return {
        success: true,
        responseTime: responseTime,
        data: response.data
      };

    } catch (error) {
      this.stats.errors++;
      
      console.error('❌ Failed to get fire alarm data:', {
        message: error.message,
        code: error.code,
        url: `${this.baseUrl}/fire-alarm/data`
      });

      return {
        success: false,
        error: error.message,
        code: error.code
      };
    }
  }

  /**
   * Send command ke ESP32
   */
  async sendCommand(command, parameters = {}) {
    const startTime = Date.now();
    
    try {
      console.log('📤 Sending command to ESP32:', { command, parameters });
      
      const response = await axios.post(`${this.baseUrl}/fire-alarm/command`, {
        command: command,
        parameters: parameters,
        timestamp: Date.now()
      }, {
        timeout: 10000,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'FireAlarm-App/1.0'
        }
      });

      const endTime = Date.now();
      const responseTime = endTime - startTime;
      
      this.stats.requests++;
      this.stats.lastResponse = {
        timestamp: Date.now(),
        status: response.status,
        responseTime: responseTime,
        data: response.data
      };
      this.stats.responseTime.push(responseTime);

      console.log('✅ Command sent to ESP32:', {
        command,
        responseTime: `${responseTime}ms`,
        response: response.data
      });

      return {
        success: true,
        responseTime: responseTime,
        data: response.data
      };

    } catch (error) {
      this.stats.errors++;
      
      console.error('❌ Failed to send command to ESP32:', {
        command,
        message: error.message,
        code: error.code,
        url: `${this.baseUrl}/fire-alarm/command`
      });

      return {
        success: false,
        error: error.message,
        code: error.code
      };
    }
  }

  /**
   * Get ESP32 system info
   */
  async getSystemInfo() {
    try {
      console.log('ℹ️ Getting ESP32 system info...');
      
      const response = await axios.get(`${this.baseUrl}/system/info`, {
        timeout: 5000,
        headers: {
          'User-Agent': 'FireAlarm-App/1.0'
        }
      });

      this.stats.requests++;
      
      console.log('✅ ESP32 System Info:', response.data);
      
      return {
        success: true,
        data: response.data
      };

    } catch (error) {
      this.stats.errors++;
      
      console.error('❌ Failed to get system info:', error.message);
      
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Get connection statistics
   */
  getStats() {
    const avgResponseTime = this.stats.responseTime.length > 0
      ? this.stats.responseTime.reduce((a, b) => a + b, 0) / this.stats.responseTime.length
      : 0;

    const minResponseTime = this.stats.responseTime.length > 0
      ? Math.min(...this.stats.responseTime)
      : 0;

    const maxResponseTime = this.stats.responseTime.length > 0
      ? Math.max(...this.stats.responseTime)
      : 0;

    return {
      isConnected: this.isConnected,
      baseUrl: this.baseUrl,
      totalRequests: this.stats.requests,
      totalErrors: this.stats.errors,
      successRate: this.stats.requests > 0 
        ? ((this.stats.requests - this.stats.errors) / this.stats.requests * 100).toFixed(2) + '%'
        : '0%',
      avgResponseTime: Math.round(avgResponseTime) + 'ms',
      minResponseTime: minResponseTime + 'ms',
      maxResponseTime: maxResponseTime + 'ms',
      lastResponse: this.stats.lastResponse
    };
  }

  /**
   * Monitor ESP32 connection
   */
  startMonitoring(interval = 30000) {
    console.log(`🔄 Starting ESP32 monitoring (${interval}ms interval)`);
    
    this.monitoringInterval = setInterval(async () => {
      await this.testConnection();
    }, interval);

    // Initial test
    this.testConnection();
  }

  /**
   * Stop monitoring
   */
  stopMonitoring() {
    if (this.monitoringInterval) {
      clearInterval(this.monitoringInterval);
      console.log('⏹ ESP32 monitoring stopped');
    }
  }
}

// Create singleton instance
const esp32Analyzer = new ESP32Analyzer();

export default esp32Analyzer;