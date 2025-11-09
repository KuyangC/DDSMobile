import { StyleSheet, View } from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'
import { Stack } from "expo-router";
import React, { useState } from 'react'
import SettingDetail from '../settingsPage/settingDetail'
import SettingsContent from '../settingsPage/settingContent'

const Settings = () => {
    const [activeMenu, setActiveMenu] = useState<string>('');

    return (
        <SafeAreaView style={styles.safeArea}>
            <Stack.Screen options={{ header: () => null }} />
            <View style={styles.container}>
                {/* Navbar Settings di kiri */}
                <View style={styles.settingsWrapper}>
                    <SettingDetail onMenuPress={setActiveMenu} />
                </View>

                {/* Content di kanan */}
                <View style={styles.content}>
                    <SettingsContent activeMenu={activeMenu} />
                </View>
            </View>
        </SafeAreaView>
    )
}

export default Settings

const styles = StyleSheet.create({
    safeArea: {
        flex: 1,
        backgroundColor: 'white',
    },
    container: {
        flex: 1,
        flexDirection: 'row',
    },
    settingsWrapper: {
        width: 280,
        backgroundColor: '#f0f0f0',
    },
    content: {
        flex: 1,
        backgroundColor: 'white',
    },
});