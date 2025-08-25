//
//  MKSFBXSDeviceInfoModel.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/5.
//

import Foundation
import MKBaseSwiftModule

enum DeviceInfoModelError: LocalizedError {
    case readMacAddress
    case readBatteryVoltage
    case readBatteryPercent
    case readDeviceModel
    case readSoftware
    case readHardware
    case readFirmware
    case readManu
    case readManuDate
    
    var errorDescription: String? {
        switch self {
        case .readMacAddress:
            return "Read Mac Address Error"
        case .readBatteryVoltage:
            return "Read Battery Voltage Error"
        case .readBatteryPercent:
            return "Read Battery Percent Error"
        case .readDeviceModel:
            return "Read Device Model Error"
        case .readSoftware:
            return "Read Software Error"
        case .readHardware:
            return "Read Hardware Error"
        case .readFirmware:
            return "Read Firmware Error"
        case .readManu:
            return "Read Manu Error"
        case .readManuDate:
            return "Read Manu Date Error"
        }
    }
}

class MKSFBXSDeviceInfoModel {
    var software: String = ""
    var firmware: String = ""
    var hardware: String = ""
    var voltage: String = ""
    var batteryPercent: String = ""
    var macAddress: String = ""
    var productMode: String = ""
    var manu: String = ""
    var manuDate: String = ""
    
    func read() async throws {
        do {
            macAddress = try await MKSFBXSInterface.readMacAddress()
            voltage = try await MKSFBXSInterface.readBatteryVoltage()
            batteryPercent = try await MKSFBXSInterface.readBatteryPercentage()
            productMode = try await MKSFBXSInterface.readDeviceModel()
            software = try await MKSFBXSInterface.readSoftware()
            firmware = try await MKSFBXSInterface.readFirmware()
            hardware = try await MKSFBXSInterface.readHardware()
            manu = try await MKSFBXSInterface.readManufacturer()
            manuDate = try await MKSFBXSInterface.readProductionDate()
        } catch {
            throw error
        }
    }
}
