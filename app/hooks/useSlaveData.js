import { useState, useEffect } from 'react';
import useFirebaseRealtime from './useFirebaseRealtime';
import { processDataPooling } from '../utils/fireAlarmParser';
import logService from '../services/logService';

const useSlaveData = () => {
  const { data: rawDataObject, loading, error } = useFirebaseRealtime('all_slave_data');
  
  // This state will hold the parsed data: { masterStatus: {}, slaves: {} }
  const [processedData, setProcessedData] = useState({ masterStatus: {}, slaves: {} });
  const [previousData, setPreviousData] = useState({ masterStatus: {}, slaves: {} });

  useEffect(() => {
    // The data from Firebase is an object, e.g., { raw_data: "...", timestamp: "..." }
    // We need to specifically access the `raw_data` property.
    if (rawDataObject && typeof rawDataObject.raw_data === 'string') {
      const dataString = rawDataObject.raw_data;
      const newData = processDataPooling(dataString);
      
      // Log important status changes with details
      if (previousData.masterStatus) {
        const prev = previousData.masterStatus;
        const curr = newData.masterStatus;
        
        // Alarm changes
        if (prev.alarm_active && !curr.alarm_active) {
          try { 
            logService.logEvent('NORMAL', 'All alarms cleared'); 
          } catch(e) { console.warn(e); }
        } else if (!prev.alarm_active && curr.alarm_active) {
          try { 
            const alarmSlaves = Object.keys(newData.slaves).filter(key => 
              newData.slaves[key].status === 'ALARM'
            );
            logService.logEvent('ALARM', 'Fire alarm activated', null, null, {
              type: 'ALARM_SYSTEM',
              affectedSlaves: alarmSlaves.length
            }); 
          } catch(e) { console.warn(e); }
        }
        
        // Trouble changes
        if (prev.trouble_active && !curr.trouble_active) {
          try { 
            logService.logEvent('NORMAL', 'All troubles cleared'); 
          } catch(e) { console.warn(e); }
        } else if (!prev.trouble_active && curr.trouble_active) {
          try { 
            const troubleSlaves = Object.keys(newData.slaves).filter(key => 
              newData.slaves[key].status === 'TROUBLE'
            );
            logService.logEvent('TROUBLE', 'System trouble detected', null, null, {
              type: 'TROUBLE_SYSTEM',
              affectedSlaves: troubleSlaves.length
            }); 
          } catch(e) { console.warn(e); }
        }
        
        // Command changes
        if (prev.silenced !== curr.silenced) {
          try { 
            logService.logEvent('COMMAND', `System ${curr.silenced ? 'silenced' : 'unsilenced'}`, null, null, {
              operation: curr.silenced ? 'SILENCED' : 'UNSILENCED'
            }); 
          } catch(e) { console.warn(e); }
        }
        
        if (prev.supervisory !== curr.supervisory) {
          try { 
            logService.logEvent('COMMAND', `Drill mode ${curr.supervisory ? 'activated' : 'deactivated'}`, null, null, {
              operation: curr.supervisory ? 'DRILL_ON' : 'DRILL_OFF'
            }); 
          } catch(e) { console.warn(e); }
        }
      }
      
      // Check individual slave changes
      Object.keys(newData.slaves || {}).forEach(address => {
        const prevSlave = previousData.slaves?.[address];
        const currSlave = newData.slaves[address];
        
        if (currSlave) {
          // Status changes
          if (!prevSlave && currSlave.online) {
            try { 
              logService.logEvent('NORMAL', `Slave ${address} came online`, currSlave, address); 
            } catch(e) { console.warn(e); }
          } else if (!currSlave.online && prevSlave && prevSlave.online) {
            try { 
              logService.logEvent('TROUBLE', `Slave ${address} went offline`, currSlave, address); 
            } catch(e) { console.warn(e); }
          } else if (prevSlave && currSlave.status !== prevSlave.status) {
            if (currSlave.status === 'ALARM') {
              const zones = currSlave.alarm_zones?.length > 0 
                ? `Zones: ${currSlave.alarm_zones.join(', ')}`
                : '';
              try { 
                logService.logEvent('ALARM', `Fire alarm in slave ${address}. ${zones}`, currSlave, address); 
              } catch(e) { console.warn(e); }
            } else if (currSlave.status === 'TROUBLE') {
              const zones = currSlave.trouble_zones?.length > 0 
                ? `Zones: ${currSlave.trouble_zones.join(', ')}`
                : '';
              try { 
                logService.logEvent('TROUBLE', `Trouble in slave ${address}. ${zones}`, currSlave, address); 
              } catch(e) { console.warn(e); }
            } else if (currSlave.status === 'NORMAL' && prevSlave.status !== 'NORMAL') {
              try { 
                logService.logEvent('NORMAL', `Slave ${address} returned to normal`, currSlave, address); 
              } catch(e) { console.warn(e); }
            }
          }
        }
      });
      
      setProcessedData(newData);
      setPreviousData(newData);
    } else {
      // If the data is not in the expected format, we reset to a default state.
      // The processDataPooling function initializes all slaves to OFFLINE when passed null.
      const defaultData = processDataPooling(null);
      setProcessedData(defaultData);
    }
  }, [rawDataObject]); // Effect runs when the object from Firebase changes
  // eslint-disable-next-line react-hooks/exhaustive-deps

  // The UI component expects an object with a `slaves` property.
  // We pass the whole processed data object.
  return { slaveData: processedData, loading, error };
};

export default useSlaveData;