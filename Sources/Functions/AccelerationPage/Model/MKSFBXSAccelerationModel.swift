//
//  MKSFBXSAccelerationModel.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/5.
//

import Foundation
import MKBaseSwiftModule
import MKSwiftBleModule

enum AccelerationModelError: LocalizedError {
    case readTriggerParams
    case readTriggerCount
    case configTriggerParams
    
    var errorDescription: String? {
        switch self {
        case .readTriggerParams:
            return "Read Trigger Params Error"
        case .readTriggerCount:
            return "Read Motion trigger count Error"
        case .configTriggerParams:
            return "Config Trigger Params Error"
        }
    }
}

@MainActor class MKSFBXSAccelerationModel {
    
    /// 0:1hz,1:10hz,2:25hz,3:50hz,4:100hz
    var samplingRate: Int = 0
    
    /// 0:±2g,1:±4g,2:±8g,3:±16g
    var scale: Int = 0
    var threshold: String = "0"
    var triggerCount: String = "0"
    
    func read() async throws {
        do {
            triggerCount = try await readTriggerCount()
            (scale,samplingRate,threshold) = try await readTriggerParams()
        } catch {
            throw error
        }
    }
    
    func config() async throws {
        do {
            _ = try await configTriggerParams()
        } catch {
            throw error
        }
    }
    
    private func readTriggerParams() async throws -> (scale: Int, samplingRate: Int, threshold: String) {
        do {
            let result = try await MKSFBXSInterface.readThreeAxisDataParams()
            
            return (result.gravityReference,result.samplingRate,String(result.motionThreshold))
        } catch {
            throw error
        }
    }
    
    private func configTriggerParams() async throws -> Bool {
        do {
            let result = try await MKSFBXSInterface.configThreeAxisDataParams(dataRate: MKSFBXSThreeAxisDataRate(rawValue: self.samplingRate) ?? .rate1hz, acceleration: MKSFBXSThreeAxisDataAG(rawValue: self.scale) ?? .ag0, motionThreshold: Int(self.threshold)!)
            if !result {
                throw AccelerationModelError.configTriggerParams
            }
            return result
        }catch {
            throw error
        }
    }
    
    private func readTriggerCount() async throws -> String {
        do {
            return try await MKSFBXSInterface.readMotionTriggerCount()
        }catch {
            throw error
        }
    }
}
