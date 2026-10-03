with open("PumpCheckExpo/App.tsx", "r") as f:
    content = f.read()

content = content.replace("""export default function App() {
  return (
    <NavigationContainer theme={navTheme}>
      <StatusBar style="light" />
      <RootNavigator />
    </NavigationContainer>
  );
}""", """export default function App() {
  return (
    <AuthProvider>
      <NavigationContainer theme={navTheme}>
        <StatusBar style="light" />
        <RootNavigator />
      </NavigationContainer>
    </AuthProvider>
  );
}""")

with open("PumpCheckExpo/App.tsx", "w") as f:
    f.write(content)
print("Wrapped with AuthProvider!")
