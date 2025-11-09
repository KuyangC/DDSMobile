// app/_layout.tsx

import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar'; // Import StatusBar

export default function RootLayout() {
  return (
    <>
      {/* Atur StatusBar agar tersembunyi */}
      <StatusBar style="light" hidden={true} />
      
      <Stack>
        <Stack.Screen name="index" options={{ headerShown: false }} />
        <Stack.Screen name="login" options={{ headerShown: false }} />
      </Stack>
    </>
  );
}