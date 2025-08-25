//
//  MKSFBXSRemoteReminderController.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/21.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

class MKSFBXSRemoteReminderController: MKSwiftBaseViewController {
    
    // MARK: - Data
    private lazy var section0List = [MKSFBXSRemoteReminderCellModel]()
    private lazy var section1List = [MKSwiftTextFieldCellModel]()
    private lazy var section2List = [MKSFBXSRemoteReminderCellModel]()
    private lazy var section3List = [MKSwiftTextFieldCellModel]()
    private lazy var section4List = [MKSwiftTextButtonCellModel]()
    private lazy var headerList = [MKSwiftTableSectionLineHeaderModel]()
    
    private lazy var dataModel: MKSFBXSRemoteReminderModel = {
        return MKSFBXSRemoteReminderModel()
    }()
    
    // MARK: - Life Cycle
    deinit {
        print("MKSFBXSRemoteReminderController销毁")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        readDatasFromDevice()
    }
    
    // MARK: - Interface
    private func readDatasFromDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        
        Task {[weak self] in
            guard let self = self else { return }
            do {
                try await self.dataModel.read()
                MKSwiftHudManager.shared.hide()
                self.loadSectionDatas()
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                self.view.showCentralToast(errorMessage)
            }
        }
    }
    
    private func reminderLED() {
        guard dataModel.ledBlinkingTime.count > 0,
              let time = Int(dataModel.ledBlinkingTime),
              time >= 1, time <= 600 else {
            view.showCentralToast("Blink Time Error")
            return
        }
        
        guard dataModel.ledBlinkingInterval.count > 0,
              let interval = Int(dataModel.ledBlinkingInterval),
              interval >= 1, interval <= 100 else {
            view.showCentralToast("Blink Interval Error")
            return
        }
        MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)
        
        Task {[weak self] in
            guard let self = self else { return }
            do {
                _ = try await MKSFBXSInterface.configRemoteReminderLEDNotiParams(blinkingTime: time, blinkingInterval: interval)
                MKSwiftHudManager.shared.hide()
                self.view.showCentralToast("Success")
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                self.view.showCentralToast(errorMessage)
            }
        }
    }
    
    private func reminderBuzzer() {
        guard dataModel.buzzerRingingTime.count > 0,
              let time = Int(dataModel.buzzerRingingTime),
              time >= 1, time <= 600 else {
            view.showCentralToast("Ringing Time Error")
            return
        }
        
        guard dataModel.buzzerRingingInterval.count > 0,
              let interval = Int(dataModel.buzzerRingingInterval),
              interval >= 1, interval <= 100 else {
            view.showCentralToast("Ringing Interval Error")
            return
        }
        
        MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)
        
        Task {[weak self] in
            guard let self = self else { return }
            do {
                try await self.dataModel.config()
                MKSwiftHudManager.shared.hide()
                self.view.showCentralToast("Success")
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                self.view.showCentralToast(errorMessage)
            }
        }
    }
    
    // MARK: - Load Datas
    private func loadSectionDatas() {
        loadSection0Datas()
        loadSection1Datas()
        loadSection2Datas()
        loadSection3Datas()
        loadSection4Datas()
        
        for _ in 0..<5 {
            headerList.append(MKSwiftTableSectionLineHeaderModel())
        }
        
        tableView.reloadData()
    }
    
    private func loadSection0Datas() {
        let cellModel = MKSFBXSRemoteReminderCellModel()
        cellModel.msg = "LED notification"
        cellModel.index = 0
        section0List.append(cellModel)
    }
    
    private func loadSection1Datas() {
        let cellModel1 = MKSwiftTextFieldCellModel()
        cellModel1.index = 0
        cellModel1.msg = "Blinking time"
        cellModel1.textPlaceholder = "1~600"
        cellModel1.textFieldValue = dataModel.ledBlinkingTime
        cellModel1.textFieldType = .realNumberOnly
        cellModel1.unit = "s"
        cellModel1.maxLength = 3
        section1List.append(cellModel1)
        
        let cellModel2 = MKSwiftTextFieldCellModel()
        cellModel2.index = 1
        cellModel2.msg = "Blinking interval"
        cellModel2.textPlaceholder = "1~100"
        cellModel2.textFieldValue = dataModel.ledBlinkingInterval
        cellModel2.textFieldType = .realNumberOnly
        cellModel2.unit = "x 100ms"
        cellModel2.maxLength = 3
        section1List.append(cellModel2)
    }
    
    private func loadSection2Datas() {
        let cellModel = MKSFBXSRemoteReminderCellModel()
        cellModel.msg = "Buzzer notification"
        cellModel.index = 1
        section2List.append(cellModel)
    }
    
    private func loadSection3Datas() {
        let cellModel1 = MKSwiftTextFieldCellModel()
        cellModel1.index = 2
        cellModel1.msg = "Ringing time"
        cellModel1.textPlaceholder = "1~600"
        cellModel1.textFieldValue = dataModel.buzzerRingingTime
        cellModel1.textFieldType = .realNumberOnly
        cellModel1.unit = "s"
        cellModel1.maxLength = 3
        section3List.append(cellModel1)
        
        let cellModel2 = MKSwiftTextFieldCellModel()
        cellModel2.index = 3
        cellModel2.msg = "Ringing interval"
        cellModel2.textPlaceholder = "1~100"
        cellModel2.textFieldValue = dataModel.buzzerRingingInterval
        cellModel2.textFieldType = .realNumberOnly
        cellModel2.unit = "x 100ms"
        cellModel2.maxLength = 3
        section3List.append(cellModel2)
    }
    
    private func loadSection4Datas() {
        let cellModel = MKSwiftTextButtonCellModel()
        cellModel.index = 0
        cellModel.msg = "Ringing frequency"
        cellModel.dataList = ["4000 Hz", "4500 Hz"]
        cellModel.dataListIndex = dataModel.ringingFre
        section4List.append(cellModel)
    }
    
    // MARK: - UI
    private func loadSubViews() {
        defaultTitle = "Remote reminder"
        view.backgroundColor = Color.rgb(242, 242, 242)
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    // MARK: - UI
    private lazy var tableView: MKSwiftBaseTableView = {
        let view = MKSwiftBaseTableView(frame: .zero, style: .plain)
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = Color.rgb(242, 242, 242)
        return view
    }()
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension MKSFBXSRemoteReminderController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return headerList.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return section0List.count
        case 1: return section1List.count
        case 2: return section2List.count
        case 3: return section3List.count
        case 4: return section4List.count
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (section == 0 || section == 2) ? 10.0 : 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = MKSwiftTableSectionLineHeader.dequeueHeader(with: tableView)
        headerView.headerModel = headerList[section]
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            //LED notification
            let cell = MKSFBXSRemoteReminderCell.cell(with: tableView)
            cell.dataModel = section0List[indexPath.row]
            cell.delegate = self
            return cell
            
        case 1:
            let cell = MKSwiftTextFieldCell.initCellWithTableView(tableView)
            cell.dataModel = section1List[indexPath.row]
            cell.delegate = self
            return cell
            
        case 2:
            //Buzzer notification
            let cell = MKSFBXSRemoteReminderCell.cell(with: tableView)
            cell.dataModel = section2List[indexPath.row]
            cell.delegate = self
            return cell
            
        case 3:
            let cell = MKSwiftTextFieldCell.initCellWithTableView(tableView)
            cell.dataModel = section3List[indexPath.row]
            cell.delegate = self
            return cell
            
        case 4:
            let cell = MKSwiftTextButtonCell.initCellWithTableView(tableView)
            cell.dataModel = section4List[indexPath.row]
            cell.delegate = self
            return cell
            
        default:
            return UITableViewCell()
        }
    }
}

// MARK: - MKSwiftTextFieldCellDelegate
extension MKSFBXSRemoteReminderController: @preconcurrency MKSwiftTextFieldCellDelegate {
    func mkDeviceTextCellValueChanged(_ index: Int, textValue: String) {
        switch index {
        case 0:
            //LED notification
            //Blinking time
            dataModel.ledBlinkingTime = textValue
            section1List[0].textFieldValue = textValue
            
        case 1:
            //LED notification
            //Blinking interval
            dataModel.ledBlinkingInterval = textValue
            section1List[1].textFieldValue = textValue
            
        case 2:
            //Buzzer notification
            //Ringing time
            dataModel.buzzerRingingTime = textValue
            section3List[0].textFieldValue = textValue
            
        case 3:
            //Buzzer notification
            //Ringing interval
            dataModel.buzzerRingingInterval = textValue
            section3List[1].textFieldValue = textValue
            
        default:
            break
        }
    }
}

// MARK: - MKSwiftTextButtonCellDelegate
extension MKSFBXSRemoteReminderController: @preconcurrency MKSwiftTextButtonCellDelegate {
    func MKSwiftTextButtonCellSelected(index: Int, dataListIndex: Int, value: String) {
        if index == 0 {
            dataModel.ringingFre = dataListIndex
            section4List[0].dataListIndex = dataListIndex
        }
    }
}

// MARK: - MKSFBXSRemoteReminderCellDelegate
extension MKSFBXSRemoteReminderController: @preconcurrency MKSFBXSRemoteReminderCellDelegate {
    func bxs_swf_remindButtonPressed(index: Int) {
        if index == 0 {
            reminderLED()
        } else if index == 1 {
            reminderBuzzer()
        }
    }
}
