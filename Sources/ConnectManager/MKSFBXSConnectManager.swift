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
    
    func getPassword() -> String { password }
    func getNeedPassword() -> Bool { needPassword }
    func getThStatus() -> Int { thStatus }
    func getAccStatus() -> Int { accStatus }
    func getHallStatus() -> Bool { hallStatus }
    func getResetByButton() -> Bool { resetByButton }
        
    // MARK: - Singleton
    
    static let shared = MKSFBXSConnectManager()
    private init() {}
    
    // MARK: - Public Methods
    
    func connectDevice(_ peripheral: CBPeripheral, password: String?) async throws {
        try await connectAndValidate(peripheral, password: password)
        
        async let hallStatus = readHallStatus()
        async let resetStatus = readResetButtonStatus()
        async let sensorType = readSensorType()
        
        // 3. 更新设备状态
        do {
            (self.hallStatus, self.resetByButton, self.accStatus, self.thStatus) = try await (
                hallStatus, resetStatus, sensorType.axis, sensorType.tempHumidity
            )
        } catch {
            // 如果任何读取失败，断开连接并重新抛出错误
            await MKSwiftBXPSCentralManager.shared.disconnect()
            throw error
        }
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
    
    private func readHallStatus() async throws ->Bool {
        do {
            return try await MKSFBXSInterface.readHallSensorStatus()
        } catch {
            throw error
        }
    }
    
    private func readResetButtonStatus() async throws ->Bool {
        do {
            return try await MKSFBXSInterface.readResetDeviceByButtonStatus()
        } catch {
            throw error
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
