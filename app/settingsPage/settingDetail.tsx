import { Poppins_500Medium, Poppins_600SemiBold, Poppins_700Bold, useFonts } from '@expo-google-fonts/poppins';
import { useRouter } from 'expo-router';
import React from 'react';
import { StyleSheet, Text, TouchableOpacity, View } from 'react-native';

const SettingsDetail = () => {
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
    <View style={styles.container}>
      <View style={styles.navbarContainer}>
        <Text style={styles.header}>SETTINGS</Text>
      </View>
      <View>
        <TouchableOpacity style={styles.settingsButton}
          onPress={() => router.push('./')}
        >
          <Text style={styles.buttonText}>CREDENTIALS</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.settingsButton}
          onPress={() => router.push('./')}
        >
          <Text style={styles.buttonText}>USER ACCOUNT</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.settingsButton}
          onPress={() => router.push('./')}
        >
          <Text style={styles.buttonText}>LOG DATA</Text>
        </TouchableOpacity>
      </View>
      <View style={styles.bottomSection}>
        <TouchableOpacity style={styles.logButton}
          onPress={() => router.push('./')}
        >
          <Text style={styles.buttonText}>LOGOUT</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
};

export default SettingsDetail;

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f0f0f0',
    padding: 8,
    alignItems: 'center',
  },
  navbarContainer: {
    alignItems: 'center',
    marginBottom: -10,
  },
  header: {
    fontSize: 26,
    fontFamily: "Poppins_700Bold",
    textAlign: 'center',
    marginBottom: 4,
  },
  settingsButton: {
    backgroundColor: '#11B653',
    paddingVertical: 8,
    paddingHorizontal: 50,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 2, height: 2 },
    shadowOpacity: 100,
    shadowRadius: 2,
    elevation: 3,
  },
  buttonText: {
    fontSize: 20,
    fontFamily: "Poppins_600SemiBold",
    color: '#FFFFFF',
    fontWeight: '600',
  },
  bottomSection: {
    marginTop: 10,
    alignItems: 'center',
  },
  logButton: {
    backgroundColor: '#FF3B30',
  },
});
