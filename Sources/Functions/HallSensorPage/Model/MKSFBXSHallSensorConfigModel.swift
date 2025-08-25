//
//  MKSFBXSHallSensorConfigModel.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/19.
//

import Foundation
import MKBaseSwiftModule

enum HallSensorConfigModelError: LocalizedError {
    case readMotionTriggerCount
    
    var errorDescription: String? {
        switch self {
        case .readMotionTriggerCount:
            return "Read Motion trigger count Error"
        }
    }
}

@MainActor class MKSFBXSHallSensorConfigModel {
    
    var count: String = "0"
    
    func read() async throws {
        do {
            self.count = try await MKSFBXSInterface.readHallTriggerCount()
        } catch {
            throw error
        }
    }
}
