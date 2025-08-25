//
//  MKSFBXSSlotDataBaseModel.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/23.
//

import Foundation

struct MKSFBXSSlotParamsDataModel: Sendable, MKSFBXSSlotAdvContentParam {
    var advInterval: Int = 0      // 20ms~65535ms
    var advDuration: Int = 0      // 1s~65535s
    var standbyDuration: Int = 0  // 0s~65535s
    var rssi: Int = 0             // -100dBm~0dBm
    var txPower: Int = 0          // 0:-20dBm, 1:-16dBm, etc.
}

struct MKSFBXSSlotTriggerParamsDataModel: Sendable, MKSFBXSSlotTriggeredAdvContentParam {
    var advInterval: Int = 0      // 20ms~65535ms
    var advDuration: Int = 0      // 0s~65535s
    var rssi: Int = 0             // -100dBm~0dBm
    var txPower: Int = 0          // 0:-20dBm, 1:-16dBm, etc.
}

class MKSFBXSSlotDataBaseModel: NSObject {
    var index: Int
    
    var slotType: MKSFBXSSlotType = .null
    
    // MARK: - advContent Param
    var advInterval: String = ""
    var powerModeIsOn: Bool = false
    var advDuration: String = ""
    var standbyDuration: String = ""
    var rssi: Int = 0
    /*
     对于deviceType=23的C112设备，最高支持到0dBm，其余可以支持到+6dBm
     0:-20dBm
     1:-16dBm
     2:-12dBm
     3:-8dBm
     4:-4dBm
     5:0dBm
     6:3dBm
     7:4dBm
     8:6dBm
     */
    var txPower: Int = 0
    
    // MARK: - UID
    var namespaceID: String = ""
    var instanceID: String = ""
    
    // MARK: - iBeacon
    var major: String = ""
    var minor: String = ""
    var uuid: String = ""
    
    // MARK: - Sensor Info
    var deviceName: String = ""
    var tagID: String = ""
    
    // MARK: - URL
    var urlType: Int = 0  // 0:@"http://www.",1:@"https://www.",2:@"http://",3:@"https://"
    var urlContent: String = ""
    
    init(slotIndex index: Int) {
        self.index = index
        super.init()
    }
    
    func read() async throws {}
    
    func config() async throws {}
    
    func updateSlotDatas(_ dic: [String: Any]) {
        guard !dic.isEmpty else { return }
        
        if let advIntervalValue = dic["advInterval"] as? String {
            advInterval = "\(Int(Double(advIntervalValue)! * 0.01))"
        }
        
        if let advDurationValue = dic["advDuration"] as? String {
            advDuration = advDurationValue
        }
        
        if let standbyDurationValue = dic["standbyDuration"] as? String {
            standbyDuration = Int(standbyDurationValue)! == 0 ? "" : "\(standbyDurationValue)"
            powerModeIsOn = Int(standbyDurationValue)! > 0
        }
        
        if let rssiValue = dic["rssi"] as? String {
            rssi = Int(rssiValue)!
        }
        
        if let txPowerValue = dic["txPower"] as? String {
            txPower = getTxPowerValue(txPowerValue)
        }
        
        guard let slotType = dic["slotType"] as? String else { return }
        
        switch slotType {
        case "ff":
            self.slotType = .null
        case "00":
            self.slotType = .uid
            if let advContent = dic["advContent"] as? [String: Any] {
                namespaceID = advContent["namespaceID"] as? String ?? ""
                instanceID = advContent["instanceID"] as? String ?? ""
            }
        case "10":
            self.slotType = .url
            if let advContent = dic["advContent"] as? [String: Any] {
                urlType = advContent["urlType"] as? Int ?? 0
                urlContent = advContent["urlContent"] as? String ?? ""
            }
        case "20":
            self.slotType = .tlm
        case "50":
            self.slotType = .beacon
            if let advContent = dic["advContent"] as? [String: Any] {
                major = advContent["major"] as? String ?? ""
                minor = advContent["minor"] as? String ?? ""
                uuid = advContent["uuid"] as? String ?? ""
            }
        case "80":
            self.slotType = .sensorInfo
            if let advContent = dic["advContent"] as? [String: Any] {
                deviceName = advContent["deviceName"] as? String ?? ""
                tagID = advContent["tagID"] as? String ?? ""
            }
        default:
            break
        }
    }
    
    func getTxPowerValue(_ power: String) -> Int {
        switch power {
        case "-20dBm": return 0
        case "-16dBm": return 1
        case "-12dBm": return 2
        case "-8dBm": return 3
        case "-4dBm": return 4
        case "0dBm": return 5
        case "3dBm": return 6
        case "4dBm": return 7
        case "6dBm": return 8
        default: return 0
        }
    }
    
    func validParams() -> Bool {
        if slotType == .null {
            return true
        }
        
        guard !advInterval.isEmpty,
              let advIntervalValue = Int(advInterval),
              advIntervalValue >= 1, advIntervalValue <= 100 else {
            return false
        }
        
        guard !advDuration.isEmpty,
              let advDurationValue = Int(advDuration),
              advDurationValue >= 1, advDurationValue <= 65535 else {
            return false
        }
        
        if powerModeIsOn {
            guard !standbyDuration.isEmpty,
                  let standbyDurationValue = Int(standbyDuration),
                  standbyDurationValue >= 1, standbyDurationValue <= 65535 else {
                return false
            }
        }
        
        if slotType != .tlm {
            guard rssi >= -127, rssi <= 0 else {
                return false
            }
        }
        
        switch slotType {
        case .uid:
            guard !namespaceID.isEmpty, namespaceID.count == 20,
                  !instanceID.isEmpty, instanceID.count == 12 else {
                return false
            }
        case .url:
            let result = MKSwiftBXPSSDKDataAdopter.fetchUrlString(urlType: MKSFBXSURLHeaderType(rawValue: urlType)!, urlContent: urlContent)
            guard !result.isEmpty else {
                return false
            }
        case .beacon:
            guard !major.isEmpty, let majorValue = Int(major),
                  majorValue >= 0, majorValue <= 65535,
                  !minor.isEmpty, let minorValue = Int(minor),
                  minorValue >= 0, minorValue <= 65535,
                  !uuid.isEmpty, uuid.count == 32 else {
                return false
            }
        case .sensorInfo:
            guard !deviceName.isEmpty, deviceName.count <= 20,
                  !tagID.isEmpty, tagID.count <= 12, tagID.count % 2 == 0 else {
                return false
            }
        default:
            break
        }
        
        return true
    }
    
    func currentContentParam() -> MKSFBXSSlotParamsDataModel {
        var param = MKSFBXSSlotParamsDataModel()
        param.advInterval = (Int(advInterval) ?? 0) * 100
        param.advDuration = Int(advDuration) ?? 0
        param.standbyDuration = powerModeIsOn ? (Int(standbyDuration) ?? 0) : 0
        param.rssi = rssi
        param.txPower = txPower
        return param
    }
    
    func currentTriggerContentParam() -> MKSFBXSSlotTriggerParamsDataModel {
        var param = MKSFBXSSlotTriggerParamsDataModel()
        param.advInterval = (Int(advInterval) ?? 0) * 100
        param.advDuration = Int(advDuration) ?? 0
        param.rssi = rssi
        param.txPower = txPower
        return param
    }
}
