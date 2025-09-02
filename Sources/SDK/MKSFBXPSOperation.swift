//
//  MKSwiftBXPSOperation.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/6/19.
//

import Foundation
import CoreBluetooth
import MKSwiftBleModule

enum BXPSOperationError: LocalizedError {
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .timeout:
            return "Communication timeout"
        }
    }
}

class MKSwiftBXPSOperation: Operation, MKSwiftBleOperationProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    
    private var receiveTimer: DispatchSourceTimer?
    private var operationID: MKSFBXSTaskOperationID
    private var completeBlock: ((Error?, [String: Any]?) -> Void)?
    private var commandBlock: (() -> Void)?
    private var timeout: Bool = false
    private var receiveTimerCount: Int = 0
    private var dataList: [Data] = []
    
    private var _executing: Bool = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    private var _finished: Bool = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }
    
    override var isExecuting: Bool {
        return _executing
    }
    
    override var isFinished: Bool {
        return _finished
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    // MARK: - Initialization
    
    init(operationID: MKSFBXSTaskOperationID,
         commandBlock: (() -> Void)?,
         completeBlock: ((Error?, [String: Any]?) -> Void)?) {
        self.operationID = operationID
        self.commandBlock = commandBlock
        self.completeBlock = completeBlock
        super.init()
        _executing = false
        _finished = false
    }
    
    deinit {
        print("MP任务销毁")
    }
    
    // MARK: - Operation Overrides
    
    override func start() {
        if isFinished || isCancelled {
            _finished = true
            return
        }
        
        _executing = true
        startCommunication()
    }
    
    // MARK: - MKBLEBaseOperationProtocol
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic) {
        let data = MKSFBXSTaskAdopter.parseReadData(with: characteristic)
        dataParserReceivedData(data)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic) {
        let data = MKSFBXSTaskAdopter.parseWriteData(with: characteristic)
        dataParserReceivedData(data)
    }
    
    // MARK: - Private Methods
    
    private func startCommunication() {
        if isCancelled {
            return
        }
        
        // 切换到主线程执行 commandBlock
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 安全检查
            if self.commandBlock != nil {
                self.commandBlock!()
            }
            self.startReceiveTimer()
        }
    }
    
    private func startReceiveTimer() {
        let timerQueue = DispatchQueue(label: "com.bxps.receiveTimer", qos: .utility)
        receiveTimer = DispatchSource.makeTimerSource(queue: timerQueue)
        receiveTimer?.schedule(deadline: .now(), repeating: 0.1, leeway: .nanoseconds(0))
        
        receiveTimer?.setEventHandler { [weak self] in
            guard let self = self else {
                // 4. self 为 nil 时取消定时器
                self?.receiveTimer?.cancel()
                return
            }
            
            // 5. 检查取消状态
            guard !self.isCancelled else {
                self.receiveTimer?.cancel()
                return
            }
            
            // 6. 超时逻辑
            if self.timeout || self.receiveTimerCount >= 50 {
                self.receiveTimer?.cancel() // 超时后立即取消
                self.receiveTimer = nil
                self.timeout = true
                self.receiveTimerCount = 0
                self.finishOperation()
                self.completeBlock?(BXPSOperationError.timeout, nil)
                return
            }
            self.receiveTimerCount += 1
        }
        
        if isCancelled {
            return
        }
        
        receiveTimer?.resume()
    }
    
    private func finishOperation() {
        _executing = false
        _finished = true
    }
    
    private func dataParserReceivedData(_ dataDic: [String: Any]?) {
        guard !isCancelled,
              _executing,
              !timeout,
              let dataDic = dataDic,
              !dataDic.isEmpty else {
            return
        }
        
        guard let operationIDValue = dataDic["operationID"] as? Int,
              let currentOperationID = MKSFBXSTaskOperationID(rawValue: Int(operationIDValue)) else {
            print("operationID 转换失败")
            return
        }
        
        if currentOperationID == .defaultTaskOperationID || currentOperationID != operationID {
            print("operationID 不匹配: 收到 \(currentOperationID), 预期 \(operationID)")
            return
        }
        
        guard let returnData = dataDic["returnData"] as? [String: Any],
              !returnData.isEmpty else {
            return
        }
        
        // Handle fragmented data
        if let totalNum = returnData[mk_bxs_swf_totalNumKey] as? String, !totalNum.isEmpty {
            receiveTimerCount = 0
            if let data = returnData[mk_bxs_swf_contentKey] as? Data {
                dataList.append(data)
            }
            
            if dataList.count == Int(totalNum) {
                receiveTimer?.cancel()
                receiveTimer = nil
                finishOperation()
                completeBlock?(nil, ["result":dataList])
            }
            return
        }
        
        receiveTimer?.cancel()
        receiveTimer = nil
        finishOperation()
        completeBlock?(nil, returnData)
    }
}
