import { Poppins_500Medium, Poppins_600SemiBold, useFonts } from '@expo-google-fonts/poppins';
import React from 'react';
import { StyleSheet, Text, View, ScrollView } from 'react-native';
import LogViewer from '../../components/LogViewer';
import ESP32ConnectionTester from '../../components/ESP32ConnectionTester';
import FirebaseConnectionTester from '../../components/FirebaseConnectionTester';

interface SettingsContentProps {
    activeMenu: string;
}

const SettingsContent: React.FC<SettingsContentProps> = ({ activeMenu }) => {
    let [fontsLoaded] = useFonts({
        Poppins_500Medium,
        Poppins_600SemiBold
    });

    if (!fontsLoaded) {
        return null;
    }

    const renderContent = () => {
        switch (activeMenu) {
            case 'credentials':
                return (
                    <View>
                        <Text style={styles.title}>Credentials Settings</Text>
                        <Text style={styles.contentText}>
                            Manage your login credentials and authentication settings here.
                        </Text>
                        {/* Tambah form credentials di sini */}
                    </View>
                );
            
            case 'userAccount':
                return (
                    <View>
                        <Text style={styles.title}>User Account</Text>
                        <Text style={styles.contentText}>
                            Update your profile information and account settings.
                        </Text>
                        {/* Tambah form user account di sini */}
                    </View>
                );
            
            case 'project':
                return (
                    <View>
                        <Text style={styles.title}>Project Settings</Text>
                        <Text style={styles.contentText}>
                            Configure project-specific settings and preferences.
                        </Text>
                        {/* Tambah project settings di sini */}
                    </View>
                );
            
            case 'esp32Connection':
                return <ESP32ConnectionTester />;
            
            case 'firebaseConnection':
                return <FirebaseConnectionTester />;
            
            case 'logData':
                return <LogViewer />;
            
            default:
                return (
                    <View style={styles.placeholder}>
                        <Text style={styles.placeholderText}>
                            Select a menu from the left to get started
                        </Text>
                    </View>
                );
        }
    };

    return (
        <ScrollView style={styles.container}>
            {renderContent()}
        </ScrollView>
    );
};

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#fff',
        padding: 20,
    },
    title: {
        fontSize: 24,
        fontFamily: "Poppins_600SemiBold",
        color: '#000',
        marginBottom: 15,
    },
    contentText: {
        fontSize: 16,
        fontFamily: "Poppins_500Medium",
        color: '#333',
        lineHeight: 24,
    },
    placeholder: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        paddingVertical: 100,
    },
    placeholderText: {
        fontSize: 18,
        fontFamily: "Poppins_500Medium",
        color: '#666',
        textAlign: 'center',
    },
});

export default SettingsContent;