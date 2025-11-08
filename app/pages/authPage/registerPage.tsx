import React, { useState } from 'react';
import { 
  View, 
  Text, 
  TextInput, 
  TouchableOpacity, 
  StyleSheet, 
  Image, 
  Dimensions, 
  ScrollView,
  Alert
} from 'react-native';
import { useRouter, Stack } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useFonts, Poppins_700Bold, Poppins_600SemiBold, Poppins_500Medium } from '@expo-google-fonts/poppins';
import { useAuth } from '../../hooks/useAuth';

// --- DIMENSI DAN SKALA FIX ---
const baseWidth = 1280;
const baseHeight = 800;
const { width: screenWidth, height: screenHeight } = Dimensions.get('window');
const scale = screenWidth / baseWidth;
const scaleSize = (size: number) => {
  return Math.round(size * scale);
};
// --- AKHIR DIMENSI DAN SKALA ---

const Signup = () => {
  const router = useRouter();
  const { register, loading, error } = useAuth();
  
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    repeatPassword: ''
  });

  let [fontsLoaded] = useFonts({
    Poppins_700Bold,
    Poppins_600SemiBold,
    Poppins_500Medium
  });

  if (!fontsLoaded) {
    return null;
  }

  const handleRegister = async () => {
    // Validasi form
    if (!formData.email || !formData.password) {
      Alert.alert('Error', 'Please fill all fields');
      return;
    }

    if (formData.password !== formData.repeatPassword) {
      Alert.alert('Error', 'Passwords do not match');
      return;
    }

    if (formData.password.length < 6) {
      Alert.alert('Error', 'Password must be at least 6 characters');
      return;
    }

    const result = await register(formData.email, formData.password);

    if (result.success) {
      Alert.alert('Success', 'Registration successful!');
      // Redirect ke halaman login atau main app
      router.push('/pages/authPage/loginPage');
    } else {
      Alert.alert('Registration Failed', result.error || 'Something went wrong');
    }
  };

  return (
    <SafeAreaView style={styles.safeArea}>
      <Stack.Screen options={{ header: () => null }} />
      <View style={styles.aspectRatioContainer}>
        <View style={styles.container}>
          {/* Sisi Kiri - Formulir Signup dengan ScrollView */}
          <View style={styles.leftContainer}>
            <ScrollView 
              style={styles.scrollView}
              contentContainerStyle={styles.scrollContent}
              showsVerticalScrollIndicator={false}
            >
              <View style={styles.formWrapper}>
                {/* Logo DDS di bagian atas */}
                <View style={styles.logoContainer}>
                  <Image style={styles.logoImage} source={require('@/assets/images/base.png')} />
                  <Text style={styles.subtitle}>FIRE ALARM SYSTEM</Text>
                </View>
                
                <View style={styles.formContainer}>
                  <Text style={styles.welcomeText}>Create an account</Text>
                  <Text style={styles.tagline}>Your Safety Solution Partner</Text>

                  {/* Input Email */}
                  <View style={styles.inputContainer}>
                    <Text style={styles.inputLabel}>Email</Text>
                    <TextInput
                      style={styles.textInput}
                      placeholder="example@yourmail.com"
                      placeholderTextColor="#999"
                      keyboardType="email-address"
                      autoCapitalize="none"
                      value={formData.email}
                      onChangeText={(text) => setFormData({...formData, email: text})}
                    />
                  </View>

                  {/* Input Password */}
                  <View style={styles.inputContainer}>
                    <Text style={styles.inputLabel}>Password</Text>
                    <TextInput
                      style={styles.textInput}
                      placeholder="minimum 6 characters"
                      placeholderTextColor="#999"
                      secureTextEntry
                      value={formData.password}
                      onChangeText={(text) => setFormData({...formData, password: text})}
                    />
                  </View>

                  {/* Input Repeat Password */}
                  <View style={styles.inputContainer}>
                    <Text style={styles.inputLabel}>Repeat Password</Text>
                    <TextInput
                      style={styles.textInput}
                      placeholder="confirm your password"
                      placeholderTextColor="#999"
                      secureTextEntry
                      value={formData.repeatPassword}
                      onChangeText={(text) => setFormData({...formData, repeatPassword: text})}
                    />
                  </View>

                  {/* Tombol Sign Up */}
                  <TouchableOpacity 
                    style={[styles.signupButton, loading && styles.signupButtonDisabled]}
                    onPress={handleRegister}
                    disabled={loading}
                  >
                    <Text style={styles.signupButtonText}>
                      {loading ? 'Creating Account...' : 'Sign - up'}
                    </Text>
                  </TouchableOpacity>

                  {/* Link Sign In */}
                  <View style={styles.signinContainer}>
                    <Text style={styles.signinText}
                    onPress={() => router.push('/pages/authPage/loginPage')}>
                      Already have account?{' '}
                      <Text style={styles.signinLink}>Sign in</Text>
                    </Text>
                  </View>
                </View>
              </View>
            </ScrollView>
          </View>

          {/* Sisi Kanan - Gambar Latar Tetap Diam */}
          <View style={styles.rightContainer}>
            <Image 
              source={require('@/assets/images/login.png')}
              style={styles.backgroundImage}    
              resizeMode="cover"
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
    paddingHorizontal: scaleSize(102.4),
  },
  rightContainer: {
    flex: 1,
    overflow: 'hidden',
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
    paddingVertical: scaleSize(20),
  },
  formWrapper: {
    width: '100%',
  },
  logoContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: scaleSize(50),
    marginBottom: scaleSize(-60),
    marginLeft: scaleSize(-40),
  },
  logoImage: {
    width: scaleSize(200),
    height: scaleSize(200),
    marginRight: scaleSize(10),
    resizeMode: 'contain',
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
  tagline: {
    fontSize: scaleSize(14),
    fontFamily: 'Poppins_500Medium',
    color: '#666',
    marginBottom: scaleSize(30),
  },
  inputContainer: {
    marginTop: scaleSize(-20),
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
  signupButton: {
    backgroundColor: '#11B653',
    paddingVertical: scaleSize(15),
    borderRadius: scaleSize(8),
    alignItems: 'center',
    marginTop: scaleSize(10),
    marginBottom: scaleSize(10),
  },
  signupButtonDisabled: {
    backgroundColor: '#ccc',
  },
  signupButtonText: {
    fontSize: scaleSize(16),
    fontFamily: 'Poppins_600SemiBold',
    color: '#fff',
  },
  signinContainer: {
    alignItems: 'center',
  },
  signinLink: {
    color: '#11B653',
    fontFamily: 'Poppins_600SemiBold',
  },
  backgroundImage: {
    width: '100%',
    height: '100%',
  },
});

export default Signup;