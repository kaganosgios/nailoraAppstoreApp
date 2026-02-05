//
//  MainTabView.swift
//  nailApp


import SwiftUI
import Combine

class TabNavigationManager: ObservableObject {
    @Published var selectedTab = 0
    @Published var selectedTemplateForCreation: NailTemplate?
    @Published var shouldSwitchToCreateTab = false
    
    func switchToCreateTab(withTemplate template: NailTemplate? = nil) {
        selectedTemplateForCreation = template
        shouldSwitchToCreateTab = true
        selectedTab = 1
    }
    
    func clearTemplateSelection() {
        selectedTemplateForCreation = nil
        shouldSwitchToCreateTab = false
    }
}

struct MainTabView: View {
    @StateObject private var authService = AuthService.shared
    @StateObject private var tabNavigation = TabNavigationManager()
    
    var body: some View {
        TabView(selection: $tabNavigation.selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            CreateNailView(selectedTemplate: tabNavigation.selectedTemplateForCreation)
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("Create")
                }
                .tag(1)
            
            ColorMatcherView()
                .tabItem {
                    Image(systemName: "paintpalette.fill")
                    Text("Colors")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(.pink)
        .environmentObject(authService)
        .environmentObject(tabNavigation)
    }
}

#Preview {
    MainTabView()
}
