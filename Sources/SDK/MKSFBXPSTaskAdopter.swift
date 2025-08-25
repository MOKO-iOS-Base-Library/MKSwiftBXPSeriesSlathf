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
        let readData = characteristic.value
        let result = MKSwiftBleSDKAdopter.hexStringFromData(readData!)
        print("+++++\(characteristic.uuid.uuidString)-----\(result)")
        
        if characteristic.uuid == CBUUID(string: "AA01") {
            return parseCustomData(readData)
        }
        if characteristic.uuid == CBUUID(string: "AA04") {
            // Password related
            return parsePasswordData(readData)
        }
        if characteristic.uuid == CBUUID(string: "AA06") {
            // Temperature/Humidity related
            return parseHTData(readData)
        }
        if characteristic.uuid == CBUUID(string: "AA08") {
            // Hall sensor related
            return parseHallSensorData(readData)
        }
        
        return [:]
    }
    
    static func parseWriteData(with characteristic: CBCharacteristic) -> [String: Any] {
        return [:]
    }
    
    // MARK: - Data Parsing
    
    private static func parseHTData(_ readData: Data?) -> [String: Any] {
        guard let readData = readData else {
            return [:]
        }
        
        let readString = MKSwiftBleSDKAdopter.hexStringFromData(readData)
        guard readString.count >= 8 else { return [:] }
            
        let header = readString.bleSubstring(from: 0, length: 2)
        if header != "eb" {
            return [:]
        }
        
        let dataLen = MKSwiftBleSDKAdopter.getDecimalWithHex(readString, range: NSRange(location: 6, length: 2))
        
        if readData.count != dataLen + 4 {
            return [:]
        }
        
        let flag = readString.bleSubstring(from: 2, length: 2)
        let cmd = readString.bleSubstring(from: 4, length: 2)
        let content: String = readString.bleSubstring(from: 8, length: dataLen * 2)
        
        // Non-fragmented protocol
        if flag == "00" {
            // Read
            return parseHTReadData(content, cmd: cmd, data: readData)
        }
        if flag == "01" {
            return parseHTConfigData(content, cmd: cmd)
        }
        
        return [:]
    }
    
    private static func parseHTReadData(_ content: String, cmd: String, data: Data) -> [String: Any] {
        var operationID: MKSFBXSTaskOperationID = .defaultTaskOperationID
        var resultDic: [String: Any] = [:]
        
        if cmd == "70" {
            // Read real-time temperature/humidity data
            operationID = .taskReadTemperatureHumidityDataOperation
            
            let tempTemp = MKSwiftBleSDKAdopter.signedHexTurnString((content.bleSubstring(from: 0, length: 4))).intValue
            let tempHui = MKSwiftBleSDKAdopter.getDecimalWithHex(content, range: NSRange(location: 4, length: 4))
            
            let temperature = String(format: "%.1f", Double(tempTemp) * 0.1)
            let humidity = String(format: "%.1f", Double(tempHui) * 0.1)
            
            resultDic = [
                "temperature": temperature,
                "humidity": humidity
            ]
        }
        
        return dataParserGetDataSuccess(resultDic, operationID: operationID)
    }
    
    private static func parseHTConfigData(_ content: String, cmd: String) -> [String: Any] {
        var operationID: MKSFBXSTaskOperationID = .defaultTaskOperationID
        let success = content == "aa"
        
        if cmd == "51" {
            // Verify password
            operationID = .connectPasswordOperation
        } else if cmd == "52" {
            // Change password
            operationID = .taskConfigConnectPasswordOperation
        } else if cmd == "53" {
            // Whether password verification is needed
            operationID = .taskConfigPasswordVerificationOperation
        }
        
        return dataParserGetDataSuccess(["success": success], operationID: operationID)
    }
    
    private static func parsePasswordData(_ readData: Data?) -> [String: Any] {
        guard let readData = readData else {return [:]}
            
        let readString = MKSwiftBleSDKAdopter.hexStringFromData(readData)
        guard readString.count >= 8 else { return [:] }
            
        let header = readString.bleSubstring(from: 0, length: 2)
        if header != "eb" {
            return [:]
        }
        
        let dataLen = MKSwiftBleSDKAdopter.getDecimalWithHex(readString, range: NSRange(location: 6, length: 2))
        
        if readData.count != dataLen + 4 {
            return [:]
        }
        
        let flag = readString.bleSubstring(from: 2, length: 2)
        let cmd = readString.bleSubstring(from: 4, length: 2)
        let content: String = readString.bleSubstring(from: 8, length: dataLen * 2)
        
        // Non-fragmented protocol
        if flag == "00" {
            // Read
            return parsePasswordReadData(content, cmd: cmd, data: readData)
        }
        if flag == "01" {
            return parsePasswordConfigData(content, cmd: cmd)
        }
        
        return [:]
    }
    
    private static func parsePasswordReadData(_ content: String, cmd: String, data: Data) -> [String: Any] {
        var operationID: MKSFBXSTaskOperationID = .defaultTaskOperationID
        var resultDic: [String: Any] = [:]
        
        if cmd == "53" {
            // Read if device connection requires password
            operationID = .taskReadNeedPasswordOperation
            resultDic = ["state": content]
        }
        
        return dataParserGetDataSuccess(resultDic, operationID: operationID)
    }
    
    private static func parsePasswordConfigData(_ content: String, cmd: String) -> [String: Any] {
        var operationID: MKSFBXSTaskOperationID = .defaultTaskOperationID
        let success = content == "aa"
        
        if cmd == "51" {
            // Verify password
            operationID = .connectPasswordOperation
        } else if cmd == "52" {
            // Change password
            operationID = .taskConfigConnectPasswordOperation
        } else if cmd == "53" {
            // Whether password verification is needed
            operationID = .taskConfigPasswordVerificationOperation
        }
        
        return dataParserGetDataSuccess(["success": success], operationID: operationID)
    }
    
    private static func parseCustomData(_ readData: Data?) -> [String: Any] {
        
        guard let readData = readData else {return [:]}
            
        let readString = MKSwiftBleSDKAdopter.hexStringFromData(readData)
        guard readString.count >= 8 else { return [:] }
            
        let header = readString.bleSubstring(from: 0, length: 2)
        if header == "ec" {
            // Multi-packet data
            return parseMultiPacketData(readString)
        }
        if header != "eb" {
            return [:]
        }
        
        let dataLen = MKSwiftBleSDKAdopter.getDecimalWithHex(readString, range: NSRange(location: 6, length: 2))
        
        if readData.count != dataLen + 4 {
            return [:]
        }
        
        let flag = readString.bleSubstring(from: 2, length: 2)
        let cmd = readString.bleSubstring(from: 4, length: 2)
        let content: String = readString.bleSubstring(from: 8, length: dataLen * 2)
                
        // Non-fragmented protocol
        if flag == "00" {
            // Read
            return parseCustomReadData(content, cmd: cmd, data: readData)
        }
        if flag == "01" {
            return parseCustomConfigData(content, cmd: cmd)
        }
        
        return [:]
    }
    
    private static func parseCustomReadData(_ content: String, cmd: String, data: Data) -> [String: Any] {
        var operationID:MKSFBXSTaskOperationID = .defaultTaskOperationID
        var resultDic: [String: Any] = [:]
        
        if cmd == "20" {
            // Read MAC address
            operationID = .taskReadMacAddressOperation
            let macParts = [
                content.bleSubstring(from: 0, length: 2),
                content.bleSubstring(from: 2, length: 2),
                content.bleSubstring(from: 4, length: 2),
                content.bleSubstring(from: 6, length: 2),
                content.bleSubstring(from: 8, length: 2),
                content.bleSubstring(from: 10, length: 2)
            ]
            let macAddress = macParts.joined(separator: ":").uppercased()
            resultDic = ["macAddress": macAddress]
        } else if cmd == "21" {
            // Read three-axis sensor parameters
            operationID = .taskReadThreeAxisDataParamsOperation
            resultDic = [
                "samplingRate":content.bleSubstring(from: 0, length: 2),
                "gravityReference":content.bleSubstring(from: 2, length: 2),
                "motionThreshold":MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 4, length: 2))
            ]
        } else if cmd == "23" {
            // Read button reset function
            operationID = .taskReadResetDeviceByButtonStatusOperation
            resultDic = ["isOn": content == "01"]
        } else if cmd == "25" {
            // Read hall power on/off function
            operationID = .taskReadHallSensorStatusOperation
            resultDic = ["isOn": content == "01"]
        } else if cmd == "29" {
            // Firmware
            operationID = .taskReadFirmwareOperation
            let subData = data.subdata(in: 4..<data.count)
            if let firmwareString = String(data: subData, encoding: .utf8) {
                resultDic = ["firmware": firmwareString]
            }
        } else if cmd == "2a" {
            // Manufacturer
            operationID = .taskReadManufacturerOperation
            let subData = data.subdata(in: 4..<data.count)
            if let manufacturerString = String(data: subData, encoding: .utf8) {
                resultDic = ["manufacturer": manufacturerString]
            }
        } else if cmd == "2b" {
            // Production date
            operationID = .taskReadProductDateOperation
            let year = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 0, length: 4))
            var month = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 4, length: 2))
            if month.count == 1 {
                month = "0" + month
            }
            var day = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 6, length: 2))
            if day.count == 1 {
                day = "0" + day
            }
            resultDic = ["productionDate": "\(year)/\(month)/\(day)"]
        } else if cmd == "2c" {
            // Software
            operationID = .taskReadSoftwareOperation
            let subData = data.subdata(in: 4..<data.count)
            if let softwareString = String(data: subData, encoding: .utf8) {
                resultDic = ["software": softwareString]
            }
        } else if cmd == "2d" {
            // Hardware
            operationID = .taskReadHardwareOperation
            let subData = data.subdata(in: 4..<data.count)
            if let hardwareString = String(data: subData, encoding: .utf8) {
                resultDic = ["hardware": hardwareString]
            }
        } else if cmd == "2e" {
            // Product model
            operationID = .taskReadDeviceModelOperation
            let subData = data.subdata(in: 4..<data.count)
            if let modelString = String(data: subData, encoding: .utf8) {
                resultDic = ["modeID": modelString]
            }
        } else if cmd == "30" {
            // Read broadcast channel type
            operationID = .taskReadSlotTypeOperation
            let slot1 = content.bleSubstring(from: 0, length: 2)
            let slot2 = content.bleSubstring(from: 2, length: 2)
            let slot3 = content.bleSubstring(from: 4, length: 2)
            resultDic = ["slotList": [slot1, slot2, slot3]]
        } else if cmd == "31" {
            // Read channel trigger type
            operationID = .taskReadSlotTriggerDataOperation
            resultDic = MKSwiftBXPSSDKDataAdopter.parseSlotTriggerParam(content)
        } else if cmd == "32" {
            // Read pre-trigger broadcast parameters
            operationID = .taskReadBeforeTriggerSlotDataOperation
            resultDic = MKSwiftBXPSSDKDataAdopter.parseSlotData(content, advData: data, hasStandbyDuration: true)
        } else if cmd == "33" {
            // Read trigger broadcast parameters
            operationID = .taskReadTriggerSlotDataOperation
            resultDic = MKSwiftBXPSSDKDataAdopter.parseSlotData(content, advData: data, hasStandbyDuration: false)
        } else if cmd == "34" {
            // Read channel broadcast content
            operationID = .taskReadSlotDataOperation
            resultDic = MKSwiftBXPSSDKDataAdopter.parseSlotData(content, advData: data, hasStandbyDuration: true)
        } else if cmd == "35" {
            // Read low battery percentage reminder function and alarm threshold
            operationID = .taskReadADVChannelOperation
            let channel = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 0, length: content.count))
            resultDic = ["channel": channel]
        } else if cmd == "36" {
            // Read AOA CTE broadcast frame status
            operationID = .taskReadDirectionFindingStatusOperation
            resultDic = ["isOn": content == "01"]
        } else if cmd == "37" {
            // Read connectable status
            operationID = .taskReadConnectableOperation
            resultDic = ["connectable": content == "01"]
        } else if cmd == "3c" {
            // Read Tag ID auto-fill status
            operationID = .taskTagIDAutofillStatusOperation
            resultDic = ["isOn": content == "01"]
        } else if cmd == "3e" {
            // Read system runtime
            operationID = .taskDeviceRuntimeOperation
            let time = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 0, length: content.count))
            resultDic = ["time": time]
        } else if cmd == "3f" {
            // Read device current UTC timestamp
            operationID = .taskReadDeviceUTCTimeOperation
            let timestamp = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 0, length: content.count))
            resultDic = ["timestamp": timestamp]
        } else if cmd == "40" {
            // Read temperature/humidity data storage switch status
            operationID = .taskReadTHDataStoreStatusOperation
            let isOn = content.bleSubstring(from: 0, length: 2) == "01"
            let interval = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 2, length: 4))
            resultDic = [
                "isOn": isOn,
                "interval": interval
            ]
        } else if cmd == "41" {
            // Read temperature/humidity sampling rate
            operationID = .taskReadTHSamplingRateOperation
            let count = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 0, length: content.count))
            resultDic = ["samplingRate": count]
        } else if cmd == "43" {
            // Read temperature/humidity historical data total count
            operationID = .taskReadHTRecordTotalNumbersOperation
            let count = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 0, length: content.count))
            resultDic = ["count": count]
        } else if cmd == "68" {
            // Read hall sensor trigger count
            operationID = .taskReadHallTriggerCountOperation
            let count = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 0, length: content.count))
            resultDic = ["count": count]
        } else if cmd == "69" {
            // Read motion trigger count
            operationID = .taskReadMotionTriggerCountOperation
            let count = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 0, length: content.count))
            resultDic = ["count": count]
        } else if cmd == "6a" {
            // Read battery voltage
            operationID = .taskReadBatteryVoltageOperation
            let voltage = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 0, length: content.count))
            resultDic = ["voltage": voltage]
        } else if cmd == "6b" {
            // Read battery remaining percentage
            operationID = .taskReadBatteryPercentageOperation
            let percentage = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 0, length: content.count))
            resultDic = ["percentage": percentage]
        } else if cmd == "4a" {
            // Read sensor model
            operationID = .taskReadSensorTypeOperation
            let axis = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 0, length: 2))
            let tempHumidity = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 2, length: 2))
            let lightSensor = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 4, length: 2))
            let pir = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 6, length: 2))
            let tof = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 8, length: 2))
            resultDic = [
                "axis": axis,
                "tempHumidity": tempHumidity,
                "lightSensor": lightSensor,
                "pir": pir,
                "tof": tof
            ]
        } else if cmd == "63" {
            // Read buzzer frequency
            operationID = .taskReadRemoteReminderBuzzerFrequencyOperation
            let frequency = MKSwiftBleSDKAdopter.getDecimalWithHex(content, range: NSRange(location: 0, length: 2))
            resultDic = ["frequency": frequency == 4500 ? "1" : "0"]
        } else if cmd == "65" {
            // Read trigger LED reminder status
            operationID = .taskReadTriggerLEDIndicatorStatusOperation
            resultDic = ["isOn": content == "01"]
        } else if cmd == "6c" {
            // Read battery percentage/voltage value
            operationID = .taskReadBatteryADVModeOperation
            let mode = MKSwiftBleSDKAdopter.getDecimalWithHex(content, range: NSRange(location: 0, length: 2))
            resultDic = ["mode": "\(mode - 1)"]
        } else if cmd == "24" {
            // Read post-trigger channel broadcast parameters
            operationID = .taskReadTriggeredSlotParamsOperation
            let slotIndex = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 0, length: 2))
            let advInterval = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 2, length: 4))
            let advDuration = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 6, length: 4))
            let rssi = MKSwiftBleSDKAdopter.signedHexTurnString(content.bleSubstring(from: 10, length: 2))
            let txPowerString = MKSwiftBXPSSDKDataAdopter.fetchTxPowerValueString(content.bleSubstring(from: 12, length: 2))
            let txPower = MKSwiftBXPSSDKDataAdopter.fetchTxPowerValueString(txPowerString)
            resultDic = [
                "slotIndex": slotIndex,
                "advInterval": advInterval,
                "advDuration": advDuration,
                "rssi": "\(rssi)",
                "txPower": txPower
            ]
        } else if cmd == "2f" {
            // Read device type
            operationID = .taskReadDeviceTypeOperation
            let chipType = content.bleSubstring(from: 0, length: 2)
            let binary = MKSwiftBleSDKAdopter.binaryByhex(content.bleSubstring(from: 2, length: 2))
            
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
        } else if cmd == "6c" {
            // Read all channel broadcast types
            operationID = .taskReadSlotAdvTypeOperation
            var typeList: [String] = []
            for i in 0..<6 {
                let start = content.index(content.startIndex, offsetBy: i * 2)
                let end = content.index(start, offsetBy: 2)
                typeList.append(String(content[start..<end]))
            }
            resultDic = ["typeList": typeList]
        } else if cmd == "6d" {
            // Read hall record switch
            operationID = .taskReadHallDataStoreStatusOperation
            resultDic = ["isOn": content == "01"]
        }
        
        return dataParserGetDataSuccess(resultDic, operationID: operationID)
    }
    
    private static func parseCustomConfigData(_ content: String, cmd: String) -> [String: Any] {
        var operationID = MKSFBXSTaskOperationID.defaultTaskOperationID
        let success = content == "aa"
        
        if cmd == "01" {
            // No operation
        } else if cmd == "21" {
            // Configure three-axis sensor parameters
            operationID = .taskConfigThreeAxisDataParamsOperation
        } else if cmd == "23" {
            // Configure button reset function
            operationID = .taskConfigResetDeviceByButtonStatusOperation
        } else if cmd == "25" {
            // Configure hall power on/off status
            operationID = .taskConfigHallSensorStatusOperation
        } else if cmd == "31" {
            // Configure trigger parameters
            operationID = .taskConfigSlotTriggerParamsOperation
        } else if cmd == "32" {
            // Configure pre-trigger broadcast parameters
            operationID = .taskConfigBeforeTriggerSlotDataOperation
        } else if cmd == "33" {
            // Configure trigger broadcast parameters
            operationID = .taskConfigTriggerSlotDataOperation
        } else if cmd == "34" {
            // Configure pre-trigger channel broadcast content
            operationID = .taskConfigSlotDataOperation
        } else if cmd == "35" {
            // Configure broadcast channel enable
            operationID = .taskConfigADVChannelOperation
        } else if cmd == "36" {
            // Configure AOA CTE broadcast frame
            operationID = .taskConfigDirectionFindingStatusOperation
        } else if cmd == "37" {
            // Configure connectable status
            operationID = .taskConfigConnectableOperation
        } else if cmd == "3c" {
            // Configure Tag ID auto-fill status
            operationID = .taskConfigTagIDAutofillStatusOperation
        } else if cmd == "3f" {
            // Configure device UTC time
            operationID = .taskConfigDeviceTimeOperation
        } else if cmd == "40" {
            // Configure temperature/humidity storage parameters
            operationID = .taskConfigTHDataStoreStatusOperation
        } else if cmd == "41" {
            // Configure temperature/humidity sampling rate
            operationID = .taskConfigTHSamplingRateOperation
        } else if cmd == "42" {
            // Clear temperature/humidity historical data
            operationID = .taskDeleteBXPRecordHTDatasOperation
        } else if cmd == "61" {
            // Remote reminder
            operationID = .taskConfigRemoteReminderLEDNotiParamsOperation
        } else if cmd == "62" {
            // Configure remote buzzer
            operationID = .taskConfigRemoteReminderBuzzerNotiParamsOperation
        } else if cmd == "63" {
            // Configure buzzer frequency
            operationID = .taskConfigRemoteReminderBuzzerFrequencyOperation
        } else if cmd == "65" {
            // Configure trigger LED reminder status
            operationID = .taskConfigTriggerLEDIndicatorStatusOperation
        } else if cmd == "68" {
            // Clear hall sensor trigger count
            operationID = .taskClearHallTriggerCountOperation
        } else if cmd == "69" {
            // Clear motion trigger count
            operationID = .taskClearMotionTriggerCountOperation
        } else if cmd == "6b" {
            // Configure battery capacity
            operationID = .taskConfigBatteryResetOperation
        } else if cmd == "6c" {
            // Configure battery percentage/voltage value
            operationID = .taskConfigBatteryADVModeOperation
        } else if cmd == "24" {
            // Configure post-trigger channel broadcast parameters
            operationID = .taskConfigTriggeredSlotParamOperation
        } else if cmd == "26" {
            // Power off
            operationID = .taskPowerOffOperation
        } else if cmd == "28" {
            // Factory reset
            operationID = .taskFactoryResetOperation
        } else if cmd == "6d" {
            // Configure hall record switch status
            operationID = .taskConfigHallDataStoreStatusOperation
        } else if cmd == "6f" {
            // Clear hall sensor historical data
            operationID = .taskClearHallHistoryDataOperation
        }
        
        return dataParserGetDataSuccess(["success": success], operationID: operationID)
    }
    
    private static func parseHallSensorData(_ readData: Data?) -> [String: Any] {
        guard let readData = readData else {return [:]}
            
        let readString = MKSwiftBleSDKAdopter.hexStringFromData(readData)
        guard readString.count >= 8 else { return [:] }
            
        let header = readString.bleSubstring(from: 0, length: 2)
        
        if header != "eb" {
            return [:]
        }
        
        let dataLen = MKSwiftBleSDKAdopter.getDecimalWithHex(readString, range: NSRange(location: 6, length: 2))
        
        if readData.count != dataLen + 4 {
            return [:]
        }
        
        let flag = readString.bleSubstring(from: 2, length: 2)
        let cmd = readString.bleSubstring(from: 4, length: 2)
        let content: String = readString.bleSubstring(from: 8, length: dataLen * 2)
        
        // Non-fragmented protocol
        if flag != "00" {
            // Read
            return [:]
        }
        
        var operationID: MKSFBXSTaskOperationID = .defaultTaskOperationID
        var resultDic: [String: Any] = [:]
        
        if cmd == "90" {
            // Read hall sensor status
            operationID = .taskReadMagnetStatusOperation
            resultDic = ["moved": content == "01"]
        }
        
        return dataParserGetDataSuccess(resultDic, operationID: operationID)
    }
    
    private static func parseMultiPacketData(_ content: String) -> [String: Any] {
        if content.count < 8 {
            return [:]
        }
        
        let flag = content.bleSubstring(from: 2, length: 2)
        let cmd = content.bleSubstring(from: 4, length: 2)
        
        if flag == "00" {
            // Read
            if content.count < 16 {
                return [:]
            }
            
            let totalNum = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 6, length: 4))
            let index = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 10, length: 4))
            
            var operationID: MKSFBXSTaskOperationID = .defaultTaskOperationID
            
            
            let resultDic: [String: Any] = [
                mk_bxs_swf_totalNumKey: totalNum,
                mk_bxs_swf_totalIndexKey: index,
                mk_bxs_swf_contentKey: content.substring(from: 16, length: (content.count - 16))
            ]
            
            if cmd == "6e" {
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
