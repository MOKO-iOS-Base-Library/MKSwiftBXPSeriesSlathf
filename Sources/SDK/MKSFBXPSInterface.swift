//
//  MKSwiftBXPSInterface+Async.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/6/19.
//

import Foundation
import MKSwiftBleModule
import CoreBluetooth

@MainActor public class MKSFBXSInterface {
    
    // MARK: - Custom Methods (Async)
    
    static func readMacAddress() async throws -> String {
        let result = try await readData(taskID: .taskReadMacAddressOperation, cmdFlag: "20")
        
        guard let macAddress = result.value["macAddress"] as? String else {
            throw MKSwiftBleError.paramsError
        }
        
        return macAddress
    }
    
    static func readThreeAxisDataParams() async throws -> (samplingRate: Int, gravityReference: Int, motionThreshold: Int) {
        let result = try await readData(taskID: .taskReadThreeAxisDataParamsOperation, cmdFlag: "21")
        
        guard let samplingRate = result.value["samplingRate"] as? Int,
              let gravityReference = result.value["gravityReference"] as? Int,
              let motionThreshold = result.value["motionThreshold"] as? Int else {
            throw MKSwiftBleError.paramsError
        }
        
        return (samplingRate, gravityReference, motionThreshold)
    }
    
    static func readFirmware() async throws -> String {
        let result = try await readData(taskID: .taskReadFirmwareOperation, cmdFlag: "29")
        
        guard let firmware = result.value["firmware"] as? String else {
            throw MKSwiftBleError.paramsError
        }
        
        return firmware
    }
    
    static func readManufacturer() async throws -> String {
        let result = try await readData(taskID: .taskReadManufacturerOperation, cmdFlag: "2a")
        
        guard let manufacturer = result.value["manufacturer"] as? String else {
            throw MKSwiftBleError.paramsError
        }
        
        return manufacturer
    }
    
    static func readProductionDate() async throws -> String {
        let result = try await readData(taskID: .taskReadProductDateOperation, cmdFlag: "2b")
        
        guard let productionDate = result.value["productionDate"] as? String else {
            throw MKSwiftBleError.paramsError
        }
        
        return productionDate
    }
    
    static func readSoftware() async throws -> String {
        let result = try await readData(taskID: .taskReadSoftwareOperation, cmdFlag: "2c")
        
        guard let software = result.value["software"] as? String else {
            throw MKSwiftBleError.paramsError
        }
        
        return software
    }
    
    static func readHardware() async throws -> String {
        let result = try await readData(taskID: .taskReadHardwareOperation, cmdFlag: "2d")
        
        guard let hardware = result.value["hardware"] as? String else {
            throw MKSwiftBleError.paramsError
        }
        
        return hardware
    }
    
    static func readDeviceModel() async throws -> String {
        let result = try await readData(taskID: .taskReadDeviceModelOperation, cmdFlag: "2e")
        
        guard let modeID = result.value["modeID"] as? String else {
            throw MKSwiftBleError.paramsError
        }
        
        return modeID
    }
    
    static func readConnectable() async throws -> Bool {
        let result = try await readData(taskID: .taskReadConnectableOperation, cmdFlag: "37")
        
        guard let connectable = result.value["connectable"] as? Bool else {
            throw MKSwiftBleError.paramsError
        }
        
        return connectable
    }
    
    static func readTriggeredSlotParams(index: Int) async throws -> MKSwiftBleResult {
        guard index >= 0 && index <= 2 else {
            throw MKSwiftBleError.paramsError
        }
        let indexString = MKSwiftBleSDKAdopter.fetchHexValue(index + 3, byteLen: 1)
        let commandString = "ea002401" + indexString
                
        return try await MKSwiftBXPSCentralManager.shared.addTask(with: .taskReadTriggeredSlotParamsOperation, characteristic: MKSwiftBXPSCentralManager.shared.peripheral()!.bxs_swf_custom, commandData: commandString)
    }
    
    static func readDeviceType() async throws -> [String: Bool] {
        let result = try await readData(taskID: .taskReadDeviceTypeOperation, cmdFlag: "2f")
        
        guard let dic = result.value as? [String: Bool] else {
            throw MKSwiftBleError.paramsError
        }
        
        return dic
    }
    
    static func readSlotAdvType() async throws -> [String] {
        let result = try await readData(taskID: .taskReadSlotAdvTypeOperation, cmdFlag: "6c")
        
        guard let typeList = result.value["typeList"] as? [String] else {
            throw MKSwiftBleError.paramsError
        }
        
        return typeList
    }
    
    static func readHallDataStoreStatus() async throws -> Bool {
        let result = try await readData(taskID: .taskReadHallDataStoreStatusOperation, cmdFlag: "6d")
        
        guard let isOn = result.value["isOn"] as? Bool else {
            throw MKSwiftBleError.paramsError
        }
        
        return isOn
    }
    
    static func readHallHistoryData() async throws -> [[String: Any]] {
        let returnData = try await readData(taskID: .taskReadHallHistoryDataOperation, cmdFlag: "6e")
        
        guard let hexStrings = returnData.value["result"] as? [String] else {
            throw MKSwiftBleError.paramsError
        }
        
        let list = MKSwiftBXPSSDKDataAdopter.parseHallData(hexStrings)
        return list
    }
    
    // MARK: - New Methods (Async)
    
    static func readResetDeviceByButtonStatus() async throws -> Bool {
        let result = try await readData(taskID: .taskReadResetDeviceByButtonStatusOperation, cmdFlag: "23")
        
        guard let isOn = result.value["isOn"] as? Bool else {
            throw MKSwiftBleError.paramsError
        }
        
        return isOn
    }
    
    static func readHallSensorStatus() async throws -> Bool {
        let result = try await readData(taskID: .taskReadHallSensorStatusOperation, cmdFlag: "25")
        
        guard let isOn = result.value["isOn"] as? Bool else {
            throw MKSwiftBleError.paramsError
        }
        
        return isOn
    }
    
    static func readSlotType() async throws -> [String] {
        let result = try await readData(taskID: .taskReadSlotTypeOperation, cmdFlag: "30")

        guard let slotList = result.value["slotList"] as? [String] else {
            throw MKSwiftBleError.paramsError
        }
        
        return slotList
    }
    
    static func readSlotTriggerData(index: Int) async throws -> MKSwiftBleResult {
        guard index >= 0 && index <= 2 else {
            throw MKSwiftBleError.paramsError
        }
        let commandString = "ea003101" + MKSwiftBleSDKAdopter.fetchHexValue(index, byteLen: 1)
                
        return try await MKSwiftBXPSCentralManager.shared.addTask(with: .taskReadSlotTriggerDataOperation, characteristic: MKSwiftBXPSCentralManager.shared.peripheral()!.bxs_swf_custom, commandData: commandString)
    }
    
    static func readBeforeTriggerSlotData(index: Int) async throws -> MKSwiftBleResult {
        guard index >= 0 && index <= 2 else {
            throw MKSwiftBleError.paramsError
        }
        let indexString = MKSwiftBleSDKAdopter.fetchHexValue(index, byteLen: 1)
        let commandString = "ea003201" + indexString
                
        return try await MKSwiftBXPSCentralManager.shared.addTask(with: .taskReadBeforeTriggerSlotDataOperation, characteristic: MKSwiftBXPSCentralManager.shared.peripheral()!.bxs_swf_custom, commandData: commandString)
    }
    
    static func readTriggerSlotData(index: Int) async throws -> MKSwiftBleResult {
        guard index >= 0 && index <= 2 else {
            throw MKSwiftBleError.paramsError
        }
        let indexString = MKSwiftBleSDKAdopter.fetchHexValue(index, byteLen: 1)
        let commandString = "ea003301" + indexString
                
        return try await MKSwiftBXPSCentralManager.shared.addTask(with: .taskReadTriggerSlotDataOperation, characteristic: MKSwiftBXPSCentralManager.shared.peripheral()!.bxs_swf_custom, commandData: commandString)
    }
    
    static func readSlotData(index: Int) async throws -> MKSwiftBleResult {
        guard index >= 0 && index <= 2 else {
            throw MKSwiftBleError.paramsError
        }
        let indexString = MKSwiftBleSDKAdopter.fetchHexValue(index, byteLen: 1)
        let commandString = "ea003401" + indexString
                
        return try await MKSwiftBXPSCentralManager.shared.addTask(with: .taskReadSlotDataOperation, characteristic: MKSwiftBXPSCentralManager.shared.peripheral()!.bxs_swf_custom, commandData: commandString)
    }
    
    static func readADVChannel() async throws -> String {
        let result = try await readData(taskID: .taskReadADVChannelOperation, cmdFlag: "35")
        
        guard let channel = result.value["channel"] as? String else {
            throw MKSwiftBleError.paramsError
        }
        
        return channel
    }
    
    static func readDirectionFindingStatus() async throws -> Bool {
        let result = try await readData(taskID: .taskReadDirectionFindingStatusOperation, cmdFlag: "36")
        
        guard let isOn = result.value["isOn"] as? Bool else {
            throw MKSwiftBleError.paramsError
        }
        
        return isOn
    }
    
    static func readTagIDAutofillStatus() async throws -> Bool {
        let result = try await readData(taskID: .taskTagIDAutofillStatusOperation, cmdFlag: "3c")
        
        guard let isOn = result.value["isOn"] as? Bool else {
            throw MKSwiftBleError.paramsError
        }
        
        return isOn
    }
    
    static func readDeviceRuntime() async throws -> String {
        let result = try await readData(taskID: .taskDeviceRuntimeOperation, cmdFlag: "3e")
        
        guard let time = result.value["time"] as? String else {
            throw MKSwiftBleError.paramsError
        }
        
        return time
    }
    
    static func readDeviceUTCTime() async throws -> String {
        let result = try await readData(taskID: .taskReadDeviceUTCTimeOperation, cmdFlag: "3f")
        
        guard let timestamp = result.value["timestamp"] as? String else {
            throw MKSwiftBleError.paramsError
        }
        
        return timestamp
    }
    
    static func readTHDataStoreParams() async throws -> (isOn: Bool, interval: String) {
        let result = try await readData(taskID: .taskReadTHDataStoreStatusOperation, cmdFlag: "40")
        
        guard let isOn = result.value["isOn"] as? Bool,
              let interval = result.value["interval"] as? String else {
            throw MKSwiftBleError.paramsError
        }
        
        return (isOn, interval)
    }
    
    static func readHTSamplingRate() async throws -> String {
        let result = try await readData(taskID: .taskReadTHSamplingRateOperation, cmdFlag: "41")
        
        guard let samplingRate = result.value["samplingRate"] as? String else {
            throw MKSwiftBleError.paramsError
        }
        
        return samplingRate
    }
    
    static func readHTRecordTotalNumbers() async throws -> String {
        let result = try await readData(taskID: .taskReadHTRecordTotalNumbersOperation, cmdFlag: "43")
        
        guard let count = result.value["count"] as? String else {
            throw MKSwiftBleError.paramsError
        }
        
        return count
    }
    
    static func readSensorType() async throws -> (axis: String, tempHumidity: String, lightSensor: String, pir: String, tof: String) {
        let result = try await readData(taskID: .taskReadSensorTypeOperation, cmdFlag: "4a")
        
        guard let axis = result.value["axis"] as? String,
              let tempHumidity = result.value["tempHumidity"] as? String,
              let lightSensor = result.value["lightSensor"] as? String,
              let pir = result.value["pir"] as? String,
              let tof = result.value["tof"] as? String else {
            throw MKSwiftBleError.paramsError
        }
        
        return (axis, tempHumidity, lightSensor, pir, tof)
    }
    
    static func readRemoteReminderBuzzerFrequency() async throws -> String {
        let result = try await readData(taskID: .taskReadRemoteReminderBuzzerFrequencyOperation, cmdFlag: "63")
        
        guard let frequency = result.value["frequency"] as? String else {
            throw MKSwiftBleError.paramsError
        }
        
        return frequency
    }
    
    static func readTriggerLEDIndicatorStatus() async throws -> Bool {
        let result = try await readData(taskID: .taskReadTriggerLEDIndicatorStatusOperation, cmdFlag: "65")
        
        guard let isOn = result.value["isOn"] as? Bool else {
            throw MKSwiftBleError.paramsError
        }
        
        return isOn
    }
    
    static func readHallTriggerCount() async throws -> String {
        let result = try await readData(taskID: .taskReadHallTriggerCountOperation, cmdFlag: "68")
        
        guard let count = result.value["count"] as? String else {
            throw MKSwiftBleError.paramsError
        }
        
        return count
    }
    
    static func readMotionTriggerCount() async throws -> String {
        let result = try await readData(taskID: .taskReadMotionTriggerCountOperation, cmdFlag: "69")
        
        guard let count = result.value["count"] as? String else {
            throw MKSwiftBleError.paramsError
        }
        
        return count
    }
    
    static func readBatteryVoltage() async throws -> String {
        let result = try await readData(taskID: .taskReadBatteryVoltageOperation, cmdFlag: "6a")
        
        guard let voltage = result.value["voltage"] as? String else {
            throw MKSwiftBleError.paramsError
        }
        
        return voltage
    }
    
    static func readBatteryPercentage() async throws -> String {
        let result = try await readData(taskID: .taskReadBatteryPercentageOperation, cmdFlag: "6b")
        
        guard let percentage = result.value["percentage"] as? String else {
            throw MKSwiftBleError.paramsError
        }
        
        return percentage
    }
    
    static func readBatteryADVMode() async throws -> String {
        let result = try await readData(taskID: .taskReadBatteryADVModeOperation, cmdFlag: "6c")
        
        guard let mode = result.value["mode"] as? String else {
            throw MKSwiftBleError.paramsError
        }
        
        return mode
    }
    
    // MARK: - AA06 Temperature & Humidity Related
    
    static func readTemperatureHumidityData() async throws -> (temperature: String, humidity: String) {
        let result = try await MKSwiftBXPSCentralManager.shared.addReadTask(with: .taskReadTemperatureHumidityDataOperation, characteristic: MKSwiftBXPSCentralManager.shared.peripheral()?.bxs_swf_temperatureHumidity)
        
        guard let temperature = result.value["temperature"] as? String,
              let humidity = result.value["humidity"] as? String else {
            throw MKSwiftBleError.paramsError
        }
        
        return (temperature, humidity)
    }
    
    // MARK: - AA07 Password Related
    
    static func readPasswordVerification() async throws -> Bool {
        let result = try await readPasswordData(
            taskID: .taskReadNeedPasswordOperation,
            cmdFlag: "53"
        )
        
        guard let state = result.value["state"] as? String else {
            throw MKSwiftBleError.paramsError
        }
        
        return (state == "01")
    }
    
    // MARK: - AA08 Hall Sensor Data
    
    static func readMagnetStatus() async throws -> Bool {
        let result = try await MKSwiftBXPSCentralManager.shared.addReadTask(with: .taskReadMagnetStatusOperation, characteristic: MKSwiftBXPSCentralManager.shared.peripheral()?.bxs_swf_hallSensor)
        
        guard let moved = result.value["moved"] as? Bool else {
            throw MKSwiftBleError.paramsError
        }
        
        return moved
    }
    
    // MARK: - Private Async Methods
    
    private static func readData(taskID: MKSFBXSTaskOperationID, cmdFlag: String) async throws -> MKSwiftBleResult {
        let commandString = "ea00" + cmdFlag + "00"
        return try await MKSwiftBXPSCentralManager.shared.addTask(with: taskID, characteristic: MKSwiftBXPSCentralManager.shared.peripheral()?.bxs_swf_custom, commandData: commandString)
    }
    
    private static func readPasswordData(taskID: MKSFBXSTaskOperationID, cmdFlag: String) async throws -> MKSwiftBleResult {
        let commandString = "ea00" + cmdFlag + "00"
        return try await MKSwiftBXPSCentralManager.shared.addTask(with: taskID, characteristic: MKSwiftBXPSCentralManager.shared.peripheral()?.bxs_swf_password, commandData: commandString)
    }
}


