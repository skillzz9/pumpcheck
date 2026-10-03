import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, ActivityIndicator } from 'react-native';
import { useAuth } from '../store/AuthContext';
import { Theme } from '../theme/Theme';

export function LoginView() {
  const { login } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleLogin = async () => {
    setLoading(true);
    setError('');
    try {
      await login(email, password);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Welcome Back</Text>
      
      <TextInput
        style={styles.input}
        placeholder="Email"
        placeholderTextColor={Theme.taupeGrey}
        autoCapitalize="none"
        value={email}
        onChangeText={setEmail}
      />
      
      <TextInput
        style={styles.input}
        placeholder="Password"
        placeholderTextColor={Theme.taupeGrey}
        secureTextEntry
        value={password}
        onChangeText={setPassword}
      />
      
      {!!error && <Text style={styles.error}>{error}</Text>}
      
      <TouchableOpacity style={styles.button} onPress={handleLogin} disabled={loading}>
        {loading ? <ActivityIndicator color={Theme.pitchBlack} /> : <Text style={styles.buttonText}>Login</Text>}
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Theme.bgGradient[0], padding: 24, justifyContent: 'center' },
  title: { fontSize: 32, fontWeight: 'bold', color: Theme.textPrimary, marginBottom: 32 },
  input: { backgroundColor: Theme.cardBackground, color: Theme.textPrimary, padding: 16, borderRadius: 12, marginBottom: 16 },
  button: { backgroundColor: Theme.accent, padding: 16, borderRadius: 12, alignItems: 'center', marginTop: 16 },
  buttonText: { color: Theme.pitchBlack, fontWeight: 'bold', fontSize: 16 },
  error: { color: 'red', marginTop: 8 }
});
