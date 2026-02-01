//
//  OnboardingView.swift
//  nailApp


import SwiftUI

struct OnboardingView: View {
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false
    @State private var currentPage = 0
    @State private var nailFrequency = "Occasionally"
    @State private var showQuestions = false
    
    let frequencyOptions = ["Weekly", "Monthly", "Occasionally", "Rarely"]
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.pink.opacity(0.1), .purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(currentPage == index ? Color.pink : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.top, 20)
                
                TabView(selection: $currentPage) {
                    OnboardingPage(
                        image: "onboarding1",
                        title: "Welcome to Nailora",
                        description: "Discover beautiful nail designs and try them on virtually before your next salon visit."
                    )
                    .tag(0)
                    
                    QuestionsPage(
                        nailFrequency: $nailFrequency,
                        frequencyOptions: frequencyOptions
                    )
                    .tag(1)
                    
                    OnboardingPage(
                        image: "onboarding2",
                        title: "Ready to Transform?",
                        description: "Upload your nail photo, choose a design, and see the magic happen in seconds."
                    )
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                VStack(spacing: 16) {
                    Button(action: handleNext) {
                        HStack {
                            Text(currentPage == 2 ? "Get Started" : "Continue")
                                .fontWeight(.semibold)
                            Image(systemName: currentPage == 2 ? "arrow.right.circle.fill" : "arrow.right")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.pink, .pink.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }
                    
                    if currentPage < 2 {
                        Button(action: skipOnboarding) {
                            Text("Skip")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func handleNext() {
        if currentPage < 2 {
            withAnimation {
                currentPage += 1
            }
        } else {
            completeOnboarding()
        }
    }
    
    private func skipOnboarding() {
        completeOnboarding()
    }
    
    private func completeOnboarding() {
        // testing set  to false to show onboarding
        //  production set to true
        onboardingCompleted = true
        
    }
}

struct OnboardingPage: View {
    let image: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 25) {
            Spacer()
            
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 360)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .pink.opacity(0.2), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 25)
            
            VStack(spacing: 16) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
    }
}

struct QuestionsPage: View {
    @Binding var nailFrequency: String
    let frequencyOptions: [String]
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 80))
                .foregroundColor(.pink)
                .padding()
                .background(
                    Circle()
                        .fill(Color.pink.opacity(0.1))
                        .frame(width: 150, height: 150)
                )
            
            VStack(spacing: 16) {
                Text("Help Us Personalize")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("How often do you get your nails done?")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 12) {
                ForEach(frequencyOptions, id: \.self) { option in
                    Button(action: {
                        withAnimation(.spring()) {
                            nailFrequency = option
                        }
                    }) {
                        HStack {
                            Text(option)
                                .font(.body)
                                .fontWeight(nailFrequency == option ? .semibold : .regular)
                            
                            Spacer()
                            
                            if nailFrequency == option {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.pink)
                            }
                        }
                        .foregroundColor(nailFrequency == option ? .pink : .primary)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(nailFrequency == option ? Color.pink.opacity(0.1) : Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(nailFrequency == option ? Color.pink : Color.gray.opacity(0.2), lineWidth: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
