with open("PumpCheckExpo/App.tsx", "r") as f:
    content = f.read()

content = content.replace("import { MainTab } from './src/screens/MainTab';", "import { MainTab } from './src/screens/MainTab';\nimport { CommentModal } from './src/screens/CommentModal';")

content = content.replace("<Stack.Screen name=\"MainTab\" component={MainTab} />", "<Stack.Screen name=\"MainTab\" component={MainTab} />\n        <Stack.Screen name=\"CommentModal\" component={CommentModal} options={{ presentation: 'modal' }} />")

with open("PumpCheckExpo/App.tsx", "w") as f:
    f.write(content)
print("Patched App.tsx!")
