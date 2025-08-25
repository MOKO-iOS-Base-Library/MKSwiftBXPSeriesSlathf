//
//  MKSFBXSTriggerParamManager.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/23.
//

import Foundation

enum TriggerParamManagerError: LocalizedError {
    case readStepOneModel
    case configStepOneModel
    case readStepTwoModel
    case configStepTwoModel
    case readStepThreeModel
    case configStepThreeModel
    
    var errorDescription: String? {
        switch self {
        case .readStepOneModel:
            return "Read Step One Data Error"
        case .configStepOneModel:
            return "Config Step One Data Error"
        case .readStepTwoModel:
            return "Read Step Two Data Error"
        case .configStepTwoModel:
            return "Config Step Two Data Error"
        case .readStepThreeModel:
            return "Read Step Three Data Error"
        case .configStepThreeModel:
            return "Config Step Three Data Error"
        }
    }
}

class MKSFBXSTriggerParamManager {
    var slotIndex: Int = 0
        
    lazy var stepOneModel: MKSFBXSTriggerStepOneModel = {
        return MKSFBXSTriggerStepOneModel.init(slotIndex: slotIndex)
    }()
    
    lazy var stepTwoModel: MKSFBXSTriggerStepTwoModel = {
        return MKSFBXSTriggerStepTwoModel.init(slotIndex: slotIndex)
    }()
    lazy var stepThreeModel: MKSFBXSTriggerStepThreeModel = {
        return MKSFBXSTriggerStepThreeModel.init(slotIndex: slotIndex)
    }()
        
    // Singleton implementation
    static var shared: MKSFBXSTriggerParamManager {
        if _shared == nil {
            _shared = MKSFBXSTriggerParamManager()
        }
        return _shared!
    }
    
    static func sharedDealloc() {
        _shared = nil
    }
    
    nonisolated(unsafe) private static var _shared: MKSFBXSTriggerParamManager?
    
    func fetchStepThreeAlert() -> String {
        let triggerType = stepOneModel.fetchTriggerType()
        
        switch triggerType {
        case 0:
            //温度触发
            return fetchTemperatureTriggerMsg()
        case 1:
            //湿度触发
            return fetchHumidityTriggerMsg()
        case 2:
            //移动触发
            return fetchMotionTriggerMsg()
        case 3:
            //霍尔触发
            return fetchHallTriggerMsg()
        default:
            return ""
        }
    }
    
    // MARK: - Public Methods
    
    func read() async throws {
        do {
            try await readStepOneModel()
            try await readStepTwoModel()
            try await readStepThreeModel()
        } catch {
            throw error
        }
    }
    
    func config() async throws {
        do {
            try await configStepOneModel()
            if !stepOneModel.trigger {
                //关闭触发，step2和step3需要发送No data
                stepTwoModel.slotType = .null
                stepThreeModel.slotType = .null
            }
            try await configStepTwoModel()
            try await configStepThreeModel()
        } catch {
            throw error
        }
    }
    
    
    
    // MARK: - Private Methods
    
    private func readStepOneModel() async throws {
        do {
            try await stepOneModel.read()
        } catch {
            throw error
        }
    }
    
    private func configStepOneModel() async throws {
        do {
            try await stepOneModel.config()
        } catch {
            throw error
        }
    }
    
    private func readStepTwoModel() async throws {
        do {
            try await stepTwoModel.read()
        } catch {
            throw error
        }
    }
    
    private func configStepTwoModel() async throws {
        do {
            try await stepTwoModel.config()
        } catch {
            throw error
        }
    }
    
    private func readStepThreeModel() async throws {
        do {
            try await stepThreeModel.read()
        } catch {
            throw error
        }
    }
    
    private func configStepThreeModel() async throws {
        do {
            try await stepThreeModel.config()
        } catch {
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    // MARK: - Private Methods

    private func fetchTemperatureTriggerMsg() -> String {
        if stepOneModel.tempEvent == 0 {
            // Above
            if !stepThreeModel.trigger {
                // 不开启触发前广播
                if let advDuration = Int(stepTwoModel.advDuration), advDuration > 0 {
                    if !stepOneModel.lockedAdvIsOn {
                        return "*The Beacon will start advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after device temperature is more than or equal to \(stepOneModel.temperature)℃, and stop advertising immediately after device temperature is less than \(stepOneModel.temperature)℃"
                    }
                    return "*The Beacon will start advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after device temperature is more than or equal to \(stepOneModel.temperature)℃.(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before stopping)"
                }
                if let advDuration = Int(stepTwoModel.advDuration), advDuration == 0 {
                    if !stepOneModel.lockedAdvIsOn {
                        return "*The Beacon will keep advertising at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after device temperature is more than or equal to \(stepOneModel.temperature)℃, and stop advertising immediately after device temperature is less than \(stepOneModel.temperature)℃"
                    }
                    return "*The Beacon will keep advertising at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after device temperature is more than or equal to \(stepOneModel.temperature)℃, and stop advertising after device temperature is less than \(stepOneModel.temperature)℃.（If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the 5s post-trigger broadcast before stopping）"
                }
                return ""
            }
            // 开启触发前广播
            let standbyDuration = Int(stepThreeModel.standbyDuration) ?? 0
            let advDuration = Int(stepTwoModel.advDuration) ?? 0
            
            if standbyDuration > 0 && advDuration > 0 {
                var noteMsg = " *The Beacon will advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms when device temperature is more than or equal to \(stepOneModel.temperature)℃, and advertising for \(stepThreeModel.advDuration)s every \(standbyDuration)s at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when device temperature is less than \(stepOneModel.temperature)℃"
                if stepOneModel.lockedAdvIsOn {
                    noteMsg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before switching to the pre-trigger broadcast state)"
                }
                return noteMsg
            }
            if standbyDuration == 0 && advDuration > 0 {
                var noteMsg = "*The Beacon will advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms when device temperature is more than or equal to \(stepOneModel.temperature)℃, and  keep advertising at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when device temperature is less than \(stepOneModel.temperature)℃"
                if stepOneModel.lockedAdvIsOn {
                    noteMsg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before switching to the pre-trigger broadcast state)"
                }
                return noteMsg
            }
            if standbyDuration > 0 && advDuration == 0 {
                var noteMsg = "*The Beacon will keep advertising at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms when device temperature is more than or equal to \(stepOneModel.temperature)℃, and advertising for \(stepThreeModel.advDuration)s every \(standbyDuration)s at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when device temperature is less than \(stepOneModel.temperature)℃."
                if stepOneModel.lockedAdvIsOn {
                    noteMsg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered,the beacon will be locked to complete the 5s post-trigger broadcast before switching to the pre-trigger broadcast state)"
                }
                return noteMsg
            }
            if standbyDuration == 0 && advDuration == 0 {
                var noteMsg = "*The Beacon will keep advertising at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms when device temperature is more than or equal to \(stepOneModel.temperature)℃, and  keep advertising at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when device temperature is less than \(stepOneModel.temperature)℃"
                if stepOneModel.lockedAdvIsOn {
                    noteMsg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered,the beacon will be locked to complete the 5s post-trigger broadcast before switching to the pre-trigger broadcast state)"
                }
                return noteMsg
            }
            
            return ""
        }
        if stepOneModel.tempEvent == 1 {
            // Below
            if !stepThreeModel.trigger {
                // 不开启触发前广播
                if let advDuration = Int(stepTwoModel.advDuration), advDuration > 0 {
                    if !stepOneModel.lockedAdvIsOn {
                        return "*The Beacon will start advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after device temperature is less than or equal to \(stepOneModel.temperature)℃, and stop advertising immediately after device temperature is more than \(stepOneModel.temperature)℃."
                    }
                    return "*The Beacon will start advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after device temperature is less than or equal to \(stepOneModel.temperature)℃.(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before stopping)"
                }
                if let advDuration = Int(stepTwoModel.advDuration), advDuration == 0 {
                    if !stepOneModel.lockedAdvIsOn {
                        return "*The Beacon will keep advertising at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after device temperature is less than or equal to \(stepOneModel.temperature)℃, and stop advertising immediately after device temperature is more than \(stepOneModel.temperature)℃"
                    }
                    return "*The Beacon will keep advertising at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after device temperature is less than or equal to \(stepOneModel.temperature)℃, and stop advertising after device temperature is more than \(stepOneModel.temperature)℃.(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the 5s post-trigger broadcast before stopping)"
                }
                return ""
            }
            // 开启触发前广播
            let standbyDuration = Int(stepThreeModel.standbyDuration) ?? 0
            let advDuration = Int(stepTwoModel.advDuration) ?? 0
            
            if standbyDuration > 0 && advDuration > 0 {
                var noteMsg = "*The Beacon will advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms when device temperature is less than or equal to \(stepOneModel.temperature)℃, and advertising for \(stepThreeModel.advDuration)s every \(standbyDuration)s at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when device temperature is more than \(stepOneModel.temperature)℃."
                if stepOneModel.lockedAdvIsOn {
                    noteMsg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before switching to the pre-trigger broadcast state)"
                }
                return noteMsg
            }
            if standbyDuration == 0 && advDuration > 0 {
                var noteMsg = "*The Beacon will advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms when device temperature is less than or equal to \(stepOneModel.temperature)℃, and  keep advertising at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when device temperature is more than \(stepOneModel.temperature)℃."
                if stepOneModel.lockedAdvIsOn {
                    noteMsg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before switching to the pre-trigger broadcast state)"
                }
                return noteMsg
            }
            if standbyDuration > 0 && advDuration == 0 {
                var noteMsg = "*The Beacon will keep advertising at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms when device temperature is less than or equal to \(stepOneModel.temperature)℃, and advertising for \(stepThreeModel.advDuration)s every \(standbyDuration)s at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when device temperature is more than \(stepOneModel.temperature)℃."
                if stepOneModel.lockedAdvIsOn {
                    noteMsg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered,the beacon will be locked to complete the 5s post-trigger broadcast before switching to the pre-trigger broadcast state）)"
                }
                return noteMsg
            }
            if standbyDuration == 0 && advDuration == 0 {
                var noteMsg = "*The Beacon will keep advertising at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms when device temperature is less than or equal to \(stepOneModel.temperature)℃, and  keep advertising at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when device temperature is more than \(stepOneModel.temperature)℃"
                if stepOneModel.lockedAdvIsOn {
                    noteMsg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered,the beacon will be locked to complete the 5s post-trigger broadcast before switching to the pre-trigger broadcast state）)"
                }
                return noteMsg
            }
            
            return ""
        }
        return ""
    }

    private func fetchHumidityTriggerMsg() -> String {
        if stepOneModel.humidityEvent == 0 {
            // Above
            if !stepThreeModel.trigger {
                // 关闭触发前广播
                if let advDuration = Int(stepTwoModel.advDuration), advDuration > 0 {
                    if !stepOneModel.lockedAdvIsOn {
                        return "*The Beacon will start advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after device Himidity is more than or equal to \(stepOneModel.humidity)%, and stop advertising immediately after device Himidity is less than \(stepOneModel.humidity)%."
                    }
                    return "*The Beacon will start advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after device Himidity is more than or equal to \(stepOneModel.humidity)%.(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before stopping)"
                }
                if let advDuration = Int(stepTwoModel.advDuration), advDuration == 0 {
                    if !stepOneModel.lockedAdvIsOn {
                        return "*The Beacon will keep advertising at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after device Himidity is more than or equal to \(stepOneModel.humidity)%, and stop advertising immediately after device Himidity is less than \(stepOneModel.humidity)%."
                    }
                    return "*The Beacon will keep advertising at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after device Himidity is more than or equal to \(stepOneModel.humidity)%, and stop advertising after device Himidity is less than \(stepOneModel.humidity)%.(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the 5s post-trigger broadcast before stopping)"
                }
                
                return ""
            }
            // 开启触发前广播
            let standbyDuration = Int(stepThreeModel.standbyDuration) ?? 0
            let advDuration = Int(stepTwoModel.advDuration) ?? 0
            
            if standbyDuration > 0 && advDuration > 0 {
                var noteMsg = "*The Beacon will advertising for\(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms when device Himidity is more than or equal to \(stepOneModel.humidity)%, and advertising for \(stepThreeModel.advDuration)s every \(standbyDuration)s at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when device Himidity is less than \(stepOneModel.humidity)%."
                if stepOneModel.lockedAdvIsOn {
                    noteMsg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before switching to the pre-trigger broadcast state)"
                }
                return noteMsg
            }
            if standbyDuration == 0 && advDuration > 0 {
                var noteMsg = "*The Beacon will advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms when device Himidity is more than or equal to \(stepOneModel.humidity)%, and keep advertising at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when device Himidity is less than \(stepOneModel.humidity)%."
                if stepOneModel.lockedAdvIsOn {
                    noteMsg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before switching to the pre-trigger broadcast state)"
                }
                return noteMsg
            }
            if standbyDuration > 0 && advDuration == 0 {
                var noteMsg = "*The Beacon will keep advertising at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms when device Himidity is more than or equal to \(stepOneModel.humidity)%, and advertising for \(stepThreeModel.advDuration)s every \(standbyDuration)s at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when device Himidity is less than \(stepOneModel.humidity)%."
                if stepOneModel.lockedAdvIsOn {
                    noteMsg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered,the beacon will be locked to complete the 5s post-trigger broadcast before switching to the pre-trigger broadcast state)"
                }
                return noteMsg
            }
            if standbyDuration == 0 && advDuration == 0 {
                var noteMsg = "*The Beacon will keep advertising at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms when device Himidity is more than or equal to \(stepOneModel.humidity)%, and  keep advertising at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when device Himidity is less than \(stepOneModel.humidity)%."
                if stepOneModel.lockedAdvIsOn {
                    noteMsg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered,the beacon will be locked to complete the 5s post-trigger broadcast before switching to the pre-trigger broadcast state)"
                }
                return noteMsg
            }
            
            return ""
        }
        if stepOneModel.humidityEvent == 1 {
            // Below
            if !stepThreeModel.trigger {
                // 关闭触发前广播
                if let advDuration = Int(stepTwoModel.advDuration), advDuration > 0 {
                    if !stepOneModel.lockedAdvIsOn {
                        return "*The Beacon will start advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after device Himidity is less than or equal to \(stepOneModel.humidity)%, and stop advertising immediately after device Himidity is more than \(stepOneModel.humidity)%."
                    }
                    
                    return "*The Beacon will start advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after device Himidity is less than or equal to \(stepOneModel.humidity)%.(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before stopping)"
                }
                if let advDuration = Int(stepTwoModel.advDuration), advDuration == 0 {
                    if !stepOneModel.lockedAdvIsOn {
                        return "*The Beacon will keep advertising at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after device Himidity is less than or equal to \(stepOneModel.humidity)%, and stop advertising immediately after device Himidity is more than \(stepOneModel.humidity)%."
                    }
                    return "*The Beacon will keep advertising at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after device Himidity is less than or equal to \(stepOneModel.humidity)%, and stop advertising after device Himidity is more than \(stepOneModel.humidity)%.(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the 5s post-trigger broadcast before stopping)"
                }
                
                return ""
            }
            // 开启触发前广播
            let standbyDuration = Int(stepThreeModel.standbyDuration) ?? 0
            let advDuration = Int(stepTwoModel.advDuration) ?? 0
            
            if standbyDuration > 0 && advDuration > 0 {
                var noteMsg = "*The Beacon will advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms when device Himidity is less than or equal to \(stepOneModel.humidity)%, and advertising for \(stepThreeModel.advDuration)s every \(standbyDuration)s at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when device Himidity is more than \(stepOneModel.humidity)%."
                if stepOneModel.lockedAdvIsOn {
                    noteMsg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before switching to the pre-trigger broadcast state)"
                }
                return noteMsg
            }
            if standbyDuration == 0 && advDuration > 0 {
                var noteMsg = "*The Beacon will advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms when device Himidity is less than or equal to \(stepOneModel.humidity)%, and  keep advertising at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when device Himidity is more than \(stepOneModel.humidity)%."
                if stepOneModel.lockedAdvIsOn {
                    noteMsg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before switching to the pre-trigger broadcast state)"
                }
                return noteMsg
            }
            if standbyDuration > 0 && advDuration == 0 {
                var noteMsg = "*The Beacon will keep advertising at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms when device Himidity is less than or equal to \(stepOneModel.humidity)%, and advertising for \(stepThreeModel.advDuration)s every \(standbyDuration)s at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when device Himidity is more than \(stepOneModel.humidity)%."
                if stepOneModel.lockedAdvIsOn {
                    noteMsg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered,the beacon will be locked to complete the 5s post-trigger broadcast before switching to the pre-trigger broadcast state)"
                }
                return noteMsg
            }
            if standbyDuration == 0 && advDuration == 0 {
                var noteMsg = "*The Beacon will keep advertising at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms when device Himidity is less than or equal to \(stepOneModel.humidity)%, and keep advertising at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when device Himidity is more than \(stepOneModel.humidity)%."
                if stepOneModel.lockedAdvIsOn {
                    noteMsg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered,the beacon will be locked to complete the 5s post-trigger broadcast before switching to the pre-trigger broadcast state)"
                }
                return noteMsg
            }
            
            return ""
        }
        return ""
    }

    private func fetchMotionTriggerMsg() -> String {
        if stepOneModel.motionEvent == 0 {
            // Device start moving
            if !stepThreeModel.trigger {
                // 关闭触发前广播
                if let advDuration = Int(stepTwoModel.advDuration), advDuration > 0 {
                    return "*The Beacon will start advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after device moves, and stop advertising immediately after device keep stationary for \(stepOneModel.motionVerificationPeriod)s"
                }
                return "*The Beacon will start advertising for \(stepOneModel.motionVerificationPeriod)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after device moves, and stop advertising immediately after device keep stationary for \(stepOneModel.motionVerificationPeriod)s"
            }
            
            // 打开触发前广播
            let standbyDuration = Int(stepThreeModel.standbyDuration) ?? 0
            let advDuration = Int(stepTwoModel.advDuration) ?? 0
            
            if standbyDuration > 0 {
                if advDuration > 0 {
                    return " *The Beacon will advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after device moves, and advertising for \(stepThreeModel.advDuration)s every \(standbyDuration)s at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when device keep stationary for \(stepOneModel.motionVerificationPeriod)s"
                }
                return "*The Beacon will advertising for \(stepOneModel.motionVerificationPeriod)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after device moves, and advertising for \(stepThreeModel.advDuration)s every \(standbyDuration)s at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when device keep stationary for \(stepOneModel.motionVerificationPeriod)s"
            }
            if advDuration > 0 {
                return "*The Beacon will advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after device moves, and  keep advertising at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when device keep stationary for \(stepOneModel.motionVerificationPeriod)s"
            }
            return "*The Beacon will advertising for \(stepOneModel.motionVerificationPeriod)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after device moves, and  keep advertising at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when device keep stationary for \(stepOneModel.motionVerificationPeriod)s"
        }
        if stepOneModel.motionEvent == 1 {
            // Device remains stationary
            if !stepThreeModel.trigger {
                // 关闭触发前广播
                if let advDuration = Int(stepTwoModel.advDuration), advDuration > 0 {
                    return "*The Beacon will start advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after device keep stationary for \(stepOneModel.motionVerificationPeriod)s, and stop advertising immediately when device moves."
                }
                return "*The Beacon will keep advertising at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after device keep stationary for \(stepOneModel.motionVerificationPeriod)s, and stop advertising immediately when device moves."
            }
            // 打开触发前广播
            if let advDuration = Int(stepTwoModel.advDuration), advDuration > 0 {
                return "*The Beacon will start advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after device keep stationary for \(stepOneModel.motionVerificationPeriod)s, and advertising for \(stepThreeModel.advDuration)s at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when device moves."
            }
            return "*The Beacon will keep advertising at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after device keep stationary for \(stepOneModel.motionVerificationPeriod)s, and advertising for StaticVs at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when device moves. "
        }
        return ""
    }

    private func fetchHallTriggerMsg() -> String {
        if stepOneModel.hallEvent == 0 {
            // Door open
            if !stepThreeModel.trigger {
                // 关闭触发前广播
                if let advDuration = Int(stepTwoModel.advDuration), advDuration > 0 {
                    if !stepOneModel.lockedAdvIsOn {
                        return "*The Beacon will start advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after door open, and stop advertising immediately when door close."
                    }
                    return "*The Beacon will start advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms when door open.(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before stopping)"
                }
                if let advDuration = Int(stepTwoModel.advDuration), advDuration == 0 {
                    if !stepOneModel.lockedAdvIsOn {
                        return "*The Beacon will keep advertising at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after door open, and stop advertising immediately when door close."
                    }
                    return "*The Beacon will keep advertising at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after door open, and stop advertising when door close.(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the 5s post-trigger broadcast before stopping)"
                }
                
                return ""
            }
            // 打开触发前广播
            let standbyDuration = Int(stepThreeModel.standbyDuration) ?? 0
            let advDuration = Int(stepTwoModel.advDuration) ?? 0
            
            if standbyDuration > 0 && advDuration > 0 {
                var noteMsg = "*The Beacon will advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after door open, and advertising for \(stepThreeModel.advDuration)s every \(standbyDuration)s at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when door close."
                if stepOneModel.lockedAdvIsOn {
                    noteMsg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before switching to the pre-trigger broadcast state)"
                }
                return noteMsg
            }
            if standbyDuration == 0 && advDuration > 0 {
                var noteMsg = " *The Beacon will advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after door open,and keep advertising at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when door close."
                if stepOneModel.lockedAdvIsOn {
                    noteMsg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before switching to the pre-trigger broadcast state)"
                }
                return noteMsg
            }
            if standbyDuration > 0 && advDuration == 0 {
                var noteMsg = "*The Beacon will keep advertising at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after door open, and advertising for \(stepThreeModel.advDuration)s every \(standbyDuration)s at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when door close."
                if stepOneModel.lockedAdvIsOn {
                    noteMsg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered,the beacon will be locked to complete the 5s post-trigger broadcast before switching to the pre-trigger broadcast state)"
                }
                return noteMsg
            }
            if standbyDuration == 0 && advDuration == 0 {
                var noteMsg = "*The Beacon will keep advertising at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after door open, and keep advertising at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when door close."
                if stepOneModel.lockedAdvIsOn {
                    noteMsg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered,the beacon will be locked to complete the 5s post-trigger broadcast before switching to the pre-trigger broadcast state)"
                }
                return noteMsg
            }
            
            return ""
        }
        if stepOneModel.hallEvent == 1 {
            // Door close
            if !stepThreeModel.trigger {
                // 关闭触发前广播
                if let advDuration = Int(stepTwoModel.advDuration), advDuration > 0 {
                    if !stepOneModel.lockedAdvIsOn {
                        return "*The Beacon will start advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after door close, and stop advertising immediately when door open."
                    }
                    return "*The Beacon will start advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after door close.(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before stopping)"
                }
                if let advDuration = Int(stepTwoModel.advDuration), advDuration == 0 {
                    if !stepOneModel.lockedAdvIsOn {
                        return "*The Beacon will keep advertising at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after door close, and stop advertising immediately when door open."
                    }
                    return "*The Beacon will keep advertising at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after door close, and stop advertising when door open.(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the 5s post-trigger broadcast before stopping)"
                }
                
                return ""
            }
            // 打开触发前广播
            let standbyDuration = Int(stepThreeModel.standbyDuration) ?? 0
            let advDuration = Int(stepTwoModel.advDuration) ?? 0
            
            if standbyDuration > 0 && advDuration > 0 {
                var noteMsg = "*The Beacon will advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after door close, and advertising for \(stepThreeModel.advDuration)s every \(standbyDuration)s at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when door open."
                if stepOneModel.lockedAdvIsOn {
                    noteMsg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before switching to the pre-trigger broadcast state)"
                }
                return noteMsg
            }
            if standbyDuration == 0 && advDuration > 0 {
                var noteMsg = "*The Beacon will advertising for \(advDuration)s at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after door close, and keep advertising at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when door open."
                if stepOneModel.lockedAdvIsOn {
                    noteMsg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered, the beacon will be locked to complete the Total adv duration broadcast before switching to the pre-trigger broadcast state)"
                }
                return noteMsg
            }
            if standbyDuration > 0 && advDuration == 0 {
                var noteMsg = "*The Beacon will keep advertising at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after door close, and advertising for \(stepThreeModel.advDuration)s every \(standbyDuration)s at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when door open."
                if stepOneModel.lockedAdvIsOn {
                    noteMsg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered,the beacon will be locked to complete the 5s post-trigger broadcast before switching to the pre-trigger broadcast state)"
                }
                return noteMsg
            }
            if standbyDuration == 0 && advDuration == 0 {
                var noteMsg = "*The Beacon will keep advertising at the interval of \(fetchIntervalMsgValue(stepTwoModel.advInterval))ms after door close, and keep advertising at the interval of \(fetchIntervalMsgValue(stepThreeModel.advInterval))ms when door open."
                if stepOneModel.lockedAdvIsOn {
                    noteMsg += "(If the beacon quickly returns to a state where the trigger condition is no longer met shortly after the event is triggered,the beacon will be locked to complete the 5s post-trigger broadcast before switching to the pre-trigger broadcast state)"
                }
                return noteMsg
            }
            
            return ""
        }
        return ""
    }

    private func fetchIntervalMsgValue(_ interval: String) -> String {
        if let intervalValue = Int(interval) {
            return "\(intervalValue * 100)"
        }
        return "0"
    }
}
