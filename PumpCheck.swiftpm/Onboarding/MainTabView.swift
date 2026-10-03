import SwiftUI

struct MainTabView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var selectedTab = 3
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "list.bullet")
                }
                .tag(0)
            
            ProgramView(viewModel: viewModel)
                .tabItem {
                    Label("Program", systemImage: "list.clipboard")
                }
                .tag(1)
            
            ProgressTab(viewModel: viewModel)
                .tabItem {
                    Label("Progress", systemImage: "chart.xyaxis.line")
                }
                .tag(2)
            
            ProfileView(viewModel: viewModel)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(3)
        }
        .tint(.white)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            
            // Classic iOS glassy blur effect for dark mode
            appearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterialDark)
            
            let itemAppearance = UITabBarItemAppearance()
            itemAppearance.selected.iconColor = .white
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
            itemAppearance.normal.iconColor = UIColor(Theme.paleSky).withAlphaComponent(0.5)
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Theme.paleSky).withAlphaComponent(0.5)]
            
            appearance.stackedLayoutAppearance = itemAppearance
            
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}
