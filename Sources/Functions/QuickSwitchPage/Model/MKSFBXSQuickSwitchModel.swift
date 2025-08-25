//
//  MKSFBXSQuickSwitchModel.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/19.
//

import Foundation
import MKBaseSwiftModule

enum QuickSwitchModelError: LocalizedError {
    case readConnectable
    case readTriggerLEDIndicator
    case readPasswordVerification
    case readTagIDFill
    case readResetByButton
    case readPowerOffByButton
    
    var errorDescription: String? {
        switch self {
        case .readConnectable:
            return "Read Connectable Error"
        case .readTriggerLEDIndicator:
            return "Read Trigger LED indicator Error"
        case .readPasswordVerification:
            return "Read Password verification Error"
        case .readTagIDFill:
            return "Read Tag ID Autofill Error"
        case .readResetByButton:
            return "Read Reset Beacon by button Error"
        case .readPowerOffByButton:
            return "Read Turn off Beacon by button Error"
        }
    }
}

@MainActor class MKSFBXSQuickSwitchModel {
    var connectable: Bool = false
    var trigger: Bool = false
    var passwordVerification: Bool = false
    var autoFill: Bool = false
    var resetByButton: Bool = false
    var turnOffByButton: Bool = false
    var direction: Bool = false
    
    func read() async throws {
        do {
            connectable = try await MKSFBXSInterface.readConnectable()
            trigger = try await MKSFBXSInterface.readTriggerLEDIndicatorStatus()
            passwordVerification = try await MKSFBXSInterface.readPasswordVerification()
            autoFill = try await MKSFBXSInterface.readTagIDAutofillStatus()
            resetByButton = try await MKSFBXSInterface.readResetDeviceByButtonStatus()
            turnOffByButton = try await MKSFBXSInterface.readHallSensorStatus()
        } catch {
            throw error
        }
    }
}
