//
//  User.swift
//  nailApp


import Foundation
import FirebaseAuth
import Combine

struct User: Codable, Identifiable {
    let id: String
    let email: String?
    var displayName: String?
    let createdAt: Date
    var credits: Int
    var isGuest: Bool
    var deviceId: String?
    
    init(id: String, email: String? = nil, displayName: String? = nil, credits: Int = 1, isGuest: Bool = true, deviceId: String? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.createdAt = Date()
        self.credits = credits
        self.isGuest = isGuest
        self.deviceId = deviceId
    }
    
    init(from firebaseUser: FirebaseAuth.User, credits: Int = 1, deviceId: String? = nil) {
        self.id = firebaseUser.uid
        self.email = firebaseUser.email
        self.displayName = firebaseUser.displayName
        self.createdAt = Date()
        self.credits = credits
        self.isGuest = false
        self.deviceId = deviceId
    }
}

struct CreditTransaction: Codable, Identifiable {
    let id: String
    let userId: String
    let amount: Int
    let type: TransactionType
    let description: String
    let timestamp: Date
    
    enum TransactionType: String, Codable {
        case purchase
        case consumption
        case bonus
        case merge
    }
}
