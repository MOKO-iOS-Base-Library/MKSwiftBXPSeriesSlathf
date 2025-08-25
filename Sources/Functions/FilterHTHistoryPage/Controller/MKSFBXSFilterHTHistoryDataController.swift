//
//  MKSFBXSFilterHTHistoryDataController.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/17.
//

import UIKit
import MessageUI
import SnapKit
import MKBaseSwiftModule

class MKSFBXSFilterHTHistoryDataController: MKSwiftBaseViewController {
    
    // MARK: - Constants
    private let textBackViewHeight = Screen.height - Layout.topBarHeight - 70.0
    private let timeTextViewWidth: CGFloat = 130.0
    private let htTextViewWidth: CGFloat = 80.0
    private let htTextViewOffset_Y: CGFloat = 60.0
    private var textViewSpace: CGFloat {
        return (Screen.width - 30.0 - timeTextViewWidth - 2 * htTextViewWidth) / 4
    }
    
    // MARK: - Properties
    var dataList: [[String: String]] = []
    
    
    // MARK: - Life Cycle
    deinit {
        print("MKSFBXSFilterHTHistoryDataController销毁")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        processDatas()
    }
    
    // MARK: - Private Methods
    private func drawHTCurveView() {
        MKSwiftHudManager.shared.showHUD(with: "Loading...", in: view, isPenetration: false)
        let maxTemp = temperatureList.compactMap { Float($0) }.max() ?? 0
        let minTemp = temperatureList.compactMap { Float($0) }.min() ?? 0
        let maxHumidity = humidityList.compactMap { Float($0) }.max() ?? 0
        let minHumidity = humidityList.compactMap { Float($0) }.min() ?? 0
        
        curveView.updateTemperatureDatas(temperatureList: temperatureList,
                                        temperatureMax: CGFloat(maxTemp),
                                        temperatureMin: CGFloat(minTemp),
                                        humidityList: humidityList,
                                        humidityMax: CGFloat(maxHumidity),
                                        humidityMin: CGFloat(minHumidity)) {
            MKSwiftHudManager.shared.hide()
        }
    }
    
    private func processDatas() {
        guard !dataList.isEmpty else { return }
        
        MKSwiftHudManager.shared.showHUD(with: "Loading...", in: view, isPenetration: false)
        var text = ""
        for item in dataList {
            temperatureList.append(item["temperature"]!)
            humidityList.append(item["humidity"]!)
            
            let tempTemperature = "\(item["temperature"]!)℃"
            let tempHumidity = "\(item["humidity"]!)%RH"
            let tempString = "\n\(item["date"]!)\t\t\(tempTemperature)\t\t\(tempHumidity)"
            text += tempString
        }
        
        MKSwiftHudManager.shared.hide()
        
        textView.text += text
        textView.scrollRangeToVisible(NSRange(location: textView.text.count, length: 1))
        topView.updateSumRecord("\(dataList.count)")
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
        mailComposer.addAttachmentData(data, mimeType: "application/xlsx", fileName: "Temperature&HumidityDatas.xlsx")
        mailComposer.setMessageBody(bodyMsg, isHTML: false)
        
        present(mailComposer, animated: true)
    }
    
    private func loadSubViews() {
        defaultTitle = "Export T&H Data"
        view.backgroundColor = Color.rgb(242, 242, 242)
        
        view.addSubview(backView)
        backView.snp.remakeConstraints { make in
            make.left.equalTo(5)
            make.right.equalTo(-5)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-10)
        }
        
        backView.addSubview(topView)
        topView.snp.makeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.top.equalTo(5)
            make.height.equalTo(50)
        }
        
        backView.addSubview(textBackView)
        textBackView.addSubview(textView)
        backView.addSubview(curveView)
    }
    
    // MARK: - UI Components
    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8.0
        return view
    }()
    
    private lazy var topView: MKSFBXSFilterHTHistoryHeaderView = {
        let view = MKSFBXSFilterHTHistoryHeaderView()
        view.delegate = self
        return view
    }()
    
    private lazy var textView: UITextView = {
        let textView = UITextView(frame: CGRect(x: 10.0, y: 3 * 5.0 + Font.MKFont(13.0).lineHeight, width: Screen.width - 30.0 - 2 * 10.0 , height: textBackViewHeight - 55.0 - Font.MKFont(13.0).lineHeight))
        textView.font = Font.MKFont(13.0)
        textView.layoutManager.allowsNonContiguousLayout = false
        textView.isEditable = false
        textView.textColor = Color.defaultText
        return textView
    }()
    
    private lazy var curveView: MKSFBXSExportHTDataCurveView = {
        let view = MKSFBXSExportHTDataCurveView(frame: CGRect(x:Screen.width - 10.0, y: htTextViewOffset_Y, width: Screen.width - 30.0, height: textBackViewHeight))
        return view
    }()
    
    private lazy var textBackView: UIView = {
        let view = UIView(frame: CGRect(x: 10.0, y: htTextViewOffset_Y, width: Screen.width - 30.0, height: textBackViewHeight))
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
        
        timeLabel.frame = CGRect(x: textViewSpace, y: 5.0, width: timeTextViewWidth, height: Font.MKFont(13.0).lineHeight)
        tempLabel.frame = CGRect(x: 2 * textViewSpace + timeTextViewWidth, y: 5.0, width: htTextViewWidth, height: Font.MKFont(13.0).lineHeight)
        humidityLabel.frame = CGRect(x: 3 * textViewSpace + timeTextViewWidth + htTextViewWidth, y: 5.0, width: htTextViewWidth, height: Font.MKFont(13.0).lineHeight)
        
        return view
    }()
    
    private lazy var temperatureList: [String] = {
        return []
    }()
    
    private lazy var humidityList: [String] = {
        return []
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

extension MKSFBXSFilterHTHistoryDataController: @preconcurrency MFMailComposeViewControllerDelegate {
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

extension MKSFBXSFilterHTHistoryDataController: @preconcurrency MKSFBXSFilterHTHistoryHeaderViewDelegate {
    func bxs_swf_filterHTHistoryHeaderView_switchButtonPressed(_ selected: Bool) {
        if selected {
            UIView.animate(withDuration: 0.3) {
                self.textBackView.frame = CGRect(x: -(Screen.width - 10.0), y: self.htTextViewOffset_Y, width: Screen.width - 30.0, height: self.textBackViewHeight)
                self.curveView.frame = CGRect(x: 10.0, y: self.htTextViewOffset_Y, width: Screen.width - 30.0, height: self.textBackViewHeight)
            } completion: { _ in
                self.drawHTCurveView()
            }
            return
        }
        
        UIView.animate(withDuration: 0.3) {
            self.textBackView.frame = CGRect(x: 10.0, y: self.htTextViewOffset_Y, width: Screen.width - 30.0, height: self.textBackViewHeight)
            self.curveView.frame = CGRect(x: Screen.width - 10.0, y: self.htTextViewOffset_Y, width: Screen.width - 30.0, height: self.textBackViewHeight)
        }
    }
    
    func bxs_swf_filterHTHistoryHeaderView_exportButtonPressed() {
        MKSwiftHudManager.shared.showHUD(with: "Waiting...", in: view, isPenetration: false)
        Task {
            do {
                try await MKSFBXSExcelManager.exportExcel(withTHDataList: dataList)
                MKSwiftHudManager.shared.hide()
                sharedExcel()
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                view.showCentralToast(errorMessage)
            }
        }
    }
}

