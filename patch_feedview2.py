with open("PumpCheckExpo/src/screens/FeedView.tsx", "r") as f:
    content = f.read()

content = content.replace("export function FeedView() {", "import { useNavigation } from '@react-navigation/native';\n\nexport function FeedView() {\n  const navigation = useNavigation();")

content = content.replace("<TouchableOpacity style={{ marginLeft: 16 }}>", "<TouchableOpacity style={{ marginLeft: 16 }} onPress={() => navigation.navigate('CommentModal', { post })}>")

with open("PumpCheckExpo/src/screens/FeedView.tsx", "w") as f:
    f.write(content)
print("Patched FeedView.tsx!")
