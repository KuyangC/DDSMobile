import { StyleSheet, View } from "react-native";
import { SafeAreaView } from 'react-native-safe-area-context';
import { Stack } from "expo-router";
import NavBar from "./mainPage/navbar";
import ModuleTable from "./mainPage/areaTable";

const Index = () => {
  return (
    <SafeAreaView style={styles.safeArea}>
      <Stack.Screen options={{ header: () => null }} />
      <View style={styles.container}>
        {/* Navbar 280px x 800px */}
        <View style={styles.navbarWrapper}>
          <NavBar />
        </View>

        {/* Content Area */}
        <View style={styles.content}>
          <ModuleTable />
        </View>
      </View>
    </SafeAreaView>
  );
}

export default Index;

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: 'white',
  },
  container: {
    flex: 1,
    flexDirection: 'row',
  },
  navbarWrapper: {
    width: 280,
    backgroundColor: '#f0f0f0',
  },
  content: {
    flex: 1,
    backgroundColor: 'white',
  },
});