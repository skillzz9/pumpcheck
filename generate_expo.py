import os

def write_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(content.strip() + "\n")

# Theme
write_file("PumpCheckExpo/src/theme/Theme.ts", """
export const Theme = {
  pitchBlack: '#0c1a27',
  darkCoffee: '#000000',
  neonIce: '#6bd0fa',
  deepBlue: '#6bd0fa',
  textBoxBlue: '#000000',
  paleSky: '#d8eefd',
  taupeGrey: '#645853',
  bgGradient: ['#0c1a27', '#0c1a27'],
  cardBackground: '#000000',
  accent: '#6bd0fa',
  textPrimary: '#d8eefd',
  textSecondary: 'rgba(216, 238, 253, 0.7)'
};
""")

# App.tsx
write_file("PumpCheckExpo/App.tsx", """
import React from 'react';
import { NavigationContainer, DefaultTheme } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { MainTab } from './src/screens/MainTab';
import { StatusBar } from 'expo-status-bar';

const Stack = createNativeStackNavigator();
const navTheme = {
  ...DefaultTheme,
  colors: {
    ...DefaultTheme.colors,
    background: '#0c1a27',
  },
};

export default function App() {
  return (
    <NavigationContainer theme={navTheme}>
      <StatusBar style="light" />
      <Stack.Navigator screenOptions={{ headerShown: false }}>
        <Stack.Screen name="MainTab" component={MainTab} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
""")

# MainTab.tsx
write_file("PumpCheckExpo/src/screens/MainTab.tsx", """
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
""")

# FeedView.tsx
write_file("PumpCheckExpo/src/screens/FeedView.tsx", """
import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { Theme } from '../theme/Theme';
import { Ionicons } from '@expo/vector-icons';

type PostComment = {
  id: string;
  username: string;
  photoBase64: string;
  text: string;
  isLiked: boolean;
  likesCount: number;
};

type FeedPost = {
  id: string;
  username: string;
  imageName: string;
  kudos: number;
  isKudoed: boolean;
  caption: string;
  comments: PostComment[];
};

export function FeedView() {
  const [posts, setPosts] = useState<FeedPost[]>([
    {
      id: "1", username: "alex_fitness", imageName: "dummy1", kudos: 12, isKudoed: false, caption: "Crushed the morning workout! 💪",
      comments: [{ id: "c1", username: "gym_bro", photoBase64: "", text: "Looking huge man!", isLiked: false, likesCount: 2 }]
    },
    { id: "2", username: "sarah_lifts", imageName: "dummy2", kudos: 45, isKudoed: true, caption: "Leg day is the best day. 🦵", comments: [] }
  ]);

  const toggleKudo = (id: string) => {
    setPosts(prev => prev.map(p => {
      if (p.id === id) {
        return { ...p, isKudoed: !p.isKudoed, kudos: p.isKudoed ? p.kudos - 1 : p.kudos + 1 };
      }
      return p;
    }));
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      {posts.map(post => (
        <View key={post.id} style={styles.post}>
          <View style={styles.imagePlaceholder}>
            <Ionicons name="image-outline" size={50} color="rgba(100, 88, 83, 0.5)" />
          </View>
          <View style={styles.actions}>
            <TouchableOpacity onPress={() => toggleKudo(post.id)}>
              <Ionicons name={post.isKudoed ? "heart" : "heart-outline"} size={28} color={post.isKudoed ? Theme.accent : Theme.textPrimary} />
            </TouchableOpacity>
            <TouchableOpacity style={{ marginLeft: 16 }}>
              <Ionicons name="chatbubble-outline" size={26} color={Theme.textPrimary} />
            </TouchableOpacity>
          </View>
          {post.kudos > 0 && (
            <Text style={styles.kudosText}>{post.kudos} {post.kudos === 1 ? 'kudo' : 'kudos'}</Text>
          )}
        </View>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Theme.pitchBlack,
  },
  content: {
    paddingVertical: 16,
    gap: 24,
  },
  post: {
    marginBottom: 24,
  },
  imagePlaceholder: {
    width: '100%',
    aspectRatio: 1,
    backgroundColor: Theme.cardBackground,
    justifyContent: 'center',
    alignItems: 'center',
  },
  actions: {
    flexDirection: 'row',
    paddingHorizontal: 12,
    paddingTop: 8,
  },
  kudosText: {
    color: Theme.textPrimary,
    fontWeight: 'bold',
    fontSize: 14,
    paddingHorizontal: 12,
    marginTop: 4,
  }
});
""")

print("Files generated!")
