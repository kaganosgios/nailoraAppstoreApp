//
//  FirebaseService.swift
//  nailApp


import Foundation
import FirebaseFirestore
import FirebaseStorage
import UIKit
import Combine

@MainActor
class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    @Published var templates: [NailTemplate] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    
    func fetchTemplates(category: TemplateCategory = .all) async {
        let hasCachedData = !templates.isEmpty
        if !hasCachedData {
            isLoading = true
        }
        defer { isLoading = false }
        
        do {
            var query: Query = db.collection("templates")
            
            if category != .all {
                query = query.whereField("category", isEqualTo: category.rawValue)
            }
            
            let snapshot = try await query.getDocuments()
            
            var firestoreTemplates: [NailTemplate] = snapshot.documents.compactMap { document in
                try? document.data(as: NailTemplate.self)
            }
            
            if firestoreTemplates.isEmpty {
                firestoreTemplates = await fetchTemplatesFromStorage()
            }
            
            self.templates = firestoreTemplates
            
        } catch {
            self.errorMessage = error.localizedDescription
            self.templates = await fetchTemplatesFromStorage()
        }
    }
    
    func fetchTemplatesFromStorage() async -> [NailTemplate] {
        let possiblePaths = [
            "templates/public",
            "templates",
            "public/templates",
            ""
        ]
        
        for path in possiblePaths {
            let storageRef = path.isEmpty ? storage.reference() : storage.reference().child(path)
            
            do {
                let result = try await storageRef.listAll()
                
                var templates: [NailTemplate] = []
                
                for (index, item) in result.items.enumerated() {
                    let lowercasedName = item.name.lowercased()
                    guard lowercasedName.hasSuffix(".png") || 
                          lowercasedName.hasSuffix(".jpg") || 
                          lowercasedName.hasSuffix(".jpeg") else {
                        continue
                    }
                    
                    do {
                        let downloadURL = try await item.downloadURL()
                        let name = item.name.replacingOccurrences(of: ".png", with: "")
                                             .replacingOccurrences(of: ".jpg", with: "")
                                             .replacingOccurrences(of: ".jpeg", with: "")
                                             .replacingOccurrences(of: "_", with: " ")
                                             .capitalized
                        
                        let template = NailTemplate(
                            id: "template_\(index + 1)",
                            name: name.isEmpty ? "Template \(index + 1)" : name,
                            previewImageURL: downloadURL.absoluteString,
                            category: .all,
                            isPublic: true
                        )
                        templates.append(template)
                    } catch {
                        print("Failed to get download URL for \(item.name): \(error)")
                    }
                }
                
                for prefix in result.prefixes {
                    do {
                        let subResult = try await prefix.listAll()
                        for (index, item) in subResult.items.enumerated() {
                            let lowercasedName = item.name.lowercased()
                            guard lowercasedName.hasSuffix(".png") || 
                                  lowercasedName.hasSuffix(".jpg") || 
                                  lowercasedName.hasSuffix(".jpeg") else {
                                continue
                            }
                            
                            do {
                                let downloadURL = try await item.downloadURL()
                                let name = item.name.replacingOccurrences(of: ".png", with: "")
                                                     .replacingOccurrences(of: ".jpg", with: "")
                                                     .replacingOccurrences(of: ".jpeg", with: "")
                                                     .replacingOccurrences(of: "_", with: " ")
                                                     .capitalized
                                
                                let template = NailTemplate(
                                    id: "template_\(prefix.name)_\(index + 1)",
                                    name: name.isEmpty ? "Template \(index + 1)" : name,
                                    previewImageURL: downloadURL.absoluteString,
                                    category: .all,
                                    isPublic: true
                                )
                                templates.append(template)
                            } catch {
                                print("Failed to get download URL for \(item.name): \(error)")
                            }
                        }
                    } catch {
                        print("Failed to list prefix \(prefix.name): \(error)")
                    }
                }
                
                if !templates.isEmpty {
                    return templates
                }
                
            } catch {
                print("Failed to fetch from path '\(path)': \(error.localizedDescription)")
                continue
            }
        }
        
        self.errorMessage = "No templates found in any storage location"
        return []
    }
    
    
    func uploadUserImage(_ image: UIImage, userId: String, fileName: String? = nil) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let name = fileName ?? "\(UUID().uuidString).jpg"
        let storageRef = storage.reference().child("users/\(userId)/generations/\(name)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    func uploadNailPhoto(_ image: UIImage, userId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            throw NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let name = "nail_photo_\(UUID().uuidString).jpg"
        let storageRef = storage.reference().child("users/\(userId)/uploads/\(name)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    func uploadCustomTemplate(_ image: UIImage, userId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            throw NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let name = "custom_template_\(UUID().uuidString).jpg"
        let storageRef = storage.reference().child("users/\(userId)/templates/\(name)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    
    func saveGeneratedImage(_ generatedImage: GeneratedImage) async throws {
        try db.collection("users").document(generatedImage.userId)
            .collection("generations").document(generatedImage.id)
            .setData(from: generatedImage)
    }
    
    func fetchUserGenerations(userId: String) async throws -> [GeneratedImage] {
        let snapshot = try await db.collection("users").document(userId)
            .collection("generations")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: GeneratedImage.self)
        }
    }
    
    func fetchUserGenerationHistory(userId: String) async throws -> [GeneratedImage] {
        let snapshot = try await db.collection("users").document(userId)
            .collection("generations")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: GeneratedImage.self)
        }
    }
    
    func deleteGeneratedImage(_ generation: GeneratedImage) async throws {
        if let imageURL = URL(string: generation.generatedImageURL) {
            let storageRef = storage.reference(forURL: generation.generatedImageURL)
            try? await storageRef.delete()
        }
        
        try await db.collection("users").document(generation.userId)
            .collection("generations").document(generation.id)
            .delete()
    }
    
    // MARK: - Credit Transactions
    
    func recordCreditTransaction(_ transaction: CreditTransaction) async throws {
        try db.collection("users").document(transaction.userId)
            .collection("transactions").document(transaction.id)
            .setData(from: transaction)
    }
    
    func fetchCreditTransactions(userId: String) async throws -> [CreditTransaction] {
        let snapshot = try await db.collection("users").document(userId)
            .collection("transactions")
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: CreditTransaction.self)
        }
    }
    
    
    func recordPurchase(_ purchase: PurchaseTransaction) async throws {
        try db.collection("purchases")
            .document(purchase.id)
            .setData(from: purchase)
    }
}

