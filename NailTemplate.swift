//
//  NailTemplate.swift
//  nailApp


import Foundation
import Combine

struct NailTemplate: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let previewImageURL: String
    let category: TemplateCategory
    let isPublic: Bool
    let createdAt: Date
    
    init(id: String, name: String, previewImageURL: String, category: TemplateCategory, isPublic: Bool = true) {
        self.id = id
        self.name = name
        self.previewImageURL = previewImageURL
        self.category = category
        self.isPublic = isPublic
        self.createdAt = Date()
    }
}

enum TemplateCategory: String, Codable, CaseIterable, Hashable {
    case all = "All"
    case classic = "Classic"
    case french = "French"
    case gel = "Gel"
    case acrylic = "Acrylic"
    case art = "Nail Art"
    case minimalist = "Minimalist"
    case glitter = "Glitter"
    case ombre = "Ombre"
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .classic: return "hand.raised"
        case .french: return "sparkles"
        case .gel: return "drop.fill"
        case .acrylic: return "cube.fill"
        case .art: return "paintbrush.fill"
        case .minimalist: return "minus"
        case .glitter: return "star.fill"
        case .ombre: return "gradient"
        }
    }
}

struct GeneratedImage: Codable, Identifiable {
    let id: String
    let userId: String
    let originalTemplateId: String?
    let templateName: String?
    let generatedImageURL: String
    let mode: GenerationMode
    let createdAt: Date
    let creditsUsed: Int
    let colorBrandRecommendations: [ColorBrandMatch]?
}

enum GenerationMode: String, Codable {
    case baseTransformation = "base"
    case advancedTransformation = "advanced"
    
    var displayName: String {
        switch self {
        case .baseTransformation:
            return "Base"
        case .advancedTransformation:
            return "Advanced"
        }
    }
    
    var description: String {
        switch self {
        case .baseTransformation:
            return "Standard nail design transformation"
        case .advancedTransformation:
            return "Enhanced transformation with detailed styling"
        }
    }
    
    var creditCost: Int {
        switch self {
        case .baseTransformation:
            return 1
        case .advancedTransformation:
            return 2
        }
    }
    
    var geminiModel: String {
        switch self {
        case .baseTransformation:
            return APIKeys.GeminiModel.baseTransformation
        case .advancedTransformation:
            return APIKeys.GeminiModel.advancedTransformation
        }
    }
}
