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

import { useNavigation } from '@react-navigation/native';

export function FeedView() {
  const navigation = useNavigation<any>();
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
            <TouchableOpacity style={{ marginLeft: 16 }} onPress={() => navigation.navigate('CommentModal', { post })}>
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
