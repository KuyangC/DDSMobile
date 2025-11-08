import { StyleSheet, Text, View, TouchableOpacity } from 'react-native';
import { useFonts, Poppins_700Bold, Poppins_500Medium, Poppins_600SemiBold } from '@expo-google-fonts/poppins';
import { useRouter } from 'expo-router';
import React from 'react'

const NavBar = () => {
  const router = useRouter();

  let [fontsLoaded] = useFonts({
    Poppins_700Bold,
    Poppins_500Medium,
    Poppins_600SemiBold
  });

  if (!fontsLoaded) {
    return null;
  }


  return (
    <View style={styles.navbarContainer}>
      <View style={styles.headerSection}>
        <Text style={styles.header}>PROJECT CONTROLL</Text>
        <Text style={styles.projectName}>Gedung Atria</Text>
        <Text style={styles.usage}>Usage Billing: </Text>
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
        <View style={styles.statusCard}>
          <Text style={styles.statusValue}>SYSTEM NORMAL</Text>
        </View>
      </View>

      {/* STATUS ITEMS - 1 BARIS HORIZONTAL SEMUA */}
      <View style={styles.panelRow}>
        <View style={styles.lightItem}>
          <Text style={styles.lightText}>AC POWER</Text>
          <View style={[styles.lightBullet, styles.lightOff]} />
        </View>
        <View style={styles.lightItem}>
          <Text style={styles.lightText}>DC POWER</Text>
          <View style={[styles.lightBullet, styles.lightOff]} />
        </View>
        <View style={styles.lightItem}>
          <Text style={styles.lightText}>ALARM</Text>
          <View style={[styles.lightBullet, styles.lightOff]} />
        </View>
        <View style={styles.lightItem}>
          <Text style={styles.lightText}>TROUBLE</Text>
          <View style={[styles.lightBullet, styles.lightOff]} />
        </View>
        <View style={styles.lightItem}>
          <Text style={styles.lightText}>DRILL</Text>
          <View style={[styles.lightBullet, styles.lightOff]} />
        </View>
        <View style={styles.lightItem}>
          <Text style={styles.lightText}>SILENCED</Text>
          <View style={[styles.lightBullet, styles.lightOff]} />
        </View>
        <View style={styles.lightItem}>
          <Text style={styles.lightText}>DISABLED</Text>
          <View style={[styles.lightBullet, styles.lightOff]} />
        </View>
      </View>

      <View style={styles.moduleContainer}>
        <View style={styles.moduleRow}>
          <View style={styles.moduleItem}>
            <Text style={styles.moduleLabel}>MODULE REGISTER</Text>
            <Text style={styles.moduleValue}>63</Text>
          </View>
          <View style={styles.moduleItem}>
            <Text style={styles.moduleLabel}>ZONE REGISTER</Text>
            <Text style={styles.moduleValue}>315</Text>
          </View>
        </View>
        <View style={styles.moduleRow}>
          <View style={styles.moduleItem}>
            <Text style={styles.moduleLabel}>MODULE ACTIVE</Text>
            <Text style={styles.moduleValue}>20</Text>
          </View>
          <View style={styles.moduleItem}>
            <Text style={styles.moduleLabel}>ZONE ACTIVE</Text>
            <Text style={styles.moduleValue}>100</Text>
          </View>
        </View>
      </View>

      <View style={styles.buttonContainer}>
        <View style={styles.buttonRow}>
          <View style={[styles.buttonItem, styles.systemResetButton]}>
            <Text style={styles.buttonText}>SYSTEM RESET</Text>
          </View>
          <View style={[styles.buttonItem, styles.acknowledgeButton]}>
            <Text style={styles.buttonText}>ACKNOWLEDGE</Text>
          </View>
        </View>
        <View style={styles.buttonRow}>
          <View style={[styles.buttonItem, styles.drillButton]}>
            <Text style={styles.buttonText}>DRILL</Text>
          </View>
          <View style={[styles.buttonItem, styles.silencedButton]}>
            <Text style={styles.buttonText}>SILENCED</Text>
          </View>
        </View>
      </View>

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
});