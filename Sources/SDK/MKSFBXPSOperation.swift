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
    
    private let lock = NSLock()
    private let timerQueue = DispatchQueue(label: "com.mk.bxps.timer", attributes: .concurrent)
    
    private var operationID: MKSFBXSTaskOperationID
    private var completeBlock: ((Error?, MKSwiftBleResult?) -> Void)?
    private var commandBlock: (() -> Void)?
    
    private var receiveTimer: DispatchSourceTimer?
    private var timeout: Bool = false
    private var receiveTimerCount: Int = 0
    private var dataList: [Data] = []
    private var timerStarted: Bool = false
    
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
        lock.lock()
        defer { lock.unlock() }
        return _executing
    }
    
    override var isFinished: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _finished
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    // MARK: - Initialization
    
    init(operationID: MKSFBXSTaskOperationID,
         commandBlock: (() -> Void)?,
         completeBlock: ((Error?, MKSwiftBleResult?) -> Void)?) {
        self.operationID = operationID
        self.commandBlock = commandBlock
        self.completeBlock = completeBlock
        super.init()
        _executing = false
        _finished = false
    }
    
    deinit {
        print("MP任务销毁")
        stopReceiveTimer()
    }
    
    // MARK: - Operation Overrides
    
    override func start() {
        // 必须在主线程执行 KVO 通知
        if Thread.isMainThread {
            startOperation()
        } else {
            DispatchQueue.main.async {
                self.startOperation()
            }
        }
    }
    
    private func startOperation() {
        lock.lock()
        
        if isCancelled {
            lock.unlock()
            // 如果已取消，需要正确设置状态
            if !_finished {
                finishOperation()
            }
            return
        }
        
        if _finished {
            lock.unlock()
            return
        }
        
        // 设置执行状态（这会触发 KVO）
        _executing = true
        lock.unlock()
        
        // 在后台线程执行实际工作，避免阻塞主线程
        DispatchQueue.global().async { [weak self] in
            self?.startCommunication()
        }
    }
    
    override func cancel() {
        lock.lock()
        defer { lock.unlock() }
        
        super.cancel()
        communicationTimeout()
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
        lock.lock()
        let cancelled = isCancelled
        let finished = _finished
        lock.unlock()
        
        if cancelled || finished {
            finishOperation()
            return
        }
        
        // 安全检查
        guard let block = commandBlock else {
            print("Error: commandBlock is nil")
            communicationTimeout()
            return
        }
        
        // 在主线程执行 commandBlock（通常涉及 UI 或 CoreBluetooth）
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.lock.lock()
            let cancelled = self.isCancelled
            self.lock.unlock()
            
            if cancelled {
                self.finishOperation()
                return
            }
            
            // 直接执行
            block()
            self.startReceiveTimer()
        }
    }
    
    private func startReceiveTimer() {
        lock.lock()
        defer { lock.unlock() }
        
        guard !timerStarted, !timeout, !isCancelled, !_finished else {
            return
        }
        
        timerStarted = true
        receiveTimerCount = 0
        
        receiveTimer = DispatchSource.makeTimerSource(queue: timerQueue)
        receiveTimer?.schedule(deadline: .now() + 5.0) // 5秒超时
        
        receiveTimer?.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.communicationTimeout()
        }
        
        receiveTimer?.setCancelHandler { [weak self] in
            guard let self = self else { return }
            self.lock.lock()
            defer { self.lock.unlock() }
            self.timerStarted = false
        }
        
        receiveTimer?.resume()
    }
    
    private func stopReceiveTimer() {
        lock.lock()
        defer { lock.unlock() }
        
        receiveTimer?.cancel()
        receiveTimer = nil
        timerStarted = false
    }
    
    private func finishOperation() {
        lock.lock()
        defer { lock.unlock() }
        
        if _finished {
            return
        }
        
        stopReceiveTimer()
        
        // 必须在主线程执行 KVO 通知
        if Thread.isMainThread {
            _executing = false
            _finished = true
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self._executing = false
                self._finished = true
            }
        }
        
        // 清理 block 防止循环引用
        commandBlock = nil
        completeBlock = nil
    }
    
    private func communicationTimeout() {
        lock.lock()
        defer { lock.unlock() }
        
        guard !timeout else { return }
        timeout = true
        
        stopReceiveTimer()
        
        // 保存 block 引用
        let block = completeBlock
        completeBlock = nil // 防止重复调用
        
        finishOperation()
        
        DispatchQueue.main.async {
            block?(BXPSOperationError.timeout, nil)
        }
    }
    
    private func dataParserReceivedData(_ dataDic: [String: Any]?) {
        lock.lock()
        defer { lock.unlock() }
        
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
                stopReceiveTimer()
                
                // 创建 Sendable 结果
                let result = MKSwiftBleResult(value: ["result": dataList])
                let block = completeBlock
                completeBlock = nil
                
                finishOperation()
                
                DispatchQueue.main.async {
                    block?(nil, result)
                }
            }
            return
        }
        
        stopReceiveTimer()
        
        // 创建 Sendable 结果
        let result = MKSwiftBleResult(value: returnData)
        let block = completeBlock
        completeBlock = nil
        
        finishOperation()
        
        DispatchQueue.main.async {
            block?(nil, result)
        }
    }
}
