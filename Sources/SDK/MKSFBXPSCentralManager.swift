//
//  MKSwiftBXPSCentralManager.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/6/18.
//

import Foundation
@preconcurrency import CoreBluetooth
import MKSwiftBleModule

// MARK: - Notification Names
public extension Notification.Name {
    static let mk_bxs_swf_peripheralConnectStateChanged = Notification.Name("mk_bxs_swf_peripheralConnectStateChangedNotification")
    static let mk_bxs_swf_centralManagerStateChanged = Notification.Name("mk_bxs_swf_centralManagerStateChangedNotification")
    static let mk_bxs_swf_deviceDisconnectType = Notification.Name("mk_bxs_swf_deviceDisconnectTypeNotification")
    static let mk_bxs_swf_receiveThreeAxisData = Notification.Name("mk_bxs_swf_receiveThreeAxisDataNotification")
    static let mk_bxs_swf_receiveHallSensorStatusChanged = Notification.Name("mk_bxs_swf_receiveHallSensorStatusChangedNotification")
    static let mk_bxs_swf_receiveHTData = Notification.Name("mk_bxs_swf_receiveHTDataNotification")
    static let mk_bxs_swf_receiveRecordHTData = Notification.Name("mk_bxs_swf_receiveRecordHTDataNotification")
}

enum BXPSCentralManagerError: LocalizedError {
    case passwordFromatError
    case passwordError
    case deviceBusyError
    case disconnectedError
    case characteristicError
    case requestError
    
    var errorDescription: String? {
        switch self {
        case .passwordFromatError:
            return "The password should be 1 to 16 ASCII characters."
        case .passwordError:
            return "Password Error"
        case .deviceBusyError:
            return "Device is busy now"
        case .disconnectedError:
            return "The current connection device is in disconnect"
        case .characteristicError:
            return "The characteristic is nil"
        case .requestError:
            return "Request data error"
        }
    }
}

// MARK: - Main Class
@MainActor public class MKSwiftBXPSCentralManager: NSObject {
    
    // MARK: - Properties
    public weak var delegate: MKSFBXSCentralManagerScanDelegate?
    public private(set) var connectStatus: MKSFBXSCentralConnectStatus = .unknown
    
    private static var _shared: MKSwiftBXPSCentralManager?
        
    private let scanUUIDS = [
        CBUUID(string: "FEAA"),
        CBUUID(string: "FEAB"),
        CBUUID(string: "EA01"),
        CBUUID(string: "EB01"),
        CBUUID(string: "EAFF")
    ]
    
    private var characteristicWriteBlock: ((CBPeripheral, CBCharacteristic, Error?) -> Void)?
    
    private var readingNeedPassword: Bool = false
    
    deinit {
        print("MKSwiftBXPSCentralManager deinit")
    }
    
    
    // MARK: - Initialization
    private override init() {
        super.init()
        // Load data manager
        MKSwiftBleBaseCentralManager.shared.configCentralManager(self)
    }
    
    // MARK: - Public Methods
    
    static var shared: MKSwiftBXPSCentralManager {
        if _shared == nil {
            _shared = MKSwiftBXPSCentralManager()
        }
        return _shared!
    }
    
    public static func sharedDealloc() {
        // Dealloc shared instances
        _shared = nil
    }
    
    public static func removeFromCentralList() {
        // Remove from central list
        if _shared == nil {
            return
        }
        MKSwiftBleBaseCentralManager.shared.removeCentralManager()
        _shared = nil
    }
    
    public func centralManager() -> CBCentralManager {
        // Return central manager instance
        return MKSwiftBleBaseCentralManager.shared.centralManager
    }
    
    public func peripheral() -> CBPeripheral? {
        // Return connected peripheral
        return MKSwiftBleBaseCentralManager.shared.peripheral()
    }
    
    public func centralStatus() -> MKSFBXSCentralManagerStatus {
        // Return central status
        return MKSwiftBleBaseCentralManager.shared.centralStatus == .enable ? .enable : .unable
    }
    
    public func otaContralCharacteristic() -> CBCharacteristic? {
        guard connectStatus == .connected, let peripheral = peripheral() else {
            return nil
        }
        // Return OTA control characteristic
        return peripheral.bxs_swf_otaControl
    }
    
    public func otaDataCharacteristic() -> CBCharacteristic? {
        guard connectStatus == .connected, let peripheral = peripheral() else {
            return nil
        }
        // Return OTA data characteristic
        return peripheral.bxs_swf_otaData
    }
    
    public func startScan() {
        // Start scanning for peripherals
        
        MKSwiftBleBaseCentralManager.shared.scanForPeripherals(withServices: scanUUIDS)
    }
    
    public func stopScan() {
        // Stop scanning
        MKSwiftBleBaseCentralManager.shared.stopScan()
    }
    
    public func readNeedPassword(with peripheral: CBPeripheral) async throws -> UInt8 {
        do {
            if readingNeedPassword {
                throw BXPSCentralManagerError.deviceBusyError
            }
            readingNeedPassword = true
            let bxsPeripheral: MKSwiftBXPSPeripheral = MKSwiftBXPSPeripheral(peripheral: peripheral, dfuMode: false)
            _ = try await MKSwiftBleBaseCentralManager.shared.connectDevice(bxsPeripheral)
            let state = try await confirmNeedPassword()
            MKSwiftBleBaseCentralManager.shared.disconnect()
            readingNeedPassword = false
            return state
        } catch {
            readingNeedPassword = false
            MKSwiftBleBaseCentralManager.shared.disconnect()
            throw error
        }
    }
    
    public func connectPeripheral(_ peripheral: CBPeripheral, password: String? = nil, dfu: Bool? = false) async throws -> CBPeripheral {
        if let password = password {
            guard !password.isEmpty, password.count <= 16, MKSwiftBleSDKAdopter.asciiString(password) else {
                throw BXPSCentralManagerError.passwordFromatError
            }
        }
        
        do {
            let bxsPeripheral: MKSwiftBXPSPeripheral = MKSwiftBXPSPeripheral(peripheral: peripheral, dfuMode: dfu ?? false)
            _ = try await MKSwiftBleBaseCentralManager.shared.connectDevice(bxsPeripheral)
            if let password = password {
                //需要连接密码
                let success = try await sendPasswordToDevice(password: password)
                if success == false {
                    //密码错误
                    MKSwiftBleBaseCentralManager.shared.disconnect()
                    throw BXPSCentralManagerError.passwordError
                }
            }
            // 免密登录
            self.connectStatus = .connected
            NotificationCenter.default.post(
                name: .mk_bxs_swf_peripheralConnectStateChanged,
                object: nil
            )
            return bxsPeripheral.peripheral
        } catch {
            throw error
        }
    }
    
    public func disconnect() {
        MKSwiftBleBaseCentralManager.shared.disconnect()
    }
    
    func addTask(with operationID: MKSFBXSTaskOperationID,
                 characteristic: CBCharacteristic?,
                 commandData: String) async throws -> MKSwiftBleResult {
        // 检查设备连接
        guard peripheral() != nil else {
            throw BXPSCentralManagerError.disconnectedError
        }
        
        // 检查特征值
        guard let characteristic = characteristic else {
            throw BXPSCentralManagerError.characteristicError
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            // 创建操作
            let operation: MKSwiftBXPSOperation = MKSwiftBXPSOperation.init(operationID: operationID) {
                MKSwiftBleBaseCentralManager.shared.sendDataToPeripheral(
                    commandData,
                    characteristic: characteristic,
                    type: .withResponse
                )
            } completeBlock: { error, returnData in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let returnData = returnData else {
                    continuation.resume(throwing: BXPSCentralManagerError.requestError)
                    return
                }
                
                continuation.resume(returning: returnData)
            }
            
            // 添加操作到队列
            MKSwiftBleBaseCentralManager.shared.addOperation(operation)
        }
    }

    func addReadTask(with operationID: MKSFBXSTaskOperationID,
                     characteristic: CBCharacteristic?) async throws -> MKSwiftBleResult {
        // 检查设备连接
        guard let peripheral = peripheral() else {
            throw BXPSCentralManagerError.disconnectedError
        }
        
        // 检查特征值
        guard let characteristic = characteristic else {
            throw BXPSCentralManagerError.characteristicError
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            // 创建操作
            let operation: MKSwiftBXPSOperation = MKSwiftBXPSOperation.init(operationID: operationID) {
                peripheral.readValue(for: characteristic)
            } completeBlock: { error, returnData in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let returnData = returnData else {
                    continuation.resume(throwing: BXPSCentralManagerError.requestError)
                    return
                }
                
                continuation.resume(returning: returnData)
            }
            
            // 添加操作到队列
            MKSwiftBleBaseCentralManager.shared.addOperation(operation)
        }
    }
    
    public func addCharacteristicWriteBlock(_ block: @escaping (CBPeripheral, CBCharacteristic, Error?) -> Void) {
        characteristicWriteBlock = block
    }
    
    public func notifyThreeAxisData(_ notify: Bool) -> Bool {
        guard connectStatus == .connected,
              let peripheral = peripheral(),
              let threeSensor = peripheral.bxs_swf_threeSensor else {
            return false
        }
        
        peripheral.setNotifyValue(notify, for: threeSensor)
        return true
    }
    
    public func notifyHallSensorData(_ notify: Bool) -> Bool {
        guard connectStatus == .connected,
              let peripheral = peripheral(),
              let hallSensor = peripheral.bxs_swf_hallSensor else {
            return false
        }
        
        peripheral.setNotifyValue(notify, for: hallSensor)
        return true
    }
    
    public func notifyTHSensorData(_ notify: Bool) -> Bool {
        guard connectStatus == .connected,
              let peripheral = peripheral(),
              let temperatureHumidity = peripheral.bxs_swf_temperatureHumidity else {
            return false
        }
        
        peripheral.setNotifyValue(notify, for: temperatureHumidity)
        return true
    }
    
    public func notifyRecordTHData(_ notify: Bool) -> Bool {
        guard connectStatus == .connected,
              let peripheral = peripheral(),
              let recordTH = peripheral.bxs_swf_recordTH else {
            return false
        }
        
        peripheral.setNotifyValue(notify, for: recordTH)
        return true
    }
    
    // MARK: - Private Methods
    
    private func sendPasswordToDevice(password:String) async throws -> Bool {
        
        if password.count == 0 || password.count > 16 {
            throw BXPSCentralManagerError.passwordFromatError
        }
        
        var lenString = String(format: "%1lx", password.count)
        if lenString.count == 1 {
            lenString = "0" + lenString
        }
        
        var commandData = "ea0151" + lenString
        for i in 0..<password.count {
            let asciiCode = password[password.index(password.startIndex, offsetBy: i)].unicodeScalars.first?.value ?? 0
            commandData += String(format: "%1lx", asciiCode)
        }
        
        let result = try await MKSwiftBXPSCentralManager.shared.addTask(with: .connectPasswordOperation, characteristic: MKSwiftBXPSCentralManager.shared.peripheral()?.bxs_swf_password, commandData: commandData)
        
        guard let success = result.value["success"] as? Bool else {
            throw BXPSCentralManagerError.passwordError
        }
        
        return success
    }
    
    private func confirmNeedPassword() async throws -> UInt8 {
        do {
            let commandData = "ea005300"
            
            let result = try await MKSwiftBXPSCentralManager.shared.addTask(with: .taskReadNeedPasswordOperation, characteristic: MKSwiftBXPSCentralManager.shared.peripheral()?.bxs_swf_password, commandData: commandData)
            
            guard let state = result.value["state"] as? UInt8 else {
                throw BXPSCentralManagerError.requestError
            }
            return state
        } catch {
            throw error
        }
    }
    
    private func clearAllParams() {
        characteristicWriteBlock = nil
        if readingNeedPassword == false {
            return
        }
        
        disconnect()
        readingNeedPassword = false
    }
}

// MARK: - Extensions

extension MKSwiftBXPSCentralManager: MKSwiftBleCentralManagerProtocol {
    nonisolated public func centralManagerDiscoverPeripheral(_ peripheral: CBPeripheral, advertisementData: MKBleAdvInfo) {
        let identifier = peripheral.identifier.uuidString
        let localName = advertisementData.localName
        let isConnectable = advertisementData.isConnectable
        DispatchQueue.global().async {
            if let localName = localName,
               localName == "MK_OTA" {
                // OTA广播帧
                let beaconModel = MKSFBXSOTABeacon()
                beaconModel.frameType = .ota
                beaconModel.identifier = identifier
                beaconModel.rssi = advertisementData.rssi
                beaconModel.peripheral = peripheral
                beaconModel.deviceName = localName
                beaconModel.connectEnable = isConnectable ?? false
                
                DispatchQueue.main.async {
                    self.delegate?.mk_bxs_swf_receiveBeacon([beaconModel])
                }
                return
            }
            
            let deviceList = MKSFBXSBaseBeacon.parseAdvData(advertisementData)
            
            for beaconModel in deviceList {
                beaconModel.identifier = peripheral.identifier.uuidString
                beaconModel.rssi = advertisementData.rssi
                beaconModel.peripheral = peripheral
                beaconModel.deviceName = localName
                beaconModel.connectEnable = isConnectable ?? false
            }
            
            DispatchQueue.main.async {
                self.delegate?.mk_bxs_swf_receiveBeacon(deviceList)
            }
        }
    }
    
    nonisolated public func centralManagerStartScan() {
        DispatchQueue.main.async {
            self.delegate?.mk_bxs_swf_startScan()
        }
    }
    
    nonisolated public func centralManagerStopScan() {
        DispatchQueue.main.async {
            self.delegate?.mk_bxs_swf_stopScan()
        }
    }
    
    nonisolated public func centralManagerStateChanged(_ state: MKSwiftCentralManagerState) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                        name: .mk_bxs_swf_centralManagerStateChanged,
                        object: nil
                    )
        }
    }
    
    nonisolated public func peripheralConnectStateChanged(_ state: MKSwiftPeripheralConnectState) {
        
        Task { @MainActor in
            guard !self.readingNeedPassword else { return }
            
            self.connectStatus = {
                switch state {
                case .unknown: return .unknown
                case .connecting: return .connecting
                case .disconnect: return .disconnect
                case .connectedFailed: return .connectedFailed
                case .connected: return .connected
                }
            }()
            
            NotificationCenter.default.post(
                name: .mk_bxs_swf_peripheralConnectStateChanged,
                object: nil
            )
        }
    }
    
    nonisolated public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        if error != nil || characteristic.value == nil {
            print("+++++++++++++++++接收数据出错")
            return
        }
        
        switch characteristic.uuid.uuidString {
        case "AA02":
            // 设备断开连接的类型
            if characteristic.value?.count == 5 {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .mk_bxs_swf_deviceDisconnectType,
                        object: nil,
                        userInfo: ["type": characteristic.value![4]]
                    )
                }
            }
            
        case "AA03":
            // 三轴数据
            if characteristic.value?.count == 10 {
                let xData = MKSwiftBleSDKAdopter.signedDataTurnToInt(characteristic.value!.subdata(in: 4..<6))
                let yData = MKSwiftBleSDKAdopter.signedDataTurnToInt(characteristic.value!.subdata(in: 6..<8))
                let zData = MKSwiftBleSDKAdopter.signedDataTurnToInt(characteristic.value!.subdata(in: 8..<10))
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .mk_bxs_swf_receiveThreeAxisData,
                        object: nil,
                        userInfo: [
                            "xData": "\(xData)",
                            "yData": "\(yData)",
                            "zData": "\(zData)"
                        ]
                    )
                }
            }
            
        case "AA08":
            // 霍尔传感器状态
            if characteristic.value?.count == 5 {
                let moved = characteristic.value![4] == 0x01
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .mk_bxs_swf_receiveHallSensorStatusChanged,
                        object: nil,
                        userInfo: ["moved": moved]
                    )
                }
            }
            
        case "AA06":
            // 温湿度数据
            if characteristic.value?.count == 8 {
                let tempTemp = MKSwiftBleSDKAdopter.signedDataTurnToInt(characteristic.value!.subdata(in: 4..<6))
                
                let tempHui = MKSwiftBleSDKAdopter.getDecimalFromData(characteristic.value!, range: 6..<8)
                
                let temperature = String(format: "%.1f", Double(tempTemp) * 0.1)
                let humidity = String(format: "%.1f", Double(tempHui) * 0.1)
                
                let htData = [
                    "temperature": temperature,
                    "humidity": humidity
                ]
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .mk_bxs_swf_receiveHTData,
                        object: nil,
                        userInfo: htData
                    )
                }
            }
            
        case "AA09":
            // 符合采样条件已储存的温湿度数据
            print(characteristic.value!)
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .mk_bxs_swf_receiveRecordHTData,
                    object: nil,
                    userInfo: ["content": characteristic.value!]
                )
            }
            
        default:
            break
        }
    }
    
    nonisolated public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        if let error = error {
            print("+++++++++++++++++发送数据出错: \(error.localizedDescription)")
            return
        }
        DispatchQueue.main.async {
            self.characteristicWriteBlock?(peripheral, characteristic, error)
        }
        
    }
}
