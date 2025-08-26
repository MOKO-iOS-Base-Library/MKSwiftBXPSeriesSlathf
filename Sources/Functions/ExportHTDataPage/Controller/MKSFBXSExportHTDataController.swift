//
//  MKSFBXSExportHTDataController.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/17.
//

@preconcurrency import UIKit
import MessageUI
import SnapKit

import MKBaseSwiftModule
import MKSwiftBleModule

class MKSFBXSExportHTDataController: MKSwiftBaseViewController {
    
    // MARK: - Constants
    private let textBackViewHeight = Screen.height - Layout.topBarHeight - 170.0
    private let timeTextViewWidth: CGFloat = 130.0
    private let htTextViewWidth: CGFloat = 80.0
    private let htTextViewOffset_Y: CGFloat = 160.0
    private var textViewSpace: CGFloat {
        return (Screen.width - 30.0 - timeTextViewWidth - 2 * htTextViewWidth) / 4
    }
    
    // MARK: - Properties
    private var parseTimer: DispatchSourceTimer?
    private var displayTimer: DispatchSourceTimer?
    private var receiveComplete = false
    private var temperatureList = [String]()
    private var humidityList = [String]()
    private var dataList = [[String: String]]()
    private var contentList = [String]()
    private var textMsg = ""
    private var totalCount = 0
    private var parseIndex = 0
    
    private var runDate: Date?
    private var isTimersRunning = false
    private var timerQueue = DispatchQueue(label: "com.moko.timerQueue", attributes: .concurrent)
    
    // MARK: - Life Cycle
    deinit {
        print("MKSFBXSExportHTDataController销毁")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if !(navigationController?.viewControllers.contains(self) ?? false) {
            performCleanup()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        readDeviceRunTimes()
    }
    
    // MARK: - Timer Methods
    private func startParseTimer() {
        // 先取消现有的定时器
        cancelTimer()
        
        // 创建新的定时器
        parseTimer = DispatchSource.makeTimerSource(queue: timerQueue)
        parseTimer?.schedule(deadline: .now(), repeating: 0.3, leeway: .milliseconds(10))
        
        parseTimer?.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            // 检查是否完成
            if self.receiveComplete {
                DispatchQueue.main.async {
                    self.cancelTimer()
                    self.topView.resetAllStatus()
                    self.textView.text = self.textMsg
                    self.textView.scrollRangeToVisible(NSRange(location: self.textView.text.count, length: 1))
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.dismissMaskView()
                    }
                }
                return
            }
            
            // 处理数据
            DispatchQueue.main.async {
                self.processNotifyDatas()
            }
        }
        
        // 设置取消处理器
        parseTimer?.setCancelHandler { [weak self] in
            self?.isTimersRunning = false
            print("Parse timer cancelled")
        }
        
        // 启动定时器
        parseTimer?.resume()
        isTimersRunning = true
        print("Parse timer started")
    }
    
    private func startDisplayTimer() {
        // 创建显示定时器（在主线程运行）
        displayTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        displayTimer?.schedule(deadline: .now(), repeating: 2.0, leeway: .milliseconds(50))
        
        displayTimer?.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            if self.receiveComplete {
                self.displayTimer?.cancel()
                self.displayTimer = nil
                return
            }
            
            // 更新文本显示
            if !self.textMsg.isEmpty {
                self.textView.text = self.textMsg
                self.textView.scrollRangeToVisible(NSRange(location: self.textView.text.count, length: 1))
            }
        }
        
        displayTimer?.resume()
        print("Display timer started")
    }
    
    // MARK: - Data Processing
    private func parseTemperatureHumidityData(_ content: String) -> String {
        let total = content.count / 16
        var text = ""
        
        for i in 0..<total {
            let subContent = content.substring(from: i * 16, length: 16)
            
            let timeStr = String(subContent.prefix(8))
            let time = strtoul(timeStr, nil, 16)
            
            let timestamp: String
            if time < 1577808000 {
                if let runDate = runDate {
                    timestamp = dateFormatter.string(from: runDate.addingTimeInterval(TimeInterval(time)))
                } else {
                    timestamp = ""
                }
            } else {
                timestamp = dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(time)))
            }
            
            let tempTemp = MKSwiftBleSDKAdopter.signedHexTurnString(subContent.substring(from: 8, length: 4))
            
            let tempHui = MKSwiftBleSDKAdopter.getDecimalWithHex(subContent, range: NSRange(location: 12, length: 4))
            
            let temperature = String(format: "%.1f", tempTemp.doubleValue * 0.1)
            let humidity = String(format: "%.1f", Double(tempHui) * 0.1)
            
            let tempTemperature = "\(temperature)℃"
            temperatureList.append(temperature)
            
            let tempHumidity = "\(humidity)%RH"
            humidityList.append(humidity)
            
            let tempString = "\n\(timestamp)\t\t\(tempTemperature)\t\t\(tempHumidity)"
            text.append(tempString)
            
            let htData: [String: String] = [
                "temperature": temperature,
                "humidity": humidity,
                "date": timestamp
            ]
            dataList.append(htData)
        }
        
        return text
    }
    
    private func processNotifyDatas() {
        guard parseIndex < contentList.count else {
            return
        }
        
        let content = contentList[parseIndex]
        let text = parseTemperatureHumidityData(String(content.dropFirst(16)))
        
        textMsg = text + textMsg
        maskView.updateCurrentNumber("\(dataList.count)")
        
        parseIndex += 1
        if parseIndex == totalCount {
            receiveComplete = true
            print("All data processed, total: \(totalCount)")
        }
    }
    
    // MARK: - Actions
    @objc private func dismissMaskView() {
        maskView.dismiss()
    }
    
    private func drawHTCurveView() {
        MKSwiftHudManager.shared.showHUD(with: "Loading...", in: view, isPenetration: false)
        
        let tempMax = (temperatureList as NSArray).value(forKeyPath: "@max.floatValue") as? Float ?? 0
        let tempMin = (temperatureList as NSArray).value(forKeyPath: "@min.floatValue") as? Float ?? 0
        let humiMax = (humidityList as NSArray).value(forKeyPath: "@max.floatValue") as? Float ?? 0
        let humiMin = (humidityList as NSArray).value(forKeyPath: "@min.floatValue") as? Float ?? 0
        
        curveView.updateTemperatureDatas(temperatureList: temperatureList,
                                         temperatureMax: CGFloat(tempMax),
                                         temperatureMin: CGFloat(tempMin),
                                         humidityList: humidityList,
                                         humidityMax: CGFloat(humiMax),
                                         humidityMin: CGFloat(humiMin)) {
            MKSwiftHudManager.shared.hide()
        }
    }
    
    private func sharedExcel() {
        if !MFMailComposeViewController.canSendMail() {
            UIApplication.shared.open(URL(string: "MESSAGE://")!, options: [:], completionHandler: nil)
            return
        }
        
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let path = (documentPath as NSString).appendingPathComponent("Temperature&HumidityDatas.xlsx")
        
        if !FileManager.default.fileExists(atPath: path) {
            view.showCentralToast("File not exist")
            return
        }
        
        guard let data = FileManager.default.contents(atPath: path) else {
            view.showCentralToast("Load file error")
            return
        }
        
        let infoDictionary = Bundle.main.infoDictionary
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let bodyMsg = "APP Version: \(version) + + OS: \(App.systemVersion)"
        
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        mailComposer.setToRecipients(["Development@mokotechnology.com"])
        mailComposer.setSubject("Feedback of mail")
        mailComposer.addAttachmentData(data, mimeType: "application/xlsx", fileName: "Temperature&HumidityDatas.xlsx")
        mailComposer.setMessageBody(bodyMsg, isHTML: false)
        
        present(mailComposer, animated: true)
    }
    
    // MARK: - Interface Methods
    private func deleteRecordDatas() {
        dataList.removeAll()
        temperatureList.removeAll()
        humidityList.removeAll()
        contentList.removeAll()
        textView.text = ""
        textMsg = ""
        topView.resetAllStatus()
        
        UIView.animate(withDuration: 0.3) {
            self.textBackView.frame = CGRect(x: 10, y: self.htTextViewOffset_Y, width: Screen.width - 30, height: self.textBackViewHeight)
            self.curveView.frame = CGRect(x: Screen.width - 10, y: self.htTextViewOffset_Y, width: Screen.width - 30, height: self.textBackViewHeight)
        }
        
        _ = MKSwiftBXPSCentralManager.shared.notifyRecordTHData(false)
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        
        Task {[weak self] in
            guard let self = self else { return }
            do {
                let result = try await MKSFBXSInterface.deleteBXPRecordHTDatas()
                MKSwiftHudManager.shared.hide()
                let msg = result ? "Empty successfully!" : "Empty failed!"
                self.view.showCentralToast(msg)
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                self.view.showCentralToast(errorMessage)
            }
        }
    }
    
    private func readDeviceRunTimes() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        Task {[weak self] in
            guard let self = self else { return }
            do {
                let result = try await MKSFBXSInterface.readDeviceRuntime()
                MKSwiftHudManager.shared.hide()
                
                let current = Date().timeIntervalSince1970
                self.runDate = Date(timeIntervalSince1970: current - Double(result)!)
                
                self.loadSubViews()
                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(self.receiveRecordHTData(_:)),
                                                       name: .mk_bxs_swf_receiveRecordHTData,
                                                       object: nil)
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                self.view.showCentralToast(errorMessage)
            }
        }
    }
    
    private func readTotalNumbers() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        receiveComplete = false
        totalCount = 0
        parseIndex = 0
        contentList.removeAll()
        dataList.removeAll()
        temperatureList.removeAll()
        humidityList.removeAll()
        textMsg = ""
        
        Task {[weak self] in
            guard let self = self else {
                MKSwiftHudManager.shared.hide()
                return
            }
            do {
                let count = try await MKSFBXSInterface.readHTRecordTotalNumbers()
                MKSwiftHudManager.shared.hide()
                self.maskView.show(with: self.view)
                self.maskView.updateTotalNumber("\(count)")
                
                let countValue = Int(count) ?? 0
                if countValue == 0 {
                    self.topView.resetAllStatus()
                    self.textView.text = ""
                    self.maskView.updateCurrentNumber("0")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.dismissMaskView()
                    }
                    return
                }
                
                // 检查蓝牙连接状态
                guard MKSwiftBXPSCentralManager.shared.connectStatus == .connected else {
                    self.view.showCentralToast("Device disconnected")
                    self.dismissMaskView()
                    return
                }
                
                // 启用通知
                let notifySuccess = MKSwiftBXPSCentralManager.shared.notifyRecordTHData(true)
                guard notifySuccess else {
                    self.view.showCentralToast("Enable notification failed")
                    self.dismissMaskView()
                    return
                }
                
                print("Starting timers for \(countValue) data points")
                self.startParseTimer()
                self.startDisplayTimer()
                
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                self.view.showCentralToast(errorMessage)
                self.dismissMaskView()
            }
        }
    }
    
    @objc private func receiveRecordHTData(_ note: Notification) {
        guard let userInfo = note.userInfo,
              let content = userInfo["content"] as? String else {
            return
        }
        
        let total = MKSwiftBleSDKAdopter.getDecimalWithHex(content, range: NSRange(location: 6, length: 4))
        let index = MKSwiftBleSDKAdopter.getDecimalWithHex(content, range: NSRange(location: 10, length: 4))
        
        totalCount = total
        contentList.append(content)
        
        print("Received data packet \(index + 1)/\(total)")
        
        if total == (index + 1) {
            _ = MKSwiftBXPSCentralManager.shared.notifyRecordTHData(false)
            print("All data packets received")
        }
    }
    
    // MARK: - Cleanup Methods
    private func performCleanup() {
        // 取消定时器
        cancelTimer()
        
        // 移除通知监听
        NotificationCenter.default.removeObserver(self)
        
        // 停止蓝牙通知（在主线程执行）
        DispatchQueue.main.async {
            _ = MKSwiftBXPSCentralManager.shared.notifyRecordTHData(false)
        }
    }
    
    private func cancelTimer() {
        // 确保定时器正确取消
        if let parseTimer = parseTimer {
            parseTimer.cancel()
            self.parseTimer = nil
        }
        
        if let displayTimer = displayTimer {
            displayTimer.cancel()
            self.displayTimer = nil
        }
        
        isTimersRunning = false
        print("All timers cancelled")
    }
    
    // MARK: - UI Setup
    private func loadSubViews() {
        defaultTitle = "Export T&H Data"
        view.backgroundColor = Color.rgb(242, 242, 242)
        
        view.addSubview(backView)
        backView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(5)
            make.right.equalToSuperview().offset(-5)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-10)
        }
        
        backView.addSubview(topView)
        topView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.top.equalToSuperview().offset(5)
            make.height.equalTo(50)
        }
        
        backView.addSubview(filterView)
        filterView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.top.equalTo(topView.snp.bottom).offset(20)
            make.height.equalTo(80)
        }
        
        backView.addSubview(textBackView)
        textBackView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.width.equalTo(Screen.width - 30)
            make.top.equalToSuperview().offset(htTextViewOffset_Y)
            make.height.equalTo(textBackViewHeight)
        }
        
        textBackView.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.top.equalToSuperview().offset(3 * 5 + Font.MKFont(13.0).lineHeight)
            make.bottom.equalToSuperview().offset(-40)
        }
        
        backView.addSubview(curveView)
        curveView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Screen.width - 10)
            make.width.equalTo(Screen.width - 30)
            make.top.equalToSuperview().offset(htTextViewOffset_Y)
            make.height.equalTo(textBackViewHeight)
        }
    }
    
    // MARK: - UI Components (lazy loading)
    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8.0
        return view
    }()
    
    private lazy var topView: MKSFBXSExportDataHeaderView = {
        let view = MKSFBXSExportDataHeaderView()
        view.delegate = self
        return view
    }()
    
    private lazy var filterView: MKSFBXSFilterHistoryDataView = {
        let view = MKSFBXSFilterHistoryDataView()
        view.delegate = self
        return view
    }()
    
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.font = Font.MKFont(13.0)
        textView.layoutManager.allowsNonContiguousLayout = false
        textView.isEditable = false
        textView.textColor = Color.defaultText
        return textView
    }()
    
    private lazy var textBackView: UIView = {
        let view = UIView()
        view.layer.masksToBounds = true
        view.layer.borderWidth = 0.5
        view.layer.cornerRadius = 2.0
        view.layer.borderColor = Color.rgb(227, 227, 227).cgColor
        
        let timeLabel = loadTextLabel("Time")
        let tempLabel = loadTextLabel("Temperature")
        let humidityLabel = loadTextLabel("Humidity")
        
        view.addSubview(timeLabel)
        view.addSubview(tempLabel)
        view.addSubview(humidityLabel)
        
        timeLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(textViewSpace)
            make.top.equalToSuperview().offset(5)
            make.width.equalTo(timeTextViewWidth)
            make.height.equalTo(Font.MKFont(13.0).lineHeight)
        }
        
        tempLabel.snp.makeConstraints { make in
            make.left.equalTo(timeLabel.snp.right).offset(textViewSpace)
            make.top.equalToSuperview().offset(5)
            make.width.equalTo(htTextViewWidth)
            make.height.equalTo(Font.MKFont(13.0).lineHeight)
        }
        
        humidityLabel.snp.makeConstraints { make in
            make.left.equalTo(tempLabel.snp.right).offset(textViewSpace)
            make.top.equalToSuperview().offset(5)
            make.width.equalTo(htTextViewWidth)
            make.height.equalTo(Font.MKFont(13.0).lineHeight)
        }
        
        return view
    }()
    
    private lazy var curveView: MKSFBXSExportHTDataCurveView = {
        let view = MKSFBXSExportHTDataCurveView()
        return view
    }()
    
    private lazy var maskView: MKSFBXSHistoryDataMaskView = {
        let view = MKSFBXSHistoryDataMaskView()
        return view
    }()
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return formatter
    }()
    
    private func loadTextLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.textColor = Color.defaultText
        label.font = Font.MKFont(13.0)
        label.textAlignment = .center
        label.text = text
        return label
    }
}

// MARK: - MFMailComposeViewControllerDelegate
extension MKSFBXSExportHTDataController: @preconcurrency MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result {
        case .cancelled:
            break
        case .saved:
            break
        case .sent:
            view.showCentralToast("send success")
        case .failed:
            break
        @unknown default:
            break
        }
        controller.dismiss(animated: true)
    }
}

// MARK: - MKSFBXSExportDataHeaderViewDelegate
extension MKSFBXSExportHTDataController: @preconcurrency MKSFBXSExportDataHeaderViewDelegate {
    func mk_bxs_swf_syncButtonPressed(_ selected: Bool) {
        if selected {
            textView.text = ""
            textMsg = ""
            contentList.removeAll()
            dataList.removeAll()
            temperatureList.removeAll()
            humidityList.removeAll()
            
            readTotalNumbers()
            return
        }
        _ = MKSwiftBXPSCentralManager.shared.notifyRecordTHData(false)
        receiveComplete = false
        totalCount = 0
        parseIndex = 0
        cancelTimer()
    }
    
    func mk_bxs_swf_switchButtonPressed(_ selected: Bool) {
        if selected {
            UIView.animate(withDuration: 0.3) {
                self.textBackView.frame = CGRect(x: -(Screen.width - 10), y: self.htTextViewOffset_Y, width: Screen.width - 30, height: self.textBackViewHeight)
                self.curveView.frame = CGRect(x: 10, y: self.htTextViewOffset_Y, width: Screen.width - 30, height: self.textBackViewHeight)
            } completion: { _ in
                self.drawHTCurveView()
            }
            return
        }
        
        UIView.animate(withDuration: 0.3) {
            self.textBackView.frame = CGRect(x: 10, y: self.htTextViewOffset_Y, width: Screen.width - 30, height: self.textBackViewHeight)
            self.curveView.frame = CGRect(x: Screen.width - 10, y: self.htTextViewOffset_Y, width: Screen.width - 30, height: self.textBackViewHeight)
        }
    }
    
    func mk_bxs_swf_deleteButtonPressed() {
        let msg = "Are you sure to erase all the saved T&H datas？"
        let alertView = MKSwiftAlertView()
        
        let confirmAction = MKSwiftAlertViewAction(title: "OK") { [self] in
            deleteRecordDatas()
        }
        let cancelAction = MKSwiftAlertViewAction(title: "Cancel") {
            
        }
        alertView.addAction(confirmAction)
        alertView.addAction(cancelAction)
        alertView.showAlert(title: "Warning!",message: msg,notificationName: "mk_bxs_swf_needDismissAlert")
    }
    
    func mk_bxs_swf_exportButtonPressed() {
        MKSwiftHudManager.shared.showHUD(with: "Waiting...", in: view, isPenetration: false)
        Task {[weak self] in
            guard let self = self else { return }
            do {
                try await MKSFBXSExcelManager.exportExcel(withTHDataList: self.dataList)
                MKSwiftHudManager.shared.hide()
                self.sharedExcel()
            }catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                self.view.showCentralToast(errorMessage)
            }
        }
    }
}

// MARK: - MKSFBXSFilterHistoryDataViewDelegate
extension MKSFBXSExportHTDataController: @preconcurrency MKSFBXSFilterHistoryDataViewDelegate {
    func bxs_swf_dateSelectedView(startPressed startDate: String, endDate: String) {
        print("\(startDate)   \(endDate)")
        MKSwiftHudManager.shared.showHUD(with: "Loading...", in: view, isPenetration: false)
        
        guard let start = dateFormatter.date(from: startDate),
              let end = dateFormatter.date(from: endDate) else {
            return
        }
        
        let predicate = NSPredicate { (data, _) -> Bool in
            guard let dict = data as? [String: Any],
                  let dateStr = dict["date"] as? String,
                  let date = self.dateFormatter.date(from: dateStr) else {
                return false
            }
            return date.compare(start) != .orderedAscending && date.compare(end) != .orderedDescending
        }
        
        let filteredDataList = (dataList as NSArray).filtered(using: predicate)
        
        MKSwiftHudManager.shared.hide()
        
        guard let filteredList = filteredDataList as? [[String: String]], !filteredList.isEmpty else {
            view.showCentralToast("No matching data!")
            return
        }
        
        let vc = MKSFBXSFilterHTHistoryDataController()
        vc.dataList = filteredList
        navigationController?.pushViewController(vc, animated: true)
    }
}
