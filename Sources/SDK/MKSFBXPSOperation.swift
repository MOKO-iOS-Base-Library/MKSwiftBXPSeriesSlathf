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
    
    private let stateQueue = DispatchQueue(label: "com.bxps.operation.state", attributes: .concurrent)
    
    private var receiveTimer: DispatchSourceTimer?
    private var operationID: MKSFBXSTaskOperationID
    private var completeBlock: ((Error?, [String: Any]?) -> Void)?
    private var commandBlock: (() -> Void)?

    private var _timeout: Bool = false
    private var timeout: Bool {
        get { stateQueue.sync { _timeout } }
        set { stateQueue.async(flags: .barrier) { self._timeout = newValue } }
    }
    
    private var _receiveTimerCount: Int = 0
    private var receiveTimerCount: Int {
        get { stateQueue.sync { _receiveTimerCount } }
        set { stateQueue.async(flags: .barrier) { self._receiveTimerCount = newValue } }
    }
    
    private var _dataList: [Data] = []
    private var dataList: [Data] {
        get { stateQueue.sync { _dataList } }
        set { stateQueue.async(flags: .barrier) { self._dataList = newValue } }
    }
    
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
    
    // MARK: - 修复取消方法
    override func cancel() {
        super.cancel()
        
        // 在主线程执行取消操作
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 安全调用 completeBlock（如果操作被取消）
            if let block = self.completeBlock, !self.isFinished {
                block(NSError(domain: "OperationCancelled", code: -1, userInfo: nil), nil)
                self.completeBlock = nil
            }
            
            self.stopReceiveTimer()
            self.finishOperation()
        }
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
        receiveTimer?.schedule(deadline: .now() + 0.1, repeating: 0.1, leeway: .milliseconds(5))
        
        // 使用 weak self 避免循环引用
        receiveTimer?.setEventHandler { [weak self] in
            guard let self = self else {
                return
            }
            
            // 检查操作是否已经完成或取消
            if self.isFinished || self.isCancelled {
                self.stopReceiveTimer()
                return
            }
            
            // 原子性检查超时条件
            let shouldTimeout = self.timeout || self.receiveTimerCount >= 50
            if shouldTimeout {
                self.handleTimeout()
                return
            }
            
            self.receiveTimerCount += 1
        }
        
        // 设置取消处理器
        receiveTimer?.setCancelHandler { [weak self] in
            self?.receiveTimer = nil
        }
        
        if isCancelled || isFinished {
            stopReceiveTimer()
            return
        }
        
        receiveTimer?.resume()
    }
    
    private func handleTimeout() {
        // 确保只在主线程执行回调
        DispatchQueue.main.async { [weak self] in
            guard let self = self, !self.isFinished else { return }
            
            // 设置超时状态
            self.timeout = true
            
            // 安全调用 completeBlock（只调用一次）
            if let block = self.completeBlock {
                block(BXPSOperationError.timeout, nil)
                // 调用后立即置空，避免重复调用
                self.completeBlock = nil
            }
            
            // 停止定时器并完成操作
            self.stopReceiveTimer()
            self.finishOperation()
        }
    }
    
    private func stopReceiveTimer() {
        receiveTimer?.cancel()
        receiveTimer = nil
        receiveTimerCount = 0
    }
    
    private func finishOperation() {
        // 确保状态修改是原子的
        guard !_finished else { return }
        
        _executing = false
        _finished = true
        
        // 清理资源
        completeBlock = nil
        commandBlock = nil
        stopReceiveTimer()
    }
    
    private func dataParserReceivedData(_ dataDic: [String: Any]?) {
        guard !isCancelled, _executing, !timeout, !isFinished else {
            return
        }
        
        guard let dataDic = dataDic, !dataDic.isEmpty else {
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
        
        let safeResult = MKSwiftBleResult(value: returnData)
                
        DispatchQueue.main.async { [weak self] in
            guard let self = self, !self.isFinished else { return }
            
            // 现在可以安全地访问 safeResult.value
            if let totalNum = safeResult.value[mk_bxs_swf_totalNumKey] as? String, !totalNum.isEmpty {
                self.receiveTimerCount = 0
                if let data = safeResult.value[mk_bxs_swf_contentKey] as? Data {
                    self.dataList.append(data)
                }
                
                if self.dataList.count == Int(totalNum) ?? 0 {
                    self.stopReceiveTimer()
                    
                    if let block = self.completeBlock {
                        block(nil, ["result": self.dataList])
                        self.completeBlock = nil
                    }
                    
                    self.finishOperation()
                }
                return
            }
            
            self.stopReceiveTimer()
            
            if let block = self.completeBlock {
                // 传递安全的结果
                block(nil, safeResult.value)
                self.completeBlock = nil
            }
            
            self.finishOperation()
        }
    }
}
