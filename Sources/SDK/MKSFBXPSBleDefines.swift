//
//  File.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/6/17.
//

import Foundation

import CoreBluetooth

import MKSwiftBleModule

// MARK: - Beacon Types
public enum MKSFBXSDataFrameType: Int {
    case uid
    case url
    case tlm
    case sensorInfo
    case beacon
    case productionTest
    case ota
    case unknown
}

public class MKSFBXSBaseBeacon: @unchecked Sendable {
    public var frameType: MKSFBXSDataFrameType = .unknown
    public var rssi: NSNumber = 0
    public var connectEnable: Bool = false
    public var identifier: String?
    public var peripheral: CBPeripheral?
    public var advertiseData: Data?
    public var deviceName: String?
    
    public class func parseAdvData(_ advData: MKBleAdvInfo) -> [MKSFBXSBaseBeacon] {
        guard let advDic = advData.serviceData else {
            return []
        }
        
        var beaconList: [MKSFBXSBaseBeacon] = []
        
        for (key, value) in advDic {
            if key == CBUUID(string: "FEAA") {
                let frameType = fetchFEAAFrameType(value)
                if let beacon = fetchBaseBeacon(with: frameType, advData: value) {
                    beaconList.append(beacon)
                }
            } else if key == CBUUID(string: "FEAB") {
                let frameType = fetchFEABFrameType(value)
                if let beacon = fetchBaseBeacon(with: frameType, advData: value) {
                    if let iBeacon = beacon as? MKSFBXSiBeacon {
                        if let txPower = advData.txPowerLevel {
                            iBeacon.txPower = NSNumber(value: txPower)
                        }
                    }
                    beaconList.append(beacon)
                }
            } else if key == CBUUID(string: "EA01") {
                let frameType = fetchEA01FrameType(value)
                if let beacon = fetchBaseBeacon(with: frameType, advData: value) {
                    beaconList.append(beacon)
                }
            } else if key == CBUUID(string: "EB01") {
                let frameType = fetchEB01FrameType(value)
                if let beacon = fetchBaseBeacon(with: frameType, advData: value) {
                    beaconList.append(beacon)
                }
            }
        }
        
        return beaconList
    }
    
    public class func fetchBaseBeacon(with frameType: MKSFBXSDataFrameType, advData: Data) -> MKSFBXSBaseBeacon? {
        var beacon: MKSFBXSBaseBeacon?
        
        switch frameType {
        case .uid:
            beacon = MKSFBXSUIDBeacon(advData)
        case .url:
            beacon = MKSFBXSURLBeacon(advData)
        case .tlm:
            beacon = MKSFBXSTLMBeacon(advData)
        case .sensorInfo:
            beacon = MKSFBXSSensorInfoBeacon(advData)
        case .beacon:
            beacon = MKSFBXSiBeacon(advData)
        case .productionTest:
            beacon = MKSFBXSProductionTestBeacon(advData)
        case .ota:
            beacon = MKSFBXSOTABeacon()
        case .unknown:
            return nil
        }
        
        beacon?.advertiseData = advData
        beacon?.frameType = frameType
        return beacon
    }
    
    public class func parseDataType(with slotData: Data) -> MKSFBXSDataFrameType {
        if slotData.isEmpty {
            return .unknown
        }
        
        let bytes = [UInt8](slotData)
        switch bytes[0] {
        case 0x00: return .uid
        case 0x10: return .url
        case 0x20: return .tlm
        case 0x80: return .sensorInfo
        case 0x50: return .beacon
        default: return .unknown
        }
    }
    
    // MARK: - Private Frame Type Detection
    private class func fetchFEAAFrameType(_ data: Data) -> MKSFBXSDataFrameType {
        if data.isEmpty { return .unknown }
        let bytes = [UInt8](data)
        switch bytes[0] {
        case 0x00: return .uid
        case 0x10: return .url
        case 0x20: return .tlm
        default: return .unknown
        }
    }
    
    private class func fetchFEABFrameType(_ data: Data) -> MKSFBXSDataFrameType {
        if data.isEmpty { return .unknown }
        let bytes = [UInt8](data)
        switch bytes[0] {
        case 0x50: return .beacon
        default: return .unknown
        }
    }
    
    private class func fetchEA01FrameType(_ data: Data) -> MKSFBXSDataFrameType {
        if data.isEmpty { return .unknown }
        let bytes = [UInt8](data)
        switch bytes[0] {
        case 0x80: return .sensorInfo
        default: return .unknown
        }
    }
    
    private class func fetchEB01FrameType(_ data: Data) -> MKSFBXSDataFrameType {
        if data.isEmpty { return .unknown }
        let bytes = [UInt8](data)
        switch bytes[0] {
        case 0x90: return .productionTest
        default: return .unknown
        }
    }
}

// MARK: - Beacon Subclasses
public class MKSFBXSUIDBeacon: MKSFBXSBaseBeacon, @unchecked Sendable {
    public var txPower: NSNumber = NSNumber(value: 0)
    public var namespaceId: String = ""
    public var instanceId: String = ""
    
    public init?(_ advData: Data) {
        super.init()
        if advData.count < 18 { return nil }
        
        let bytes = [UInt8](advData)
        txPower = bytes[1] & 0x80 != 0 ? NSNumber(value: Int8(bitPattern: bytes[1])) : NSNumber(value: bytes[1])
        
        namespaceId = (2...11).map { String(format: "%02x", bytes[$0]) }.joined()
        instanceId = (12...17).map { String(format: "%02x", bytes[$0]) }.joined()
    }
}

public class MKSFBXSURLBeacon: MKSFBXSBaseBeacon, @unchecked Sendable {
    public var txPower: NSNumber = NSNumber(value: 0)
    public var shortUrl: String = ""
    
    public init?(_ advData: Data) {
        super.init()
        if advData.count < 3 { return nil }
        
        let bytes = [UInt8](advData)
        txPower = bytes[1] & 0x80 != 0 ? NSNumber(value: Int8(bitPattern: bytes[1])) : NSNumber(value: bytes[1])
        
        let urlScheme = MKSwiftBXPSSDKDataAdopter.getUrlscheme(hexChar: CChar(bytes[2]))
        var url = urlScheme
        
        for i in 3..<advData.count {
            url += MKSwiftBXPSSDKDataAdopter.getUrlscheme(hexChar: CChar(bytes[i]))
        }
        
        shortUrl = url
    }
}

public class MKSFBXSTLMBeacon: MKSFBXSBaseBeacon, @unchecked Sendable {
    public var version: NSNumber = NSNumber(value: 0)
    public var mvPerbit: NSNumber = NSNumber(value: 0)
    public var temperature: NSNumber = NSNumber(value: 0)
    public var advertiseCount: NSNumber = NSNumber(value: 0)
    public var deciSecondsSinceBoot: NSNumber = NSNumber(value: 0)
    
    public init?(_ advData: Data) {
        super.init()
        if advData.count < 14 { return nil }
        
        let bytes = [UInt8](advData)
        version = NSNumber(value: bytes[1])
        mvPerbit = NSNumber(value: (Int(bytes[2]) << 8) + Int(bytes[3]))
        
        let tempInt = bytes[4]
        temperature = NSNumber(value: tempInt & 0x80 != 0 ?
            Float(Int8(bitPattern: tempInt)) + Float(bytes[5]) / 256.0 :
            Float(tempInt) + Float(bytes[5]) / 256.0)
        
        let count = (Int(bytes[6]) << 24) + (Int(bytes[7]) << 16) + (Int(bytes[8]) << 8) + Int(bytes[9])
        advertiseCount = NSNumber(value: count)
        
        let seconds = (Int(bytes[10]) << 24) + (Int(bytes[11]) << 16) + (Int(bytes[12]) << 8) + Int(bytes[13])
        deciSecondsSinceBoot = NSNumber(value: Float(seconds) / 10.0)
    }
}

public class MKSFBXSSensorInfoBeacon: MKSFBXSBaseBeacon, @unchecked Sendable {
    public var magnetStatus: Bool = false
    public var moved: Bool = false
    public var triaxialSensor: Bool = false
    public var tempSensor: Bool = false
    public var humiditySensor: Bool = false
    public var flash: Bool = false
    public var hallSensorCount: String = ""
    public var movedCount: String = ""
    public var xData: String = ""
    public var yData: String = ""
    public var zData: String = ""
    public var temperature: String = ""
    public var humidity: String = ""
    public var battery: String = ""
    public var tagID: String = ""
    
    public init?(_ advData: Data) {
        super.init()
        if advData.count < 16 { return nil }
        
//        var content = MKSwiftBleSDKAdopter.hexStringFromData(advData)
//        content = content.bleSubstring(from: 2, length: (content.count - 2))
        var index = 1
        let state = MKSwiftBleSDKAdopter.hexStringFromData(advData.subdata(in: index..<(index + 1)))
        let binary = MKSwiftBleSDKAdopter.binaryByhex(state)
        index += 1
        
        magnetStatus = (binary.bleSubstring(from: 7, length: 1) == "1")
        moved = (binary.bleSubstring(from: 6, length: 1) == "1")
        triaxialSensor = (binary.bleSubstring(from: 5, length: 1) == "1")
        tempSensor = (binary.bleSubstring(from: 4, length: 1) == "1")
        humiditySensor = (binary.bleSubstring(from: 3, length: 1) == "1")
        flash = (binary.bleSubstring(from: 2, length: 1) == "1")
        
        hallSensorCount = MKSwiftBleSDKAdopter.getDecimalStringFromData(advData, range: index..<(index + 2))
        index += 2
        
        movedCount = MKSwiftBleSDKAdopter.getDecimalStringFromData(advData, range: index..<(index + 2))
        index += 2
        
        let tempXData = MKSwiftBleSDKAdopter.signedDataTurnToInt(advData.subdata(in: index..<(index + 2)))
        xData = "\(tempXData)"
        index += 2
        
        let tempYData = MKSwiftBleSDKAdopter.signedDataTurnToInt(advData.subdata(in: index..<(index + 2)))
        yData = "\(tempYData)"
        index += 2
        
        let tempZData = MKSwiftBleSDKAdopter.signedDataTurnToInt(advData.subdata(in: index..<(index + 2)))
        zData = "\(tempZData)"
        index += 2
        
        let tempNumber = MKSwiftBleSDKAdopter.signedDataTurnToInt(advData.subdata(in: index..<(index + 2)))
        temperature = String(format: "%.1f", Double(tempNumber) * 0.1)
        index += 2
        
        let humidityNumber = MKSwiftBleSDKAdopter.getDecimalFromData(advData, range: index..<(index + 2))
        humidity = String(format: "%.1f", Double(humidityNumber) * 0.1)
        index += 2
        
        battery = MKSwiftBleSDKAdopter.getDecimalStringFromData(advData, range: index..<(index + 2))
        index += 2
        
        tagID = MKSwiftBleSDKAdopter.hexStringFromData(advData.subdata(in: index..<advData.count))
    }
}

public class MKSFBXSiBeacon: MKSFBXSBaseBeacon, @unchecked Sendable {
    public var rssi1M: NSNumber = NSNumber(value: 0)
    public var txPower: NSNumber = NSNumber(value: 0)
    public var interval: String = ""
    public var major: String = ""
    public var minor: String = ""
    public var uuid: String = ""
    
    public init?(_ advData: Data) {
        super.init()
        if advData.count < 7 { return nil }
        
        let bytes = [UInt8](advData.prefix(2))
        rssi1M = bytes[1] & 0x80 != 0 ? NSNumber(value: Int8(bitPattern: bytes[1])) : NSNumber(value: bytes[1])
        
        let content = MKSwiftBleSDKAdopter.hexStringFromData(advData)
        let temp = content.bleSubstring(from: 4, length: content.count - 4)
        
        interval = MKSwiftBleSDKAdopter.getDecimalStringWithHex(temp, range: NSRange(location: 0, length: 2))
        
        var uuidParts = [
            temp.bleSubstring(from: 2, length: 8),
            temp.bleSubstring(from: 10, length: 4),
            temp.bleSubstring(from: 14, length: 4),
            temp.bleSubstring(from: 18, length: 4),
            temp.bleSubstring(from: 22, length: 12)
        ]
        
        uuidParts.insert("-", at: 1)
        uuidParts.insert("-", at: 3)
        uuidParts.insert("-", at: 5)
        uuidParts.insert("-", at: 7)
        
        uuid = uuidParts.joined().uppercased()
        major = MKSwiftBleSDKAdopter.getDecimalStringWithHex(temp, range: NSRange(location: 34, length: 4))
        minor = MKSwiftBleSDKAdopter.getDecimalStringWithHex(temp, range: NSRange(location: 38, length: 4))
    }
}

public class MKSFBXSProductionTestBeacon: MKSFBXSBaseBeacon, @unchecked Sendable {
    public var battery: String = ""
    public var macAddress: String = ""
    
    public init?(_ advData: Data) {
        super.init()
        if advData.count < 8 { return nil }
        
        let content = MKSwiftBleSDKAdopter.hexStringFromData(advData)
        battery = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 2, length: 4))
        
        let tempMac = content.bleSubstring(from: 6, length: 12)
        let macParts = [
            tempMac.bleSubstring(from: 0, length: 2),
            tempMac.bleSubstring(from: 2, length: 2),
            tempMac.bleSubstring(from: 4, length: 2),
            tempMac.bleSubstring(from: 6, length: 2),
            tempMac.bleSubstring(from: 8, length: 2),
            tempMac.bleSubstring(from: 10, length: 2)
        ]
        
        macAddress = macParts.joined(separator: ":")
    }
}

public class MKSFBXSOTABeacon: MKSFBXSBaseBeacon, @unchecked Sendable {
    override init() {
        super.init()
    }
}
