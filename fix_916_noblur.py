import sys

def replace_in_file(filepath, old, new):
    with open(filepath, 'r') as f:
        content = f.read()
    if old in content:
        content = content.replace(old, new)
        with open(filepath, 'w') as f:
            f.write(content)

# 1. ProfileView.swift
old_profile = """                        Color.clear
                            .aspectRatio(9.0 / 16.0, contentMode: .fit)
                            .overlay(
                                ZStack {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .blur(radius: 20)
                                        .opacity(0.5)
                                        
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                }
                            )
                            .clipped()
                            .background(Theme.pitchBlack)"""
new_profile = """                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .background(Theme.pitchBlack)"""
replace_in_file("PumpCheck.swiftpm/Onboarding/ProfileView.swift", old_profile, new_profile)

# 2. ProgressTab.swift
old_tab = """                                Color.clear
                                    .aspectRatio(9.0 / 16.0, contentMode: .fit)
                                    .overlay(
                                        ZStack {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .blur(radius: 20)
                                                .opacity(0.5)
                                                
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFit()
                                        }
                                    )
                                    .clipped()
                                    .background(Theme.pitchBlack)"""
new_tab = """                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                    .background(Theme.pitchBlack)"""
replace_in_file("PumpCheck.swiftpm/Onboarding/ProgressTab.swift", old_tab, new_tab)


# 3. ProgressDetailView.swift
old_detail = """                            Color.clear
                                .aspectRatio(9.0 / 16.0, contentMode: .fit)
                                .overlay(
                                    ZStack {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .blur(radius: 20)
                                            .opacity(0.5)
                                            
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFit()
                                    }
                                )
                                .clipped()
                                .background(Theme.pitchBlack)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal, 24)"""
new_detail = """                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .background(Theme.pitchBlack)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal, 24)"""
replace_in_file("PumpCheck.swiftpm/Onboarding/ProgressDetailView.swift", old_detail, new_detail)

