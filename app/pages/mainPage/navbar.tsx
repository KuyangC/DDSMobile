import { StyleSheet, Text, View, TouchableOpacity, Alert } from 'react-native';
import { useFonts, Poppins_700Bold, Poppins_500Medium, Poppins_600SemiBold } from '@expo-google-fonts/poppins';
import { useRouter } from 'expo-router';
import React from 'react';
import useSlaveData from '../../hooks/useSlaveData';
import useProjectInfo from '../../hooks/useProjectInfo';
import useAppSilence from '../../hooks/useAppSilence';
import { fireAlarmCommands, appCommands } from '../../services/fireAlarmService';

const NavBar = () => {
  const router = useRouter();
  const { slaveData } = useSlaveData();
  const { projectInfo } = useProjectInfo();
  const { isSilenced: isAppSilenced } = useAppSilence();
  const [buttonFeedback, setButtonFeedback] = React.useState<string | null>(null);

  let [fontsLoaded] = useFonts({
    Poppins_700Bold,
    Poppins_500Medium,
    Poppins_600SemiBold
  });

  if (!fontsLoaded) {
    return null;
  }

  // Function to determine system status based on all slaves
  const getSystemStatus = () => {
    const slaves = Object.values(slaveData.slaves || {} as any);
    
    // Check if any slave has ALARM status
    if (slaves.some((slave: any) => slave.status === 'ALARM')) {
      return {
        text: 'SYSTEM ALARM',
        backgroundColor: '#ff4d4d', // Red
        color: '#FFFFFF'
      };
    }
    
    // Check if any slave has TROUBLE status
    if (slaves.some((slave: any) => slave.status === 'TROUBLE')) {
      return {
        text: 'SYSTEM TROUBLE',
        backgroundColor: '#ffc107', // Orange/Yellow
        color: '#000000'
      };
    }
    
    // Default to NORMAL
    return {
      text: 'SYSTEM NORMAL',
      backgroundColor: '#11B653', // Green
      color: '#FFFFFF'
    };
  };

  const systemStatus = getSystemStatus();

  // Calculate active modules and zones dynamically
  const getActiveStats = () => {
    const slaves = Object.values(slaveData.slaves || {} as any);
    const onlineSlaves = slaves.filter((slave: any) => slave.online);
    const activeZones = onlineSlaves.reduce((total: number, slave: any) => {
      const alarmZones = slave.alarm_zones?.length || 0;
      const troubleZones = slave.trouble_zones?.length || 0;
      return total + alarmZones + troubleZones;
    }, 0);

    return {
      activeModules: onlineSlaves.length,
      activeZones: activeZones
    };
  };

  const activeStats = getActiveStats();

  // Function to get register counts dynamically
  const getRegisterStats = () => {
    return {
      moduleRegister: projectInfo.moduleRegister, // From Firebase
      zoneRegister: projectInfo.zoneRegister // From Firebase
    };
  };

  const registerStats = getRegisterStats();

  // Handler untuk fire alarm commands
  const handleFireAlarmCommand = async (commandType: string) => {
    console.log('🔥 Button pressed:', commandType);
    setButtonFeedback(`Processing ${commandType}...`);
    
    try {
      const masterStatus = slaveData.masterStatus as any || {};
      console.log('🔧 Current master status:', masterStatus);
      
      // Show confirmation dialog for critical operations
      if (commandType === 'SYSTEM_RESET') {
        setButtonFeedback(null);
        Alert.alert(
          'System Reset Confirmation',
          'This will reset all alarms and restore system to normal state. Continue?',
          [
            { text: 'Cancel', style: 'cancel' },
            { 
              text: 'Reset', 
              style: 'destructive',
              onPress: async () => {
                const result = await fireAlarmCommands.systemReset(masterStatus);
                console.log('✅ System reset result:', result);
                setButtonFeedback('System reset complete!');
                setTimeout(() => setButtonFeedback(null), 2000);
                Alert.alert('Success', result.message);
              }
            }
          ]
        );
        return;
      }
      
      // Handle other commands
      let result;
      switch (commandType) {
        case 'ACKNOWLEDGE':
          result = await fireAlarmCommands.acknowledge(masterStatus);
          console.log('✅ Acknowledge result:', result);
          setButtonFeedback('Alarm acknowledged!');
          setTimeout(() => setButtonFeedback(null), 2000);
          Alert.alert('Success', 'Alarm acknowledged successfully');
          break;
          
        case 'DRILL':
          result = await fireAlarmCommands.drill(masterStatus);
          const isDrillActive = masterStatus.supervisory;
          console.log('✅ Drill result:', result);
          setButtonFeedback(`Drill mode ${isDrillActive ? 'deactivated' : 'activated'}!`);
          setTimeout(() => setButtonFeedback(null), 2000);
          Alert.alert('Success', `Drill mode ${isDrillActive ? 'deactivated' : 'activated'}`);
          break;
          
        case 'SILENCED_APP':
          // App-only silence, doesn't affect backend
          console.log('🔇 App silence toggle, current state:', isAppSilenced);
          result = await appCommands.toggleSilence(isAppSilenced);
          console.log('✅ App silence result:', result);
          setButtonFeedback(result.message);
          setTimeout(() => setButtonFeedback(null), 2000);
          Alert.alert('Success', result.message);
          break;
          
        default:
          console.error('❌ Unknown command:', commandType);
          setButtonFeedback(null);
          Alert.alert('Error', 'Unknown command');
          return;
      }
      
    } catch (error) {
      console.error(`❌ Error executing ${commandType}:`, error);
      setButtonFeedback(`Error: ${error.message}`);
      setTimeout(() => setButtonFeedback(null), 3000);
      Alert.alert('Error', `Failed to execute ${commandType}. Please try again.`);
    }
  };


  return (
    <View style={styles.navbarContainer}>
      <View style={styles.headerSection}>
        <Text style={styles.header}>PROJECT CONTROLL</Text>
        <Text style={styles.projectName}>{projectInfo.projectName}</Text>
        <Text style={styles.usage}>Usage Billing: {projectInfo.usageBilling}</Text>
      </View>

      {/* Row Container */}
      <View style={styles.horizontalContainer}>
        {/* Connection Section */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>CONNECTION</Text>
          <View style={styles.row}>
            <Text style={styles.label}>WiFi :</Text>
            <Text style={styles.value}>Atria Lt. 1</Text>
          </View>
        </View>

        {/* Signal Section */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>SIGNAL</Text>
          <View style={styles.row}>
            <Text style={styles.label}>Strength</Text>
            <View style={styles.signalIndicator}>
              <View style={[styles.signalBar, styles.signalStrong]} />
              <View style={[styles.signalBar, styles.signalStrong]} />
              <View style={[styles.signalBar, styles.signalMedium]} />
              <View style={[styles.signalBar, styles.signalWeak]} />
            </View>
          </View>
        </View>
      </View>

      {/* MASTER STATUS */}
      <View style={styles.statusContainer}>
        <Text style={styles.statusTitle}>SYSTEM STATUS</Text>
        <View style={[styles.statusCard, { backgroundColor: systemStatus.backgroundColor }]}>
          <Text style={[styles.statusValue, { color: systemStatus.color }]}>{systemStatus.text}</Text>
        </View>
      </View>

      {/* STATUS ITEMS - 1 BARIS HORIZONTAL SEMUA */}
      <View style={styles.panelRow}>
        <View style={styles.lightItem}>
          <Text style={styles.lightText}>AC POWER</Text>
          <View style={[styles.lightBullet, (slaveData.masterStatus as any)?.ac_power ? styles.lightOn : styles.lightOff]} />
        </View>
        <View style={styles.lightItem}>
          <Text style={styles.lightText}>DC POWER</Text>
          <View style={[styles.lightBullet, (slaveData.masterStatus as any)?.dc_power ? styles.lightOn : styles.lightOff]} />
        </View>
        <View style={styles.lightItem}>
          <Text style={styles.lightText}>ALARM</Text>
          <View style={[styles.lightBullet, (slaveData.masterStatus as any)?.alarm_active ? styles.lightOn : styles.lightOff]} />
        </View>
        <View style={styles.lightItem}>
          <Text style={styles.lightText}>TROUBLE</Text>
          <View style={[styles.lightBullet, (slaveData.masterStatus as any)?.trouble_active ? styles.lightOn : styles.lightOff]} />
        </View>
        <View style={styles.lightItem}>
          <Text style={styles.lightText}>DRILL</Text>
          <View style={[styles.lightBullet, (slaveData.masterStatus as any)?.supervisory ? styles.lightOn : styles.lightOff]} />
        </View>
        <View style={styles.lightItem}>
          <Text style={styles.lightText}>SILENCED</Text>
          <View style={[styles.lightBullet, isAppSilenced ? styles.lightOn : styles.lightOff]} />
        </View>
        <View style={styles.lightItem}>
          <Text style={styles.lightText}>DISABLED</Text>
          <View style={[styles.lightBullet, (slaveData.masterStatus as any)?.disabled ? styles.lightOn : styles.lightOff]} />
        </View>
      </View>

      <View style={styles.moduleContainer}>
        <View style={styles.moduleRow}>
          <View style={styles.moduleItem}>
            <Text style={styles.moduleLabel}>MODULE REGISTER</Text>
            <Text style={styles.moduleValue}>{registerStats.moduleRegister}</Text>
          </View>
          <View style={styles.moduleItem}>
            <Text style={styles.moduleLabel}>ZONE REGISTER</Text>
            <Text style={styles.moduleValue}>{registerStats.zoneRegister}</Text>
          </View>
        </View>
        <View style={styles.moduleRow}>
          <View style={styles.moduleItem}>
            <Text style={styles.moduleLabel}>MODULE ACTIVE</Text>
            <Text style={styles.moduleValue}>{activeStats.activeModules}</Text>
          </View>
          <View style={styles.moduleItem}>
            <Text style={styles.moduleLabel}>ZONE ACTIVE</Text>
            <Text style={styles.moduleValue}>{activeStats.activeZones}</Text>
          </View>
        </View>
      </View>

      <View style={styles.buttonContainer}>
        <View style={styles.buttonRow}>
          <TouchableOpacity 
            style={[styles.buttonItem, styles.systemResetButton]}
            onPress={() => handleFireAlarmCommand('SYSTEM_RESET')}
            activeOpacity={0.7}
          >
            <Text style={styles.buttonText}>SYSTEM RESET</Text>
          </TouchableOpacity>
          <TouchableOpacity 
            style={[styles.buttonItem, styles.acknowledgeButton]}
            onPress={() => handleFireAlarmCommand('ACKNOWLEDGE')}
            activeOpacity={0.7}
          >
            <Text style={styles.buttonText}>ACKNOWLEDGE</Text>
          </TouchableOpacity>
        </View>
        <View style={styles.buttonRow}>
          <TouchableOpacity 
            style={[styles.buttonItem, styles.drillButton]}
            onPress={() => handleFireAlarmCommand('DRILL')}
            activeOpacity={0.7}
          >
            <Text style={styles.buttonText}>DRILL</Text>
          </TouchableOpacity>
          <TouchableOpacity 
            style={[styles.buttonItem, styles.silencedButton]}
            onPress={() => {
              console.log('🔇 SILENCED button clicked!');
              Alert.alert('Test', 'Silenced button pressed!');
              handleFireAlarmCommand('SILENCED_APP');
            }}
            activeOpacity={0.7}
          >
            <Text style={styles.buttonText}>SILENCED</Text>
          </TouchableOpacity>
        </View>
      </View>
      
      {/* Visual Feedback */}
      {buttonFeedback && (
        <View style={styles.feedbackContainer}>
          <Text style={styles.feedbackText}>{buttonFeedback}</Text>
        </View>
      )}

      {/* Image dan Button dalam layout vertikal */}
      <View style={styles.bottomSection}>
        {/* Image 
        <Image 
          source={require('base.png')} 
          style={styles.imageBottom} 
        />
        */}
        <TouchableOpacity 
        style={styles.settingsButton}
        onPress={() => router.push('./pages/settingsPage/settings')}
        activeOpacity={0.7}
      >
        <Text style={styles.settingsButtonText}>Settings</Text>
      </TouchableOpacity>
      </View>
    </View>
  );
}

export default NavBar;

const styles = StyleSheet.create({
  navbarContainer: {
    flex: 1,
    backgroundColor: '#f0f0f0',
    padding: 8,
    alignItems: 'center',
  },
  headerSection: {
    alignItems: 'center',
    marginBottom: -10,
  },
  header: {
    fontSize: 20,
    fontFamily: "Poppins_700Bold",
    textAlign: 'center',
    marginBottom: 4,
  },
  projectName: {
    fontSize: 18,
    fontFamily: "Poppins_500Medium",
    textAlign: 'center',
    marginBottom: 4,
  },
  usage: {
    fontSize: 14,
    fontFamily: "Poppins_500Medium",
    textAlign: 'center',
  },
  horizontalContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    padding: 8,
    borderRadius: 8,
    margin: 8,
    width: '100%',
    marginBottom: 5,
  },
  section: {
    alignItems: 'center',
  },
  sectionTitle: {
    fontFamily: "Poppins_500Medium",
    fontSize: 12,
    fontWeight: '600',
    marginBottom: 4,
    letterSpacing: 0.5,
    textAlign: 'center',
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 2,
  },
  label: {
    fontSize: 10,
    fontWeight: '400',
    width: 50,
    textAlign: 'center',
    fontFamily: "Poppins_500Medium",
  },
  value: {
    fontSize: 10,
    fontWeight: '600',
    textAlign: 'center',
    fontFamily: "Poppins_500Medium",
  },
  signalIndicator: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    height: 16,
    justifyContent: 'center',
  },
  signalBar: {
    width: 3,
    marginRight: 2,
    borderRadius: 1,
  },
  signalStrong: {
    height: 12,
    backgroundColor: '#4CAF50',
  },
  signalMedium: {
    height: 9,
    backgroundColor: '#FFC107',
  },
  signalWeak: {
    height: 6,
    backgroundColor: '#FF5722',
  },
  statusCard: {
    backgroundColor: '#11B653',
    padding: 7,
    borderRadius: 20,
    alignItems: 'center',
    marginVertical: 2,
    width: '100%',
    height: 40,
  },
  statusValue: {
    fontSize: 16,
    fontFamily: "Poppins_600SemiBold",
    color: '#FFFFFF',
  },
  statusContainer: {
    alignItems: 'center',
    marginVertical: 5,
    width: '100%',
  },
  statusTitle: {
    fontFamily: "Poppins_500Medium",
    fontSize: 12,
    color: '#000',
    marginBottom: 2,
  },
  panelRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 8,
    width: '100%',
    flexWrap: 'nowrap',
  },
  lightItem: {
    alignItems: 'center',
    marginHorizontal: 1,
  },
  lightBullet: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginTop: 1,
    backgroundColor: '#CCCCCC',
  },
  lightOff: {
    backgroundColor: '#CCCCCC',
  },
  lightOn: {
    backgroundColor: '#FF0000',
  },
  lightText: {
    color: '#000000',
    fontFamily: "Poppins_500Medium",
    fontSize: 8,
    fontWeight: '500',
    textAlign: 'center',
  },
  moduleContainer: {
    marginTop: 10,
    width: '100%',
  },
  moduleRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 6,
  },
  moduleItem: {
    flex: 1,
    alignItems: 'center',
    marginHorizontal: 2,
  },
  moduleLabel: {
    fontSize: 9,
    fontFamily: "Poppins_500Medium",
    color: '#000',
    textAlign: 'center',
    marginBottom: 1,
  },
  moduleValue: {
    fontSize: 14,
    fontFamily: "Poppins_600SemiBold",
    color: '#000',
    textAlign: 'center',
  },
  buttonContainer: {
    marginTop: 0,
    width: '100%',
  },
  buttonRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 6,
  },
  buttonItem: {
    flex: 1,
    backgroundColor: '#2C2C2C',
    paddingVertical: 8,
    paddingHorizontal: 4,
    borderRadius: 6,
    alignItems: 'center',
    justifyContent: 'center',
    marginHorizontal: 3,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.3,
    shadowRadius: 2,
    elevation: 3,
  },
  systemResetButton: {
    backgroundColor: '#FF3B30', // Red
  },
  acknowledgeButton: {
    backgroundColor: '#4CD964', // Green
  },
  drillButton: {
    backgroundColor: '#007AFF', // Blue
  },
  silencedButton: {
    backgroundColor: '#FF9500', // Orange
  },
  buttonText: {
    fontSize: 10,
    fontFamily: "Poppins_500Medium",
    color: '#FFFFFF',
    textAlign: 'center',
    fontWeight: '600',
  },
  // STYLES BARU UNTUK BOTTOM SECTION
  bottomSection: {
    marginTop: 10,
    alignItems: 'center',
    width: '100%',
  },
  imageBottom: {
    width: 100,
    height: 40,
    resizeMode: 'contain',
    marginBottom: 8,
  },
  settingsButton: {
    backgroundColor: '#2C2C2C',
    paddingVertical: 8,
    paddingHorizontal: 16,
    borderRadius: 6,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.3,
    shadowRadius: 2,
    elevation: 3,
  },
  settingsButtonText: {
    fontSize: 12,
    fontFamily: "Poppins_500Medium",
    color: '#FFFFFF',
    fontWeight: '600',
  },
  feedbackContainer: {
    marginTop: 8,
    padding: 8,
    backgroundColor: '#4CAF50',
    borderRadius: 6,
    alignItems: 'center',
    width: '100%',
  },
  feedbackText: {
    fontSize: 10,
    fontFamily: "Poppins_500Medium",
    color: '#FFFFFF',
    textAlign: 'center',
  },
});