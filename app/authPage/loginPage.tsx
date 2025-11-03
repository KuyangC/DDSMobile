import React from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, Image, Dimensions } from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Stack } from "expo-router";
import { useFonts, Poppins_700Bold, Poppins_600SemiBold, Poppins_500Medium } from '@expo-google-fonts/poppins';

// --- DIMENSI DAN SKALA FIX ---
const baseWidth = 1280;
const baseHeight = 800;
const { width: screenWidth, height: screenHeight } = Dimensions.get('window');
const scale = screenWidth / baseWidth;
const scaleSize = (size) => {
  return size * scale;
};
// --- AKHIR DIMENSI DAN SKALA ---

const Login = () => {
  const router = useRouter();
  
  let [fontsLoaded] = useFonts({
    Poppins_700Bold,
    Poppins_600SemiBold,
    Poppins_500Medium
  });

  if (!fontsLoaded) {
    return null;
  }

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
                <Image style={styles.logoImage} source={require('@/assets/images/base.png')} />
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
                  />
                </View>

                {/* Link Lupa Password */}
                <TouchableOpacity style={styles.forgotPasswordContainer}>
                  <Text style={styles.forgotPasswordText}>Forget Password?</Text>
                </TouchableOpacity>

                {/* Tombol Sign In */}
                <TouchableOpacity 
                  style={styles.loginButton}
                  onPress={() => router.push('/')}
                >
                  <Text style={styles.loginButtonText}>Sign - in</Text>
                </TouchableOpacity>

                {/* Link Sign Up */}
                <View style={styles.signupContainer}>
                  <Text 
                  style={styles.signupText}
                  onPress={() => router.push('/authPage/registerPage')}
                  >
                    Dont have an account?{' '}
                    <Text style={styles.signupLink}>Sign up</Text>
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
    // Menyelaraskan konten ke atas
    justifyContent: 'flex-start',
  },
  // Container baru untuk logo dan subtitle
  logoContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: scaleSize(-30), // Jarak ke bawah menuju form
    marginLeft: scaleSize(-40), // Penyesuaian posisi ke kiri
  },
  // Style khusus untuk gambar logo
  logoImage: {
    width: scaleSize(200), // Sesuaikan ukuran logo
    height: scaleSize(200), // Sesuaikan ukuran logo
    marginRight: scaleSize(10), // Jarak ke subtitle
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
});

export default Login;