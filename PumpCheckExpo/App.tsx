import React from 'react';
import { AuthProvider, useAuth } from './src/store/AuthContext';
import { LoginView } from './src/screens/LoginView';
import { ActivityIndicator, View } from 'react-native';
import { NavigationContainer, DefaultTheme } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { MainTab } from './src/screens/MainTab';
import { CommentModal } from './src/screens/CommentModal';
import { StatusBar } from 'expo-status-bar';

const Stack = createNativeStackNavigator();
const navTheme = {
  ...DefaultTheme,
  colors: {
    ...DefaultTheme.colors,
    background: '#0c1a27',
  },
};


function RootNavigator() {
  const { user, loading } = useAuth();
  if (loading) return <View style={{flex: 1, backgroundColor: '#0c1a27', justifyContent: 'center'}}><ActivityIndicator /></View>;
  
  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      {user ? (
        <>
          <Stack.Screen name="MainTab" component={MainTab} />
          <Stack.Screen name="CommentModal" component={CommentModal} options={{ presentation: 'modal' }} />
        </>
      ) : (
        <Stack.Screen name="Login" component={LoginView} />
      )}
    </Stack.Navigator>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <NavigationContainer theme={navTheme}>
        <StatusBar style="light" />
        <RootNavigator />
      </NavigationContainer>
    </AuthProvider>
  );
}
