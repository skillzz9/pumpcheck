with open("PumpCheckExpo/src/screens/ProfileView.tsx", "r") as f:
    content = f.read()

content = content.replace("((goal: any, index: number)) =>", "(goal: any, index: number) =>")
with open("PumpCheckExpo/src/screens/ProfileView.tsx", "w") as f:
    f.write(content)
