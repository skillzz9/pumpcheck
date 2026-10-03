import json

with open("PumpCheckExpo/app.json", "r") as f:
    data = json.load(f)

if "ios" not in data["expo"]:
    data["expo"]["ios"] = {}
data["expo"]["ios"]["bundleIdentifier"] = "com.pumpcheck.expo"

with open("PumpCheckExpo/app.json", "w") as f:
    json.dump(data, f, indent=2)

print("Added bundleIdentifier!")
