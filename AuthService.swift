//
//  AuthService.swift
//  nailApp


import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let deviceManager = DeviceManager.shared
    
    private init() {
        Task {
            await checkAuthStatus()
        }
    }
    
    func checkAuthStatus() async {
        if let firebaseUser = Auth.auth().currentUser {
            await fetchUser(userId: firebaseUser.uid)
        } else {
            await createGuestUser()
        }
    }
    
    private func createGuestUser() async {
        do {
            let result = try await Auth.auth().signInAnonymously()
            let deviceId = deviceManager.deviceId
            let guestCredits = deviceManager.guestCredits
            
            let guestUser = User(
                id: result.user.uid, // Use Firebase UID instead of deviceId
                credits: guestCredits,
                isGuest: true,
                deviceId: deviceId
            )
            
            try db.collection("users").document(guestUser.id).setData(from: guestUser)
            
            self.currentUser = guestUser
            self.isAuthenticated = true // Now authenticated via Firebase Auth
        } catch {
            print("Error creating anonymous user: \(error)")
            let deviceId = deviceManager.deviceId
            let guestCredits = deviceManager.guestCredits
            
            let guestUser = User(
                id: deviceId,
                credits: guestCredits,
                isGuest: true,
                deviceId: deviceId
            )
            
            self.currentUser = guestUser
            self.isAuthenticated = false
        }
    }
    
    private func fetchUser(userId: String) async {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if let user = try? document.data(as: User.self) {
                self.currentUser = user
                self.isAuthenticated = !user.isGuest
            } else {
                await createGuestUser()
            }
        } catch {
            self.errorMessage = error.localizedDescription
            await createGuestUser()
        }
    }
    
    func signUp(email: String, password: String, displayName: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let deviceId = deviceManager.deviceId
            
            let hasUsedFreeCredit = deviceManager.hasUsedFreeCredit()
            
            let guestCredits = deviceManager.guestCredits
            
            
            let initialCredits: Int
            if hasUsedFreeCredit {
                initialCredits = 0
            } else {
                initialCredits = guestCredits
            }
            
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            
            var newUser = User(from: result.user, credits: initialCredits, deviceId: deviceId)
            newUser.isGuest = false
            newUser.displayName = displayName
            
            try db.collection("users").document(newUser.id).setData(from: newUser)
            
            if !hasUsedFreeCredit {
                deviceManager.markFreeCreditAsUsed()
                deviceManager.resetGuestCreditsToZero()
            }
            
            self.currentUser = newUser
            self.isAuthenticated = true
            
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            
            let deviceId = deviceManager.deviceId
            
            let userDoc = try await db.collection("users").document(result.user.uid).getDocument()
            
            if var existingUser = try? userDoc.data(as: User.self) {
                existingUser.deviceId = deviceId
                
                try db.collection("users").document(existingUser.id).setData(from: existingUser)
                
                self.currentUser = existingUser
                self.isAuthenticated = true
            } else {
                let hasUsedFreeCredit = deviceManager.hasUsedFreeCredit()
                let initialCredits = deviceManager.getFreeCreditsForNewUser()
                
                var newUser = User(from: result.user, credits: initialCredits, deviceId: deviceId)
                newUser.isGuest = false
                
                try db.collection("users").document(newUser.id).setData(from: newUser)
                
                if !hasUsedFreeCredit {
                    deviceManager.markFreeCreditAsUsed()
                }
                
                self.currentUser = newUser
                self.isAuthenticated = true
            }
            
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signOut() async throws {
        do {
            try Auth.auth().signOut()
            await createGuestUser()
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func updateUserCredits(_ credits: Int) async throws {
        guard let user = currentUser else { return }
        
        if user.isGuest {
            deviceManager.guestCredits = credits
            var updatedUser = user
            updatedUser.credits = credits
            self.currentUser = updatedUser
        } else {
            try await db.collection("users").document(user.id).updateData([
                "credits": credits
            ])
            var updatedUser = user
            updatedUser.credits = credits
            self.currentUser = updatedUser
        }
    }
    
    func deductCredits(_ amount: Int) -> Bool {
        guard let user = currentUser else { return false }
        
        if user.credits >= amount {
            let newCredits = user.credits - amount
            Task {
                try? await updateUserCredits(newCredits)
            }
            return true
        }
        return false
    }
    
    func addCredits(_ amount: Int) {
        guard let user = currentUser else { return }
        let newCredits = user.credits + amount
        Task {
            try? await updateUserCredits(newCredits)
        }
    }
    
    func deleteAccount() async throws {
        guard let user = currentUser, !user.isGuest else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot delete guest account"])
        }
        
        guard let firebaseUser = Auth.auth().currentUser else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }
        
        try await db.collection("users").document(user.id).delete()
        
        let generationsSnapshot = try await db.collection("users").document(user.id).collection("generations").getDocuments()
        for document in generationsSnapshot.documents {
            try await document.reference.delete()
        }
        
        let transactionsSnapshot = try await db.collection("users").document(user.id).collection("transactions").getDocuments()
        for document in transactionsSnapshot.documents {
            try await document.reference.delete()
        }
        
        try await firebaseUser.delete()
        
        await createGuestUser()
    }
}
