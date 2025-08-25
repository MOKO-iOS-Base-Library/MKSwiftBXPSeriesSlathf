//
//  MKSFBXSTHSensorController.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/23.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

class MKSFBXSTHSensorController: MKSwiftBaseViewController {
    
    // MARK: - Life Cycle
    
    deinit {
        print("MKSFBXSTHSensorController销毁")
        DispatchQueue.main.async {
            _ = MKSwiftBXPSCentralManager.shared.notifyTHSensorData(false)
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        readDataFromDevice()
    }
    
    // MARK: - Action
    
    override func rightButtonMethod() {
        MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)
        Task {
            do {
                try await dataModel.config()
                MKSwiftHudManager.shared.hide()
                view.showCentralToast("Success")
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                view.showCentralToast(errorMessage)
            }
        }
    }
    
    // MARK: - Notification
    
    @objc private func receiveHTData(_ note: Notification) {
        guard let dic = note.userInfo as? [String: Any], !dic.isEmpty else { return }
        
        headerViewModel.temperature = dic["temperature"] as? String ?? ""
        headerViewModel.humidity = dic["humidity"] as? String ?? ""
        headerView.dataModel = headerViewModel
    }
    
    //MARK: - Interface
    private func syncTime() {
        MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)
        Task {
            do {
                let date = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
                let timestamp = dateFormatter.string(from: date)
                _ = try await MKSFBXSInterface.configDeviceTime(timestamp: UInt(date.timeIntervalSince1970))
                MKSwiftHudManager.shared.hide()
                let cellModel = section2List[0]
                cellModel.date = timestamp
                dataModel.deviceTime = timestamp
                tableView.reloadData()
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                view.showCentralToast(errorMessage)
            }
        }
    }
    
    // MARK: - Data
    
    private func readDataFromDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        Task {
            do {
                try await dataModel.read()
                MKSwiftHudManager.shared.hide()
                headerViewModel.interval = dataModel.samplingInterval
                loadSectionDatas()
                NotificationCenter.default.addObserver(self,
                                                     selector: #selector(receiveHTData(_:)),
                                                     name: NSNotification.Name("mk_bxs_swf_receiveHTDataNotification"),
                                                     object: nil)
                _ = MKSwiftBXPSCentralManager.shared.notifyTHSensorData(true)
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                view.showCentralToast(errorMessage)
            }
        }
    }
    
    private func loadSectionDatas() {
        loadSection0Datas()
        loadSection1Datas()
        loadSection2Datas()
        loadSection3Datas()
        
        for _ in 0..<4 {
            headerList.append(MKSwiftTableSectionLineHeaderModel())
        }
        
        tableView.reloadData()
    }
    
    private func loadSection0Datas() {
        let cellModel = MKSwiftTextSwitchCellModel()
        cellModel.msg = "T&H Data Store"
        cellModel.index = 0
        cellModel.isOn = dataModel.dataStore
        section0List.append(cellModel)
    }
    
    private func loadSection1Datas() {
        let cellModel = MKSwiftTextFieldCellModel()
        cellModel.msg = "Storage interval"
        cellModel.index = 0
        cellModel.textFieldType = .realNumberOnly
        cellModel.textPlaceholder = "0~65535"
        cellModel.maxLength = 5
        cellModel.textFieldValue = dataModel.interval
        cellModel.unit = "min"
        section1List.append(cellModel)
    }
    
    private func loadSection2Datas() {
        let cellModel = MKSFBXSSyncTimeCellModel()
        cellModel.date = dataModel.deviceTime
        section2List.append(cellModel)
    }
    
    private func loadSection3Datas() {
        let cellModel = MKSwiftSettingTextCellModel()
        cellModel.leftMsg = "Export T&H data"
        section3List.append(cellModel)
    }
    
    // MARK: - UI
    
    private func setupUI() {
        titleLabel.font = Font.MKFont(15.0)
        defaultTitle = "Temperature & Humidity"
        rightButton.setImage(moduleIcon(name: "bxs_swf_slotSaveIcon", in: .module), for: .normal)
        view.backgroundColor = Color.rgb(242, 242, 242)
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(5)
            make.right.equalToSuperview().offset(-5)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    // MARK: - Properties
    
    private lazy var tableView: MKSwiftBaseTableView = {
        let tableView = MKSwiftBaseTableView(frame: .zero, style: .plain)
        tableView.backgroundColor = Color.rgb(242, 242, 242)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = headerView
        return tableView
    }()
    private lazy var headerViewModel = MKSFBXSTHSensorHeaderViewModel()
    private lazy var headerView: MKSFBXSTHSensorHeaderView = {
        let headerView = MKSFBXSTHSensorHeaderView(frame: CGRect(x: 0, y: 0, width: Screen.width, height: 200))
        headerView.delegate = self
        return headerView
    }()
    private lazy var section0List = [MKSwiftTextSwitchCellModel]()
    private lazy var section1List = [MKSwiftTextFieldCellModel]()
    private lazy var section2List = [MKSFBXSSyncTimeCellModel]()
    private lazy var section3List = [MKSwiftSettingTextCellModel]()
    private lazy var headerList = [MKSwiftTableSectionLineHeaderModel]()
    
    private lazy var dataModel = MKSFBXSTHSensorModel()
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension MKSFBXSTHSensorController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return headerList.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return section0List.count
        case 1: return dataModel.dataStore ? section1List.count : 0
        case 2: return section2List.count
        case 3: return section3List.count
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = MKSwiftTextSwitchCell.initCellWithTableView(tableView)
            cell.dataModel = section0List[indexPath.row]
            cell.delegate = self
            return cell
        case 1:
            let cell = MKSwiftTextFieldCell.initCellWithTableView(tableView)
            cell.dataModel = section1List[indexPath.row]
            cell.delegate = self
            return cell
        case 2:
            let cell = MKSFBXSSyncTimeCell.initCell(with: tableView)
            cell.dataModel = section2List[indexPath.row]
            cell.delegate = self
            return cell
        default:
            let cell = MKSwiftSettingTextCell.initCellWithTableView(tableView)
            cell.dataModel = section3List[indexPath.row]
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 2 ? 80 : 44
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = MKSwiftTableSectionLineHeader.dequeueHeader(with: tableView)
        headerView.headerModel = headerList[section]
        return headerView
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 3 && indexPath.row == 0 {
            let vc = MKSFBXSExportHTDataController()
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

// MARK: - MKSwiftTextSwitchCellDelegate

extension MKSFBXSTHSensorController: @preconcurrency MKSwiftTextSwitchCellDelegate {
    func MKSwiftTextSwitchCellStatusChanged(isOn: Bool, index: Int) {
        if index == 0 {
            dataModel.dataStore = isOn
            section0List[0].isOn = isOn
            tableView.reloadSections(IndexSet(integer: 1), with: .none)
            return
        }
    }
}

// MARK: - MKSwiftTextFieldCellDelegate

extension MKSFBXSTHSensorController: @preconcurrency MKSwiftTextFieldCellDelegate {
    func mkDeviceTextCellValueChanged(_ index: Int, textValue: String) {
        if index == 0 {
            dataModel.interval = textValue
            section1List[0].textFieldValue = textValue
            return
        }
    }
}

// MARK: - MKSFBXSTHSensorHeaderViewDelegate

extension MKSFBXSTHSensorController: @preconcurrency MKSFBXSTHSensorHeaderViewDelegate {
    func bxs_swf_thSensorHeaderView_samplingIntervalChanged(interval: String) {
        dataModel.samplingInterval = interval
        headerViewModel.interval = interval
    }
}

// MARK: - MKSFBXSSyncTimeCellDelegate

extension MKSFBXSTHSensorController: @preconcurrency MKSFBXSSyncTimeCellDelegate {
    func bxs_swf_syncTimeCell_syncTimePressed() {
        syncTime()
    }
}
