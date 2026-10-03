import React from 'react';
import { View, Text, StyleSheet, ScrollView, Image, TouchableOpacity } from 'react-native';
import { Theme } from '../theme/Theme';
import { Ionicons } from '@expo/vector-icons';

// Mock data since we don't have Firebase hooked up yet
const MOCK_USER = {
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
};

export function ProfileView() {
  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        {/* Header section with white background */}
        <View style={styles.headerBlock}>
          <View style={styles.profileImageContainer}>
            <Ionicons name="person" size={60} color="rgba(100, 88, 83, 0.5)" />
          </View>
          
          <Text style={styles.username}>@{MOCK_USER.username}</Text>
          
          <View style={styles.statsContainer}>
            {/* Height Pill */}
            <View style={styles.pill}>
              <Ionicons name="resize" size={16} color={Theme.accent} />
              <Text style={styles.pillText}>{MOCK_USER.height} {MOCK_USER.isHeightCm ? "cm" : "in"}</Text>
            </View>
            
            {/* Weight Pill */}
            <View style={styles.pill}>
              <Ionicons name="scale-outline" size={16} color={Theme.accent} />
              <Text style={styles.pillText}>{MOCK_USER.weight} {MOCK_USER.isWeightKg ? "kg" : "lbs"}</Text>
            </View>
            
            {/* Kudos Pill */}
            <View style={styles.pill}>
              <Ionicons name="thumbs-up" size={16} color={Theme.accent} />
              <Text style={styles.pillText}>{MOCK_USER.kudos}</Text>
            </View>
          </View>
        </View>
        
        {/* Lifts Section */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Proudest Lifts</Text>
          {MOCK_USER.proudestLifts.map(lift => (
            <View key={lift.id} style={styles.card}>
              <Text style={styles.liftName}>{lift.name}</Text>
              <Text style={styles.liftStats}>{lift.weight} × {lift.reps}</Text>
            </View>
          ))}
        </View>

        {/* Goals Section */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Goals</Text>
          {MOCK_USER.goals.map((goal, index) => (
            <View key={index} style={styles.cardRow}>
              <Ionicons name="checkmark-circle" size={20} color={Theme.accent} />
              <Text style={styles.goalText}>{goal}</Text>
            </View>
          ))}
        </View>

        {/* Logout */}
        <TouchableOpacity style={styles.logoutButton}>
          <Text style={styles.logoutText}>Log Out</Text>
        </TouchableOpacity>
        
        <View style={{ height: 40 }} />
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Theme.bgGradient[0] },
  scrollContent: { },
  headerBlock: {
    backgroundColor: '#ffffff',
    paddingTop: 60,
    paddingBottom: 24,
    paddingHorizontal: 24,
    alignItems: 'center',
    borderBottomLeftRadius: 24,
    borderBottomRightRadius: 24,
    marginBottom: 24
  },
  profileImageContainer: {
    width: 100, height: 100,
    borderRadius: 50,
    backgroundColor: Theme.cardBackground,
    justifyContent: 'center', alignItems: 'center',
    marginBottom: 16
  },
  username: {
    fontSize: 24, fontWeight: 'bold', color: Theme.pitchBlack, marginBottom: 24
  },
  statsContainer: {
    flexDirection: 'row', gap: 12, width: '100%'
  },
  pill: {
    flex: 1, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 6,
    paddingVertical: 8,
    backgroundColor: Theme.pitchBlack,
    borderRadius: 20
  },
  pillText: {
    fontSize: 14, fontWeight: 'bold', color: Theme.textPrimary
  },
  section: {
    paddingHorizontal: 24, marginBottom: 24, gap: 12
  },
  sectionTitle: {
    fontSize: 20, fontWeight: 'bold', color: Theme.textPrimary, marginBottom: 4
  },
  card: {
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center',
    backgroundColor: Theme.cardBackground, padding: 16, borderRadius: 16
  },
  liftName: {
    fontSize: 16, fontWeight: '600', color: Theme.textPrimary
  },
  liftStats: {
    fontSize: 16, fontWeight: 'bold', color: Theme.accent
  },
  cardRow: {
    flexDirection: 'row', alignItems: 'center', gap: 16,
    backgroundColor: Theme.cardBackground, padding: 16, borderRadius: 16
  },
  goalText: {
    fontSize: 16, fontWeight: '500', color: Theme.textPrimary
  },
  logoutButton: {
    backgroundColor: Theme.cardBackground,
    marginHorizontal: 24,
    paddingVertical: 16,
    borderRadius: 16,
    alignItems: 'center'
  },
  logoutText: {
    color: '#ff4444', fontSize: 16, fontWeight: 'bold'
  }
});
