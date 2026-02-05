//
//  DeviceManager.swift
//  nailApp


import Foundation
import UIKit
import Combine

class DeviceManager {
    static let shared = DeviceManager()
    
    private let deviceIdKey = "device_id"
    private let guestCreditsKey = "guest_credits"
    private let freeCreditUsedKey = "free_credit_used"
    private let initialCredits = 1
    
    private init() {}
    
    var deviceId: String {
        if let existingId = UserDefaults.standard.string(forKey: deviceIdKey) {
            return existingId
        }
        
        let newId = generateDeviceId()
        UserDefaults.standard.set(newId, forKey: deviceIdKey)
        UserDefaults.standard.set(initialCredits, forKey: "\(guestCreditsKey)_\(newId)")
        return newId
    }
    
    private func generateDeviceId() -> String {
        let uuid = UUID().uuidString
        let timestamp = Int(Date().timeIntervalSince1970)
        return "device_\(timestamp)_\(uuid.prefix(8))"
    }
    
    var guestCredits: Int {
        get {
            return UserDefaults.standard.integer(forKey: "\(guestCreditsKey)_\(deviceId)")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "\(guestCreditsKey)_\(deviceId)")
        }
    }
    
    func deductGuestCredits(_ amount: Int) -> Bool {
        let currentCredits = guestCredits
        guard currentCredits >= amount else { return false }
        guestCredits = currentCredits - amount
        return true
    }
    
    func addGuestCredits(_ amount: Int) {
        guestCredits += amount
    }
    
    func resetGuestCredits() {
        guestCredits = initialCredits
    }
    
    func resetGuestCreditsToZero() {
        guestCredits = 0
    }
    
   
    func hasUsedFreeCredit() -> Bool {
        return UserDefaults.standard.bool(forKey: "\(freeCreditUsedKey)_\(deviceId)")
    }
    

    func markFreeCreditAsUsed() {
        UserDefaults.standard.set(true, forKey: "\(freeCreditUsedKey)_\(deviceId)")
    }
    
    func getFreeCreditsForNewUser() -> Int {
        if hasUsedFreeCredit() {
            return 0
        } else {
            return 1
        }
    }
}
