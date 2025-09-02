//
//  MKSwiftBXPSTaskAdopter.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/6/18.
//

import Foundation
import CoreBluetooth
import MKSwiftBleModule

class MKSFBXSTaskAdopter {
    // MARK: - Public Methods
    
    static func parseReadData(with characteristic: CBCharacteristic) -> [String: Any] {
        guard let data = characteristic.value else {
            return [:]
        }
        guard data.count > 4 else {
            return [:]
        }
                
        print("+++++\(characteristic.uuid.uuidString)-----\(data)")
        
        if characteristic.uuid == CBUUID(string: "AA01") {
            return parseCustomData(data)
        }
        if characteristic.uuid == CBUUID(string: "AA04") {
            // Password related
            return parsePasswordData(data)
        }
        if characteristic.uuid == CBUUID(string: "AA06") {
            // Temperature/Humidity related
            return parseHTData(data)
        }
        if characteristic.uuid == CBUUID(string: "AA08") {
            // Hall sensor related
            return parseHallSensorData(data)
        }
        
        return [:]
    }
    
    static func parseWriteData(with characteristic: CBCharacteristic) -> [String: Any] {
        return [:]
    }
    
    // MARK: - Data Parsing
    
    private static func parseHTData(_ readData: Data) -> [String: Any] {
        
        guard readData.count >= 4 else { return [:] }
            
        if readData[0] != 0xeb {
            return [:]
        }
                
        let content = readData.subdata(in: 4..<readData.count)
        
        // Non-fragmented protocol
        if readData[1] == 0x00 {
            // Read
            return parseHTReadData(content, cmd: readData[2])
        }
        if readData[1] == 0x01 {
            return parseHTConfigData(content, cmd: readData[2])
        }
        
        return [:]
    }
    
    private static func parseHTReadData(_ content: Data, cmd: UInt8) -> [String: Any] {
        var operationID: MKSFBXSTaskOperationID = .defaultTaskOperationID
        var resultDic: [String: Any] = [:]
        
        if cmd == 0x70 {
            // Read real-time temperature/humidity data
            operationID = .taskReadTemperatureHumidityDataOperation
            
            let tempTemp = MKSwiftBleSDKAdopter.signedDataTurnToInt(content.subdata(in: 0..<2))
            
            let tempHui = MKSwiftBleSDKAdopter.getDecimalFromData(content, range: 2..<4)
            
            let temperature = String(format: "%.1f", Double(tempTemp) * 0.1)
            let humidity = String(format: "%.1f", Double(tempHui) * 0.1)
            
            resultDic = [
                "temperature": temperature,
                "humidity": humidity
            ]
        }
        
        return dataParserGetDataSuccess(resultDic, operationID: operationID)
    }
    
    private static func parseHTConfigData(_ content: Data, cmd: UInt8) -> [String: Any] {
        var operationID: MKSFBXSTaskOperationID = .defaultTaskOperationID
        let success = content[0] == 0xaa
        
        if cmd == 0x51 {
            // Verify password
            operationID = .connectPasswordOperation
        } else if cmd == 0x52 {
            // Change password
            operationID = .taskConfigConnectPasswordOperation
        } else if cmd == 0x53 {
            // Whether password verification is needed
            operationID = .taskConfigPasswordVerificationOperation
        }
        
        return dataParserGetDataSuccess(["success": success], operationID: operationID)
    }
    
    private static func parsePasswordData(_ readData: Data) -> [String: Any] {
            
        guard readData.count >= 4 else { return [:] }
            
        if readData[0] != 0xeb {
            return [:]
        }
                
        let content = readData.subdata(in: 4..<readData.count)
        
        // Non-fragmented protocol
        if readData[1] == 0x00 {
            // Read
            return parsePasswordReadData(content, cmd: readData[2])
        }
        if readData[1] == 0x01 {
            return parsePasswordConfigData(content, cmd: readData[2])
        }
        
        return [:]
    }
    
    private static func parsePasswordReadData(_ content: Data, cmd: UInt8) -> [String: Any] {
        var operationID: MKSFBXSTaskOperationID = .defaultTaskOperationID
        var resultDic: [String: Any] = [:]
        
        if cmd == 0x53 {
            // Read if device connection requires password
            operationID = .taskReadNeedPasswordOperation
            resultDic = ["state": content[0]]
        }
        
        return dataParserGetDataSuccess(resultDic, operationID: operationID)
    }
    
    private static func parsePasswordConfigData(_ content: Data, cmd: UInt8) -> [String: Any] {
        var operationID: MKSFBXSTaskOperationID = .defaultTaskOperationID
        let success = content[0] == 0xaa
        
        if cmd == 0x51 {
            // Verify password
            operationID = .connectPasswordOperation
        } else if cmd == 0x52 {
            // Change password
            operationID = .taskConfigConnectPasswordOperation
        } else if cmd == 0x53 {
            // Whether password verification is needed
            operationID = .taskConfigPasswordVerificationOperation
        }
        
        return dataParserGetDataSuccess(["success": success], operationID: operationID)
    }
    
    private static func parseCustomData(_ readData: Data) -> [String: Any] {
        if readData[0] == 0xec {
            // ec
            return parseMultiPacketData(readData)
        }
        if readData[0] != 0xeb {
            
            return [:]
        }
        // eb
        
        let content: Data = readData.subdata(in: 4..<readData.count)
                
        // Non-fragmented protocol
        if readData[1] == 0x00 {
            // Read
            return parseCustomReadData(content, cmd: readData[2])
        }
        if readData[1] == 0x01 {
            return parseCustomConfigData(content, cmd: readData[2])
        }
        
        return [:]
    }
    
    private static func parseCustomReadData(_ content: Data, cmd: UInt8) -> [String: Any] {
        var operationID:MKSFBXSTaskOperationID = .defaultTaskOperationID
        var resultDic: [String: Any] = [:]
        
        if cmd == 0x20 {
            // Read MAC address
            operationID = .taskReadMacAddressOperation
            let tempContent = MKSwiftBleSDKAdopter.hexStringFromData(content)
            let macParts = [
                tempContent.bleSubstring(from: 0, length: 2),
                tempContent.bleSubstring(from: 2, length: 2),
                tempContent.bleSubstring(from: 4, length: 2),
                tempContent.bleSubstring(from: 6, length: 2),
                tempContent.bleSubstring(from: 8, length: 2),
                tempContent.bleSubstring(from: 10, length: 2)
            ]
            let macAddress = macParts.joined(separator: ":").uppercased()
            resultDic = ["macAddress": macAddress]
        } else if cmd == 0x21 {
            // Read three-axis sensor parameters
            operationID = .taskReadThreeAxisDataParamsOperation
            resultDic = [
                "samplingRate":content[0],
                "gravityReference":content[1],
                "motionThreshold":content[2]
            ]
        } else if cmd == 0x23 {
            // Read button reset function
            operationID = .taskReadResetDeviceByButtonStatusOperation
            resultDic = ["isOn": content[0] == 0x01]
        } else if cmd == 0x25 {
            // Read hall power on/off function
            operationID = .taskReadHallSensorStatusOperation
            resultDic = ["isOn": content[0] == 0x01]
        } else if cmd == 0x29 {
            // Firmware
            operationID = .taskReadFirmwareOperation
            if let firmwareString = String(data: content, encoding: .utf8) {
                resultDic = ["firmware": firmwareString]
            }
        } else if cmd == 0x2a {
            // Manufacturer
            operationID = .taskReadManufacturerOperation
            if let manufacturerString = String(data: content, encoding: .utf8) {
                resultDic = ["manufacturer": manufacturerString]
            }
        } else if cmd == 0x2b {
            // Production date
            operationID = .taskReadProductDateOperation
            let year = MKSwiftBleSDKAdopter.getDecimalFromData(content, range: 0..<2)
            var month = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: 2..<3)
            if month.count == 1 {
                month = "0" + month
            }
            var day = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: 3..<4)
            if day.count == 1 {
                day = "0" + day
            }
            resultDic = ["productionDate": "\(year)/\(month)/\(day)"]
        } else if cmd == 0x2c {
            // Software
            operationID = .taskReadSoftwareOperation
            if let softwareString = String(data: content, encoding: .utf8) {
                resultDic = ["software": softwareString]
            }
        } else if cmd == 0x2d {
            // Hardware
            operationID = .taskReadHardwareOperation
            if let hardwareString = String(data: content, encoding: .utf8) {
                resultDic = ["hardware": hardwareString]
            }
        } else if cmd == 0x2e {
            // Product model
            operationID = .taskReadDeviceModelOperation
            if let modelString = String(data: content, encoding: .utf8) {
                resultDic = ["modeID": modelString]
            }
        } else if cmd == 0x30 {
            // Read broadcast channel type
            operationID = .taskReadSlotTypeOperation
            let tempContent = MKSwiftBleSDKAdopter.hexStringFromData(content)
            let slot1 = tempContent.bleSubstring(from: 0, length: 2)
            let slot2 = tempContent.bleSubstring(from: 2, length: 2)
            let slot3 = tempContent.bleSubstring(from: 4, length: 2)
            resultDic = ["slotList": [slot1, slot2, slot3]]
        } else if cmd == 0x31 {
            // Read channel trigger type
            operationID = .taskReadSlotTriggerDataOperation
            resultDic = MKSwiftBXPSSDKDataAdopter.parseSlotTriggerParam(content)
        } else if cmd == 0x32 {
            // Read pre-trigger broadcast parameters
            operationID = .taskReadBeforeTriggerSlotDataOperation
            resultDic = MKSwiftBXPSSDKDataAdopter.parseSlotData(content, hasStandbyDuration: true)
        } else if cmd == 0x33 {
            // Read trigger broadcast parameters
            operationID = .taskReadTriggerSlotDataOperation
            resultDic = MKSwiftBXPSSDKDataAdopter.parseSlotData(content, hasStandbyDuration: false)
        } else if cmd == 0x34 {
            // Read channel broadcast content
            operationID = .taskReadSlotDataOperation
            resultDic = MKSwiftBXPSSDKDataAdopter.parseSlotData(content, hasStandbyDuration: true)
        } else if cmd == 0x35 {
            // Read low battery percentage reminder function and alarm threshold
            operationID = .taskReadADVChannelOperation
            let channel = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: 0..<content.count)
            resultDic = ["channel": channel]
        } else if cmd == 0x36 {
            // Read AOA CTE broadcast frame status
            operationID = .taskReadDirectionFindingStatusOperation
            resultDic = ["isOn": content[0] == 0x01]
        } else if cmd == 0x37 {
            // Read connectable status
            operationID = .taskReadConnectableOperation
            resultDic = ["connectable": content[0] == 0x01]
        } else if cmd == 0x3c {
            // Read Tag ID auto-fill status
            operationID = .taskTagIDAutofillStatusOperation
            resultDic = ["isOn": content[0] == 0x01]
        } else if cmd == 0x3e {
            // Read system runtime
            operationID = .taskDeviceRuntimeOperation
            let time = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: 0..<content.count)
            resultDic = ["time": time]
        } else if cmd == 0x3f {
            // Read device current UTC timestamp
            operationID = .taskReadDeviceUTCTimeOperation
            let timestamp = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: 0..<content.count)
            resultDic = ["timestamp": timestamp]
        } else if cmd == 0x40 {
            // Read temperature/humidity data storage switch status
            operationID = .taskReadTHDataStoreStatusOperation
            let isOn = content[0] == 0x01
            let interval = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: 1..<3)
            resultDic = [
                "isOn": isOn,
                "interval": interval
            ]
        } else if cmd == 0x41 {
            // Read temperature/humidity sampling rate
            operationID = .taskReadTHSamplingRateOperation
            let count = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: 0..<content.count)
            resultDic = ["samplingRate": count]
        } else if cmd == 0x43 {
            // Read temperature/humidity historical data total count
            operationID = .taskReadHTRecordTotalNumbersOperation
            let count = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: 0..<content.count)
            resultDic = ["count": count]
        } else if cmd == 0x68 {
            // Read hall sensor trigger count
            operationID = .taskReadHallTriggerCountOperation
            let count = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: 0..<content.count)
            resultDic = ["count": count]
        } else if cmd == 0x69 {
            // Read motion trigger count
            operationID = .taskReadMotionTriggerCountOperation
            let count = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: 0..<content.count)
            resultDic = ["count": count]
        } else if cmd == 0x6a {
            // Read battery voltage
            operationID = .taskReadBatteryVoltageOperation
            let voltage = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: 0..<content.count)
            resultDic = ["voltage": voltage]
        } else if cmd == 0x6b {
            // Read battery remaining percentage
            operationID = .taskReadBatteryPercentageOperation
            let percentage = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: 0..<content.count)
            resultDic = ["percentage": percentage]
        } else if cmd == 0x4a {
            // Read sensor model
            operationID = .taskReadSensorTypeOperation
            let axis = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: 0..<1)
            let tempHumidity = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: 1..<2)
            let lightSensor = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: 2..<3)
            let pir = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: 3..<4)
            let tof = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: 4..<5)
            resultDic = [
                "axis": axis,
                "tempHumidity": tempHumidity,
                "lightSensor": lightSensor,
                "pir": pir,
                "tof": tof
            ]
        } else if cmd == 0x63 {
            // Read buzzer frequency
            operationID = .taskReadRemoteReminderBuzzerFrequencyOperation
            let frequency = MKSwiftBleSDKAdopter.getDecimalFromData(content, range: 0..<content.count)
            resultDic = ["frequency": frequency == 4500 ? "1" : "0"]
        } else if cmd == 0x65 {
            // Read trigger LED reminder status
            operationID = .taskReadTriggerLEDIndicatorStatusOperation
            resultDic = ["isOn": content[0] == 0x01]
        } else if cmd == 0x6c {
            // Read battery percentage/voltage value
            operationID = .taskReadBatteryADVModeOperation
            let mode = MKSwiftBleSDKAdopter.getDecimalFromData(content, range: 0..<content.count)
            resultDic = ["mode": "\(mode - 1)"]
        } else if cmd == 0x24 {
            // Read post-trigger channel broadcast parameters
            operationID = .taskReadTriggeredSlotParamsOperation
            let slotIndex = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: 0..<1)
            let advInterval = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: 1..<3)
            let advDuration = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: 3..<5)
            let rssi = MKSwiftBleSDKAdopter.signedDataTurnToInt(content.subdata(in: 5..<6))
            let txPower = MKSwiftBXPSSDKDataAdopter.fetchTxPowerValueString(Int(content[6]))
            resultDic = [
                "slotIndex": slotIndex,
                "advInterval": advInterval,
                "advDuration": advDuration,
                "rssi": "\(rssi)",
                "txPower": txPower
            ]
        } else if cmd == 0x2f {
            // Read device type
            operationID = .taskReadDeviceTypeOperation
            let chipType = MKSwiftBleSDKAdopter.hexStringFromData(content.subdata(in: 0..<1))
            let bynaryHex = MKSwiftBleSDKAdopter.hexStringFromData(content.subdata(in: 1..<2))
            let binary = MKSwiftBleSDKAdopter.binaryByhex(bynaryHex)
            
            let threeAxis = String(binary[binary.index(binary.endIndex, offsetBy: -1)]) == "1"
            let tempHumidity = String(binary[binary.index(binary.endIndex, offsetBy: -2)]) == "1"
            let hall = String(binary[binary.index(binary.endIndex, offsetBy: -3)]) == "1"
            let infrared = String(binary[binary.index(binary.endIndex, offsetBy: -4)]) == "1"
            let sixAxis = String(binary[binary.index(binary.endIndex, offsetBy: -5)]) == "1"
            let flash = String(binary[binary.index(binary.endIndex, offsetBy: -6)]) == "1"
            let pir = String(binary[binary.index(binary.endIndex, offsetBy: -7)]) == "1"
            
            resultDic = [
                "chipType": chipType,
                "threeAxis": threeAxis,
                "tempHumidity": tempHumidity,
                "hall": hall,
                "infrared": infrared,
                "sixAxis": sixAxis,
                "flash": flash,
                "pir": pir
            ]
        } else if cmd == 0x6c {
            // Read all channel broadcast types
            operationID = .taskReadSlotAdvTypeOperation
            var typeList: [String] = []
            let tempContent = MKSwiftBleSDKAdopter.hexStringFromData(content)
            for i in 0..<6 {
                typeList.append(tempContent.bleSubstring(from: (i * 2), length: 2))
            }
            resultDic = ["typeList": typeList]
        } else if cmd == 0x6d {
            // Read hall record switch
            operationID = .taskReadHallDataStoreStatusOperation
            resultDic = ["isOn": content[0] == 0x01]
        }
        
        return dataParserGetDataSuccess(resultDic, operationID: operationID)
    }
    
    private static func parseCustomConfigData(_ content: Data, cmd: UInt8) -> [String: Any] {
        var operationID = MKSFBXSTaskOperationID.defaultTaskOperationID
        let success = content[0] == 0xaa
        
        if cmd == 0x01 {
            // No operation
        } else if cmd == 0x21 {
            // Configure three-axis sensor parameters
            operationID = .taskConfigThreeAxisDataParamsOperation
        } else if cmd == 0x23 {
            // Configure button reset function
            operationID = .taskConfigResetDeviceByButtonStatusOperation
        } else if cmd == 0x25 {
            // Configure hall power on/off status
            operationID = .taskConfigHallSensorStatusOperation
        } else if cmd == 0x31 {
            // Configure trigger parameters
            operationID = .taskConfigSlotTriggerParamsOperation
        } else if cmd == 0x32 {
            // Configure pre-trigger broadcast parameters
            operationID = .taskConfigBeforeTriggerSlotDataOperation
        } else if cmd == 0x33 {
            // Configure trigger broadcast parameters
            operationID = .taskConfigTriggerSlotDataOperation
        } else if cmd == 0x34 {
            // Configure pre-trigger channel broadcast content
            operationID = .taskConfigSlotDataOperation
        } else if cmd == 0x35 {
            // Configure broadcast channel enable
            operationID = .taskConfigADVChannelOperation
        } else if cmd == 0x36 {
            // Configure AOA CTE broadcast frame
            operationID = .taskConfigDirectionFindingStatusOperation
        } else if cmd == 0x37 {
            // Configure connectable status
            operationID = .taskConfigConnectableOperation
        } else if cmd == 0x3c {
            // Configure Tag ID auto-fill status
            operationID = .taskConfigTagIDAutofillStatusOperation
        } else if cmd == 0x3f {
            // Configure device UTC time
            operationID = .taskConfigDeviceTimeOperation
        } else if cmd == 0x40 {
            // Configure temperature/humidity storage parameters
            operationID = .taskConfigTHDataStoreStatusOperation
        } else if cmd == 0x41 {
            // Configure temperature/humidity sampling rate
            operationID = .taskConfigTHSamplingRateOperation
        } else if cmd == 0x42 {
            // Clear temperature/humidity historical data
            operationID = .taskDeleteBXPRecordHTDatasOperation
        } else if cmd == 0x61 {
            // Remote reminder
            operationID = .taskConfigRemoteReminderLEDNotiParamsOperation
        } else if cmd == 0x62 {
            // Configure remote buzzer
            operationID = .taskConfigRemoteReminderBuzzerNotiParamsOperation
        } else if cmd == 0x63 {
            // Configure buzzer frequency
            operationID = .taskConfigRemoteReminderBuzzerFrequencyOperation
        } else if cmd == 0x65 {
            // Configure trigger LED reminder status
            operationID = .taskConfigTriggerLEDIndicatorStatusOperation
        } else if cmd == 0x68 {
            // Clear hall sensor trigger count
            operationID = .taskClearHallTriggerCountOperation
        } else if cmd == 0x69 {
            // Clear motion trigger count
            operationID = .taskClearMotionTriggerCountOperation
        } else if cmd == 0x6b {
            // Configure battery capacity
            operationID = .taskConfigBatteryResetOperation
        } else if cmd == 0x6c {
            // Configure battery percentage/voltage value
            operationID = .taskConfigBatteryADVModeOperation
        } else if cmd == 0x24 {
            // Configure post-trigger channel broadcast parameters
            operationID = .taskConfigTriggeredSlotParamOperation
        } else if cmd == 0x26 {
            // Power off
            operationID = .taskPowerOffOperation
        } else if cmd == 0x28 {
            // Factory reset
            operationID = .taskFactoryResetOperation
        } else if cmd == 0x6d {
            // Configure hall record switch status
            operationID = .taskConfigHallDataStoreStatusOperation
        } else if cmd == 0x6f {
            // Clear hall sensor historical data
            operationID = .taskClearHallHistoryDataOperation
        }
        
        return dataParserGetDataSuccess(["success": success], operationID: operationID)
    }
    
    private static func parseHallSensorData(_ readData: Data) -> [String: Any] {
        guard readData.count >= 4 else { return [:] }
        
        if readData[0] != 0xeb {
            return [:]
        }
                
        let content = readData.subdata(in: 4..<readData.count)
        
        // Non-fragmented protocol
        if readData[1] != 0x00 {
            // Read
            return [:]
        }
        
        var operationID: MKSFBXSTaskOperationID = .defaultTaskOperationID
        var resultDic: [String: Any] = [:]
        
        if readData[2] == 0x90 {
            // Read hall sensor status
            operationID = .taskReadMagnetStatusOperation
            resultDic = ["moved": content[0] == 0x01]
        }
        
        return dataParserGetDataSuccess(resultDic, operationID: operationID)
    }
    
    private static func parseMultiPacketData(_ content: Data) -> [String: Any] {
        if content[1] == 0x00 {
            // Read
            let totalNum = MKSwiftBleSDKAdopter.getDecimalFromData(content, range: 3..<5)
            let index = MKSwiftBleSDKAdopter.getDecimalFromData(content, range: 5..<7)
            
            var operationID: MKSFBXSTaskOperationID = .defaultTaskOperationID
            
            
            let resultDic: [String: Any] = [
                mk_bxs_swf_totalNumKey: totalNum,
                mk_bxs_swf_totalIndexKey: index,
                mk_bxs_swf_contentKey: content.subdata(in: 8..<content.count)
            ]
            
            if content[1] == 0x6e {
                // Read hall sensor historical data
                operationID = .taskReadHallHistoryDataOperation
            }
            
            return dataParserGetDataSuccess(resultDic, operationID: operationID)
        }
        
        return [:]
    }
    
    // MARK: - Helper Methods
    
    private static func dataParserGetDataSuccess(_ returnData: [String: Any], operationID: MKSFBXSTaskOperationID) -> [String: Any] {
        if returnData.isEmpty {
            return [:]
        }
        return [
            "returnData": returnData,
            "operationID": operationID.rawValue
        ]
    }
}
