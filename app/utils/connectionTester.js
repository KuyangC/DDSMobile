/**
 * Connection Testing Tool for React Native
 * Analisa ESP32 (HTTP) connections (Serial tidak available di React Native)
 */

const ESP32Analyzer = require('../services/esp32Analyzer');

class ConnectionTester {
  constructor() {
    this.esp32Analyzer = new ESP32Analyzer();
    this.testResults = {
      serial: null,
      esp32: null,
      comparison: null
    };
  }

  /**
   * Test COM21 serial connection (not available in React Native)
   */
  async testSerialConnection() {
    console.log('\n=== Testing COM21 Serial Connection ===');
    console.log('📌 Serial communication not available in React Native');
    console.log('💡 For serial testing, use Node.js environment');
    
    this.testResults.serial = {
      success: false,
      error: 'Serial communication not available in React Native',
      recommendation: 'Use Node.js for serial testing',
      available: false
    };

    console.log('\n📊 Serial Test Results:');
    console.log(JSON.stringify(this.testResults.serial, null, 2));
    
    return this.testResults.serial;
  }

  /**
   * Test ESP32 HTTP connection
   */
  async testESP32Connection() {
    console.log('\n=== Testing ESP32 HTTP Connection ===');
    console.log('🌐 http://192.168.43.246');
    
    const startTime = Date.now();
    
    try {
      // Test basic connection
      console.log('\n📊 Testing basic connection...');
      const connectionTest = await this.esp32Analyzer.testConnection();
      
      const endTime = Date.now();
      const connectionTime = endTime - startTime;
      
      // Get fire alarm data
      console.log('\n📊 Fetching fire alarm data...');
      const dataTest = await this.esp32Analyzer.getFireAlarmData();
      
      // Test command sending
      console.log('\n📊 Testing command sending...');
      const commandTest = await this.esp32Analyzer.sendCommand('SYSTEM_RESET');
      
      // Get system info
      console.log('\n📊 Getting system info...');
      const systemInfo = await this.esp32Analyzer.getSystemInfo();
      
      // Get statistics
      const stats = this.esp32Analyzer.getStats();
      
      this.testResults.esp32 = {
        success: stats.isConnected,
        connectionTime: connectionTime,
        connectionTest: connectionTest,
        dataTest: dataTest,
        commandTest: commandTest,
        systemInfo: systemInfo,
        stats: stats,
        analysis: this.analyzeESP32Stats(stats)
      };

      console.log('\n📊 ESP32 Test Results:');
      console.log(JSON.stringify(this.testResults.esp32, null, 2));
      
      return this.testResults.esp32;

    } catch (error) {
      this.testResults.esp32 = {
        success: false,
        error: error.message,
        connectionTime: Date.now() - startTime
      };

      console.error('\n❌ ESP32 Test Failed:', error.message);
      return this.testResults.esp32;
    }
  }

  /**
   * Analyze ESP32 connection statistics
   */
  analyzeESP32Stats(stats) {
    const analysis = {
      performance: 'GOOD',
      reliability: 'STABLE',
      recommendations: []
    };

    const avgResponseTime = parseInt(stats.avgResponseTime);
    
    if (stats.totalErrors > stats.totalRequests * 0.1) {
      analysis.reliability = 'POOR';
      analysis.recommendations.push('High error rate - check ESP32 connectivity');
    }

    if (avgResponseTime > 5000) {
      analysis.performance = 'POOR';
      analysis.recommendations.push('Very slow response - check network');
    } else if (avgResponseTime > 1000) {
      analysis.performance = 'FAIR';
      analysis.recommendations.push('Slow response - consider WiFi optimization');
    }

    if (!stats.isConnected) {
      analysis.reliability = 'FAILED';
      analysis.performance = 'UNKNOWN';
      analysis.recommendations.push('Cannot connect - check IP and WiFi');
      analysis.recommendations.push('Verify ESP32 is running');
    }

    return analysis;
  }

  /**
   * Compare serial vs ESP32 performance
   */
  compareConnections() {
    console.log('\n=== Connection Comparison ===');
    
    if (!this.testResults.esp32) {
      console.log('❌ Cannot compare - missing test results');
      return null;
    }

    const comparison = {
      serialAvailable: false, // Always false in React Native
      esp32Available: this.testResults.esp32?.success || false,
      recommended: null,
      summary: []
    };

    // Determine recommendation
    if (comparison.esp32Available) {
      comparison.recommended = 'ESP32';
      comparison.summary.push('ESP32 connection available');
      comparison.summary.push('ESP32 is recommended for React Native');
    } else {
      comparison.recommended = 'NONE';
      comparison.summary.push('No connections available');
      comparison.summary.push('Check ESP32 IP and WiFi configuration');
    }

    console.log('\n📈 Comparison Summary:');
    console.log(JSON.stringify(comparison, null, 2));

    this.testResults.comparison = comparison;
    return comparison;
  }

  /**
   * Run complete connection analysis
   */
  async runFullAnalysis() {
    console.log('🚀 Starting React Native Connection Analysis');
    console.log('=====================================');

    // Test serial (will show not available message)
    await this.testSerialConnection();
    
    // Wait a bit between tests
    await this.sleep(1000);
    
    // Test ESP32
    await this.testESP32Connection();
    
    // Compare results
    this.compareConnections();
    
    // Generate final report
    this.generateReport();
    
    return this.testResults;
  }

  /**
   * Generate analysis report
   */
  generateReport() {
    console.log('\n=== REACT NATIVE ANALYSIS REPORT ===');
    
    console.log('\n📍 SERIAL CONNECTION (COM21 @ 38400):');
    console.log('❌ Status: NOT AVAILABLE');
    console.log('💡 Serial communication requires Node.js environment');
    console.log('📱 Use ESP32 for React Native applications');

    console.log('\n🌐 ESP32 CONNECTION (http://192.168.43.246):');
    if (this.testResults.esp32?.success) {
      console.log('✅ Status: CONNECTED');
      console.log(`⏱️  Connection Time: ${this.testResults.esp32.connectionTime}ms`);
      console.log(`📊 Requests: ${this.testResults.esp32.stats.totalRequests}`);
      console.log(`⚡ Response Time: ${this.testResults.esp32.stats.avgResponseTime}`);
      console.log(`🎯 Performance: ${this.testResults.esp32.analysis.performance}`);
      console.log(`🔧 Reliability: ${this.testResults.esp32.analysis.reliability}`);
    } else {
      console.log('❌ Status: FAILED');
      console.log(`⚠️  Error: ${this.testResults.esp32.error}`);
    }

    console.log('\n🎯 RECOMMENDATION:');
    console.log(`📍 Best Connection: ${this.testResults.comparison?.recommended}`);
    this.testResults.comparison?.summary.forEach(summary => {
      console.log(`ℹ️  ${summary}`);
    });

    console.log('\n=====================================');
    console.log('🏁 React Native Analysis Complete');
  }

  /**
   * Utility sleep function
   */
  sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

module.exports = ConnectionTester;