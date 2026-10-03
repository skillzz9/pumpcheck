import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, TextInput, TouchableOpacity, KeyboardAvoidingView, Platform } from 'react-native';
import { Theme } from '../theme/Theme';
import { Ionicons } from '@expo/vector-icons';

export function CommentModal({ route, navigation }: any) {
  const { post } = route.params;
  const [commentText, setCommentText] = useState("");
  const [comments, setComments] = useState(post.comments || []);

  const sendComment = () => {
    if (!commentText) return;
    setComments([...comments, {
      id: Math.random().toString(),
      username: "me",
      photoBase64: "",
      text: commentText,
      isLiked: false,
      likesCount: 0
    }]);
    setCommentText("");
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <Ionicons name="chevron-back" size={24} color={Theme.textPrimary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Comments</Text>
        <View style={{ width: 24 }} />
      </View>

      <View style={styles.imagePlaceholder}>
        <Ionicons name="image-outline" size={40} color="rgba(100, 88, 83, 0.5)" />
      </View>

      <ScrollView style={styles.commentsArea}>
        {comments.length === 0 ? (
          <Text style={styles.noComments}>No comments yet.</Text>
        ) : (
          comments.map((c: any) => (
            <View key={c.id} style={styles.commentRow}>
              <View style={styles.avatar}>
                <Text style={styles.avatarText}>{c.username[0].toUpperCase()}</Text>
              </View>
              <View style={styles.commentText}>
                <Text style={styles.usernameText}>{c.username} <Text style={styles.contentText}>{c.text}</Text></Text>
                {c.likesCount > 0 && <Text style={styles.likesText}>{c.likesCount} likes</Text>}
              </View>
              <Ionicons name="heart-outline" size={14} color={Theme.textSecondary} />
            </View>
          ))
        )}
      </ScrollView>

      <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : 'height'}>
        <View style={styles.inputArea}>
          <TextInput
            style={styles.input}
            placeholder="Add a comment..."
            placeholderTextColor={Theme.taupeGrey}
            value={commentText}
            onChangeText={setCommentText}
          />
          <TouchableOpacity onPress={sendComment} disabled={!commentText}>
            <Ionicons name="send" size={24} color={commentText ? Theme.accent : Theme.taupeGrey} />
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Theme.pitchBlack },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', padding: 16, backgroundColor: Theme.pitchBlack },
  headerTitle: { color: Theme.textPrimary, fontSize: 18, fontWeight: 'bold' },
  imagePlaceholder: { height: '33%', width: '100%', backgroundColor: Theme.cardBackground, justifyContent: 'center', alignItems: 'center' },
  commentsArea: { flex: 1, backgroundColor: Theme.bgGradient[0], padding: 16 },
  noComments: { color: Theme.textSecondary, textAlign: 'center', marginTop: 40 },
  commentRow: { flexDirection: 'row', alignItems: 'flex-start', marginBottom: 16 },
  avatar: { width: 36, height: 36, borderRadius: 18, backgroundColor: 'rgba(100, 88, 83, 0.5)', justifyContent: 'center', alignItems: 'center' },
  avatarText: { color: Theme.textPrimary, fontWeight: 'bold' },
  commentText: { flex: 1, marginLeft: 12 },
  usernameText: { color: Theme.textPrimary, fontWeight: 'bold' },
  contentText: { fontWeight: 'normal' },
  likesText: { color: Theme.textSecondary, fontSize: 12, marginTop: 4 },
  inputArea: { flexDirection: 'row', padding: 16, backgroundColor: Theme.pitchBlack, alignItems: 'center' },
  input: { flex: 1, color: Theme.textPrimary, padding: 12, borderRadius: 8, borderWidth: 1, borderColor: Theme.taupeGrey, marginRight: 12 }
});
