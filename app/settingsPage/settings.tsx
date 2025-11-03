import { StyleSheet, Text, View } from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'
import { Stack } from "expo-router";
import React from 'react'
import SettingDetail from '../settingsPage/settingDetail'


const settings = () => {
    return (
        <SafeAreaView style={styles.safeArea}>
            <Stack.Screen options={{ header: () => null }} />
            <View style={styles.container}>
                {/* Navbar 280px x 800px */}
                <View style={styles.settingsWrapper}>
                    <SettingDetail/>
                </View>
            </View>
        </SafeAreaView>
    )
}

export default settings

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