//
//  MKSFBXSDFUModule.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/25.
//

@preconcurrency import CoreBluetooth
import MKBaseSwiftModule

/*
 DFU升级流程
 1、先判断设备是否有otaContral特征(@"f7bf3564-fb6d-4e53-88a4-5e37e0326063")特征，如果没有则直接认为失败。通过otaContral特征发送0x00通知设备开启dfu模式。
 2、收到设备接收0x00成功之后，判断设备是否有otaData特征(@"984227f3-34fc-4045-a5d0-2c581f81a153")，如果有的话，直接通过otaData发送一帧帧的升级数据，如果没有otaData特征，则需要先断开设备的连接，延时4s之后重新连接设备，然后跳到步骤1。
 3、当最后一帧dfu数据发送成功之后，则通过otaContral特征发送0x03通知设备结束ota，此时DFU升级完毕。
 */

enum DFUModuleError: LocalizedError {
    case updateFileError
    case disconnect
    case characteristicError
    case dfuFailed
    
    var errorDescription: String? {
        switch self {
        case .updateFileError:
            return "Dfu upgrade failure!"
        case .disconnect:
            return "Device is disconnected!"
        case .characteristicError:
            return "The current device does not support OTA"
        case .dfuFailed:
            return "DFU Failed"
        }
    }
}

class MKSFBXSDFUModule {
    
    private enum BXSOTAProcess {
        case start
        case reconnect
        case updating
        case complete
    }
    
    private let kBXTOTAByteAlignment = 4
    private let kBXTOTAByteAlignmentPadding: [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF]
    private let kBXTInitiateDFUData: UInt8 = 0x00
    private let kBXTTerminateFimwareUpdateData: UInt8 = 0x03
    private let kBXTOTAMaxMtuLen = 100
    
    private var peripheral: CBPeripheral?
    private var location = 0
    private var length = 0
    private var fileData: Data?
    private var otaProcess: BXSOTAProcess = .start
    
    private var dfuContinuation: CheckedContinuation<Void, Error>?
    
    deinit {
        print("MKSFBXSDFUModule销毁")
        NotificationCenter.default.removeObserver(self)
    }
    
    @MainActor
    func update(withFileUrl url: String) async throws {
        
        guard let zipData = try? Data(contentsOf: URL(fileURLWithPath: url)), !zipData.isEmpty else {
            throw DFUModuleError.updateFileError
        }
        
        guard MKSwiftBXPSCentralManager.shared.connectStatus == .connected else {
            throw DFUModuleError.disconnect
        }
        
        guard MKSwiftBXPSCentralManager.shared.otaContralCharacteristic() != nil else {
            throw DFUModuleError.characteristicError
        }
        
        fileData = zipData
        peripheral = MKSwiftBXPSCentralManager.shared.peripheral()
        location = 0
        length = kBXTOTAMaxMtuLen
        
        otaProcess = .reconnect
        
        writeSingleByteValue(
            kBXTInitiateDFUData,
            toCharacteristic: MKSwiftBXPSCentralManager.shared.otaContralCharacteristic()!
        )
        
        try await withCheckedThrowingContinuation { continuation in
            dfuContinuation = continuation
            MKSwiftBXPSCentralManager.shared.addCharacteristicWriteBlock { [weak self] peripheral, characteristic, error in
                if error != nil {
                    self?.dfuContinuation?.resume(throwing: DFUModuleError.dfuFailed)
                    return
                }
                self?.peripheral(peripheral, didWriteValueFor: characteristic)
            }
        }
    }
    
    @MainActor @objc private func deviceConnectTypeChanged() {
        let isDisconnected = (MKSwiftBXPSCentralManager.shared.connectStatus != .connected)
        let isNotComplete = (otaProcess != .complete)
        
        guard isDisconnected && isNotComplete else {
            return
        }
        
        // 在主线程安全地恢复continuation
        DispatchQueue.main.async { [weak self] in
            self?.dfuContinuation?.resume(throwing: DFUModuleError.dfuFailed)
        }
    }
    
    @MainActor private func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic) {
        
        Task {
            do {
                if characteristic.isEqual(MKSwiftBXPSCentralManager.shared.otaContralCharacteristic()) {
                    if otaProcess == .reconnect {
                        if MKSwiftBXPSCentralManager.shared.otaDataCharacteristic() != nil {
                            //当前设备不需要重连
                            NotificationCenter.default.addObserver(
                                self,
                                selector: #selector(deviceConnectTypeChanged),
                                name: .mk_bxs_swf_peripheralConnectStateChanged,
                                object: nil
                            )
                            writeFileData(toCharacteristic: characteristic)
                            return
                        }
                        try await reconnectDevice()
                        return
                    }
                    //设备刚进入dfu模式，重连接之后的操作。刚发送完00，设备启动dfu
                    if otaProcess == .updating {
                        writeFileData(toCharacteristic: MKSwiftBXPSCentralManager.shared.otaDataCharacteristic()!)
                        return
                    }
                    if otaProcess == .complete {
                        dfuContinuation?.resume()
                    }
                    return
                }
                if characteristic.isEqual(MKSwiftBXPSCentralManager.shared.otaDataCharacteristic()) {
                    if location < fileData!.count {
                        print("发送中")
                        writeFileData(toCharacteristic: characteristic)
                        return
                    }
                    //需要发送结束标志
                    print("发送最后一帧升级数据")
                    otaProcess = .complete
                    writeSingleByteValue(kBXTTerminateFimwareUpdateData,
                                         toCharacteristic: MKSwiftBXPSCentralManager.shared.otaContralCharacteristic()!)
                    return
                }
            } catch {
                throw error
            }
        }
    }
    
    private func reconnectDevice() async throws {
        // Reconnect device
        
        do {
            try await Task.sleep(nanoseconds: 4 * 1_000_000_000)
            _ = try await MKSwiftBXPSCentralManager.shared.connectPeripheral(peripheral!,dfu: true)
            otaProcess = .updating
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(deviceConnectTypeChanged),
                name: .mk_bxs_swf_peripheralConnectStateChanged,
                object: nil
            )
            
            await writeSingleByteValue(
                kBXTInitiateDFUData,
                toCharacteristic: MKSwiftBXPSCentralManager.shared.otaContralCharacteristic()!
            )
        } catch {
            throw error
        }
    }
    
    @MainActor private func writeFileData(toCharacteristic characteristic: CBCharacteristic) {
        guard let fileData = fileData else {
            return
        }
        
        let data: Data
        if location + length > fileData.count {
            let currentLength = fileData.count - location
            var mutableData = fileData.subdata(in: location..<(location + currentLength))
            
            let lengthPastByteAlignmentBoundary = currentLength % kBXTOTAByteAlignment
            if lengthPastByteAlignmentBoundary > 0 {
                let requiredAdditionalLength = kBXTOTAByteAlignment - lengthPastByteAlignmentBoundary
                mutableData.append(contentsOf: kBXTOTAByteAlignmentPadding[0..<requiredAdditionalLength])
            }
            
            data = mutableData
            location += currentLength
        } else {
            data = fileData.subdata(in: location..<(location + length))
            location += length
        }
        
        MKSwiftBXPSCentralManager.shared.peripheral()?.writeValue(
            data,
            for: characteristic,
            type: .withResponse
        )
    }
    
    @MainActor private func writeSingleByteValue(_ value: UInt8,
                                      toCharacteristic characteristic: CBCharacteristic) {
        let data = Data([value])
        MKSwiftBXPSCentralManager.shared.peripheral()?.writeValue(
            data,
            for: characteristic,
            type: .withResponse
        )
    }
}
