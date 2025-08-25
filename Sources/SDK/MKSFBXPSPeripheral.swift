//
//  MKSwiftBXPSPeripheral.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/6/17.
//

import Foundation
@preconcurrency import CoreBluetooth
import MKSwiftBleModule

public final class MKSwiftBXPSPeripheral: NSObject, MKSwiftBlePeripheralProtocol {
    
    public let peripheral: CBPeripheral
    public let dfu: Bool
    
    public init(peripheral: CBPeripheral, dfuMode: Bool) {
        self.peripheral = peripheral
        self.dfu = dfuMode
        super.init()
    }
    
    public func discoverServices() {
        let services = [
            CBUUID(string: "180A"),  // 厂商信息
            CBUUID(string: "AA00"),
            CBUUID(string: kBXTOtaServerUUIDString) // 自定义
        ]
        peripheral.discoverServices(services)
    }
    
    public func discoverCharacteristics() {
        guard let services = peripheral.services else { return }
        
        for service in services {
            if service.uuid == CBUUID(string: "AA00") {
                let characteristics = [
                    CBUUID(string: "AA01"), CBUUID(string: "AA02"),
                    CBUUID(string: "AA03"), CBUUID(string: "AA04"),
                    CBUUID(string: "AA05"), CBUUID(string: "AA06"),
                    CBUUID(string: "AA09"), CBUUID(string: "AA08")
                ]
                peripheral.discoverCharacteristics(characteristics, for: service)
            } else if service.uuid == CBUUID(string: kBXTOtaServerUUIDString) {
                let characteristics = [
                    CBUUID(string: kBXTOtaControlUUIDString),
                    CBUUID(string: kBXTOtaDataUUIDString)
                ]
                peripheral.discoverCharacteristics(characteristics, for: service)
            }
        }
    }
    
    public func updateCharacter(with service: CBService) {
        peripheral.bxs_swf_updateCharacter(with: service)
    }
    
    public func updateCurrentNotifySuccess(_ characteristic: CBCharacteristic) {
        peripheral.bxs_swf_updateCurrentNotifySuccess(characteristic)
    }
    
    public var connectSuccess: Bool {
        return peripheral.bxs_swf_connectSuccess(dfu: dfu)
    }
    
    public func setNil() {
        peripheral.bxs_swf_setNil()
    }
}

// MARK: - CBPeripheral Extension
extension CBPeripheral {
    // MARK: - Nested Types
    private struct BXSCharacteristics {
        var custom: CBCharacteristic?
        var disconnectType: CBCharacteristic?
        var threeSensor: CBCharacteristic?
        var password: CBCharacteristic?
        var hallSensor: CBCharacteristic?
        var temperatureHumidity: CBCharacteristic?
        var recordTH: CBCharacteristic?
        var recordVoltage: CBCharacteristic?
        var otaControl: CBCharacteristic?
        var otaData: CBCharacteristic?
        
        var customNotifySuccess = false
        var disconnectTypeNotifySuccess = false
        var passwordNotifySuccess = false
    }
    
    // MARK: - Thread-safe Storage
    private static let storageQueue = DispatchQueue(label: "com.MKSFBXS.characteristics.storage", attributes: .concurrent)
    nonisolated(unsafe) private static var _storage = [ObjectIdentifier: BXSCharacteristics]()
    
    private static var storage: [ObjectIdentifier: BXSCharacteristics] {
        get { storageQueue.sync { _storage } }
        set { storageQueue.async(flags: .barrier) { _storage = newValue } }
    }
    
    private var bxsCharacteristics: BXSCharacteristics {
        get {
            let id = ObjectIdentifier(self)
            return Self.storage[id] ?? BXSCharacteristics()
        }
        set {
            let id = ObjectIdentifier(self)
            Self.storage[id] = newValue
        }
    }
    
    // MARK: - Public Properties
    var bxs_swf_custom: CBCharacteristic? {
        get { bxsCharacteristics.custom }
        set {
            var current = bxsCharacteristics
            current.custom = newValue
            bxsCharacteristics = current
        }
    }
    
    var bxs_swf_disconnectType: CBCharacteristic? {
        get { bxsCharacteristics.disconnectType }
        set {
            var current = bxsCharacteristics
            current.disconnectType = newValue
            bxsCharacteristics = current
        }
    }
    
    var bxs_swf_threeSensor: CBCharacteristic? {
        get { bxsCharacteristics.threeSensor }
        set {
            var current = bxsCharacteristics
            current.threeSensor = newValue
            bxsCharacteristics = current
        }
    }
    
    var bxs_swf_password: CBCharacteristic? {
        get { bxsCharacteristics.password }
        set {
            var current = bxsCharacteristics
            current.password = newValue
            bxsCharacteristics = current
        }
    }
    
    var bxs_swf_hallSensor: CBCharacteristic? {
        get { bxsCharacteristics.hallSensor }
        set {
            var current = bxsCharacteristics
            current.hallSensor = newValue
            bxsCharacteristics = current
        }
    }
    
    var bxs_swf_temperatureHumidity: CBCharacteristic? {
        get { bxsCharacteristics.temperatureHumidity }
        set {
            var current = bxsCharacteristics
            current.temperatureHumidity = newValue
            bxsCharacteristics = current
        }
    }
    
    var bxs_swf_recordTH: CBCharacteristic? {
        get { bxsCharacteristics.recordTH }
        set {
            var current = bxsCharacteristics
            current.recordTH = newValue
            bxsCharacteristics = current
        }
    }
    
    var bxs_swf_recordVoltage: CBCharacteristic? {
        get { bxsCharacteristics.recordVoltage }
        set {
            var current = bxsCharacteristics
            current.recordVoltage = newValue
            bxsCharacteristics = current
        }
    }
    
    var bxs_swf_otaData: CBCharacteristic? {
        get { bxsCharacteristics.otaData }
        set {
            var current = bxsCharacteristics
            current.otaData = newValue
            bxsCharacteristics = current
        }
    }
    
    var bxs_swf_otaControl: CBCharacteristic? {
        get { bxsCharacteristics.otaControl }
        set {
            var current = bxsCharacteristics
            current.otaControl = newValue
            bxsCharacteristics = current
        }
    }
    
    // MARK: - Methods
    public func bxs_swf_updateCharacter(with service: CBService) {
        guard let characteristics = service.characteristics else { return }
        
        var current = bxsCharacteristics
        
        if service.uuid == CBUUID(string: "AA00") {
            for characteristic in characteristics {
                switch characteristic.uuid {
                case CBUUID(string: "AA01"):
                    current.custom = characteristic
                    setNotifyValue(true, for: characteristic)
                case CBUUID(string: "AA02"):
                    current.disconnectType = characteristic
                    setNotifyValue(true, for: characteristic)
                case CBUUID(string: "AA03"):
                    current.threeSensor = characteristic
                case CBUUID(string: "AA04"):
                    current.password = characteristic
                    setNotifyValue(true, for: characteristic)
                case CBUUID(string: "AA05"):
                    current.hallSensor = characteristic
                case CBUUID(string: "AA06"):
                    current.temperatureHumidity = characteristic
                case CBUUID(string: "AA09"):
                    current.recordTH = characteristic
                case CBUUID(string: "AA08"):
                    current.recordVoltage = characteristic
                default:
                    break
                }
            }
        } else if service.uuid == CBUUID(string: kBXTOtaServerUUIDString) {
            for characteristic in characteristics {
                switch characteristic.uuid {
                case CBUUID(string: kBXTOtaControlUUIDString):
                    current.otaControl = characteristic
                case CBUUID(string: kBXTOtaDataUUIDString):
                    current.otaData = characteristic
                default:
                    break
                }
            }
        }
        
        bxsCharacteristics = current
    }
    
    public func bxs_swf_updateCurrentNotifySuccess(_ characteristic: CBCharacteristic) {
        var current = bxsCharacteristics
        
        switch characteristic.uuid {
        case CBUUID(string: "AA01"):
            current.customNotifySuccess = true
        case CBUUID(string: "AA02"):
            current.disconnectTypeNotifySuccess = true
        case CBUUID(string: "AA04"):
            current.passwordNotifySuccess = true
        default:
            break
        }
        
        bxsCharacteristics = current
    }
    
    public func bxs_swf_connectSuccess(dfu: Bool) -> Bool {
        let chars = bxsCharacteristics
        
        if dfu {
            return chars.otaData != nil && chars.otaControl != nil
        }
        
        guard chars.customNotifySuccess,
              chars.passwordNotifySuccess,
              chars.disconnectTypeNotifySuccess else {
            return false
        }
        
        return chars.password != nil &&
            chars.disconnectType != nil &&
            chars.custom != nil &&
            chars.hallSensor != nil &&
            chars.threeSensor != nil &&
            chars.temperatureHumidity != nil &&
            chars.recordTH != nil &&
            chars.recordVoltage != nil
    }
    
    public func bxs_swf_setNil() {
        let id = ObjectIdentifier(self)
        Self.storageQueue.async(flags: .barrier) {
            Self._storage.removeValue(forKey: id)
        }
    }
}

