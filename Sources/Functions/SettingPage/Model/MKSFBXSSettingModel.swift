//
//  MKSFBXSSettingModel.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/25.
//

import Foundation
import MKBaseSwiftModule

enum SettingModelError: LocalizedError {
    case readHallSensorState
    case readSensorType
    case readBatteryADVMode
    case readAdvChannel
    
    var errorDescription: String? {
        switch self {
        case .readHallSensorState:
            return "Read Hall Error"
        case .readSensorType:
            return "Read Sensor Type Error"
        case .readBatteryADVMode:
            return "Config Battery ADV mode Error"
        case .readAdvChannel:
            return "Config ADV Channel Error"
        }
    }
}

class MKSFBXSSettingModel {
    // MARK: - Properties
    /// 霍尔开关机状态
    var hallStatus: Bool = false
    /// 是否支持三轴
    var supportThreeAcc: Bool = false
    /// 是否支持温湿度
    var supportTH: Bool = false
    /// 0:Voltage   1:Percentage
    var batteryAdvMode: Int = 0
    /// 0:CH37&38&39    1:CH37  2:CH38  3:CH39
    var advChannel: Int = 0
    
    func read() async throws {
        do {
            hallStatus = try await MKSFBXSInterface.readHallSensorStatus()
            (supportThreeAcc,supportTH) = try await readSensorType()
            batteryAdvMode = try await readBatteryADVMode()
            advChannel = try await readAdvChannel()
        } catch {
            throw error
        }
    }
    
    private func readSensorType() async throws -> (Bool,Bool) {
        do {
            let result = try await MKSFBXSInterface.readSensorType()
            
            return ((Int(result.axis)! > 0),(Int(result.tempHumidity)! > 0))
        }catch {
            throw error
        }
    }
    
    private func readBatteryADVMode() async throws -> Int {
        do {
            let mode = try await MKSFBXSInterface.readBatteryADVMode()
            
            return (Int(mode)! == 0 ? 1 : 0)
        }catch {
            throw error
        }
    }
    
    private func readAdvChannel() async throws -> Int {
        do {
            let channel = try await MKSFBXSInterface.readADVChannel()
            
            let channelValue = Int(channel)!
            var resultValue = 0
            if channelValue == 7 {
                //CH37&38&39
                resultValue = 0
            } else if channelValue == 1 {
                //CH37
                resultValue = 1
            } else if channelValue == 2 {
                //CH38
                resultValue = 2
            } else if channelValue == 4 {
                //CH39
                resultValue = 3
            }
            return resultValue
        }catch {
            throw error
        }
    }
}
