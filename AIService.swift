//
//  AIService.swift
//  nailApp

import Foundation
import UIKit
import SwiftUI
import Combine
import FirebaseFunctions

enum GenerationServiceError: Error, LocalizedError {
    case invalidImage
    case generationFailed
    case insufficientCredits
    case networkError
    case invalidResponse
    case apiKeyMissing
    case apiError(String)
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image provided"
        case .generationFailed:
            return "Design generation failed"
        case .insufficientCredits:
            return "Insufficient credits"
        case .networkError:
            return "Network error occurred"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiKeyMissing:
            return "API key not configured"
        case .apiError(let message):
            return "API Error: \(message)"
        case .notAuthenticated:
            return "Please sign in to use this feature"
        }
    }
}

struct ColorBrandMatch: Identifiable, Codable {
    let id = UUID()
    let brand: String
    let collection: String
    let shadeName: String
    let priceRange: String
    let hexCode: String
    let description: String
}

struct ColorBrandMatchResponse: Codable {
    let matches: [ColorBrandMatch]
}

@MainActor
class GenerationService: ObservableObject {
    static let shared = GenerationService()
    
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0
    
    private let functions = Functions.functions()
    
    private init() {}
    
    // MARK: - Generate Nail Design (Firebase Function)
    
    func generateNailDesign(
        nailPhoto: UIImage,
        templateImage: UIImage,
        mode: GenerationMode
    ) async throws -> UIImage {
        
        isGenerating = true
        generationProgress = 0
        
        defer {
            isGenerating = false
            generationProgress = 1.0
        }
        
        guard let nailData = nailPhoto.jpegData(compressionQuality: 0.9),
              let templateData = templateImage.jpegData(compressionQuality: 0.9) else {
            throw GenerationServiceError.invalidImage
        }
        
        let nailBase64 = nailData.base64EncodedString()
        let templateBase64 = templateData.base64EncodedString()
        
        updateProgress(0.2)
        
        let data: [String: Any] = [
            "nailImageBase64": nailBase64,
            "templateImageBase64": templateBase64,
            "mode": mode.rawValue,
            "requestId": UUID().uuidString
        ]
        
        do {
            updateProgress(0.4)
            
            let result = try await functions.httpsCallable("generateNailDesign").call(data)
            
            updateProgress(0.8)
            
            guard let response = result.data as? [String: Any] else {
                print("❌ Response is not a dictionary")
                throw GenerationServiceError.invalidResponse
            }
            
            print("📥 Response keys: \(response.keys)")
            
            // Check for both possible response keys
            let imageBase64 = response["imageBase64"] as? String ?? response["generatedImageBase64"] as? String
            
            guard let base64String = imageBase64 else {
                print("❌ No imageBase64 or generatedImageBase64 in response")
                throw GenerationServiceError.invalidResponse
            }
            
            guard let imageData = Data(base64Encoded: base64String) else {
                print("❌ Failed to decode base64 string")
                throw GenerationServiceError.invalidResponse
            }
            
            guard let image = UIImage(data: imageData) else {
                print("❌ Failed to create UIImage from data")
                throw GenerationServiceError.invalidResponse
            }
            
            updateProgress(1.0)
            return image
            
        } catch let error as NSError {
            print("Firebase Function Error: \(error.localizedDescription)")
            if let message = error.userInfo["message"] as? String {
                throw GenerationServiceError.apiError(message)
            }
            throw GenerationServiceError.generationFailed
        }
    }
    
    
    func fetchColorBrandRecommendations(colorHex: String) async throws -> [ColorBrandMatch] {
        print("🤖 DEBUG - AIService received colorHex: \(colorHex)")
        
        let data: [String: Any] = [
            "colorHex": colorHex,
            "requestId": UUID().uuidString
        ]
        
        do {
            let result = try await functions.httpsCallable("fetchColorBrandRecommendations").call(data)
            
            guard let response = result.data as? [String: Any],
                  let matchesData = response["matches"] as? [[String: Any]] else {
                throw GenerationServiceError.invalidResponse
            }
            
            var matches: [ColorBrandMatch] = []
            for matchDict in matchesData {
                if let brand = matchDict["brand"] as? String,
                   let shadeName = matchDict["shadeName"] as? String {
                    
                    let collection = matchDict["collection"] as? String ?? "Classic Collection"
                    let priceRange = matchDict["priceRange"] as? String ?? "$10-15"
                    let hexCode = matchDict["hexCode"] as? String ?? colorHex
                    let description = matchDict["description"] as? String ?? ""
                    
                    let match = ColorBrandMatch(
                        brand: brand,
                        collection: collection,
                        shadeName: shadeName,
                        priceRange: priceRange,
                        hexCode: hexCode,
                        description: description
                    )
                    matches.append(match)
                }
            }
            
            print("📤 DEBUG - Parsed AI Response:")
            for (index, match) in matches.enumerated() {
                print("   [\(index + 1)] \(match.brand) - \(match.shadeName)")
                print("       Requested Hex: \(colorHex)")
                print("       Response Hex: \(match.hexCode)")
                print("       Match: \(match.hexCode.uppercased() == colorHex.uppercased() ? "✅" : "❌")")
            }
            
            return matches
            
        } catch let error as NSError {
            print("Firebase Function Error: \(error.localizedDescription)")
            if let message = error.userInfo["message"] as? String {
                throw GenerationServiceError.apiError(message)
            }
            throw GenerationServiceError.generationFailed
        }
    }
    
    
    func applyColorToNailImage(colorHex: String, nailImage: UIImage) async throws -> UIImage {
        isGenerating = true
        generationProgress = 0
        
        defer {
            isGenerating = false
            generationProgress = 1.0
        }
        
        guard let nailData = nailImage.jpegData(compressionQuality: 0.9) else {
            throw GenerationServiceError.invalidImage
        }
        
        let nailBase64 = nailData.base64EncodedString()
        
        updateProgress(0.2)
        
        let data: [String: Any] = [
            "colorHex": colorHex,
            "nailImageBase64": nailBase64,
            "requestId": UUID().uuidString
        ]
        
        do {
            updateProgress(0.4)
            
            let result = try await functions.httpsCallable("applyColorToNailImage").call(data)
            
            updateProgress(0.8)
            
            guard let response = result.data as? [String: Any] else {
                print("❌ Color apply response is not a dictionary")
                throw GenerationServiceError.invalidResponse
            }
            
            print("📥 Color apply response keys: \(response.keys)")
            
            let imageBase64 = response["imageBase64"] as? String ?? response["generatedImageBase64"] as? String
            
            guard let base64String = imageBase64 else {
                print("❌ No imageBase64 or generatedImageBase64 in color apply response")
                throw GenerationServiceError.invalidResponse
            }
            
            guard let imageData = Data(base64Encoded: base64String) else {
                print("❌ Failed to decode base64 string in color apply")
                throw GenerationServiceError.invalidResponse
            }
            
            guard let image = UIImage(data: imageData) else {
                print("❌ Failed to create UIImage from data in color apply")
                throw GenerationServiceError.invalidResponse
            }
            
            updateProgress(1.0)
            return image
            
        } catch let error as NSError {
            print("Firebase Function Error: \(error.localizedDescription)")
            if let message = error.userInfo["message"] as? String {
                throw GenerationServiceError.apiError(message)
            }
            throw GenerationServiceError.generationFailed
        }
    }
     
    private func updateProgress(_ progress: Double) {
        DispatchQueue.main.async {
            self.generationProgress = progress
        }
    }
}

@available(*, deprecated, renamed: "GenerationService")
typealias AIService = GenerationService
