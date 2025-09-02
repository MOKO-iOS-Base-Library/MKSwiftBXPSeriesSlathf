//
//  MKSwiftBXSSDKDataAdopter.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/6/17.
//

import Foundation
import MKSwiftBleModule

public let kBXTOtaServerUUIDString = "1d14d6ee-fd63-4fa1-bfa4-8f47b42119f0"
public let kBXTOtaControlUUIDString = "f7bf3564-fb6d-4e53-88a4-5e37e0326063"
public let kBXTOtaDataUUIDString = "984227f3-34fc-4045-a5d0-2c581f81a153"

public let mk_bxs_swf_totalNumKey = "mk_bxs_swf_totalNumKey"
public let mk_bxs_swf_totalIndexKey = "mk_bxs_swf_totalIndexKey"
public let mk_bxs_swf_contentKey = "mk_bxs_swf_contentKey"

struct MKSwiftBleResult: @unchecked Sendable {
    let value: [String: Any]
}

// MARK: - 枚举定义

public enum MKSFBXSCentralConnectStatus: Int {
    case unknown = 0            // 未知状态
    case connecting            // 正在连接
    case connected             // 连接成功
    case connectedFailed       // 连接失败
    case disconnect
}

public enum MKSFBXSCentralManagerStatus: Int {
    case unable                // 不可用
    case enable               // 可用状态
}

public enum MKSFBXSThreeAxisDataRate: Int {
    case rate1hz = 0          // 1hz
    case rate10hz             // 10hz
    case rate25hz             // 25hz
    case rate50hz             // 50hz
    case rate100hz            // 100hz
}

public enum MKSFBXSThreeAxisDataAG: Int {
    case ag0 = 0              // ±2g
    case ag1                  // ±4g
    case ag2                  // ±8g
    case ag3                  // ±16g
}

public enum MKSFBXSTxPower: Int {
    case neg20dBm = 0         // -20dBm
    case neg16dBm             // -16dBm
    case neg12dBm             // -12dBm
    case neg8dBm              // -8dBm
    case neg4dBm              // -4dBm
    case zero_dBm             // 0dBm
    case pos3dBm              // 3dBm
    case pos4dBm              // 4dBm
    case pos6dBm              // 6dBm
}

public enum MKSFBXSURLHeaderType: Int {
    case type1 = 0            // http://www.
    case type2                // https://www.
    case type3                // http://
    case type4                // https://
}

public enum MKSFBXSTriggerType: Int {
    case none = 0
    case temperature
    case humidity
    case motionDetection
    case hall
}

public enum MKSFBXSBatteryADVMode: Int {
    case percentage = 0
    case voltage
}

public enum MKSFBXSAdvChannel: Int {
    case ch37 = 0
    case ch38
    case ch37Andch38
    case ch39
    case ch37Andch39
    case ch38Andch39
    case all                  // CH37&38&39
}

public enum MKSFBXSSlotAdvType: Int {
    case tlm = 0
    case uid
    case url
    case iBeacon
    case noData
}

public enum MKSFBXSSlotDataType: Int {
    case beforeTriggerData = 0
    case slotData
}

public enum MKSFBXSBuzzerRingingFrequencyType: Int {
    case normal = 0           // 4000Hz
    case higher               // 4500Hz
}

// MARK: - 协议定义

public protocol MKSFBXSSlotAdvContentParam {
    /// 20ms~65535ms
    var advInterval: Int { get set }
    
    /// 1s~65535s
    var advDuration: Int { get set }
    
    /// 0s~65535s
    var standbyDuration: Int { get set }
    
    /// -100dBm~0dBm
    var rssi: Int { get set }
    
    /*
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
    var txPower: Int { get set }
}

public protocol MKSFBXSSlotTriggeredAdvContentParam {
    /// 20ms~65535ms
    var advInterval: Int { get set }
    
    /// 0s~65535s
    var advDuration: Int { get set }
    
    /// -100dBm~0dBm
    var rssi: Int { get set }
    
    /*
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
    var txPower: Int { get set }
}

// MARK: - 代理协议

public protocol MKSFBXSCentralManagerScanDelegate: AnyObject {
    /// 扫描到新设备
    /// - Parameter beaconList: 设备列表
    func mk_bxs_swf_receiveBeacon(_ beaconList: [MKSFBXSBaseBeacon])
    
    /// 开始扫描设备（可选）
    func mk_bxs_swf_startScan()
    
    /// 停止扫描设备（可选）
    func mk_bxs_swf_stopScan()
}

extension MKSFBXSCentralManagerScanDelegate {
    // Make methods optional by providing defaults
    func mk_bxs_swf_startScan() {}
    func mk_bxs_swf_stopScan() {}
}

public class MKSwiftBXPSSDKDataAdopter {
    
    // MARK: - URL 相关
    
    public static func getUrlscheme(hexChar: CChar) -> String {
        switch hexChar {
        case 0x00: return "http://www."
        case 0x01: return "https://www."
        case 0x02: return "http://"
        case 0x03: return "https://"
        default: return ""
        }
    }
    
    public static func getEncodedString(hexChar: CChar) -> String {
        switch hexChar {
        case 0x00: return ".com/"
        case 0x01: return ".org/"
        case 0x02: return ".edu/"
        case 0x03: return ".net/"
        case 0x04: return ".info/"
        case 0x05: return ".biz/"
        case 0x06: return ".gov/"
        case 0x07: return ".com"
        case 0x08: return ".org"
        case 0x09: return ".edu"
        case 0x0a: return ".net"
        case 0x0b: return ".info"
        case 0x0c: return ".biz"
        case 0x0d: return ".gov"
        default: return String(format: "%c", hexChar)
        }
    }
    
    public static func fetchUrlString(urlType: MKSFBXSURLHeaderType, urlContent: String) -> String {
        if !MKValidator.isValidString(urlContent) {
            return ""
        }
        var hearder = "http://www."
        if urlType == .type2 {
            hearder = "https://www."
        } else if urlType == .type3 {
            hearder = "http://"
        } else if urlType == .type4 {
            hearder = "https://"
        }
        let url = hearder + urlContent
        if regularUrl(url) {
            //合法的URL
            return fetchUrlTypeString(urlType) + getUrlIllegalContent(urlContent)
        }
        //如果不合法
        if urlContent.count > 17 || urlContent.count < 2 {
            return ""
        }
        var content = fetchUrlTypeString(urlType)
        for char in urlContent {
            let asciiCode = Int(char.unicodeScalars.first?.value ?? 0)
            content.append(String(format: "%1lx", asciiCode))
        }
        return content
    }
    
    // MARK: - 三轴数据
    
    public static func fetchThreeAxisDataRate(_ dataRate: MKSFBXSThreeAxisDataRate) -> String {
        switch dataRate {
        case .rate1hz: return "00"
        case .rate10hz: return "01"
        case .rate25hz: return "02"
        case .rate50hz: return "03"
        case .rate100hz: return "04"
        }
    }
    
    public static func fetchThreeAxisDataAG(_ ag: MKSFBXSThreeAxisDataAG) -> String {
        switch ag {
        case .ag0: return "00"
        case .ag1: return "01"
        case .ag2: return "02"
        case .ag3: return "03"
        }
    }
    
    // MARK: - 发射功率
    
    public static func fetchTxPower(_ txPower: MKSFBXSTxPower) -> String {
        switch txPower {
        case .neg20dBm: return "ec"
        case .neg16dBm: return "f0"
        case .neg12dBm: return "f4"
        case .neg8dBm: return "f8"
        case .neg4dBm: return "fc"
        case .zero_dBm: return "00"
        case .pos3dBm: return "03"
        case .pos4dBm: return "04"
        case .pos6dBm: return "06"
        }
    }
    
    public static func fetchTxPowerValueString(_ content: Int) -> String {
        switch content {
        case 0x06: return "6dBm"
        case 0x04: return "4dBm"
        case 0x03: return "3dBm"
        case 0x00: return "0dBm"
        case 0xfc: return "-4dBm"
        case 0xf8: return "-8dBm"
        case 0xf4: return "-12dBm"
        case 0xf0: return "-16dBm"
        case 0xec: return "-20dBm"
        default: return "0dBm"
        }
    }
    
    // MARK: - 解析槽位数据
    
    public static func parseSlotData(_ content: Data, hasStandbyDuration: Bool) -> [String: Any] {
        guard content.count >= 3 else { return [:] }
        
        var resultDic = [String: Any]()
        var contentIndex = 0
        
        let slotIndex = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: contentIndex..<(contentIndex + 1))
        resultDic["slotIndex"] = slotIndex
        contentIndex += 1
        
        // 广播间隔
        let advInterval = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: contentIndex..<(contentIndex + 2))
        resultDic["advInterval"] = advInterval
        contentIndex += 2
        
        // 广播持续时间
        let advDuration = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: contentIndex..<(contentIndex + 2))
        resultDic["advDuration"] = advDuration
        contentIndex += 2
        
        // 待机持续时间
        if hasStandbyDuration {
            let standbyDuration = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: contentIndex..<(contentIndex + 2))
            resultDic["standbyDuration"] = standbyDuration
            contentIndex += 2
        }
        
        // RSSI
        let rssi = MKSwiftBleSDKAdopter.signedDataTurnToInt(content.subdata(in: contentIndex..<(contentIndex + 1)))
        resultDic["rssi"] = "\(rssi)"
        contentIndex += 1
        
        // 发射功率
        let txPower = fetchTxPowerValueString(Int(content[contentIndex]))
        resultDic["txPower"] = txPower
        contentIndex += 1
        
        let slotType = MKSwiftBleSDKAdopter.hexStringFromData(content.subdata(in: contentIndex..<(contentIndex + 1)))
        resultDic["slotType"] = slotType
        contentIndex += 2
        
        // 解析广告内容
        var advDic = [String: Any]()
        
        switch slotType.uppercased() {
        case "FF":
            break // No Data
        case "00":
            // UID
            let namespaceID = MKSwiftBleSDKAdopter.hexStringFromData(content.subdata(in: contentIndex..<(contentIndex + 10)))
            contentIndex += 10
            let instanceID = MKSwiftBleSDKAdopter.hexStringFromData(content.subdata(in: contentIndex..<(contentIndex + 6)))
            contentIndex += 6
            advDic = [
                "namespaceID": namespaceID,
                "instanceID": instanceID
            ]
        case "10":
            // URL
            let urlType = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: contentIndex..<(contentIndex + 1))
            
            contentIndex += 1
            
            let subData = content.subdata(in: contentIndex..<content.count)
            var urlContent = ""
            
            subData.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
                if let ptr = bytes.bindMemory(to: CChar.self).baseAddress {
                    for i in 0..<subData.count {
                        urlContent += getEncodedString(hexChar: ptr[i])
                    }
                }
            }
            
            advDic = [
                "urlType": urlType,
                "urlContent": urlContent,
            ]
        case "20":
            // TLM
            break
        case "50":
            // iBeacon
            let uuid = MKSwiftBleSDKAdopter.hexStringFromData(content.subdata(in: contentIndex..<(contentIndex + 16)))
            contentIndex += 16
            let major = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: contentIndex..<(contentIndex + 2))
            contentIndex += 2
            let minor = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: contentIndex..<(contentIndex + 2))
            contentIndex += 2
            
            advDic = [
                "major": major,
                "minor": minor,
                "uuid": uuid
            ]
        case "80":
            // Sensor Info
            let nameLen = Int(content[contentIndex])
            contentIndex += 1
            
            let nameData = content.subdata(in: contentIndex..<(contentIndex + nameLen))
            let deviceName = String(data: nameData, encoding: .utf8) ?? ""
            contentIndex += nameLen
            
            let tagLen = Int(content[contentIndex])
            contentIndex += 1
            let tagID = MKSwiftBleSDKAdopter.hexStringFromData(content.subdata(in: contentIndex..<(contentIndex + tagLen)))
            
            advDic = [
                "deviceName": deviceName,
                "tagID": tagID
            ]
        default:
            break
        }
        
        resultDic["advContent"] = advDic
        return resultDic
    }
    
    // MARK: - 解析槽位触发参数
    
    public static func parseSlotTriggerParam(_ content: Data) -> [String: Any] {
        guard content.count >= 2 else { return [:] }
        var contentIndex = 0
        let slotIndex = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: contentIndex..<(contentIndex + 1))
        contentIndex += 1
        
        let triggerType = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: contentIndex..<(contentIndex + 1))
        contentIndex += 1
        
        if triggerType == "00" {
            // 无触发
            return [
                "slotIndex": slotIndex,
                "triggerType": triggerType
            ]
        }
        if triggerType == "01" {
            // 温度触发
            let event = (content[contentIndex] == 0x10) ? "0" : "1"
            contentIndex += 1
            let temperature = MKSwiftBleSDKAdopter.signedDataTurnToInt(content.subdata(in: contentIndex..<(contentIndex + 2)))
            contentIndex += 2
            let lockedAdv = content[contentIndex] == 0x01
            
            return [
                "slotIndex": slotIndex,
                "triggerType": triggerType,
                "event": event,
                "temperature": "\(temperature)",
                "lockedAdv": lockedAdv
            ]
        }
        if triggerType == "02" {
            // 湿度触发
            let event = (content[contentIndex] == 0x20) ? "0" : "1"
            contentIndex += 1
            let humidity = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: contentIndex..<(contentIndex + 2))
            contentIndex += 2
            let lockedAdv = content[contentIndex] == 0x01
            
            return [
                "slotIndex": slotIndex,
                "triggerType": triggerType,
                "event": event,
                "humidity": humidity,
                "lockedAdv": lockedAdv
            ]
        }
        if triggerType == "03" {
            // 移动触发
            let event = (content[contentIndex] == 0x30) ? "0" : "1"
            contentIndex += 1
            contentIndex += 2
            let lockedAdv = content[contentIndex] == 0x01
            contentIndex += 1
            let period = MKSwiftBleSDKAdopter.getDecimalStringFromData(content, range: contentIndex..<(contentIndex + 2))
            
            return [
                "slotIndex": slotIndex,
                "triggerType": triggerType,
                "event": event,
                "lockedAdv": lockedAdv,
                "period": period
            ]
        }
        if triggerType == "04" {
            // 霍尔触发
            let event = (content[contentIndex] == 0x40) ? "0" : "1"
            contentIndex += 1
            contentIndex += 2
            let lockedAdv = content[contentIndex] == 0x01
            
            return [
                "slotIndex": slotIndex,
                "triggerType": triggerType,
                "event": event,
                "lockedAdv": lockedAdv
            ]
        }
        
        return [:]
    }
    
    // MARK: - 解析霍尔数据
    
    public static func parseHallData(_ list: [String]) -> [[String: Any]] {
        guard !list.isEmpty else { return [] }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        
        var tempList = [[String: Any]]()
        
        for content in list {
            let totalNumber = content.count / 10
            for j in 0..<totalNumber {
                let subContent = content.bleSubstring(from: j * 10, length: 10)
                
                let time = MKSwiftBleSDKAdopter.getDecimalWithHex(subContent, range: NSRange(location: 0, length: 8))
                let date = Date(timeIntervalSince1970: TimeInterval(time))
                let timestamp = dateFormatter.string(from: date)
                let moved = subContent.bleSubstring(from: 8, length: 2) == "01"
                
                let dic: [String: Any] = [
                    "timestamp": timestamp,
                    "moved": moved
                ]
                tempList.append(dic)
            }
        }
        
        return tempList
    }
    
    // MARK: - 获取广播通道命令
    
    public static func fetchAdvChannelCmd(_ channel: MKSFBXSAdvChannel) -> String {
        switch channel {
        case .ch37: return "01"
        case .ch38: return "02"
        case .ch37Andch38: return "03"
        case .ch39: return "04"
        case .ch37Andch39: return "05"
        case .ch38Andch39: return "06"
        case .all: return "07"
        }
    }
    
    // MARK: - 获取槽位广告参数命令
    
    public static func fetchSlotAdvParamsCmd(_ param: MKSFBXSSlotAdvContentParam) -> String {
        guard param.advInterval >= 20 && param.advInterval <= 65535,
              param.advDuration >= 1 && param.advDuration <= 65535,
              param.standbyDuration >= 0 && param.standbyDuration <= 65535,
              param.rssi >= -100 && param.rssi <= 0,
              param.txPower >= 0 && param.txPower <= 8 else {
            return ""
        }
        
        let advInterval = MKSwiftBleSDKAdopter.fetchHexValue(param.advInterval, byteLen: 2)
        let advDuration = MKSwiftBleSDKAdopter.fetchHexValue(param.advDuration, byteLen: 2)
        let standbyDuration = MKSwiftBleSDKAdopter.fetchHexValue(param.standbyDuration, byteLen: 2)
        let rssi = MKSwiftBleSDKAdopter.hexStringFromSignedNumber(param.rssi)
        
        let txPower = fetchTxPower(MKSFBXSTxPower(rawValue: param.txPower) ?? .zero_dBm)
        
        return "\(advInterval)\(advDuration)\(standbyDuration)\(rssi)\(txPower)"
    }
    
    // MARK: - 获取触发广告参数命令
    
    public static func fetchSlotTriggerdAdvParamsCmd(_ param: MKSFBXSSlotTriggeredAdvContentParam) -> String {
        guard param.advInterval >= 20 && param.advInterval <= 65535,
              param.advDuration >= 0 && param.advDuration <= 65535,
              param.rssi >= -100 && param.rssi <= 0,
              param.txPower >= 0 && param.txPower <= 8 else {
            return ""
        }
        
        let advInterval = MKSwiftBleSDKAdopter.fetchHexValue(param.advInterval, byteLen: 2)
        let advDuration = MKSwiftBleSDKAdopter.fetchHexValue(param.advDuration, byteLen: 2)
        let rssi = MKSwiftBleSDKAdopter.hexStringFromSignedNumber(param.rssi)
        
        let txPower = fetchTxPower(MKSFBXSTxPower(rawValue: param.txPower) ?? .zero_dBm)
        
        return "\(advInterval)\(advDuration)\(rssi)\(txPower)"
    }
    
    // MARK: - 温度转十六进制字符串
    
    public static func temperatureToHexString(_ temperature: Int) -> String {
        // 1. 处理符号和范围
        var highByte: UInt8 = 0x00
        var lowByte: UInt8
        
        if temperature >= -128 && temperature <= 127 {
            // 使用 int8_t 存储（-128~127）
            lowByte = UInt8(bitPattern: Int8(temperature))
            highByte = (temperature < 0) ? 0xFF : 0x00
        } else if temperature >= 128 && temperature <= 150 {
            // 超出 int8_t 正范围，按无符号处理
            lowByte = UInt8(temperature)
            highByte = 0x00
        } else {
            // 超出范围，强制截断（按业务需求调整）
            lowByte = (temperature < 0) ? 0x80 : 0x7F
            highByte = (temperature < 0) ? 0xFF : 0x00
        }
        
        // 2. 组合成十六进制字符串（大写，补零）
        return String(format: "%02X%02X", highByte, lowByte)
    }
    
    // MARK: - 私有方法
    
    private static func fetchUrlTypeString(_ urlType: MKSFBXSURLHeaderType) -> String {
        switch urlType {
        case .type1: return "00"
        case .type2: return "01"
        case .type3: return "02"
        case .type4: return "03"
        }
    }
    
    private static func getUrlIllegalContent(_ urlContent: String) -> String {
        guard !urlContent.isEmpty else { return "" }
        
        let tempList = urlContent.components(separatedBy: ".")
        guard !tempList.isEmpty else { return "" }
        
        var content = ""
        let expansion = getExpansionHex("." + tempList.last!)
        
        if expansion.isEmpty {
            // 如果不是符合官方要求的后缀名，判断长度是否小于2，如果是小于2则认为错误，否则直接认为符合要求
            // 如果不是符合官方要求的后缀名，判断长度是否大于17，如果是大于17则认为错误，否则直接认为符合要求
            if urlContent.count > 17 || urlContent.count < 2 {
                return ""
            }
            
            for char in urlContent.unicodeScalars {
                content += String(format: "%1lx", char.value)
            }
        } else {
            var tempString = ""
            for i in 0..<tempList.count-1 {
                tempString += ".\(tempList[i])"
            }
            tempString = String(tempString.dropFirst())
            
            if tempString.count > 16 || tempString.count < 1 {
                return ""
            }
            
            for char in tempString.unicodeScalars {
                content += String(format: "%1lx", char.value)
            }
            
            content += expansion
        }
        
        return content
    }
    
    private static func regularUrl(_ url: String) -> Bool {
        guard !url.isEmpty else { return false }
        let pred = NSPredicate(format: "SELF MATCHES %@", "[a-zA-z]+://[^\\s]*")
        return pred.evaluate(with: url)
    }
    
    private static func getExpansionHex(_ expansion: String) -> String {
        switch expansion {
        case ".com/": return "00"
        case ".org/": return "01"
        case ".edu/": return "02"
        case ".net/": return "03"
        case ".info/": return "04"
        case ".biz/": return "05"
        case ".gov/": return "06"
        case ".com": return "07"
        case ".org": return "08"
        case ".edu": return "09"
        case ".net": return "0a"
        case ".info": return "0b"
        case ".biz": return "0c"
        case ".gov": return "0d"
        default: return ""
        }
    }
}
