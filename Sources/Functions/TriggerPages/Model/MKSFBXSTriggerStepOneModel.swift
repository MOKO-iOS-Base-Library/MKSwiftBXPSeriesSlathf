//
//  MKSFBXSTriggerStepOneModel.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/23.
//

import Foundation

enum TriggerStepOneModelError: LocalizedError {
    case paramsError
    case readTriggerDatas
    case configSlotDatas
    case closeTrigger
    case configTemperatureTriggerParams
    case configHumidityTriggerParams
    case configMotionDetectionTriggerParams
    case configHallTriggerParams
    
    var errorDescription: String? {
        switch self {
        case .paramsError:
            return "Params Error"
        case .readTriggerDatas:
            return "Read Trigger Datas Error"
        case .configSlotDatas:
            return "Config Slot Datas Error"
        case .closeTrigger:
            return "Close Trigger Error"
        case .configTemperatureTriggerParams:
            return "Config Trigger Temperature Params Error"
        case .configHumidityTriggerParams:
            return "Config Trigger Humidity Params Error"
        case .configMotionDetectionTriggerParams:
            return "Config Trigger Motion Detection Params Error"
        case .configHallTriggerParams:
            return "Config Trigger Hall Params Error"
        }
    }
}

struct MKSFBXSTriggerTypeModel {
    // 0:Temperature 1:Humidity 2:Motion detection 3:Door magnetic detection
    var triggerType: Int = 0
    //当前选中的triggerType，根据传感器类型和霍尔、按键开关机状态不同，该值意义也不同
    var triggerIndex: Int = 0
    var triggerMsg: String = ""
}

class MKSFBXSTriggerStepOneModel {
    
    var trigger: Bool = false
    /// 当前选中的triggerIndex，根据传感器类型和霍尔、按键开关机状态不同，该值意义也不同
    var triggerIndex: Int = 0
    
    // Temperature parameters
    var tempEvent: Int = 0 // 0:Above 1:Below
    var temperature: Int = 0
    
    // Humidity parameters
    var humidityEvent: Int = 0 // 0:Above 1:Below
    var humidity: Int = 0
    
    // Motion parameters
    // 0:Device start moving 1:Device remains stationary
    var motionEvent: Int = 0
    var motionVerificationPeriod: String = ""
    
    // Hall parameters
    // 0:Door open 1:Door close
    var hallEvent: Int = 0
    var lockedAdvIsOn: Bool = false
    
    private var index: Int = 0
    private lazy var triggerTypeList: [MKSFBXSTriggerTypeModel] = []
    private var currentTriggerType: Int = 0 // 0:温度触发 1:湿度触发 2:移动触发 3:霍尔触发
    
    init(slotIndex index: Int) {
        self.index = index
    }
    
    // MARK: - Public Methods
    
    func fetchTriggerTypeList() -> [String] {
        return triggerTypeList.map { $0.triggerMsg }
    }
    
    func fetchTriggerType() -> Int {
        for model in triggerTypeList {
            if model.triggerIndex == triggerIndex {
                return model.triggerType
            }
        }
        return 0
    }
    
    func loadTriggerTypeList() async {
        let manager = MKSFBXSConnectManager.shared
        
        let thStatus = await manager.getThStatus()
        let accStatus = await manager.getAccStatus()
        let hallStatus = await manager.getHallStatus()
        let resetByButton = await manager.getResetByButton()
        
        if thStatus > 0 {
            var temperatureModel = MKSFBXSTriggerTypeModel()
            temperatureModel.triggerMsg = "Temperature detect"
            temperatureModel.triggerType = 0
            triggerTypeList.append(temperatureModel)
            
            if thStatus != 3 {
                //thStatus == 3:温度传感器，1/2/4为温湿度
                var humidityModel = MKSFBXSTriggerTypeModel()
                humidityModel.triggerMsg = "Humidity detect"
                humidityModel.triggerType = 1
                triggerTypeList.append(humidityModel)
            }
        }
        
        if accStatus > 0 {
            var motionModel = MKSFBXSTriggerTypeModel()
            motionModel.triggerMsg = "Motion detect"
            motionModel.triggerType = 2
            triggerTypeList.append(motionModel)
        }
        
        if !hallStatus && !resetByButton {
            var magneticModel = MKSFBXSTriggerTypeModel()
            magneticModel.triggerMsg = "magnetic detect"
            magneticModel.triggerType = 3
            triggerTypeList.append(magneticModel)
        }
        
        for index in triggerTypeList.indices {
            triggerTypeList[index].triggerIndex = index
        }
    }
    
    func read() async throws {
        do {
            let result = try await readTriggerDatas()
            await updateParams(result)
            updateTriggerIndex()
        } catch {
            throw error
        }
    }
    
    func config() async throws {
        do {
            if !validParams() {
                throw TriggerStepOneModelError.paramsError
            }
            if !trigger {
                _ = try await closeTrigger()
            } else {
                if fetchTriggerType() == 0 {
                    //温度触发
                    _ = try await configTemperatureTriggerParams()
                } else if fetchTriggerType() == 1 {
                    //湿度触发
                    _ = try await configHumidityTriggerParams()
                } else if fetchTriggerType() == 2 {
                    //移动触发
                    _ = try await configMotionDetectionTriggerParams()
                } else if fetchTriggerType() == 3 {
                    //霍尔触发
                    _ = try await configHallTriggerParams()
                }
            }
            
        } catch {
            throw error
        }
    }
    
    //MARK: - Private methods
    func validParams() -> Bool {
        if fetchTriggerType() == 2 {
            // Motion detection
            if motionEvent < 0 || motionEvent > 1 || motionVerificationPeriod.isEmpty || Int(motionVerificationPeriod) ?? 0 < 1 || Int(motionVerificationPeriod) ?? 0 > 65535 {
                return false
            }
        }
        return true
    }
    
    private func updateParams(_ result: [String: Any]) async {
        guard !result.isEmpty else { return }
        
        let manager = MKSFBXSConnectManager.shared
        
        let thStatus = await manager.getThStatus()
        let accStatus = await manager.getAccStatus()
        let hallStatus = await manager.getHallStatus()
        let resetByButton = await manager.getResetByButton()
            
        trigger = Int(result["triggerType"] as! String)! > 0
            
        if !trigger {
            if accStatus > 0 {
                // Motion detection available
                currentTriggerType = 2
                motionEvent = 0
                motionVerificationPeriod = "30"
                return
            }
            //不存在三轴传感器
            if thStatus > 0 {
                // Temperature/Humidity sensor available
                currentTriggerType = 0
                temperature = 0
                tempEvent = 0
                return
            }
            //不存在移动和温度
            if !hallStatus && !resetByButton {
                // Hall sensor available
                currentTriggerType = 3
                hallEvent = 0
                return
            }
            return
        }
        
        currentTriggerType = Int(result["triggerType"] as! String)! - 1
        lockedAdvIsOn = result["lockedAdv"] as? Bool ?? false
        
        switch currentTriggerType {
        case 0:
            //温度触发
            temperature = Int(result["temperature"] as! String)!
            tempEvent = Int(result["event"] as! String)!
        case 1:
            //湿度触发
            humidity = Int(result["humidity"] as! String)!
            humidityEvent = Int(result["event"] as! String)!
        case 2:
            //移动触发
            motionEvent = Int(result["event"] as! String)!
            motionVerificationPeriod = result["period"] as? String ?? ""
        case 3:
            //霍尔触发
            hallEvent = Int(result["event"] as! String)!
        default:
            break
        }
    }
    
    private func updateTriggerIndex() {
        for model in triggerTypeList {
            if model.triggerType == currentTriggerType {
                triggerIndex = model.triggerIndex
                break
            }
        }
    }
    
    //MARK: - Interface
    private func readTriggerDatas() async throws -> [String:Any] {
        do {
            let result = try await MKSFBXSInterface.readSlotTriggerData(index: index)
            
            return result.value
        } catch {
            throw error
        }
    }
    
    private func closeTrigger() async throws -> Bool {
        do {
            let result = try await MKSFBXSInterface.closeSlotTrigger(index: index)
            
            if !result {
                throw TriggerStepOneModelError.closeTrigger
            }
            return result
        } catch {
            throw error
        }
    }
    
    private func configTemperatureTriggerParams() async throws -> Bool {
        do {
            let result = try await MKSFBXSInterface.configTemperatureTriggerParams(slotIndex: index, triggerEvent: tempEvent, temperature: temperature, lockedADV: lockedAdvIsOn)
            
            if !result {
                throw TriggerStepOneModelError.configTemperatureTriggerParams
            }
            return result
        } catch {
            throw error
        }
    }
    
    private func configHumidityTriggerParams() async throws -> Bool {
        do {
            let result = try await MKSFBXSInterface.configHumidityTriggerParams(slotIndex: index, triggerEvent: humidityEvent, humidity: humidity, lockedADV: lockedAdvIsOn)
            
            if !result {
                throw TriggerStepOneModelError.configHumidityTriggerParams
            }
            return result
        } catch {
            throw error
        }
    }
    
    private func configMotionDetectionTriggerParams() async throws -> Bool {
        do {
            let result = try await MKSFBXSInterface.configMotionDetectionTriggerParams(slotIndex: index, triggerEvent: motionEvent, period: Int(motionVerificationPeriod)!, lockedADV: lockedAdvIsOn)
            
            if !result {
                throw TriggerStepOneModelError.configMotionDetectionTriggerParams
            }
            return result
        } catch {
            throw error
        }
    }
    
    private func configHallTriggerParams() async throws -> Bool {
        do {
            let result = try await MKSFBXSInterface.configHallTriggerParams(slotIndex: index, triggerEvent: hallEvent, lockedADV: lockedAdvIsOn)
            
            if !result {
                throw TriggerStepOneModelError.configHallTriggerParams
            }
            return result
        } catch {
            throw error
        }
    }
}
