//
//  MKSFBXSExportTempDataController.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/17.
//

// MKSFBXSExportTempDataController.swift
import UIKit
import MessageUI
import SnapKit
import MKBaseSwiftModule
import MKSwiftBleModule

class MKSFBXSExportTempDataController: MKSwiftBaseViewController {
    
    // MARK: - Constants
    private let textBackViewHeight = Screen.height - Layout.navigationBarHeight - 170.0
    private let timeViewWidth: CGFloat = 130.0
    private let tempTextViewWidth: CGFloat = 80.0
    private let tTextViewOffset_Y: CGFloat = 160.0
    private var textViewSpace: CGFloat {
        return (Screen.width - 30.0 - timeViewWidth - 2 * tempTextViewWidth) / 4
    }
    
    // MARK: - Properties
    private var parseTimer: DispatchSourceTimer?
    private var displayTimer: DispatchSourceTimer?
    private var receiveComplete = false
    private var temperatureList = [String]()
    private var dataList = [[String: String]]()
    private var contentList = [String]()
    private var textMsg = ""
    private var totalCount = 0
    private var parseIndex = 0
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return formatter
    }()
    
    private var runDate: Date?
    
    // MARK: - Life Cycle
    deinit {
        print("MKSFBXSExportTempDataController销毁")
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("mk_bxs_swf_receiveRecordHTDataNotification"), object: nil)
        DispatchQueue.main.async {[weak self] in
            _ = MKSwiftBXPSCentralManager.shared.notifyRecordTHData(false)
            self?.cancelTimer()
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
    
    // MARK: - Notification
    @objc private func receiveRecordHTData(_ note: Notification) {
        guard let content = note.userInfo?["content"] as? String else { return }
        
        let total = MKSwiftBleSDKAdopter.getDecimalWithHex(content, range: NSRange(location: 6, length: 4))
        let index = MKSwiftBleSDKAdopter.getDecimalWithHex(content, range: NSRange(location: 10, length: 4))
        
        totalCount = total
        contentList.append(content)
        
        if total == (index + 1) {
            _ = MKSwiftBXPSCentralManager.shared.notifyRecordTHData(false)
        }
    }
    
    // MARK: - Private Methods
    private func deleteRecordDatas() {
        dataList.removeAll()
        temperatureList.removeAll()
        contentList.removeAll()
        textView.text = ""
        textMsg = ""
        topView.resetAllStatus()
        
        UIView.animate(withDuration: 0.3) {
            self.textBackView.frame = CGRect(x: 10.0, y: self.tTextViewOffset_Y, width: Screen.width - 30.0, height: self.textBackViewHeight)
            self.curveView.frame = CGRect(x: Screen.width - 10.0, y: self.tTextViewOffset_Y, width: Screen.width - 30.0, height: self.textBackViewHeight)
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
        
        Task {
            do {
                let count = try await MKSFBXSInterface.readDeviceRuntime()
                MKSwiftHudManager.shared.hide()
                
                let current = Date().timeIntervalSince1970
                runDate = Date(timeIntervalSince1970: current - Double(count)!)
                
                loadSubViews()
                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(self.receiveRecordHTData(_:)),
                                                       name: .mk_bxs_swf_receiveRecordHTData,
                                                       object: nil)
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                view.showCentralToast(errorMessage)
            }
        }
    }
    
    private func readTotalNumbers() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        receiveComplete = false
        totalCount = 0
        parseIndex = 0
        
        Task {[weak self] in
            guard let self = self else { return }
            do {
                let count = try await MKSFBXSInterface.readHTRecordTotalNumbers()
                MKSwiftHudManager.shared.hide()
                
                self.maskView.show(with: view)
                self.maskView.updateTotalNumber("\(count)")
                
                if Int(count) == 0 {
                    self.topView.resetAllStatus()
                    self.textView.text = ""
                    self.textMsg = ""
                    self.maskView.updateCurrentNumber("0")
                    self.perform(#selector(self.dismissMaskView), with: nil, afterDelay: 2)
                    return
                }
                
                _ = MKSwiftBXPSCentralManager.shared.notifyRecordTHData(true)
                self.startParseTimer()
                self.startDisplayTimer()
            }catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                self.view.showCentralToast(errorMessage)
            }
        }
    }
    
    private func startParseTimer() {
        parseTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
        parseTimer?.schedule(deadline: .now(), repeating: 0.3)
        
        parseTimer?.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            if self.receiveComplete {
                DispatchQueue.main.async {
                    self.parseTimer?.cancel()
                    self.topView.resetAllStatus()
                    self.perform(#selector(self.dismissMaskView), with: nil, afterDelay: 2.0)
                }
            }
            
            DispatchQueue.main.async {
                self.processNotifyDatas()
            }
        }
        
        parseTimer?.resume()
    }
    
    private func startDisplayTimer() {
        displayTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
        displayTimer?.schedule(deadline: .now(), repeating: 2.0)
        
        displayTimer?.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            if self.receiveComplete {
                self.displayTimer?.cancel()
            }
            
            DispatchQueue.main.async {
                self.textView.text = self.textMsg
                self.textView.scrollRangeToVisible(NSRange(location: self.textView.text.count, length: 1))
            }
        }
        
        displayTimer?.resume()
    }
    
    private func drawHTCurveView() {
        
        MKSwiftHudManager.shared.showHUD(with: "Loading...", in: view, isPenetration: false)
        
        let maxTemp = temperatureList.compactMap { Float($0) }.max() ?? 0
        let minTemp = temperatureList.compactMap { Float($0) }.min() ?? 0
        
        curveView.updateTemperatureDatas(temperatureList,
                                        temperatureMax: CGFloat(maxTemp),
                                        temperatureMin: CGFloat(minTemp)) {
            MKSwiftHudManager.shared.hide()
        }
    }
    
    private func processNotifyDatas() {
        guard parseIndex < contentList.count else { return }
        
        let content = contentList[parseIndex]
        let text = parseTemperatureHumidityData(String(content.dropFirst(16)))
        
        textMsg += text
        maskView.updateCurrentNumber("\(dataList.count)")
        
        parseIndex += 1
        if parseIndex == totalCount {
            receiveComplete = true
        }
    }
    
    @objc private func dismissMaskView() {
        maskView.dismiss()
    }
    
    private func parseTemperatureHumidityData(_ content: String) -> String {
        let total = content.count / 16
        var text = ""
        
        for i in 0..<total {
            let subContent = content.substring(from: i * 16, length: 16)
            
            let timeStr = String(subContent.prefix(8))
            let time = strtoul(timeStr, nil, 16)
            
            let timestamp: String
            if time < 1577808000 {
                timestamp = dateFormatter.string(from: runDate?.addingTimeInterval(TimeInterval(time)) ?? Date())
            } else {
                timestamp = dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(time)))
            }
            
            let tempTemp = MKSwiftBleSDKAdopter.signedHexTurnString(subContent.substring(from: 8, length: 4))
            let temperature = String(format: "%.1f", tempTemp.doubleValue * 0.1)
            let tempTemperature = "\(temperature)℃"
            
            temperatureList.append(temperature)
            text += "\n\(timestamp)\t\t\(tempTemperature)"
            
            let htData: [String: String] = [
                "temperature": temperature,
                "date": timestamp
            ]
            dataList.append(htData)
        }
        
        return text
    }
    
    private func sharedExcel() {
        guard MFMailComposeViewController.canSendMail() else {
            UIApplication.shared.open(URL(string: "MESSAGE://")!, options: [:])
            return
        }
        
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let path = (documentPath as NSString).appendingPathComponent("Temperature&HumidityDatas.xlsx")
        
        guard FileManager.default.fileExists(atPath: path) else {
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
        mailComposer.addAttachmentData(data, mimeType: "application/xlsx", fileName: "Temperature.xlsx")
        mailComposer.setMessageBody(bodyMsg, isHTML: false)
        
        present(mailComposer, animated: true)
    }
    
    private func cancelTimer() {
        parseTimer?.cancel()
        displayTimer?.cancel()
    }
    
    private func loadSubViews() {
        defaultTitle = "Export Temperature Data"
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
            make.top.equalToSuperview().offset(tTextViewOffset_Y)
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
            make.top.equalToSuperview().offset(tTextViewOffset_Y)
            make.height.equalTo(textBackViewHeight)
        }
    }
    
    // MARK: - UI Components
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
        textView.backgroundColor = .white
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
        
        view.addSubview(timeLabel)
        view.addSubview(tempLabel)
        
        timeLabel.frame = CGRect(x: textViewSpace, y: 5.0, width: timeViewWidth, height: Font.MKFont(13.0).lineHeight)
        tempLabel.frame = CGRect(x: 2 * textViewSpace + timeViewWidth, y: 5.0, width: tempTextViewWidth, height: Font.MKFont(13.0).lineHeight)
        
        return view
    }()
    
    private lazy var curveView: MKSFBXSExportTempDataCurveView = {
        let view = MKSFBXSExportTempDataCurveView()
        return view
    }()
    
    private lazy var maskView: MKSFBXSHistoryDataMaskView = {
        return MKSFBXSHistoryDataMaskView()
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

extension MKSFBXSExportTempDataController: @preconcurrency MFMailComposeViewControllerDelegate {
    // MARK: - MFMailComposeViewControllerDelegate
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

extension MKSFBXSExportTempDataController: @preconcurrency MKSFBXSExportDataHeaderViewDelegate {
    func mk_bxs_swf_syncButtonPressed(_ selected: Bool) {
        if selected {
            textView.text = ""
            textMsg = ""
            contentList.removeAll()
            dataList.removeAll()
            temperatureList.removeAll()
            readTotalNumbers()
            return
        }
        
        _ = MKSwiftBXPSCentralManager.shared.notifyRecordTHData(false)
        receiveComplete = false
        totalCount = 0
        parseIndex = 0
        parseTimer?.cancel()
    }
    
    func mk_bxs_swf_switchButtonPressed(_ selected: Bool) {
        if selected {
            UIView.animate(withDuration: 0.3) {
                self.textBackView.frame = CGRect(x: -(Screen.width - 10.0), y: self.tTextViewOffset_Y, width: Screen.width - 30.0, height: self.textBackViewHeight)
                self.curveView.frame = CGRect(x: 10.0, y: self.tTextViewOffset_Y, width: Screen.width - 30.0, height: self.textBackViewHeight)
            } completion: { _ in
                self.drawHTCurveView()
            }
            return
        }
        
        UIView.animate(withDuration: 0.3) {
            self.textBackView.frame = CGRect(x: 10.0, y: self.tTextViewOffset_Y, width: Screen.width - 30.0, height: self.textBackViewHeight)
            self.curveView.frame = CGRect(x: Screen.width - 10.0, y: self.tTextViewOffset_Y, width: Screen.width - 30.0, height: self.textBackViewHeight)
        }
    }
    
    func mk_bxs_swf_deleteButtonPressed() {
        let msg = "Are you sure to erase all the saved temperature datas？"
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
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                self.view.showCentralToast(errorMessage)
            }
        }
    }
}

extension MKSFBXSExportTempDataController: @preconcurrency MKSFBXSFilterHistoryDataViewDelegate {
    func bxs_swf_dateSelectedView(startPressed startDate: String, endDate: String) {
        print("\(startDate)   \(endDate)")
        
        MKSwiftHudManager.shared.showHUD(with: "Loading...", in: view, isPenetration: false)
        
        guard let start = dateFormatter.date(from: startDate),
              let end = dateFormatter.date(from: endDate) else {
            MKSwiftHudManager.shared.hide()
            return
        }
        
        let filteredDataList = dataList.filter { data in
            guard let dateString = data["date"],
                  let date = dateFormatter.date(from: dateString) else {
                return false
            }
            return date.compare(start) != .orderedAscending && date.compare(end) != .orderedDescending
        }
        
        MKSwiftHudManager.shared.hide()
        
        if filteredDataList.isEmpty {
            view.showCentralToast("No matching data!")
            return
        }
        
        let vc = MKSFBXSFilterTempHistoryDataController()
        vc.dataList = filteredDataList
        navigationController?.pushViewController(vc, animated: true)
    }
}

