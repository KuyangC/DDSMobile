🎯 INFORMASI SISTEM YANG HARUS DIPAHAMI
Anda adalah sistem monitoring fire alarm yang memproses data pooling dari panel utama. Sistem terdiri dari 1 master dan maksimal 63 slave (address 01-3F hex).

🔧 STRUKTUR DATA POOLING
Format Data Lengkap:
text
[MASTER_STATUS][<STX>SLAVE_DATA][<STX>SLAVE_DATA]...[<ETX>]
Contoh:

text
405F<STX>010022<STX>02<STX>03<STX>040000<STX>05...<ETX>
🖥 PARSING DATA MASTER (4 DIGIT)
Format: [HEADER][STATUS_BYTE]
HEADER: 40 (konstan)

STATUS_BYTE: 5F, 57, dll (status LED indicators)

Logika Parsing Master:
dart
// LOGIKA AKTIF LOW: 0 = AKTIF/ON, 1 = NON-AKTIF/OFF
Map<String, bool> parseMasterStatus(String statusByte) {
  int value = int.parse(statusByte, radix: 16);
  return {
    'backlight_lcd': (value & 0x80) == 0,      // Bit 7: 0=ON, 1=OFF
    'ac_power': (value & 0x40) == 0,           // Bit 6: 0=ON, 1=OFF
    'dc_power': (value & 0x20) == 0,           // Bit 5: 0=ON, 1=OFF
    'alarm_active': (value & 0x10) == 0,       // Bit 4: 0=ACTIVE, 1=INACTIVE
    'trouble_active': (value & 0x08) == 0,     // Bit 3: 0=ACTIVE, 1=INACTIVE
    'supervisory': (value & 0x04) == 0,        // Bit 2: 0=ACTIVE, 1=INACTIVE
    'silenced': (value & 0x02) == 0,           // Bit 1: 0=ACTIVE, 1=INACTIVE
    'disabled': (value & 0x01) == 0,           // Bit 0: 0=ACTIVE, 1=INACTIVE
  };
}
Contoh Master Status:
405F → AC Power OFF, DC Power ON, Trouble Active

4040 → AC Power ON, DC Power OFF, semua status lain non-aktif

📡 PARSING DATA SLAVE
2 Tipe Data Slave:
1. DATA 2-DIGIT: SLAVE OFFLINE
dart
// Format: "AA" (hanya address)
// Contoh: "02", "03", "0A", "3F"
// Status: SLAVE TIDAK TERKONEKSI/OFFLINE
2. DATA 6-DIGIT: SLAVE ONLINE
dart
// Format: "AABBCC"
// - AA: Address slave (01-3F)
// - BB: Status trouble (00 = normal, lainnya = trouble)
// - CC: Status alarm + bell (00 = normal, lainnya = alarm/bell)
Decoding Status Slave Online:
dart
Map<String, dynamic> parseSlaveStatus(String slaveData) {
  String address = slaveData.substring(0, 2);
  String status = slaveData.substring(2);
  int statusValue = int.parse(status, radix: 16);
  
  return {
    'address': address,
    'online': true,
    'status': _getStatusType(statusValue),
    'bell_active': (statusValue & 0x20) != 0,  // Bit 5 = Bell
    'alarm_zones': _getZones(statusValue & 0x1F),
    'trouble_zones': _getZones((statusValue >> 8) & 0x1F),
  };
}

String _getStatusType(int status) {
  if (status == 0x0000) return 'NORMAL';
  if ((status & 0xFF00) != 0x0000) return 'TROUBLE';
  return 'ALARM';
}
Contoh Data Slave:
"010000" → Slave 01 ONLINE, NORMAL

"010022" → Slave 01 ONLINE, ALARM Zona 2, BELL ON

"011E00" → Slave 01 ONLINE, TROUBLE Zona 2,3,4,5

"02" → Slave 02 OFFLINE

🚨 HANDLING STATUS PRIORITAS
Urutan Prioritas (Tinggi ke Rendah):
ALARM dengan BELL ON → Tindakan darurat

ALARM tanpa BELL → Notifikasi silent

TROUBLE → Warning system

NORMAL → Status normal

OFFLINE → Koneksi terputus

Logic Flow:
text
TERIMA DATA POOLING
    ↓
PARSE MASTER STATUS → Update LED indicators
    ↓
LOOP SETIAP SLAVE 1-63:
    ├─ Data 6-digit → Parse status trouble/alarm/bell
    ├─ Data 2-digit → Mark OFFLINE
    └─ Tidak ada data → Mark OFFLINE
    ↓
UPDATE UI & DATABASE
    ↓
KIRIM NOTIFIKASI (jika ada alarm/trouble)
🎛 BIT MAPPING DETAIL
Master Status (Aktif Low):
text
Bit 7 (0x80): Backlight LCD (0=ON, 1=OFF)
Bit 6 (0x40): AC Power (0=ON, 1=OFF)  
Bit 5 (0x20): DC Power (0=ON, 1=OFF)
Bit 4 (0x10): Alarm Active (0=ACTIVE, 1=INACTIVE)
Bit 3 (0x08): Trouble Active (0=ACTIVE, 1=INACTIVE)
Bit 2 (0x04): Supervisory (0=ACTIVE, 1=INACTIVE)
Bit 1 (0x02): Silenced (0=ACTIVE, 1=INACTIVE)
Bit 0 (0x01): Disabled (0=ACTIVE, 1=INACTIVE)
Slave Status (Aktif High):
text
Trouble Zones (Byte tinggi):
Bit 0 (0x01): Zona 1 Trouble
Bit 1 (0x02): Zona 2 Trouble
Bit 2 (0x04): Zona 3 Trouble
Bit 3 (0x08): Zona 4 Trouble  
Bit 4 (0x10): Zona 5 Trouble

Alarm Zones + Bell (Byte rendah):
Bit 0-4 (0x01-0x10): Zona Alarm (sama mapping seperti trouble)
Bit 5 (0x20): Bell Status (1=ON, 0=OFF)
📊 CONTOH IMPLEMENTASI LENGKAP
dart
class FireAlarmSystem {
  void processDataPooling(String rawData) {
    // 1. Filter data dari noise
    String cleanData = rawData.replaceAll(RegExp(r'[\$\x85]'), '');
    
    // 2. Extract master status (4 digit pertama)
    String masterStatus = cleanData.substring(0, 4);
    Map<String, bool> master = parseMasterStatus(masterStatus.substring(2));
    
    // 3. Process slave data
    List<String> slaveSegments = cleanData.split('<STX>');
    Map<int, dynamic> slaves = {};
    
    for (int i = 1; i < slaveSegments.length; i++) {
      String segment = slaveSegments[i].replaceAll('<ETX>', '');
      if (segment.length == 2) {
        // Slave offline
        int address = int.parse(segment, radix: 16);
        slaves[address] = {'online': false, 'status': 'OFFLINE'};
      } else if (segment.length == 6) {
        // Slave online dengan status
        slaves[int.parse(segment.substring(0, 2), radix: 16)] = 
            parseSlaveStatus(segment);
      }
    }
    
    // 4. Update system state
    updateSystemState(master, slaves);
  }
  
  void updateSystemState(Map<String, bool> master, Map<int, dynamic> slaves) {
    // Implementasi update UI, database, notifikasi
    bool systemAlarm = master['alarm_active'] ?? false;
    bool systemTrouble = master['trouble_active'] ?? false;
    
    if (systemAlarm) {
      triggerAlarmProtocol(slaves);
    } else if (systemTrouble) {
      triggerTroubleProtocol(slaves);
    }
    
    updateFirebase({
      'master_status': master,
      'slaves': slaves,
      'timestamp': ServerValue.timestamp
    });
  }
}
🚨 PROTOCOL DARURAT
Alarm dengan Bell ON:
dart
void handleAlarmWithBell(int slaveId, List<int> zones) {
  // 1. Aktifkan sirene/bell fisik
  activatePhysicalBell();
  
  // 2. Tampilkan visual alarm di UI
  showAlarmUI(slaveId, zones);
  
  // 3. Kirim notifikasi darurat
  sendEmergencyNotification('ALARM! Zona ${zones.join(",")} Slave $slaveId');
  
  // 4. Log ke history
  logAlarmEvent(slaveId, zones, true);
}
Slave Offline:
dart
void handleSlaveOffline(int slaveId) {
  // 1. Update status di UI (warna abu-abu)
  updateSlaveUI(slaveId, 'offline');
  
  // 2. Kirim notifikasi troubleshooting
  sendMaintenanceAlert('Slave $slaveId offline');
  
  // 3. Log connectivity issue
  logConnectivityEvent(slaveId, 'offline');
}
✅ CHECKLIST VALIDASI
Sebelum deploy, pastikan:

Master status menggunakan logika aktif low

Data 2-digit selalu dianggap OFFLINE

Data 6-digit dengan "0000" = NORMAL

Bit 5 (0x20) pada slave = Bell status

Semua slave 1-63 selalu dimonitor

Filter karakter noise ($85, dll) berfungsi

Prioritas alarm > trouble > normal diterapkan
