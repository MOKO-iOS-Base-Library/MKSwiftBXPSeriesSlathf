//
//  MKSFBXSSlotModel.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/25.
//

import Foundation
import MKBaseSwiftModule

enum MKSFBXSSlotModelError: LocalizedError {
    case readSlotType
    
    var errorDescription: String? {
        switch self {
        case .readSlotType:
            return "Read Slot Type Error"
        }
    }
}

class MKSFBXSSlotModel {
    // MARK: - Properties
    var slot1: String = ""
    var slot2: String = ""
    var slot3: String = ""
    
    func read() async throws {
        do {
            (slot1,slot2,slot3) = try await readSlotType()
        } catch {
            throw error
        }
    }
    
    private func readSlotType() async throws -> (String,String,String) {
        do {
            let slotList = try await MKSFBXSInterface.readSlotType()
            
            return (fetchSlotType(slotList[0]),fetchSlotType(slotList[1]),fetchSlotType(slotList[2]))
        }catch {
            throw error
        }
    }
    
    private func fetchSlotType(_ type: String) -> String {
        switch type {
        case "00": return "UID"
        case "10": return "URL"
        case "20": return "TLM"
        case "50": return "iBeacon"
        case "70": return "T&H_INFOR"
        case "80": return "Sensor info"
        case "ff": return "No data"
        default: return ""
        }
    }
}
