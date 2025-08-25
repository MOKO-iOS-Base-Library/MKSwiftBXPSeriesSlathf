//
//  MKSFBXSSensorConfigModel.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/21.
//

import Foundation
import MKBaseSwiftModule
import MKSwiftBleModule

enum SensorConfigModelError: LocalizedError {
    case readHallSensorState
    case readResetByButton
    case readSensorType
    
    var errorDescription: String? {
        switch self {
        case .readHallSensorState:
            return "Read Hall Error"
        case .readResetByButton:
            return "Read Reset By Button Error"
        case .readSensorType:
            return "Read Sensor Type Error"
        }
    }
}

@MainActor class MKSFBXSSensorConfigModel {
    
    // MARK: - Properties
    var hallStatus: Bool = false
    var resetByButton: Bool = false
    /// 是否支持三轴0:No three-axis sensor    1:Lis2DH/Lis3DH 2:STK8328
    var asix: Int = 0
    /// 是否支持温湿度0:No temperature and humidity sensor   1:SHT30/SHT31   2:SHT40  3:STS40
    var th: Int = 0
    
    func read() async throws {
        do {
            hallStatus = try await MKSFBXSInterface.readHallSensorStatus()
            resetByButton = try await MKSFBXSInterface.readResetDeviceByButtonStatus()
            (asix,th) = try await readSensorType()
        } catch {
            throw error
        }
    }
    
    private func readSensorType() async throws -> (asix: Int, th: Int) {
        do {
            let result = try await MKSFBXSInterface.readSensorType()
            
            return (Int(result.axis)!,Int(result.tempHumidity)!)
        } catch {
            throw error
        }
    }
}
