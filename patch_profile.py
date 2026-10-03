with open("PumpCheckExpo/src/screens/ProfileView.tsx", "r") as f:
    content = f.read()

content = content.replace("export function ProfileView() {", """
import { useAuth } from '../store/AuthContext';

export function ProfileView() {
  const { userData, logout } = useAuth();
  
  const MOCK_USER = {
    username: userData?.username || "loading...",
    height: userData?.height || "--",
    isHeightCm: userData?.isHeightCm ?? true,
    weight: userData?.weight || "--",
    isWeightKg: userData?.isWeightKg ?? true,
    kudos: userData?.kudos || 0,
    proudestLifts: userData?.lifts || [],
    goals: userData?.goals || [],
    photoBase64: userData?.photoBase64 || ""
  };
""")

content = content.replace("""const MOCK_USER = {
  username: "alex_fitness",
  height: "180",
  isHeightCm: true,
  weight: "75",
  isWeightKg: true,
  kudos: 124,
  proudestLifts: [
    { id: "1", name: "Bench Press", weight: 100, reps: 5 },
    { id: "2", name: "Squat", weight: 140, reps: 3 },
  ],
  goals: ["Hit 200kg Deadlift", "Workout 4 days a week"]
};""", "")

content = content.replace("""<Ionicons name="person" size={60} color="rgba(100, 88, 83, 0.5)" />""", """{MOCK_USER.photoBase64 ? (
              <Image source={{ uri: `data:image/jpeg;base64,${MOCK_USER.photoBase64}` }} style={{ width: 100, height: 100, borderRadius: 50 }} />
            ) : (
              <Ionicons name="person" size={60} color="rgba(100, 88, 83, 0.5)" />
            )}""")

content = content.replace("""<TouchableOpacity style={styles.logoutButton}>""", """<TouchableOpacity style={styles.logoutButton} onPress={logout}>""")

with open("PumpCheckExpo/src/screens/ProfileView.tsx", "w") as f:
    f.write(content)
print("Patched ProfileView.tsx!")
