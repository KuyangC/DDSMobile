import React, { useState } from 'react';
import { 
  View, 
  Text, 
  TextInput, 
  TouchableOpacity, 
  StyleSheet, 
  Image, 
  Dimensions,
  Alert 
} from 'react-native';
import { useRouter, Stack } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useFonts, Poppins_700Bold, Poppins_600SemiBold, Poppins_500Medium } from '@expo-google-fonts/poppins';
import { useAuth } from '../../hooks/useAuth';
import { db } from '../../config/firebaseConfig';
import { ref, set, get } from 'firebase/database';

// --- DIMENSI DAN SKALA FIX ---
const baseWidth = 1280;
const baseHeight = 800;
const { width: screenWidth } = Dimensions.get('window');
const scale = screenWidth / baseWidth;

const scaleSize = (size: number) => {
  return Math.round(size * scale);
};
// --- AKHIR DIMENSI DAN SKALA ---

const Login = () => {
  const router = useRouter();
  const { login, loading } = useAuth();
  
  const [formData, setFormData] = useState({
    email: '',
    password: ''
  });

  const [fontsLoaded] = useFonts({
    Poppins_700Bold,
    Poppins_600SemiBold,
    Poppins_500Medium
  });

  if (!fontsLoaded) {
    return null;
  }

  const handleLogin = async () => {
    if (!formData.email || !formData.password) {
      Alert.alert('Error', 'Please fill all fields');
      return;
    }

    const result = await login(formData.email, formData.password);
    
    if (result.success) {
      Alert.alert('Success', 'Login successful!');
      router.push('/');
    } else {
      Alert.alert('Error', result.error);
    }
  };

  const handleSignUpPress = () => {
    router.push('/pages/authPage/registerPage');
  };

  const handleForgotPasswordPress = () => {
    // TODO: Implement forgot password functionality
    Alert.alert('Info', 'Forgot password feature coming soon!');
  };

  const testFirebaseConnection = async () => {
    Alert.alert('Test Initialized', 'The connection test function has been called.');
    console.log('testFirebaseConnection function called.');
    try {
      console.log('Defining test reference...');
      const testRef = ref(db, 'testConnection');
      const testData = {
        message: 'Connection test from login page',
        timestamp: new Date().toISOString()
      };
      
      console.log('Attempting to write to database...');
      await set(testRef, testData);
      console.log('Write successful. Attempting to read back...');
      
      const snapshot = await get(testRef);
      console.log('Read operation completed.');

      if (snapshot.exists()) {
        console.log('Snapshot exists.');
        Alert.alert('Firebase Connection Test', `Success: Successfully wrote and read data. ${JSON.stringify(snapshot.val())}`);
      } else {
        console.log('Snapshot does not exist.');
        Alert.alert('Firebase Connection Test', 'Failed: Wrote data but could not read it back.');
      }
    } catch (error: any) {
      console.error('An error occurred during the Firebase connection test:', error);
      Alert.alert('Firebase Connection Test Failed', `An error occurred: ${JSON.stringify(error)}`);
    }
  };

  return (
    <SafeAreaView style={styles.safeArea}>
      <Stack.Screen options={{ header: () => null }} />
      <View style={styles.aspectRatioContainer}>
        <View style={styles.container}>
          {/* Sisi Kiri - Formulir Login */}
          <View style={styles.leftContainer}>
            <View style={styles.formWrapper}>
              {/* Logo DDS di bagian atas */}
              <View style={styles.logoContainer}>
                <Image 
                  style={styles.logoImage} 
                  source={require('@/assets/images/base.png')} 
                  accessibilityLabel="DDS Logo"
                  resizeMode="contain"
                />
                <Text style={styles.subtitle}>FIRE ALARM SYSTEM</Text>
              </View>
              
              <View style={styles.formContainer}>
                <Text style={styles.welcomeText}>Welcome back</Text>
                <Text style={styles.instructionText}>please enter your detail</Text>

                {/* Input Email */}
                <View style={styles.inputContainer}>
                  <Text style={styles.inputLabel}>Email Address</Text>
                  <TextInput
                    style={styles.textInput}
                    placeholder="example@yourmail.com"
                    placeholderTextColor="#999"
                    keyboardType="email-address"
                    autoCapitalize="none"
                    autoComplete="email"
                    textContentType="emailAddress"
                    value={formData.email}
                    onChangeText={(text) => setFormData({...formData, email: text})}
                  />
                </View>

                {/* Input Password */}
                <View style={styles.inputContainer}>
                  <Text style={styles.inputLabel}>Password</Text>
                  <TextInput
                    style={styles.textInput}
                    placeholder="yourpassword"
                    placeholderTextColor="#999"
                    secureTextEntry
                    autoComplete="password"
                    textContentType="password"
                    value={formData.password}
                    onChangeText={(text) => setFormData({...formData, password: text})}
                  />
                </View>

                {/* Link Lupa Password */}
                <TouchableOpacity 
                  style={styles.forgotPasswordContainer}
                  onPress={handleForgotPasswordPress}
                  accessibilityLabel="Forgot password"
                >
                  <Text style={styles.forgotPasswordText}>Forget Password?</Text>
                </TouchableOpacity>

                {/* Tombol Sign In */}
                <TouchableOpacity 
                  style={[styles.loginButton, loading && styles.loginButtonDisabled]}
                  onPress={handleLogin}
                  disabled={loading}
                  accessibilityLabel="Sign in button"
                  accessibilityRole="button"
                >
                  <Text style={styles.loginButtonText}>
                    {loading ? 'Signing in...' : 'Sign - in'}
                  </Text>
                </TouchableOpacity>

                {/* Tombol Test Connection */}
                <TouchableOpacity
                  style={styles.debugButton}
                  onPress={testFirebaseConnection}
                >
                  <Text style={styles.loginButtonText}>Test Connection</Text>
                </TouchableOpacity>

                {/* Link Sign Up */}
                <View style={styles.signupContainer}>
                  <Text style={styles.signupText}>
                    Dont have an account?{' '}
                    <Text 
                      style={styles.signupLink}
                      onPress={handleSignUpPress}
                      accessibilityLabel="Sign up link"
                      accessibilityRole="link"
                    >
                      Sign up
                    </Text>
                  </Text>
                </View>
              </View>
            </View>
          </View>

          {/* Sisi Kanan - Gambar Latar */}
          <View style={styles.rightContainer}>
            <Image 
              source={require('@/assets/images/login.png')}
              style={styles.backgroundImage}    
              resizeMode="cover"
              accessibilityLabel="Login background"
            />
          </View>
        </View>
      </View>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: '#fff',
  },
  aspectRatioContainer: {
    width: '100%',
    aspectRatio: baseWidth / baseHeight,
    alignSelf: 'center',
  },
  container: {
    flex: 1,
    flexDirection: 'row',
    marginTop: scaleSize(-100),
  },
  leftContainer: {
    flex: 1,
    backgroundColor: '#fff',
    justifyContent: 'center',
    paddingHorizontal: scaleSize(102.4),
  },
  rightContainer: {
    flex: 1,
    overflow: 'hidden',
  },
  formWrapper: {
    width: '100%',
    justifyContent: 'flex-start',
  },
  logoContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: scaleSize(-30),
    marginLeft: scaleSize(-40),
  },
  logoImage: {
    width: scaleSize(200),
    height: scaleSize(200),
    marginRight: scaleSize(10),
  },
  subtitle: {
    fontSize: scaleSize(14),
    fontFamily: 'Poppins_600SemiBold',
    color: '#000',
  },
  formContainer: {
    width: '100%',
  },
  welcomeText: {
    fontSize: scaleSize(24),
    fontFamily: 'Poppins_700Bold',
    color: '#000',
    marginBottom: scaleSize(5),
  },
  instructionText: {
    fontSize: scaleSize(14),
    fontFamily: 'Poppins_500Medium',
    color: '#666',
    marginBottom: scaleSize(30),
  },
  inputContainer: {
    marginBottom: scaleSize(20),
  },
  inputLabel: {
    fontSize: scaleSize(14),
    fontFamily: 'Poppins_600SemiBold',
    color: '#000',
    marginBottom: scaleSize(8),
  },
  textInput: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: scaleSize(8),
    paddingHorizontal: scaleSize(15),
    paddingVertical: scaleSize(12),
    fontSize: scaleSize(16),
    fontFamily: 'Poppins_500Medium',
    backgroundColor: '#f9f9f9',
  },
  forgotPasswordContainer: {
    alignSelf: 'flex-end',
    marginBottom: scaleSize(20),
  },
  forgotPasswordText: {
    fontSize: scaleSize(14),
    fontFamily: 'Poppins_500Medium',
    color: '#666',
  },
  loginButton: {
    backgroundColor: '#11B653',
    paddingVertical: scaleSize(15),
    borderRadius: scaleSize(8),
    alignItems: 'center',
    marginTop: scaleSize(10),
    marginBottom: scaleSize(20),
  },
  loginButtonDisabled: {
    backgroundColor: '#ccc',
  },
  loginButtonText: {
    fontSize: scaleSize(16),
    fontFamily: 'Poppins_600SemiBold',
    color: '#fff',
  },
  signupContainer: {
    alignItems: 'center',
  },
  signupText: {
    fontSize: scaleSize(14),
    fontFamily: 'Poppins_500Medium',
    color: '#666',
  },
  signupLink: {
    color: '#11B653',
    fontFamily: 'Poppins_600SemiBold',
  },
  backgroundImage: {
    width: '100%',
    height: '100%',
  },
  debugButton: {
    backgroundColor: '#FFA500', // Orange color for debug button
    paddingVertical: scaleSize(15),
    borderRadius: scaleSize(8),
    alignItems: 'center',
    marginTop: scaleSize(10),
    marginBottom: scaleSize(20),
  },
});

export default Login; 