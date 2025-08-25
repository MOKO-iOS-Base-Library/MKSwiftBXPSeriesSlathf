//
//  MKSFBXSSlotConfigDataModel.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/23.
//
import Foundation
import MKBaseSwiftModule
import MKSwiftBleModule

enum SlotConfigDataModelError: LocalizedError {
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

class MKSFBXSSlotConfigDataModel: MKSFBXSSlotDataBaseModel {
    
    override init(slotIndex index: Int) {
        super.init(slotIndex: index)
    }
    
    // MARK: - Public Methods
    
    override func read() async throws {
        do {
            let result = try await readSlotDatas()
            updateSlotDatas(result)
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
            let result = try await MKSFBXSInterface.readSlotData(index: index)
            
            return result.value
        } catch {
            throw error
        }
    }
    
    private func configTLM() async throws -> Bool {
        do {
            let result = try await MKSFBXSInterface.configSlotTLM(index: index, type: .slotData, advParams: currentContentParam())
            
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
            let result = try await MKSFBXSInterface.configSlotUID(index: index, type: .slotData, advParams: currentContentParam(), namespaceID: namespaceID, instanceID: instanceID)
            
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
            let result = try await MKSFBXSInterface.configSlotURL(index: index, type: .slotData, advParams: currentContentParam(), urlType: MKSFBXSURLHeaderType(rawValue: urlType)!, urlContent: urlContent)
            
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
            let result = try await MKSFBXSInterface.configSlotBeacon(index: index, type: .slotData, advParams: currentContentParam(), major: Int(major)!, minor: Int(minor)!, uuid: uuid)
            
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
            let result = try await MKSFBXSInterface.configSlotSensorInfo(index: index, type: .slotData, advParams: currentContentParam(), deviceName: deviceName, tagID: tagID)
            
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
            let result = try await MKSFBXSInterface.configSlotNoData(slotIndex: index, type: .slotData, advParams: currentContentParam())
            
            if !result {
                throw SlotConfigDataModelError.configSlotDatas
            }
            return result
        } catch {
            throw error
        }
    }
}
