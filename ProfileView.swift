//
//  ProfileView.swift
//  nailApp
//
//  Created by Assistant on 29.01.2026.
//

import SwiftUI
import Combine

enum ProfileNavigationDestination: Hashable {
    case buyCredits
    case settings
    case generationHistory
}

struct ProfileView: View {
    @StateObject private var authService = AuthService.shared
    @StateObject private var storeKitService = StoreKitService.shared
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 24) {
                    if let user = authService.currentUser {
                        ProfileHeaderView(user: user)
                        
                        CreditsCardView(
                            credits: user.credits,
                            onBuyCredits: { navigationPath.append(ProfileNavigationDestination.buyCredits) }
                        )
                        
                        MenuSectionView(
                            isGuest: user.isGuest,
                            navigationPath: $navigationPath
                        )
                        
                        if !user.isGuest {
                            Button(action: logout) {
                                HStack {
                                    Image(systemName: "arrow.right.square")
                                    Text("Logout")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding(.top, 100)
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .navigationDestination(for: ProfileNavigationDestination.self) { destination in
                switch destination {
                case .buyCredits:
                    BuyCreditsView1()
                case .settings:
                    SettingsView()
                case .generationHistory:
                    GenerationHistoryView()
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func logout() {
        Task {
            do {
                try await authService.signOut()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

struct ProfileHeaderView: View {
    let user: User
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.pink, .pink.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Text(initials)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text(displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let email = user.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                if user.isGuest {
                    Text("Guest User")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
    }
    
    private var displayName: String {
        if let name = user.displayName, !name.isEmpty {
            return name
        }
        return user.isGuest ? "Guest" : "User"
    }
    
    private var initials: String {
        if let name = user.displayName, !name.isEmpty {
            return String(name.prefix(1)).uppercased()
        }
        return user.isGuest ? "G" : "U"
    }
}

struct CreditsCardView: View {
    let credits: Int
    let onBuyCredits: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Available Credits")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("\(credits)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.pink)
                }
                
                Spacer()
                
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.pink.opacity(0.3))
            }
            
            Button(action: onBuyCredits) {
                HStack {
                    Image(systemName: "cart.fill")
                    Text("Buy Credits")
                        .fontWeight(.semibold)
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
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
}

struct MenuSectionView: View {
    let isGuest: Bool
    @Binding var navigationPath: NavigationPath
    @State private var showSupportSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            if isGuest {
                NavigationLink(destination: AuthView().navigationBarBackButtonHidden(true)) {
                    HStack(spacing: 16) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 22))
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        
                        Text("Login / Register")
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                }
                
                Divider()
                    .padding(.leading, 56)
            }
            
            MenuButton(
                icon: "clock.arrow.circlepath",
                title: "Generation History",
                color: .pink
            ) {
                navigationPath.append(ProfileNavigationDestination.generationHistory)
            }
            
            MenuButton(
                icon: "gearshape.fill",
                title: "Settings",
                color: .gray
            ) {
                navigationPath.append(ProfileNavigationDestination.settings)
            }
            
            MenuButton(
                icon: "questionmark.circle.fill",
                title: "Help & Support",
                color: .green
            ) {
                showSupportSheet = true
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
        .sheet(isPresented: $showSupportSheet) {
            SafariWebView(url: URL(string: "https://www.notion.so/Support-Nailora-2f9ee2f85c31805bbe89f3138287a6be")!)
        }
    }
}

struct MenuButton: View {
    let icon: String
    let title: String
    let color: Color
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
        }
        
        Divider()
            .padding(.leading, 56)
    }
}

struct BuyCreditsView1: View {
    @StateObject private var storeKitService = StoreKitService.shared
    @Environment(\.dismiss) var dismiss
    @State private var showSuccess = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var selectedPack: CreditPack? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.pink.opacity(0.1))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.pink)
                    }
                    
                    Text("Buy Credits")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Choose a credit pack to continue generating beautiful nail designs")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top)
                
                if storeKitService.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding(.vertical, 40)
                } else {
                    VStack(spacing: 16) {
                        ForEach(storeKitService.creditPacks) { pack in
                            CreditPackSelectionCard(
                                pack: pack,
                                isSelected: selectedPack?.id == pack.id
                            ) {
                                withAnimation(.springAnimation()) {
                                    selectedPack = pack
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Button(action: {
                    Task {
                        let packToPurchase = selectedPack ?? storeKitService.creditPacks.first
                        if let pack = packToPurchase {
                            await storeKitService.purchase(pack)
                        }
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "cart.fill")
                            .font(.title3)
                        Text("Buy")
                            .fontWeight(.semibold)
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
                    .shadow(color: .pink.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal)
                .disabled(storeKitService.creditPacks.isEmpty)
                .opacity(storeKitService.creditPacks.isEmpty ? 0.5 : 1.0)
                
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await storeKitService.restorePurchases()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle")
                                .foregroundColor(.pink)
                            Text("Restore Purchases")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.pink.opacity(0.05))
                        .cornerRadius(12)
                    }
                    
                    Button(action: { showPrivacyPolicy = true }) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundColor(.pink)
                            Text("Privacy Policy")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.pink.opacity(0.05))
                        .cornerRadius(12)
                    }
                    
                    Button(action: { showTermsOfService = true }) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.pink)
                            Text("Terms of Service")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.pink.opacity(0.05))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.pink)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Credits Never Expire")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Your purchased credits have no expiration date. Use them anytime you want to generate beautiful nail designs.")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.pink.opacity(0.05))
                    .cornerRadius(12)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Secure Purchase")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("All transactions are processed securely through Apple. Your payment information is never stored on our servers.")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.green.opacity(0.05))
                    .cornerRadius(12)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Restore Purchases")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Lost your credits? Tap the Restore Purchases button above to recover your previous purchases.")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .navigationTitle("Buy Credits")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Success!", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Credits added to your account successfully!")
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            SafariWebView(url: URL(string: "https://www.notion.so/Privacy-Policy-Nailora-2f9ee2f85c3180afb6b4d9a9ad1376d9")!)
        }
        .sheet(isPresented: $showTermsOfService) {
            SafariWebView(url: URL(string: "https://www.notion.so/Terms-of-Use-Nailora-2f9ee2f85c3180708649ebc863dd9551")!)
        }
        .onChange(of: storeKitService.purchaseSuccess) { _, success in
            if success {
                showSuccess = true
                storeKitService.purchaseSuccess = false
            }
        }
        .alert("Error", isPresented: .constant(storeKitService.errorMessage != nil)) {
            Button("OK") {
                storeKitService.errorMessage = nil
            }
        } message: {
            Text(storeKitService.errorMessage ?? "")
        }
    }
    
    private var privacyPolicyContent: String {
        """
        Privacy Policy
        
        
        """
    }
    
    private var termsOfServiceContent: String {
        """
        Terms of Service
        
        
        """
    }
}

struct LegalDocumentView: View {
    let title: String
    let content: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(content)
                    .font(.body)
                    .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CreditPackSelectionCard: View {
    let pack: CreditPack
    let isSelected: Bool
    let action: () -> Void
    
    var labelColor: Color {
        switch pack.labelColor {
        case "blue": return .blue
        case "orange": return .orange
        case "green": return .green
        default: return .pink
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.pink : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.pink)
                            .frame(width: 14, height: 14)
                    }
                }
                
              
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(pack.name)
                            .font(.headline)
                        
                        // Label Badge
                        if let label = pack.label {
                            Text(label)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(labelColor.opacity(0.15))
                                .foregroundColor(labelColor)
                                .cornerRadius(8)
                        }
                    }
                    
                    Text("\(pack.credits) credits")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if let price = pack.price {
                    Text(price)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .pink : .primary)
                } else {
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: isSelected ? .pink.opacity(0.2) : .black.opacity(0.05), radius: isSelected ? 8 : 5, x: 0, y: isSelected ? 4 : 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.pink.opacity(0.5) : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CreditPackCard: View {
    let pack: CreditPack
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
              
              
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(pack.name)
                        .font(.headline)
                    
                    Text("\(pack.credits) credits")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if let price = pack.price {
                    Text(price)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.pink)
                } else {
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("highQualityGeneration") private var highQualityGeneration = true
    @StateObject private var authService = AuthService.shared
    @State private var showDeleteAccountAlert = false
    @State private var showDeleteConfirmation = false
    @State private var deleteErrorMessage: String?
    @State private var showDeleteError = false
    
    var body: some View {
        List {
            Section("Preferences") {
                Toggle("High Quality Generation", isOn: $highQualityGeneration)
            }
            
            Section("Legal") {
                Link(destination: URL(string: "https://www.notion.so/Privacy-Policy-Nailora-2f9ee2f85c3180afb6b4d9a9ad1376d9")!) {
                    HStack {
                        Image(systemName: "lock.shield")
                            .foregroundColor(.blue)
                        Text("Privacy Policy")
                            .foregroundColor(.blue)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.blue.opacity(0.6))
                    }
                }
                
                Link(destination: URL(string: "https://www.notion.so/Terms-of-Use-Nailora-2f9ee2f85c3180708649ebc863dd9551")!) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.green)
                        Text("Terms of Use")
                            .foregroundColor(.green)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.green.opacity(0.6))
                    }
                }
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("Build")
                    Spacer()
                    Text("2026.01.29")
                        .foregroundColor(.gray)
                }
            }
            
            if let user = authService.currentUser, !user.isGuest {
                Section("Danger Zone") {
                    Button(action: { showDeleteAccountAlert = true }) {
                        HStack {
                            Image(systemName: "trash.circle.fill")
                                .foregroundColor(.red)
                            Text("Delete Account")
                                .foregroundColor(.red)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Continue", role: .destructive) {
                showDeleteConfirmation = true
            }
        } message: {
            Text("This action cannot be undone. All your data including generation history will be permanently deleted.")
        }
        .alert("Confirm Deletion", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete My Account", role: .destructive) {
                Task {
                    await deleteAccount()
                }
            }
        } message: {
            Text("Are you absolutely sure? This will permanently delete your account and all associated data.")
        }
        .alert("Error", isPresented: $showDeleteError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(deleteErrorMessage ?? "An error occurred while deleting your account.")
        }
    }
    
    private func deleteAccount() async {
        do {
            try await authService.deleteAccount()
        } catch {
            deleteErrorMessage = error.localizedDescription
            showDeleteError = true
        }
    }
}

#Preview {
    ProfileView()
}

import SafariServices
import SwiftUI

struct SafariWebView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: url)
        safariVC.preferredBarTintColor = .systemBackground
        safariVC.preferredControlTintColor = .systemPink
        return safariVC
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
    }
}
