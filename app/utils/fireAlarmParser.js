/**
 * Parses the master status byte to determine the state of various indicators.
 * Active Low logic: 0 is ON, 1 is OFF.
 * @param {number} statusByte - The hexadecimal status byte (e.g., 0x5F).
 * @returns {object} An object with boolean flags for each indicator.
 */
export const parseMasterStatus = (statusByte) => {
  if (typeof statusByte !== 'number') {
    return {};
  }
  return {
    backlight_lcd: (statusByte & 0x80) === 0, // Bit 7: 0=ON, 1=OFF
    ac_power: (statusByte & 0x40) === 0,      // Bit 6: 0=ON, 1=OFF
    dc_power: (statusByte & 0x20) === 0,      // Bit 5: 0=ON, 1=OFF
    alarm_active: (statusByte & 0x10) === 0,  // Bit 4: 0=ACTIVE, 1=INACTIVE
    trouble_active: (statusByte & 0x08) === 0,// Bit 3: 0=ACTIVE, 1=INACTIVE
    supervisory: (statusByte & 0x04) === 0,   // Bit 2: 0=ACTIVE, 1=INACTIVE
    silenced: (statusByte & 0x02) === 0,      // Bit 1: 0=ACTIVE, 1=INACTIVE
    disabled: (statusByte & 0x01) === 0,      // Bit 0: 0=ACTIVE, 1=INACTIVE
  };
};

/**
 * Determines the overall status type based on the slave's status value.
 * @param {number} troubleStatus - The trouble byte.
 * @param {number} alarmStatus - The alarm byte.
 * @returns {string} 'NORMAL', 'TROUBLE', or 'ALARM'.
 */
const getStatusType = (troubleStatus, alarmStatus) => {
  if ((alarmStatus & 0x1F) !== 0) return 'ALARM'; // Check only alarm bits 0-4
  if (troubleStatus !== 0) return 'TROUBLE';
  return 'NORMAL';
};

/**
 * Gets the zone numbers from a status byte.
 * @param {number} statusByte - The byte containing zone information (5 bits).
 * @returns {number[]} An array of active zone numbers (1-5).
 */
const getZones = (statusByte) => {
  const zones = [];
  for (let i = 0; i < 5; i++) {
    if ((statusByte >> i) & 1) {
      zones.push(i + 1);
    }
  }
  return zones;
};

/**
 * Parses a 6-digit slave data string.
 * Format: "AABBCC" -> AA: Address, BB: Trouble, CC: Alarm+Bell
 * @param {string} slaveData - The 6-digit hex string.
 * @returns {object} A parsed slave status object.
 */
export const parseSlaveData = (slaveData) => {
  if (typeof slaveData !== 'string' || slaveData.length !== 6) {
    return null;
  }

  try {
    const address = parseInt(slaveData.substring(0, 2), 16);
    const troubleStatus = parseInt(slaveData.substring(2, 4), 16);
    const alarmStatus = parseInt(slaveData.substring(4, 6), 16);

    const status = getStatusType(troubleStatus, alarmStatus);

    return {
      address: address,
      online: true,
      status: status,
      bell_active: (alarmStatus & 0x20) !== 0, // Bit 5 = Bell
      alarm_zones: getZones(alarmStatus & 0x1F), // Bits 0-4
      trouble_zones: getZones(troubleStatus),
    };
  } catch (e) {
    console.error("Error parsing slave data:", slaveData, e);
    return null;
  }
};

/**
 * Processes the entire raw pooling data string from Firebase.
 * @param {string} rawData - The complete data string.
 * @returns {object} An object containing master status and a map of slave statuses.
 */
export const processDataPooling = (rawData) => {
  const slaves = {};
  // Always initialize to prevent stale data on bad input
  for (let i = 1; i <= 63; i++) {
    slaves[i] = { address: i, online: false, status: 'OFFLINE' };
  }

  if (typeof rawData !== 'string' || !rawData.includes('<STX>')) {
    // Return a default state if data is not a valid pooling string
    return { masterStatus: {}, slaves };
  }

  // Clean up the data string from known noise characters
  const cleanData = rawData.replace(/[\$\x85\r\n]/g, '');

  // 1. Extract and parse master status
  const masterHex = cleanData.substring(0, 4); // e.g., "405F"
  const masterStatusByte = parseInt(masterHex.substring(2), 16);
  const masterStatus = parseMasterStatus(masterStatusByte);

  // 2. Process slave data
  const slaveSegments = cleanData.substring(4).split('<STX>');

  slaveSegments.forEach(segment => {
    const cleanSegment = segment.replace(/<ETX>/g, '').trim();
    if (!cleanSegment) return;

    try {
        if (cleanSegment.length === 2) {
            const address = parseInt(cleanSegment, 16);
            if (address > 0 && address <= 63 && slaves[address]) {
                slaves[address].online = false;
                slaves[address].status = 'OFFLINE';
            }
        } else if (cleanSegment.length === 6) {
            const parsedSlave = parseSlaveData(cleanSegment);
            if (parsedSlave && parsedSlave.address > 0 && parsedSlave.address <= 63) {
                slaves[parsedSlave.address] = parsedSlave;
            }
        }
    } catch (e) {
        console.error("Error processing segment:", cleanSegment, e);
    }
  });

  return { masterStatus, slaves };
};
