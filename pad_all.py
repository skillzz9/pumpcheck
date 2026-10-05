import re

# 1. FeedView
with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

target = """                    }
                    .padding(.vertical)
                }"""
if target in content:
    content = content.replace(target, """                    }
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }""")
    with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
        f.write(content)


# 2. ProgramView
with open("PumpCheck.swiftpm/Onboarding/ProgramView.swift", "r") as f:
    content = f.read()
target = """                        Spacer(minLength: 40)
                    }
                }"""
if target in content:
    content = content.replace(target, """                        Spacer(minLength: 40)
                    }
                    .padding(.bottom, 120)
                }""")
    with open("PumpCheck.swiftpm/Onboarding/ProgramView.swift", "w") as f:
        f.write(content)

# 3. ProfileView
with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "r") as f:
    content = f.read()
target = """                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                    
                }"""
if target in content:
    content = content.replace(target, """                    }
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                    
                }""")
else:
    # try just top 20
    target2 = """                    }
                    .padding(.top, 20)
                    
                }"""
    if target2 in content:
        content = content.replace(target2, """                    }
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                    
                }""")
with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "w") as f:
    f.write(content)

# 4. PublicProfileView
with open("PumpCheck.swiftpm/Onboarding/PublicProfileView.swift", "r") as f:
    content = f.read()
target = """                        Spacer(minLength: 40)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 100)
                }"""
if target in content:
    content = content.replace(target, """                        Spacer(minLength: 40)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 120)
                }""")
else:
    target2 = """                        Spacer(minLength: 40)
                    }
                    .padding(.top, 40)
                }"""
    if target2 in content:
        content = content.replace(target2, """                        Spacer(minLength: 40)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 120)
                }""")
with open("PumpCheck.swiftpm/Onboarding/PublicProfileView.swift", "w") as f:
    f.write(content)

# 5. ProgressTab
with open("PumpCheck.swiftpm/Onboarding/ProgressTab.swift", "r") as f:
    content = f.read()
content = content.replace(".padding(.bottom, 100)", ".padding(.bottom, 120)")
with open("PumpCheck.swiftpm/Onboarding/ProgressTab.swift", "w") as f:
    f.write(content)

print("Padded all files!")
