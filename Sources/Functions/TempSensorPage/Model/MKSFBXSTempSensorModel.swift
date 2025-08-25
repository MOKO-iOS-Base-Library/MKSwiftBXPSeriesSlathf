//
//  MKSFBXSTempSensorModel.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/21.
//

import Foundation
import MKBaseSwiftModule
import MKSwiftBleModule

enum TempSensorModelError: LocalizedError {
    case readSamplingInterval
    case configSamplingInterval
    case readStoreParams
    case configStoreParams
    case readDeviceTime
    
    var errorDescription: String? {
        switch self {
        case .readSamplingInterval:
            return "Read Sampling Interval Error"
        case .configSamplingInterval:
            return "Config Sampling Interval Error"
        case .readStoreParams:
            return "Read T&H Data Store Error"
        case .configStoreParams:
            return "Config T&H Data Store Error"
        case .readDeviceTime:
            return "Read Device Time Error"
        }
    }
}

@MainActor class MKSFBXSTempSensorModel {
    
    var samplingInterval: String = ""
    var deviceTime: String = ""
    var dataStore: Bool = false
    var interval: String = ""
    
    func read() async throws {
        do {
            samplingInterval = try await MKSFBXSInterface.readHTSamplingRate()
            (dataStore,interval) = try await readStoreParams()
            deviceTime = try await readDeviceTime()
        } catch {
            throw error
        }
    }
    
    func config() async throws {
        do {
            _ = try await configSamplingInterval()
            _ = try await configStoreParams()
        } catch {
            throw error
        }
    }
    
    private func configSamplingInterval() async throws -> Bool {
        do {
            let result = try await MKSFBXSInterface.configTHSamplingRate(rate: Int(samplingInterval)!)
            if !result {
                throw TempSensorModelError.configSamplingInterval
            }
            
            return result
        }catch {
            throw error
        }
    }
    
    private func readStoreParams() async throws -> (dataStore: Bool, interval: String) {
        do {
            let result = try await MKSFBXSInterface.readTHDataStoreParams()
            
            return (result.isOn,result.interval)
        } catch {
            throw error
        }
    }
    
    private func configStoreParams() async throws -> Bool {
        do {
            let result = try await MKSFBXSInterface.configTHDataStoreStatus(isOn: dataStore, interval: Int(interval)!)
            
            if !result {
                throw TempSensorModelError.configStoreParams
            }
            
            return result
        }catch {
            throw error
        }
    }
    
    private func readDeviceTime() async throws -> String {
        do {
            let time = try await MKSFBXSInterface.readDeviceUTCTime()
            
            let timestamp = Double(time)!
            let date = Date(timeIntervalSince1970: timestamp)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
            return dateFormatter.string(from: date)
        } catch {
            throw error
        }
    }
}
