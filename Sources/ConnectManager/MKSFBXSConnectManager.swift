//
//  MKSFBXSConnectManager.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/6/30.
//

@preconcurrency import CoreBluetooth

enum ConError: LocalizedError {
    case invalidPasswordFormat
    case connectionFailed
    case invalidHallSensorData
    case invalidResetButtonData
    case invalidSensorData
    
    var errorDescription: String? {
        switch self {
        case .invalidPasswordFormat:
            return "No more than 16 characters."
        case .connectionFailed:
            return "Connect Failed"
        case .invalidHallSensorData:
            return "Hall Sensor Error"
        case .invalidResetButtonData:
            return "Reset By Button Error"
        case .invalidSensorData:
            return "Sensor Type Error"
        }
    }
}

actor MKSFBXSConnectManager {
    
    var currentPassword: String { password }
    var requiresPassword: Bool { needPassword }
    var temperatureHumidityStatus: Int { thStatus }
    var accelerometerStatus: Int { accStatus }
    var hallSensorStatus: Bool { hallStatus }
    var resetByButtonStatus: Bool { resetByButton }
    
    // MARK: - Properties
    
    /// Current connection password
    private var password: String = ""
    
    /// Whether password is required for connection
    private var needPassword: Bool = false
    
    /// Hall sensor status: true = enabled, false = disabled
    private var hallStatus: Bool = false
    
    /// Button reset status
    private var resetByButton: Bool = false
    
    /// 0: No three-axis sensor, 1: Lis2DH/Lis3DH, 2: STK8328
    private var accStatus: Int = 0
    
    /// 0: No temperature/humidity sensor, 1: SHT30/SHT31, 2: SHT40, 3: STS40 (temp only), 4: SHT43
    private var thStatus: Int = 0
            
    // MARK: - Singleton
    
    static let shared = MKSFBXSConnectManager()
    private init() {}
    
    // MARK: - Public Methods
    
    func connectDevice(_ peripheral: CBPeripheral, password: String?) async throws {
        do {
            try await connectAndValidate(peripheral, password: password)
            
            self.hallStatus = try await MKSFBXSInterface.readHallSensorStatus()
            self.resetByButton = try await MKSFBXSInterface.readResetDeviceByButtonStatus()
            (self.accStatus, self.thStatus) = try await readSensorType()
        } catch {
            // 如果任何读取失败，断开连接并重新抛出错误
            await MKSwiftBXPSCentralManager.shared.disconnect()
            throw error
        }
    }
    
    func reset() {
        password = ""
        needPassword = false
        hallStatus = false
        resetByButton = false
        accStatus = 0
        thStatus = 0
    }
    
    private func connectAndValidate(_ peripheral: CBPeripheral, password: String?) async throws {
        if let psd = password {
            guard !psd.isEmpty, psd.count <= 16 else {
                throw ConError.invalidPasswordFormat
            }
        }
        
        do {
            if let psd = password {
                _ = try await MKSwiftBXPSCentralManager.shared.connectPeripheral(peripheral, password: psd)
                self.needPassword = true
                self.password = psd
            }else {
                _ = try await MKSwiftBXPSCentralManager.shared.connectPeripheral(peripheral)
                self.needPassword = false
                self.password = ""
            }
        } catch {
            await MKSwiftBXPSCentralManager.shared.disconnect()
            throw ConError.connectionFailed
        }
    }
    
    private func readSensorType() async throws ->(axis: Int, tempHumidity: Int) {
        do {
            let result = try await MKSFBXSInterface.readSensorType()
            
            return (Int(result.axis) ?? 0,Int(result.tempHumidity) ?? 0)
        } catch {
            throw error
        }
    }
}
