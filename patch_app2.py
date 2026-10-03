with open("PumpCheckExpo/App.tsx", "r") as f:
    content = f.read()

content = content.replace("import React from 'react';", "import React from 'react';\nimport { AuthProvider, useAuth } from './src/store/AuthContext';\nimport { LoginView } from './src/screens/LoginView';\nimport { ActivityIndicator, View } from 'react-native';")

content = content.replace("export default function App() {", """
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

export default function App() {""")

content = content.replace("""      <Stack.Navigator screenOptions={{ headerShown: false }}>
        <Stack.Screen name="MainTab" component={MainTab} />
        <Stack.Screen name="CommentModal" component={CommentModal} options={{ presentation: 'modal' }} />
      </Stack.Navigator>""", "      <RootNavigator />")

with open("PumpCheckExpo/App.tsx", "w") as f:
    f.write(content)
print("Patched App.tsx!")
