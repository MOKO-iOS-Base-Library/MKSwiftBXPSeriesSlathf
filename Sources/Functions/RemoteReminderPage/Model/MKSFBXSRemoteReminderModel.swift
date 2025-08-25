//
//  MKSFBXSRemoteReminderModel.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/21.
//

import Foundation
import MKBaseSwiftModule

enum RemoteReminderModelError: LocalizedError {
    case readRingingFre
    case configRingingFre
    case configRemoteReminderBuzzer
    
    var errorDescription: String? {
        switch self {
        case .readRingingFre:
            return "Read Ringing Frequency Error"
        case .configRingingFre:
            return "Config Ringing Frequency Error"
        case .configRemoteReminderBuzzer:
            return "Config Remote Reminder Buzzer Error"
        }
    }
}

@MainActor class MKSFBXSRemoteReminderModel {
    // MARK: - LED notification
    var ledBlinkingTime: String = ""
    var ledBlinkingInterval: String = ""
    
    // MARK: - Buzzer notification
    var buzzerRingingTime: String = ""
    var buzzerRingingInterval: String = ""
    
    /// 0:4000Hz 1:4500Hz
    var ringingFre: Int = 0
    
    func read() async throws {
        do {
            ringingFre = try await readRingingFre()
        } catch {
            throw error
        }
    }
    
    func config() async throws {
        do {
            _ = try await !configRingingFre()
            _ = try await !configRemoteReminderBuzzer()
        } catch {
            throw error
        }
    }
    
    private func readRingingFre() async throws -> Int {
        do {
            let frequency = try await MKSFBXSInterface.readRemoteReminderBuzzerFrequency()
            
            return Int(frequency)!
        }catch {
            throw error
        }
    }
    
    private func configRingingFre() async throws -> Bool {
        do {
            let result = try await MKSFBXSInterface.configRemoteReminderBuzzerFrequency(frequency: MKSFBXSBuzzerRingingFrequencyType(rawValue: ringingFre)!)
            if !result {
                throw RemoteReminderModelError.configRingingFre
            }
            return true
        }catch {
            throw error
        }
    }
    
    private func configRemoteReminderBuzzer() async throws -> Bool {
        do {
            let result = try await MKSFBXSInterface.configRemoteReminderBuzzerNotiParams(ringTime: Int(buzzerRingingTime)!, ringInterval: Int(buzzerRingingInterval)!)
            if !result {
                throw RemoteReminderModelError.configRingingFre
            }
            return true
        }catch {
            throw error
        }
    }
}
