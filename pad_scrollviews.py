import re

# Pad FeedView
with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

target = "                .padding(.top, 8)"
if target in content and ".padding(.bottom, 100)" not in content:
    content = content.replace(target, target + "\n                .padding(.bottom, 100)")
    with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
        f.write(content)

# Pad ProfileView
with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "r") as f:
    content = f.read()
target = """                    }
                    .padding(.top, 20)
                    
                }
            }
        }
        .navigationTitle(viewModel.username)"""
if target in content:
    content = content.replace(target, """                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                    
                }
            }
        }
        .navigationTitle(viewModel.username)""")
    with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "w") as f:
        f.write(content)

# Pad PublicProfileView
with open("PumpCheck.swiftpm/Onboarding/PublicProfileView.swift", "r") as f:
    content = f.read()
target = """                        Spacer(minLength: 40)
                    }
                    .padding(.top, 40)
                }
            }
        }
        .navigationTitle(username)"""
if target in content:
    content = content.replace(target, """                        Spacer(minLength: 40)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationTitle(username)""")
    with open("PumpCheck.swiftpm/Onboarding/PublicProfileView.swift", "w") as f:
        f.write(content)

print("Padded ScrollViews!")
