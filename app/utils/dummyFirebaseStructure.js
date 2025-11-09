// Dummy Firebase Data Structure untuk Testing
// Simpan ini di Firebase Realtime Database dengan struktur sebagai berikut:

/*
Struktur Database Firebase:

{
  "projectInfo": {
    "name": "Gedung Atria",
    "moduleRegister": 63,
    "zoneRegister": 315,
    "usageBilling": "Rp 2.500.000",
    "location": "Jakarta Selatan",
    "lastMaintenance": "2024-11-01"
  },
  
  "projectname": "Gedung Atria", // Alternative path untuk nama project
  
  "all_slave_data": {
    "raw_data": "405F<STX>010000<STX>020022<STX>03<ETX>",
    "timestamp": 1699123456789
  },
  
  "alarm_history": [
    {
      "slaveId": 2,
      "zones": [2],
      "type": "ALARM",
      "timestamp": 1699123456789,
      "resolved": false
    }
  ],
  
  "system_logs": [
    {
      "message": "System started",
      "timestamp": 1699123456789,
      "type": "INFO"
    }
  ]
}

Contoh Data Pooling:
- "405F" = Master Status (AC OFF, DC ON, Trouble Active)
- "<STX>010000" = Slave 1, Normal
- "<STX>020022" = Slave 2, Alarm Zone 2, Bell ON
- "<STX>03" = Slave 3, Offline
- "<ETX>" = End of transmission

Bit Mapping Reference:
Master Status (Aktif Low):
- Bit 7: Backlight LCD (0=ON, 1=OFF)
- Bit 6: AC Power (0=ON, 1=OFF)
- Bit 5: DC Power (0=ON, 1=OFF)
- Bit 4: Alarm Active (0=ACTIVE, 1=INACTIVE)
- Bit 3: Trouble Active (0=ACTIVE, 1=INACTIVE)
- Bit 2: Supervisory (0=ACTIVE, 1=INACTIVE)
- Bit 1: Silenced (0=ACTIVE, 1=INACTIVE)
- Bit 0: Disabled (0=ACTIVE, 1=INACTIVE)

Slave Status:
- Format "AABBCC": AA=Address, BB=Trouble, CC=Alarm+Bell
- Bell: Bit 5 (0x20) = ON
- Zones: Bits 0-4 = 5 zones per slave
*/

export const dummyFirebaseStructure = {
  projectInfo: {
    name: "Gedung Atria",
    moduleRegister: 63,
    zoneRegister: 315,
    usageBilling: "Rp 2.500.000",
    location: "Jakarta Selatan",
    lastMaintenance: "2024-11-01"
  },
  
  projectname: "Gedung Atria",
  
  all_slave_data: {
    raw_data: "405F<STX>010000<STX>020022<STX>03<STX>040000<ETX>",
    timestamp: Date.now()
  }
};

// Contoh implementasi untuk menulis dummy data ke Firebase
export const seedDummyData = async (firebaseService) => {
  try {
    await firebaseService.writeData('projectInfo', dummyFirebaseStructure.projectInfo);
    await firebaseService.writeData('projectname', dummyFirebaseStructure.projectname);
    await firebaseService.writeData('all_slave_data', dummyFirebaseStructure.all_slave_data);
    console.log('✅ Dummy data seeded to Firebase');
  } catch (error) {
    console.error('❌ Failed to seed dummy data:', error);
  }
};