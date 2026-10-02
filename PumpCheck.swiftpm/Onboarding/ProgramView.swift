import SwiftUI

struct ProgramView: View {
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {
        ZStack {
            Theme.bgGradient.ignoresSafeArea()
            
            VStack {
                Text("Program")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                
                Spacer()
                
                Text("Program feature coming soon")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
                
                Spacer()
            }
        }
    }
}
