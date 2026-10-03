import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { FeedView } from './FeedView';
import { View, Text, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Theme } from '../theme/Theme';

const Tab = createBottomTabNavigator();

function PlaceholderScreen({ title }: { title: string }) {
  return (
    <View style={styles.container}>
      <Text style={styles.text}>{title}</Text>
    </View>
  );
}

export function MainTab() {
  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        tabBarIcon: ({ focused, color, size }) => {
          let iconName: keyof typeof Ionicons.glyphMap = 'help';
          if (route.name === 'Feed') iconName = 'list';
          else if (route.name === 'Program') iconName = 'clipboard-outline';
          else if (route.name === 'Progress') iconName = 'stats-chart';
          else if (route.name === 'Profile') iconName = 'person-circle-outline';
          return <Ionicons name={iconName} size={size} color={color} />;
        },
        tabBarActiveTintColor: '#ffffff',
        tabBarInactiveTintColor: 'rgba(216, 238, 253, 0.5)',
        tabBarStyle: {
          backgroundColor: Theme.pitchBlack,
          borderTopWidth: 0,
          elevation: 0,
        },
        headerStyle: {
          backgroundColor: Theme.pitchBlack,
        },
        headerTintColor: '#ffffff',
      })}
    >
      <Tab.Screen name="Feed" component={FeedView} />
      <Tab.Screen name="Program" children={() => <PlaceholderScreen title="Program feature coming soon" />} />
      <Tab.Screen name="Progress" children={() => <PlaceholderScreen title="Progress" />} />
      <Tab.Screen name="Profile" children={() => <PlaceholderScreen title="Profile" />} />
    </Tab.Navigator>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Theme.pitchBlack,
    justifyContent: 'center',
    alignItems: 'center',
  },
  text: {
    color: Theme.textSecondary,
    fontSize: 24,
    fontWeight: 'bold',
  }
});
