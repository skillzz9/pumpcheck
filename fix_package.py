import sys

with open("PumpCheck.swiftpm/Package.swift", "r") as f:
    content = f.read()

content = content.replace("appIcon: .placeholder(icon: .weights)", 'appIcon: .asset("AppIcon")')

with open("PumpCheck.swiftpm/Package.swift", "w") as f:
    f.write(content)

