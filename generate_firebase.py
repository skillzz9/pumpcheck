import os

def write_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(content.strip() + "\n")

write_file("PumpCheckExpo/src/firebase/config.ts", """
import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: "AIzaSyAoUsPES7HXcU-b_3YWAcOH6-UfmrWRugw",
  authDomain: "pumpcheck-b66a7.firebaseapp.com",
  projectId: "pumpcheck-b66a7",
  storageBucket: "pumpcheck-b66a7.firebasestorage.app",
  messagingSenderId: "880918542376",
  appId: "1:880918542376:ios:34c6711008e7dfc4bd5d1d"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
""")

write_file("PumpCheckExpo/src/store/AuthContext.tsx", """
import React, { createContext, useContext, useState, useEffect } from 'react';
import { auth, db } from '../firebase/config';
import { onAuthStateChanged, User, signInWithEmailAndPassword, signOut } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';

type AuthContextType = {
  user: User | null;
  userData: any | null;
  loading: boolean;
  login: (e: string, p: string) => Promise<void>;
  logout: () => Promise<void>;
};

const AuthContext = createContext<AuthContextType>({} as any);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [userData, setUserData] = useState<any | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, async (u) => {
      setUser(u);
      if (u) {
        const d = await getDoc(doc(db, 'users', u.uid));
        if (d.exists()) {
          setUserData(d.data());
        }
      } else {
        setUserData(null);
      }
      setLoading(false);
    });
    return unsub;
  }, []);

  const login = async (e: string, p: string) => {
    await signInWithEmailAndPassword(auth, e, p);
  };

  const logout = async () => {
    await signOut(auth);
  };

  return (
    <AuthContext.Provider value={{ user, userData, loading, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
""")

write_file("PumpCheckExpo/src/screens/LoginView.tsx", """
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
""")

print("Auth files generated!")
