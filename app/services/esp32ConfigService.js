/**
 * ESP32 Configuration Service
 * Manages ESP32 IP address and connection settings
 * Using Expo SecureStore for Expo Go compatibility
 */

let SecureStore = null;

// Only try to load SecureStore in native environment
const isNative = typeof window === 'undefined' || 
                !window.location || 
                (typeof navigator !== 'undefined' && navigator.product === 'ReactNative');

if (isNative) {
  try {
    SecureStore = require('expo-secure-store').default;
  } catch (error) {
    console.warn('⚠️ expo-secure-store not available, using fallback storage');
  }
} else {
  console.log('🌐 Web environment detected, using localStorage');
}

const ESP32_CONFIG_KEY = 'esp32_config';

// Web localStorage storage
class WebStorage {
  constructor() {
    this.prefix = 'ddsmobile_';
  }

  async getItemAsync(key) {
    if (typeof window === 'undefined' || !window.localStorage) {
      return null;
    }
    return window.localStorage.getItem(this.prefix + key) || null;
  }

  async setItemAsync(key, value) {
    if (typeof window === 'undefined' || !window.localStorage) {
      console.warn('localStorage not available');
      return;
    }
    window.localStorage.setItem(this.prefix + key, value);
  }

  async deleteItemAsync(key) {
    if (typeof window === 'undefined' || !window.localStorage) {
      return;
    }
    window.localStorage.removeItem(this.prefix + key);
  }
}

// Fallback storage for when no storage is available
class MemoryStorage {
  constructor() {
    this.storage = {};
  }

  async getItemAsync(key) {
    return this.storage[key] || null;
  }

  async setItemAsync(key, value) {
    this.storage[key] = value;
  }

  async deleteItemAsync(key) {
    delete this.storage[key];
  }
}

const webStorage = new WebStorage();
const memoryStorage = new MemoryStorage();

const DEFAULT_CONFIG = {
  ipAddress: '192.168.43.246',
  port: 80,
  timeout: 5000,
  monitoringInterval: 30000
};

class ESP32ConfigService {
  constructor() {
    this.config = DEFAULT_CONFIG;
    this.listeners = [];
  }

  /**
   * Load configuration from appropriate storage
   */
  async loadConfig() {
    try {
      let storedConfig = null;
      
      // Always use webStorage for web environment (Expo Go)
      if (typeof window !== 'undefined' && window.localStorage) {
        console.log('🌐 Using localStorage for web environment');
        const stored = window.localStorage.getItem('ddsmobile_' + ESP32_CONFIG_KEY);
        if (stored) {
          storedConfig = JSON.parse(stored);
        }
      } else if (SecureStore) {
        console.log('📱 Using SecureStore for mobile');
        const stored = await SecureStore.getItemAsync(ESP32_CONFIG_KEY);
        if (stored) {
          storedConfig = JSON.parse(stored);
        }
      } else {
        console.log('💾 Using memory storage fallback');
        const stored = await memoryStorage.getItemAsync(ESP32_CONFIG_KEY);
        if (stored) {
          storedConfig = JSON.parse(stored);
        }
      }
      
      if (storedConfig) {
        this.config = { ...DEFAULT_CONFIG, ...storedConfig };
        console.log('✅ ESP32 config loaded:', this.config);
      } else {
        console.log('⚠️ No ESP32 config found, using defaults');
        await this.saveConfig();
      }
      return this.config;
    } catch (error) {
      console.error('❌ Failed to load ESP32 config:', error);
      this.config = DEFAULT_CONFIG;
      try {
        await this.saveConfig();
      } catch (saveError) {
        console.warn('⚠️ Could not save fallback config:', saveError);
      }
      return this.config;
    }
  }

  /**
   * Save configuration to appropriate storage
   */
  async saveConfig(newConfig = null) {
    try {
      if (newConfig) {
        this.config = { ...this.config, ...newConfig };
      }
      
      const configString = JSON.stringify(this.config);
      
      // Always use localStorage for web environment (Expo Go)
      if (typeof window !== 'undefined' && window.localStorage) {
        console.log('🌐 Saving to localStorage');
        window.localStorage.setItem('ddsmobile_' + ESP32_CONFIG_KEY, configString);
      } else if (SecureStore) {
        console.log('📱 Saving to SecureStore');
        await SecureStore.setItemAsync(ESP32_CONFIG_KEY, configString);
      } else {
        console.log('💾 Saving to memory');
        await memoryStorage.setItemAsync(ESP32_CONFIG_KEY, configString);
      }
      
      console.log('✅ ESP32 config saved:', this.config);
      
      // Notify all listeners
      this.listeners.forEach(listener => listener(this.config));
      
      return true;
    } catch (error) {
      console.error('❌ Failed to save ESP32 config:', error);
      return false;
    }
  }

  /**
   * Get current configuration
   */
  getConfig() {
    return this.config;
  }

  /**
   * Update specific configuration values
   */
  async updateConfig(updates) {
    return await this.saveConfig(updates);
  }

  /**
   * Update IP address
   */
  async updateIpAddress(ipAddress) {
    if (!this.validateIpAddress(ipAddress)) {
      throw new Error('Invalid IP address format');
    }
    return await this.updateConfig({ ipAddress });
  }

  /**
   * Validate IP address format
   */
  validateIpAddress(ip) {
    const ipPattern = /^(\d{1,3}\.){3}\d{1,3}$/;
    if (!ipPattern.test(ip)) {
      return false;
    }
    
    const parts = ip.split('.');
    return parts.every(part => {
      const num = parseInt(part, 10);
      return num >= 0 && num <= 255;
    });
  }

  /**
   * Get base URL for ESP32
   */
  getBaseUrl() {
    return `http://${this.config.ipAddress}`;
  }

  /**
   * Reset to default configuration
   */
  async resetToDefaults() {
    this.config = { ...DEFAULT_CONFIG };
    return await this.saveConfig();
  }

  /**
   * Subscribe to configuration changes
   */
  subscribe(listener) {
    this.listeners.push(listener);
    return () => {
      const index = this.listeners.indexOf(listener);
      if (index > -1) {
        this.listeners.splice(index, 1);
      }
    };
  }

  /**
   * Get common network ranges for suggestions
   */
  getCommonNetworkRanges() {
    return [
      { label: '192.168.1.x (Home)', base: '192.168.1' },
      { label: '192.168.43.x (Android Hotspot)', base: '192.168.43' },
      { label: '192.168.0.x (Office)', base: '192.168.0' },
      { label: '10.0.0.x (Alternative)', base: '10.0.0' },
      { label: '172.16.0.x (Large Network)', base: '172.16.0' }
    ];
  }

  /**
   * Generate IP suggestions for a base network
   */
  generateIpSuggestions(base, count = 10) {
    const suggestions = [];
    for (let i = 1; i <= count; i++) {
      suggestions.push(`${base}.${i}`);
    }
    return suggestions;
  }
}

// Create singleton instance
const esp32ConfigService = new ESP32ConfigService();

export default esp32ConfigService;