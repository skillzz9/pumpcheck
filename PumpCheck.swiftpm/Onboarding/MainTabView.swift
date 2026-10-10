import SwiftUI

struct MainTabView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var selectedTab = 3
    
    // Haptic engine
    private let impactMed = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            // Main Content Area
            ZStack {
                FeedView(viewModel: viewModel)
                    .opacity(selectedTab == 0 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 0)
                    
                ProgramView(viewModel: viewModel)
                    .opacity(selectedTab == 1 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 1)
                    
                ProgressTab(viewModel: viewModel)
                    .opacity(selectedTab == 2 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 2)
                    
                DietView(viewModel: viewModel)
                    .opacity(selectedTab == 4 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 4)
                    
                ProfileView(viewModel: viewModel)
                    .opacity(selectedTab == 3 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 3)
            }
            .animation(.easeInOut(duration: 0.15), value: selectedTab)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Tab Bar Overlay
            VStack(spacing: 0) {
                Divider().background(Theme.cardBackground)
                
                HStack {
                    TabBarItem(icon: "list.bullet", title: "Feed", isSelected: selectedTab == 0) {
                        switchToTab(0)
                    }
                    TabBarItem(icon: "list.clipboard", title: "Program", isSelected: selectedTab == 1) {
                        switchToTab(1)
                    }
                    TabBarItem(icon: "chart.xyaxis.line", title: "Progress", isSelected: selectedTab == 2) {
                        switchToTab(2)
                    }
                    TabBarItem(icon: "fork.knife", title: "Diet", isSelected: selectedTab == 4) {
                        switchToTab(4)
                    }
                    TabBarItem(icon: "person.crop.circle", title: "Profile", isSelected: selectedTab == 3) {
                        switchToTab(3)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 12)
            }
            .background(
                Rectangle()
                    .fill(Theme.pitchBlack.opacity(0.85))
                    .ignoresSafeArea(edges: .bottom)
            )
            .background(.ultraThinMaterial) // Glossy blur
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    private func switchToTab(_ tab: Int) {
        if selectedTab != tab {
            impactMed.impactOccurred()
            selectedTab = tab
        }
    }
}

struct TabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isBouncing = false
    
    var body: some View {
        Button {
            action()
            // Trigger bounce
            isBouncing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isBouncing = false
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: isSelected ? .bold : .regular))
                    .frame(height: 28) // Same box for every symbol so all titles share one baseline
                    .scaleEffect(isBouncing ? 0.7 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0), value: isBouncing)
                
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
            }
            .foregroundColor(isSelected ? .white : Theme.paleSky.opacity(0.5))
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
