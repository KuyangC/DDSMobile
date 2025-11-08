import { Poppins_500Medium, Poppins_600SemiBold, Poppins_700Bold, useFonts } from '@expo-google-fonts/poppins';
import { useRouter } from 'expo-router';
import React from 'react';
import { StyleSheet, Text, TouchableOpacity, View } from 'react-native';

interface SettingDetailProps {
    onMenuPress: (menu: string) => void;
}


const SettingsDetail: React.FC<SettingDetailProps> = ({ onMenuPress }) => {
    let [fontsLoaded] = useFonts({
        Poppins_700Bold,
        Poppins_500Medium,
        Poppins_600SemiBold
    });

    if (!fontsLoaded) {
        return null;
    }
    
    const router = useRouter();

    return (
        <View style={styles.container}>
            <View style={styles.headerSection}>
                <Text style={styles.header}>SETTINGS</Text>
            </View>

            <View style={styles.menuSection}>
                <TouchableOpacity 
                    style={styles.settingsButton}
                    onPress={() => onMenuPress('credentials')}
                >
                    <Text style={styles.buttonText}>CREDENTIALS</Text>
                </TouchableOpacity>
                
                <TouchableOpacity 
                    style={styles.settingsButton}
                    onPress={() => onMenuPress('userAccount')}
                >
                    <Text style={styles.buttonText}>USER ACCOUNT</Text>
                </TouchableOpacity>
                
                <TouchableOpacity 
                    style={styles.settingsButton}
                    onPress={() => onMenuPress('project')}
                >
                    <Text style={styles.buttonText}>PROJECT</Text>
                </TouchableOpacity>

                <TouchableOpacity 
                    style={styles.settingsButton}
                    onPress={() => onMenuPress('logData')}
                >
                    <Text style={styles.buttonText}>LOG DATA</Text>
                </TouchableOpacity>
            </View>

            <View style={styles.bottomSection}>
                <TouchableOpacity 
                style={[styles.settingsButton, styles.logButton]}
                onPress={() => router.push('../authPage/loginPage')}
                >
                    <Text style={styles.buttonText}>LOGOUT</Text>
                </TouchableOpacity>
            </View>
        </View>
    );
};

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#f0f0f0',
        padding: 8,
    },
    headerSection: {
        alignItems: 'center',
        marginBottom: 20,
    },
    header: {
        fontSize: 26,
        fontFamily: "Poppins_700Bold",
        textAlign: 'center',
        marginBottom: 4,
    },
    menuSection: {
        alignItems: 'center',
    },
    settingsButton: {
        backgroundColor: '#11B653',
        paddingVertical: 12,
        paddingHorizontal: 50,
        borderRadius: 20,
        alignItems: 'center',
        justifyContent: 'center',
        elevation: 3,
        marginBottom: 10,
        width: '100%',
    },
    buttonText: {
        fontSize: 18,
        fontFamily: "Poppins_600SemiBold",
        color: '#FFFFFF',
    },
    bottomSection: {
        marginTop: 20,
        alignItems: 'center',
    },
    logButton: {
        backgroundColor: '#FF3B30',
    },
});

export default SettingsDetail;