//
//  MKSFBXSTriggerStepTwoModel.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/23.
//

import Foundation

enum TriggerStepTwoModelError: LocalizedError {
    case paramsError
    case readSlotDatas
    case configSlotDatas
    
    var errorDescription: String? {
        switch self {
        case .paramsError:
            return "Params Error"
        case .readSlotDatas:
            return "Read Slot Datas Error"
        case .configSlotDatas:
            return "Config Slot Datas Error"
        }
    }
}

class MKSFBXSTriggerStepTwoModel: MKSFBXSSlotDataBaseModel {
    
    override init(slotIndex index: Int) {
        super.init(slotIndex: index)
    }
    
    // MARK: - Public Methods
    
    override func validParams() -> Bool {
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
              advDurationValue >= 0, advDurationValue <= 65535 else {
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
    
    // MARK: - Public Methods
    
    override func read() async throws {
        do {
            let result = try await readSlotDatas()
            updateSlotDatas(result)
            if slotType == .null {
                //无触发默认显示Sensor Info
                slotType = .sensorInfo
            }
        } catch {
            throw error
        }
    }
    
    override func config() async throws {
        do {
            if !validParams() {
                throw SlotConfigDataModelError.paramsError
            }
            if slotType == .tlm {
                _ = try await configTLM()
            } else if slotType == .uid {
                _ = try await configUID()
            } else if slotType == .url {
                _ = try await configURL()
            } else if slotType == .beacon {
                _ = try await configBeacon()
            } else if slotType == .sensorInfo {
                _ = try await configSensorInfo()
            } else if slotType == .null {
                _ = try await configNoData()
            }
        } catch {
            throw error
        }
    }
    
    
    
    // MARK: - Private Methods
    
    private func readSlotDatas() async throws -> [String:Any] {
        do {
            let result = try await MKSFBXSInterface.readTriggerSlotData(index: index)
            
            return result.value
        } catch {
            throw error
        }
    }
    
    private func configTLM() async throws -> Bool {
        do {
            let result = try await MKSFBXSInterface.configSlotTriggeredTLM(index: index, advParams: currentTriggerContentParam())
            
            if !result {
                throw SlotConfigDataModelError.configSlotDatas
            }
            return result
        } catch {
            throw error
        }
    }
    
    private func configUID() async throws -> Bool {
        do {
            let result = try await MKSFBXSInterface.configSlotTriggeredUID(index: index, advParams: currentTriggerContentParam(), namespaceID: namespaceID, instanceID: instanceID)
            
            if !result {
                throw SlotConfigDataModelError.configSlotDatas
            }
            return result
        } catch {
            throw error
        }
    }
    
    private func configURL() async throws -> Bool {
        do {
            let result = try await MKSFBXSInterface.configSlotTriggeredURL(index: index, advParams: currentTriggerContentParam(), urlType: MKSFBXSURLHeaderType(rawValue: urlType)!, urlContent: urlContent)
            
            if !result {
                throw SlotConfigDataModelError.configSlotDatas
            }
            return result
        } catch {
            throw error
        }
    }
    
    private func configBeacon() async throws -> Bool {
        do {
            let result = try await MKSFBXSInterface.configSlotTriggeredBeacon(index: index, advParams: currentTriggerContentParam(), major: Int(major)!, minor: Int(minor)!, uuid: uuid)
            
            if !result {
                throw SlotConfigDataModelError.configSlotDatas
            }
            return result
        } catch {
            throw error
        }
    }
    
    private func configSensorInfo() async throws -> Bool {
        do {
            let result = try await MKSFBXSInterface.configSlotTriggeredSensorInfo(index: index, advParams: currentTriggerContentParam(), deviceName: deviceName, tagID: tagID)
            
            if !result {
                throw SlotConfigDataModelError.configSlotDatas
            }
            return result
        } catch {
            throw error
        }
    }
    
    private func configNoData() async throws -> Bool {
        do {
            let result = try await MKSFBXSInterface.configSlotTriggeredNoData(index: index, advParams: currentTriggerContentParam())
            
            if !result {
                throw SlotConfigDataModelError.configSlotDatas
            }
            return result
        } catch {
            throw error
        }
    }
}
