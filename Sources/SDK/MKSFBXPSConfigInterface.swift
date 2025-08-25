//
//  MKSwiftBXPSConfigInterface+Async.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/6/19.
//

import Foundation
import MKSwiftBleModule
import CoreBluetooth

@MainActor public extension MKSFBXSInterface {
    
    // MARK: - AA01 Custom
    
    static func configThreeAxisDataParams(dataRate: MKSFBXSThreeAxisDataRate,
                                          acceleration: MKSFBXSThreeAxisDataAG,
                                          motionThreshold: Int) async throws -> Bool {
        if motionThreshold < 1 || motionThreshold > 255 {
            throw MKSwiftBleError.paramsError
        }
        let rate = MKSwiftBXPSSDKDataAdopter.fetchThreeAxisDataRate(dataRate)
        let ag = MKSwiftBXPSSDKDataAdopter.fetchThreeAxisDataAG(acceleration)
        let threshold = MKSwiftBleSDKAdopter.fetchHexValue(motionThreshold, byteLen: 1)
        let commandString = "ea012103" + rate + ag + threshold
        return try await configData(taskID: .taskConfigThreeAxisDataParamsOperation, data: commandString)
    }
    
    static func configADVChannel(channel: MKSFBXSAdvChannel) async throws -> Bool {
        let rateString = MKSwiftBXPSSDKDataAdopter.fetchAdvChannelCmd(channel)
        let commandString = "ea013501" + rateString
        return try await configData(taskID: .taskConfigADVChannelOperation, data: commandString)
    }
    
    static func configTriggeredSlotParam(index: Int,
                                         advInterval: Int,
                                         advDuration: Int,
                                         rssi: Int,
                                         txPower: MKSFBXSTxPower) async throws -> Bool {
        if index < 0 || index > 2 || advInterval < 1 || advInterval > 100 ||
            advDuration < 1 || advDuration > 65535 || rssi < -127 || rssi > 0 {
            throw MKSwiftBleError.paramsError
        }
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(index + 3, byteLen: 1)
        let advIntervalValue = MKSwiftBleSDKAdopter.fetchHexValue(advInterval * 100, byteLen: 2)
        let advDurationValue = MKSwiftBleSDKAdopter.fetchHexValue(advDuration, byteLen: 2)
        let rssiValue = MKSwiftBleSDKAdopter.hexStringFromSignedNumber(rssi)
        let txPowerValue = MKSwiftBXPSSDKDataAdopter.fetchTxPower(txPower)
        let commandString = "ea012407" + indexValue + advIntervalValue + advDurationValue + rssiValue + txPowerValue
        return try await configData(taskID: .taskConfigTriggeredSlotParamOperation, data: commandString)
    }
    
    static func configPowerOff() async throws -> Bool {
        let commandString = "ea012600"
        return try await configData(taskID: .taskPowerOffOperation, data: commandString)
    }
    
    static func factoryReset() async throws -> Bool {
        let commandString = "ea012800"
        return try await configData(taskID: .taskFactoryResetOperation, data: commandString)
    }
    
    static func configHallDataStoreStatus(isOn: Bool) async throws -> Bool {
        let commandString = isOn ? "ea016d0101" : "ea016d0100"
        return try await configData(taskID: .taskConfigHallDataStoreStatusOperation, data: commandString)
    }
    
    static func clearHallHistoryData() async throws -> Bool {
        let commandString = "ea016f0100"
        return try await configData(taskID: .taskClearHallHistoryDataOperation, data: commandString)
    }
    
    static func batteryReset() async throws -> Bool {
        let commandString = "ea016b0101"
        return try await configData(taskID: .taskConfigBatteryResetOperation, data: commandString)
    }
    
    // MARK: - New Methods
    
    static func configResetDeviceByButtonStatus(isOn: Bool) async throws -> Bool {
        let commandString = isOn ? "ea01230101" : "ea01230100"
        return try await configData(taskID: .taskConfigResetDeviceByButtonStatusOperation, data: commandString)
    }
    
    static func configHallSensorStatus(isOn: Bool) async throws -> Bool {
        let commandString = isOn ? "ea01250101" : "ea01250100"
        return try await configData(taskID: .taskConfigHallSensorStatusOperation, data: commandString)
    }
    
    static func closeSlotTrigger(index: Int) async throws -> Bool {
        if index < 0 || index > 2 {
            throw MKSwiftBleError.paramsError
        }
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(index, byteLen: 1)
        let commandString = "ea013108" + indexValue + "00000000000000"
        return try await configData(taskID: .taskConfigSlotTriggerParamsOperation, data: commandString)
    }
    
    static func configTemperatureTriggerParams(slotIndex: Int,
                                               triggerEvent: Int,
                                               temperature: Int,
                                               lockedADV: Bool) async throws -> Bool {
        if slotIndex < 0 || slotIndex > 2 || temperature < -40 || temperature > 150 || triggerEvent < 0 || triggerEvent > 1 {
            throw MKSwiftBleError.paramsError
        }
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(slotIndex, byteLen: 1)
        let eventHex = triggerEvent == 0 ? "10" : "11"
        let tempHex = MKSwiftBXPSSDKDataAdopter.temperatureToHexString(temperature)
        let lockState = lockedADV ? "01" : "00"
        let staticPeriod = MKSwiftBleSDKAdopter.fetchHexValue(0, byteLen: 2)
        let commandString = "ea013108" + indexValue + "01" + eventHex + tempHex + lockState + staticPeriod
        return try await configData(taskID: .taskConfigSlotTriggerParamsOperation, data: commandString)
    }
    
    static func configHumidityTriggerParams(slotIndex: Int,
                                            triggerEvent: Int,
                                            humidity: Int,
                                            lockedADV: Bool) async throws -> Bool {
        if slotIndex < 0 || slotIndex > 2 || humidity < 0 || humidity > 100 || triggerEvent < 0 || triggerEvent > 1 {
            throw MKSwiftBleError.paramsError
        }
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(slotIndex, byteLen: 1)
        let eventHex = triggerEvent == 0 ? "20" : "21"
        let humidityValue = MKSwiftBleSDKAdopter.fetchHexValue(humidity, byteLen: 2)
        let lockState = lockedADV ? "01" : "00"
        let staticPeriod = MKSwiftBleSDKAdopter.fetchHexValue(0, byteLen: 2)
        let commandString = "ea013108" + indexValue + "02" + eventHex + humidityValue + lockState + staticPeriod
        return try await configData(taskID: .taskConfigSlotTriggerParamsOperation, data: commandString)
    }
    
    static func configMotionDetectionTriggerParams(slotIndex: Int,
                                                   triggerEvent: Int,
                                                   period: Int,
                                                   lockedADV: Bool) async throws -> Bool {
        if slotIndex < 0 || slotIndex > 2 || period < 1 || period > 65535 || triggerEvent < 0 || triggerEvent > 1 {
            throw MKSwiftBleError.paramsError
        }
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(slotIndex, byteLen: 1)
        let eventHex = triggerEvent == 0 ? "30" : "31"
        let lockState = lockedADV ? "01" : "00"
        let staticPeriod = MKSwiftBleSDKAdopter.fetchHexValue(period, byteLen: 2)
        let commandString = "ea013108" + indexValue + "03" + eventHex + "0000" + lockState + staticPeriod
        return try await configData(taskID: .taskConfigSlotTriggerParamsOperation, data: commandString)
    }
    
    static func configHallTriggerParams(slotIndex: Int,
                                        triggerEvent: Int,
                                        lockedADV: Bool) async throws -> Bool {
        if slotIndex < 0 || slotIndex > 2 || triggerEvent < 0 || triggerEvent > 1 {
            throw MKSwiftBleError.paramsError
        }
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(slotIndex, byteLen: 1)
        let eventHex = triggerEvent == 0 ? "40" : "41"
        let lockState = lockedADV ? "01" : "00"
        let staticPeriod = MKSwiftBleSDKAdopter.fetchHexValue(0, byteLen: 2)
        let commandString = "ea013108" + indexValue + "04" + eventHex + "0000" + lockState + staticPeriod
        return try await configData(taskID: .taskConfigSlotTriggerParamsOperation, data: commandString)
    }
    
    static func configSlotNoData(slotIndex: Int,
                                 type: MKSFBXSSlotDataType,
                                 advParams: MKSFBXSSlotAdvContentParam) async throws -> Bool {
        if slotIndex < 0 || slotIndex > 2 {
            throw MKSwiftBleError.paramsError
        }
        let paramsCmd = MKSwiftBXPSSDKDataAdopter.fetchSlotAdvParamsCmd(advParams)
        if paramsCmd.count == 0 {
            throw MKSwiftBleError.paramsError
        }
        
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(slotIndex, byteLen: 1)
        var taskID: MKSFBXSTaskOperationID = .taskConfigSlotDataOperation
        var typeString = "34"
        
        if type == .beforeTriggerData {
            typeString = "32"
            taskID = .taskConfigBeforeTriggerSlotDataOperation
        }
        
        let len = 1 + (paramsCmd.count / 2) + 1
        let lenString = MKSwiftBleSDKAdopter.fetchHexValue(len, byteLen: 1)
        let commandString = "ea01" + typeString + lenString + indexValue + paramsCmd + "ff"
        return try await configData(taskID: taskID, data: commandString)
    }
    
    static func configSlotUID(index: Int,
                              type: MKSFBXSSlotDataType,
                              advParams: MKSFBXSSlotAdvContentParam,
                              namespaceID: String,
                              instanceID: String) async throws -> Bool {
        guard index >= 0 && index <= 2,
              namespaceID.count == 20,
              MKSwiftBleSDKAdopter.checkHexCharacter(namespaceID),
              instanceID.count == 12,
              MKSwiftBleSDKAdopter.checkHexCharacter(instanceID) else {
            throw MKSwiftBleError.paramsError
        }
         
        let paramsCmd = MKSwiftBXPSSDKDataAdopter.fetchSlotAdvParamsCmd(advParams)
        if paramsCmd.count == 0 {
            throw MKSwiftBleError.paramsError
        }
        
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(index, byteLen: 1)
        var taskID: MKSFBXSTaskOperationID = .taskConfigSlotDataOperation
        var typeString = "34"
        
        if type == .beforeTriggerData {
            typeString = "32"
            taskID = .taskConfigBeforeTriggerSlotDataOperation
        }
        
        let len = 1 + (paramsCmd.count / 2) + 1 + 10 + 6
        let lenString = MKSwiftBleSDKAdopter.fetchHexValue(len, byteLen: 1)
        let commandString = "ea01" + typeString + lenString + indexValue + paramsCmd + "00" + namespaceID + instanceID
        return try await configData(taskID: taskID, data: commandString)
    }
    
    static func configSlotURL(index: Int,
                              type: MKSFBXSSlotDataType,
                              advParams: MKSFBXSSlotAdvContentParam,
                              urlType: MKSFBXSURLHeaderType,
                              urlContent: String) async throws -> Bool {
        guard index >= 0 && index <= 2 else {
            throw MKSwiftBleError.paramsError
        }
        
        let urlString = MKSwiftBXPSSDKDataAdopter.fetchUrlString(urlType: urlType, urlContent: urlContent)
        if urlString.count == 0 {
            throw MKSwiftBleError.paramsError
        }
         
        let paramsCmd = MKSwiftBXPSSDKDataAdopter.fetchSlotAdvParamsCmd(advParams)
        if paramsCmd.count == 0 {
            throw MKSwiftBleError.paramsError
        }
        
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(index, byteLen: 1)
        var taskID: MKSFBXSTaskOperationID = .taskConfigSlotDataOperation
        var typeString = "34"
        
        if type == .beforeTriggerData {
            typeString = "32"
            taskID = .taskConfigBeforeTriggerSlotDataOperation
        }
        
        let len = 1 + (paramsCmd.count / 2) + 1 + (urlString.count / 2)
        let lenString = MKSwiftBleSDKAdopter.fetchHexValue(len, byteLen: 1)
        let commandString = "ea01" + typeString + lenString + indexValue + paramsCmd + "10" + urlString
        return try await configData(taskID: taskID, data: commandString)
    }
    
    static func configSlotTLM(index: Int,
                              type: MKSFBXSSlotDataType,
                              advParams: MKSFBXSSlotAdvContentParam) async throws -> Bool {
        guard index >= 0 && index <= 2 else {
            throw MKSwiftBleError.paramsError
        }
         
        let paramsCmd = MKSwiftBXPSSDKDataAdopter.fetchSlotAdvParamsCmd(advParams)
        if paramsCmd.count == 0 {
            throw MKSwiftBleError.paramsError
        }
        
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(index, byteLen: 1)
        var taskID: MKSFBXSTaskOperationID = .taskConfigSlotDataOperation
        var typeString = "34"
        
        if type == .beforeTriggerData {
            typeString = "32"
            taskID = .taskConfigBeforeTriggerSlotDataOperation
        }
        
        let len = 1 + (paramsCmd.count / 2) + 1
        let lenString = MKSwiftBleSDKAdopter.fetchHexValue(len, byteLen: 1)
        let commandString = "ea01" + typeString + lenString + indexValue + paramsCmd + "20"
        return try await configData(taskID: taskID, data: commandString)
    }
    
    static func configSlotBeacon(index: Int,
                                 type: MKSFBXSSlotDataType,
                                 advParams: MKSFBXSSlotAdvContentParam,
                                 major: Int,
                                 minor: Int,
                                 uuid: String) async throws -> Bool {
        guard index >= 0 && index <= 2,
              major >= 0 && major <= 65535,
              minor >= 0 && minor <= 65535,
              !uuid.isEmpty,
              uuid.count == 32,
              MKSwiftBleSDKAdopter.checkHexCharacter(uuid) else {
            throw MKSwiftBleError.paramsError
        }
         
        let paramsCmd = MKSwiftBXPSSDKDataAdopter.fetchSlotAdvParamsCmd(advParams)
        if paramsCmd.count == 0 {
            throw MKSwiftBleError.paramsError
        }
        
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(index, byteLen: 1)
        var taskID: MKSFBXSTaskOperationID = .taskConfigSlotDataOperation
        var typeString = "34"
        
        if type == .beforeTriggerData {
            typeString = "32"
            taskID = .taskConfigBeforeTriggerSlotDataOperation
        }
        
        let len = 1 + (paramsCmd.count / 2) + 1 + 20
        let lenString = MKSwiftBleSDKAdopter.fetchHexValue(len, byteLen: 1)
        let majorValue = MKSwiftBleSDKAdopter.fetchHexValue(major, byteLen: 2)
        let minorValue = MKSwiftBleSDKAdopter.fetchHexValue(minor, byteLen: 2)
        let commandString = "ea01" + typeString + lenString + indexValue + paramsCmd + "50" + uuid + majorValue + minorValue
        return try await configData(taskID: taskID, data: commandString)
    }
    
    static func configSlotSensorInfo(index: Int,
                                     type: MKSFBXSSlotDataType,
                                     advParams: MKSFBXSSlotAdvContentParam,
                                     deviceName: String,
                                     tagID: String) async throws -> Bool {
        guard index >= 0 && index <= 2,
              !deviceName.isEmpty,
              deviceName.count <= 20,
              !tagID.isEmpty,
              tagID.count <= 12,
              tagID.count % 2 == 0 else {
            throw MKSwiftBleError.paramsError
        }
         
        let paramsCmd = MKSwiftBXPSSDKDataAdopter.fetchSlotAdvParamsCmd(advParams)
        if paramsCmd.count == 0 {
            throw MKSwiftBleError.paramsError
        }
        
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(index, byteLen: 1)
        var taskID: MKSFBXSTaskOperationID = .taskConfigSlotDataOperation
        var typeString = "34"
        
        if type == .beforeTriggerData {
            typeString = "32"
            taskID = .taskConfigBeforeTriggerSlotDataOperation
        }
        
        var tempString = ""
        for char in deviceName {
            let asciiCode = Int(char.unicodeScalars.first?.value ?? 0)
            tempString.append(String(format: "%1lx", asciiCode))
        }
        
        let nameLen = MKSwiftBleSDKAdopter.fetchHexValue(deviceName.count, byteLen: 1)
        let tagIDLen = MKSwiftBleSDKAdopter.fetchHexValue(tagID.count / 2, byteLen: 1)
        let len = 1 + (paramsCmd.count / 2) + 1 + deviceName.count + (tagID.count / 2) + 2
        let lenString = MKSwiftBleSDKAdopter.fetchHexValue(len, byteLen: 1)
        let commandString = "ea01" + typeString + lenString + indexValue + paramsCmd + "80" + nameLen + tempString + tagIDLen + tagID
        return try await configData(taskID: taskID, data: commandString)
    }
    
    static func configSlotTriggeredNoData(index: Int,
                                          advParams: MKSFBXSSlotTriggeredAdvContentParam) async throws -> Bool {
        guard index >= 0 && index <= 2 else {
            throw MKSwiftBleError.paramsError
        }
         
        let paramsCmd = MKSwiftBXPSSDKDataAdopter.fetchSlotTriggerdAdvParamsCmd(advParams)
        if paramsCmd.count == 0 {
            throw MKSwiftBleError.paramsError
        }
        
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(index, byteLen: 1)
        let len = 1 + (paramsCmd.count / 2) + 1
        let lenString = MKSwiftBleSDKAdopter.fetchHexValue(len, byteLen: 1)
        let commandString = "ea0133" + lenString + indexValue + paramsCmd + "ff"
        return try await configData(taskID: .taskConfigTriggerSlotDataOperation, data: commandString)
    }
    
    static func configSlotTriggeredUID(index: Int,
                                       advParams: MKSFBXSSlotTriggeredAdvContentParam,
                                       namespaceID: String,
                                       instanceID: String) async throws -> Bool {
        guard index >= 0 && index <= 2,
              namespaceID.count == 20,
              MKSwiftBleSDKAdopter.checkHexCharacter(namespaceID),
              instanceID.count == 12,
              MKSwiftBleSDKAdopter.checkHexCharacter(instanceID) else {
            throw MKSwiftBleError.paramsError
        }
         
        let paramsCmd = MKSwiftBXPSSDKDataAdopter.fetchSlotTriggerdAdvParamsCmd(advParams)
        if paramsCmd.count == 0 {
            throw MKSwiftBleError.paramsError
        }
        
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(index, byteLen: 1)
        let len = 1 + (paramsCmd.count / 2) + 1 + 10 + 6
        let lenString = MKSwiftBleSDKAdopter.fetchHexValue(len, byteLen: 1)
        let commandString = "ea0133" + lenString + indexValue + paramsCmd + "00" + namespaceID + instanceID
        return try await configData(taskID: .taskConfigTriggerSlotDataOperation, data: commandString)
    }
    
    static func configSlotTriggeredURL(index: Int,
                                       advParams: MKSFBXSSlotTriggeredAdvContentParam,
                                       urlType: MKSFBXSURLHeaderType,
                                       urlContent: String) async throws -> Bool {
        guard index >= 0 && index <= 2 else {
            throw MKSwiftBleError.paramsError
        }
         
        let urlString = MKSwiftBXPSSDKDataAdopter.fetchUrlString(urlType: urlType, urlContent: urlContent)
        if urlString.count == 0 {
            throw MKSwiftBleError.paramsError
        }
         
        let paramsCmd = MKSwiftBXPSSDKDataAdopter.fetchSlotTriggerdAdvParamsCmd(advParams)
        if paramsCmd.count == 0 {
            throw MKSwiftBleError.paramsError
        }
        
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(index, byteLen: 1)
        let len = 1 + (paramsCmd.count / 2) + 1 + (urlString.count / 2)
        let lenString = MKSwiftBleSDKAdopter.fetchHexValue(len, byteLen: 1)
        let commandString = "ea0133" + lenString + indexValue + paramsCmd + "10" + urlString
        return try await configData(taskID: .taskConfigTriggerSlotDataOperation, data: commandString)
    }
    
    static func configSlotTriggeredTLM(index: Int,
                                       advParams: MKSFBXSSlotTriggeredAdvContentParam) async throws -> Bool {
        guard index >= 0 && index <= 2 else {
            throw MKSwiftBleError.paramsError
        }
         
        let paramsCmd = MKSwiftBXPSSDKDataAdopter.fetchSlotTriggerdAdvParamsCmd(advParams)
        if paramsCmd.count == 0 {
            throw MKSwiftBleError.paramsError
        }
        
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(index, byteLen: 1)
        let len = 1 + (paramsCmd.count / 2) + 1
        let lenString = MKSwiftBleSDKAdopter.fetchHexValue(len, byteLen: 1)
        let commandString = "ea0133" + lenString + indexValue + paramsCmd + "20"
        return try await configData(taskID: .taskConfigTriggerSlotDataOperation, data: commandString)
    }
    
    static func configSlotTriggeredBeacon(index: Int,
                                          advParams: MKSFBXSSlotTriggeredAdvContentParam,
                                          major: Int,
                                          minor: Int,
                                          uuid: String) async throws -> Bool {
        guard index >= 0 && index <= 2,
              major >= 0 && major <= 65535,
              minor >= 0 && minor <= 65535,
              !uuid.isEmpty,
              uuid.count == 32,
              MKSwiftBleSDKAdopter.checkHexCharacter(uuid) else {
            throw MKSwiftBleError.paramsError
        }
        
        let paramsCmd = MKSwiftBXPSSDKDataAdopter.fetchSlotTriggerdAdvParamsCmd(advParams)
        if paramsCmd.count == 0 {
            throw MKSwiftBleError.paramsError
        }
        
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(index, byteLen: 1)
        let len = 1 + (paramsCmd.count / 2) + 1 + 20
        let lenString = MKSwiftBleSDKAdopter.fetchHexValue(len, byteLen: 1)
        let majorValue = MKSwiftBleSDKAdopter.fetchHexValue(major, byteLen: 2)
        let minorValue = MKSwiftBleSDKAdopter.fetchHexValue(minor, byteLen: 2)
        let commandString = "ea0133" + lenString + indexValue + paramsCmd + "50" + uuid + majorValue + minorValue
        return try await configData(taskID: .taskConfigTriggerSlotDataOperation, data: commandString)
    }
    
    static func configSlotTriggeredSensorInfo(index: Int,
                                              advParams: MKSFBXSSlotTriggeredAdvContentParam,
                                              deviceName: String,
                                              tagID: String) async throws -> Bool {
        guard index >= 0 && index <= 2,
              !deviceName.isEmpty,
              deviceName.count <= 20,
              !tagID.isEmpty,
              tagID.count <= 12,
              tagID.count % 2 == 0 else {
            throw MKSwiftBleError.paramsError
        }
        
        let paramsCmd = MKSwiftBXPSSDKDataAdopter.fetchSlotTriggerdAdvParamsCmd(advParams)
        if paramsCmd.count == 0 {
            throw MKSwiftBleError.paramsError
        }
        
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(index, byteLen: 1)
        var tempString = ""
        for char in deviceName {
            let asciiCode = Int(char.unicodeScalars.first?.value ?? 0)
            tempString.append(String(format: "%1lx", asciiCode))
        }
        
        let nameLen = MKSwiftBleSDKAdopter.fetchHexValue(deviceName.count, byteLen: 1)
        let tagIDLen = MKSwiftBleSDKAdopter.fetchHexValue(tagID.count / 2, byteLen: 1)
        let len = 1 + (paramsCmd.count / 2) + 1 + deviceName.count + (tagID.count / 2) + 2
        let lenString = MKSwiftBleSDKAdopter.fetchHexValue(len, byteLen: 1)
        let commandString = "ea0133" + lenString + indexValue + paramsCmd + "80" + nameLen + tempString + tagIDLen + tagID
        return try await configData(taskID: .taskConfigTriggerSlotDataOperation, data: commandString)
    }
    
    // MARK: - Direction Finding
    
    static func configDirectionFindingStatus(isOn: Bool) async throws -> Bool {
        let commandString = isOn ? "ea01360101" : "ea01360100"
        return try await configData(taskID: .taskConfigDirectionFindingStatusOperation, data: commandString)
    }
    
    // MARK: - Connectable
    
    static func configConnectable(connectable: Bool) async throws -> Bool {
        let commandString = connectable ? "ea01370101" : "ea01370100"
        return try await configData(taskID: .taskConfigConnectableOperation, data: commandString)
    }
    
    // MARK: - Tag ID Autofill
    
    static func configTagIDAutofillStatus(isOn: Bool) async throws -> Bool {
        let commandString = isOn ? "ea013c0101" : "ea013c0100"
        return try await configData(taskID: .taskConfigTagIDAutofillStatusOperation, data: commandString)
    }
    
    // MARK: - Device Time
    
    static func configDeviceTime(timestamp: UInt) async throws -> Bool {
        let value = String(format: "%1lx", timestamp)
        let commandString = "ea013f04" + value
        return try await configData(taskID: .taskConfigDeviceTimeOperation, data: commandString)
    }
    
    // MARK: - TH Data Store
    
    static func configTHDataStoreStatus(isOn: Bool,
                                             interval: Int) async throws -> Bool {
        guard interval >= 0 && interval <= 65535 else {
            throw MKSwiftBleError.paramsError
        }
        
        let status = isOn ? "01" : "00"
        let intervalString = MKSwiftBleSDKAdopter.fetchHexValue(interval, byteLen: 2)
        let commandString = "ea014003" + status + intervalString
        return try await configData(taskID: .taskConfigTHDataStoreStatusOperation, data: commandString)
    }
    
    // MARK: - TH Sampling Rate
    
    static func configTHSamplingRate(rate: Int) async throws -> Bool {
        guard rate >= 1 && rate <= 65535 else {
            throw MKSwiftBleError.paramsError
        }
        
        let rateString = MKSwiftBleSDKAdopter.fetchHexValue(rate, byteLen: 2)
        let commandString = "ea014102" + rateString
        return try await configData(taskID: .taskConfigTHSamplingRateOperation, data: commandString)
    }
    
    // MARK: - Delete BXP Record HT Datas
    
    static func deleteBXPRecordHTDatas() async throws -> Bool {
        let commandString = "ea014200"
        return try await configData(taskID: .taskDeleteBXPRecordHTDatasOperation, data: commandString)
    }
    
    // MARK: - Remote Reminder LED Notification
    
    static func configRemoteReminderLEDNotiParams(blinkingTime: Int,
                                                        blinkingInterval: Int) async throws -> Bool {
        guard blinkingTime >= 1 && blinkingTime <= 600,
              blinkingInterval >= 1 && blinkingInterval <= 100 else {
            throw MKSwiftBleError.paramsError
        }
        
        let time = MKSwiftBleSDKAdopter.fetchHexValue(blinkingTime * 10, byteLen: 2)
        let interval = MKSwiftBleSDKAdopter.fetchHexValue(blinkingInterval * 100, byteLen: 2)
        let commandString = "ea01610503" + interval + time
        return try await configData(taskID: .taskConfigRemoteReminderLEDNotiParamsOperation, data: commandString)
    }
    
    // MARK: - Remote Reminder Buzzer Notification
    
    static func configRemoteReminderBuzzerNotiParams(ringTime: Int,
                                                           ringInterval: Int) async throws -> Bool {
        guard ringTime >= 1 && ringTime <= 600,
              ringInterval >= 1 && ringInterval <= 100 else {
            throw MKSwiftBleError.paramsError
        }
        
        let time = MKSwiftBleSDKAdopter.fetchHexValue(ringTime * 10, byteLen: 2)
        let interval = MKSwiftBleSDKAdopter.fetchHexValue(ringInterval * 100, byteLen: 2)
        let commandString = "ea0162050e" + interval + time
        return try await configData(taskID: .taskConfigRemoteReminderBuzzerNotiParamsOperation, data: commandString)
    }
    
    // MARK: - Remote Reminder Buzzer Frequency
    
    static func configRemoteReminderBuzzerFrequency(frequency: MKSFBXSBuzzerRingingFrequencyType) async throws -> Bool {
        let commandString = (frequency == .higher) ? "ea0163021194" : "ea0163020fa0"
        return try await configData(taskID: .taskConfigRemoteReminderBuzzerFrequencyOperation, data: commandString)
    }
    
    // MARK: - Trigger LED Indicator
    
    static func configTriggerLEDIndicatorStatus(isOn: Bool) async throws -> Bool {
        let commandString = isOn ? "ea01650101" : "ea01650100"
        return try await configData(taskID: .taskConfigTriggerLEDIndicatorStatusOperation, data: commandString)
    }
    
    // MARK: - Clear Hall Trigger Count
    
    static func clearHallTriggerCount() async throws -> Bool {
        let commandString = "ea016800"
        return try await configData(taskID: .taskClearHallTriggerCountOperation, data: commandString)
    }
    
    // MARK: - Clear Motion Trigger Count
    
    static func clearMotionTriggerCount() async throws -> Bool {
        let commandString = "ea016900"
        return try await configData(taskID: .taskClearMotionTriggerCountOperation, data: commandString)
    }
    
    // MARK: - Battery ADV Mode
    
    static func configBatteryADVMode(mode: MKSFBXSBatteryADVMode) async throws -> Bool {
        let valueString = MKSwiftBleSDKAdopter.fetchHexValue(mode.rawValue + 1, byteLen: 1)
        let commandString = "ea016c01" + valueString
        return try await configData(taskID: .taskConfigBatteryADVModeOperation, data: commandString)
    }
    
    // MARK: - AA07 Password Related
    
    static func configConnectPassword(password: String) async throws -> Bool {
        if password.isEmpty || password.count > 16 {
            throw MKSwiftBleError.paramsError
        }
        
        var commandData = ""
        for char in password {
            let asciiCode = char.unicodeScalars.first?.value ?? 0
            commandData += String(format: "%1lx", asciiCode)
        }
        
        var lenString = String(format: "%1lx", password.count)
        if lenString.count == 1 {
            lenString = "0" + lenString
        }
        
        let commandString = "ea0152" + lenString + commandData
        return try await configPasswordData(taskID: .taskConfigConnectPasswordOperation, data: commandString)
    }
    
    static func configPasswordVerification(isOn: Bool) async throws -> Bool {
        let commandString = isOn ? "ea01530101" : "ea01530100"
        return try await configPasswordData(taskID: .taskConfigPasswordVerificationOperation, data: commandString)
    }
    
    // MARK: - Private Methods
    
    private static func configData(taskID: MKSFBXSTaskOperationID,
                                   data: String) async throws -> Bool {
        try await config(taskID: taskID,
                        characteristic: MKSwiftBXPSCentralManager.shared.peripheral()?.bxs_swf_custom,
                        data: data)
    }
    
    private static func configPasswordData(taskID: MKSFBXSTaskOperationID,
                                         data: String) async throws -> Bool {
        try await config(taskID: taskID,
                       characteristic: MKSwiftBXPSCentralManager.shared.peripheral()?.bxs_swf_password,
                       data: data)
    }
    
    private static func configHTData(taskID: MKSFBXSTaskOperationID,
                                   data: String) async throws -> Bool {
        try await config(taskID: taskID,
                       characteristic: MKSwiftBXPSCentralManager.shared.peripheral()?.bxs_swf_temperatureHumidity,
                       data: data)
    }
    
    private static func config(taskID: MKSFBXSTaskOperationID,
                             characteristic: CBCharacteristic?,
                             data: String) async throws -> Bool {
        let result = try await MKSwiftBXPSCentralManager.shared.addTask(with: taskID, characteristic: characteristic, commandData: data)
        
        guard let success = result.value["success"] as? Bool else {
            throw MKSwiftBleError.setParamsError
        }
        
        return success
    }
}
