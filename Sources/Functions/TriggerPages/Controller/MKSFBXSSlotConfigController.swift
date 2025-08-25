//
//  MKSFBXSSlotConfigController.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/24.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

class MKSFBXSSlotConfigController: MKSwiftBaseViewController {
    
    // MARK: - Properties
    
    var slotIndex: Int = 0
    
    private var thStatus: Int = 0
    private var accStatus: Int = 0
    private var hallStatus: Bool = false
    private var resetByButton: Bool = false
    
    private lazy var section0List: [Any] = []
    private lazy var section1List: [MKSFBXSSlotParamCellModel] = []
    private lazy var section2List: [MKSwiftNormalTextCellModel] = []
    private lazy var headerList: [MKSwiftTableSectionLineHeaderModel] = []
    
    private lazy var dataModel: MKSFBXSSlotConfigDataModel = {
        return MKSFBXSSlotConfigDataModel(slotIndex: slotIndex)
    }()
    
    // MARK: - Life Cycle
    
    deinit {
        print("MKSFBXSSlotConfigController销毁")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        readDataFromDevice()
    }
    
    // MARK: - Super Method
    
    override func rightButtonMethod() {
        saveDataToDevice()
    }
    
    // MARK: - Interface
    
    private func readDataFromDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        let dataModel = self.dataModel
        Task {
            do {
                thStatus = await MKSFBXSConnectManager.shared.getThStatus()
                accStatus = await MKSFBXSConnectManager.shared.getAccStatus()
                hallStatus = await MKSFBXSConnectManager.shared.getHallStatus()
                resetByButton = await MKSFBXSConnectManager.shared.getResetByButton()
                
                try await dataModel.read()
                MKSwiftHudManager.shared.hide()
                headerView.updateFrameType(dataModel.slotType)
                loadSectionDatas()
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                view.showCentralToast(errorMessage)
            }
        }
    }
    
    private func saveDataToDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)
        let dataModel = self.dataModel
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
    
    // MARK: - Private Methods
    
    private func loadSection0Cell(_ row: Int) -> UITableViewCell {
        switch dataModel.slotType {
        case .uid:
            let cell = MKSFBXSSlotUIDCell.initCell(with: tableView)
            cell.dataModel = section0List[row] as? MKSFBXSSlotUIDCellModel
            cell.delegate = self
            return cell
        case .url:
            let cell = MKSFBXSSlotURLCell.initCell(with: tableView)
            cell.dataModel = section0List[row] as? MKSFBXSSlotURLCellModel
            cell.delegate = self
            return cell
        case .beacon:
            let cell = MKSFBXSSlotBeaconCell.initCell(with: tableView)
            cell.dataModel = section0List[row] as? MKSFBXSSlotBeaconCellModel
            cell.delegate = self
            return cell
        case .sensorInfo:
            let cell = MKSFBXSSlotSensorInfoCell.initCell(with: tableView)
            cell.dataModel = section0List[row] as? MKSFBXSSlotSensorInfoCellModel
            cell.delegate = self
            return cell
        default:
            return MKSwiftBaseCell.init(style: .default, reuseIdentifier: "MKSFBXSSlotConfigControllerCell")
        }
    }
    
    private func loadSection1Cell(_ row: Int) -> UITableViewCell {
        if dataModel.slotType != .null {
            let cell = MKSFBXSSlotParamCell.initCell(with: tableView)
            cell.dataModel = section1List[row]
            cell.delegate = self
            return cell
        }
        return MKSwiftBaseCell.init(style: .default, reuseIdentifier: "MKSFBXSSlotConfigControllerCell")
    }
    
    private func loadSection2Cell(_ row: Int) -> UITableViewCell {
        let cell = MKSwiftNormalTextCell.initCellWithTableView(tableView)
        cell.dataModel = section2List[row]
        return cell
    }
    
    private func loadSectionDatas() {
        loadSection0Datas()
        loadSection1Datas()
        loadSection2Datas()
        
        headerList.removeAll()
        
        for _ in 0..<3 {
            let headerModel = MKSwiftTableSectionLineHeaderModel()
            headerList.append(headerModel)
        }
        
        tableView.reloadData()
    }
    
    private func loadSection0Datas() {
        section0List.removeAll()
        
        switch dataModel.slotType {
        case .uid:
            let cellModel = MKSFBXSSlotUIDCellModel()
            cellModel.namespaceID = dataModel.namespaceID
            cellModel.instanceID = dataModel.instanceID
            section0List.append(cellModel)
        case .url:
            let cellModel = MKSFBXSSlotURLCellModel()
            cellModel.urlType = dataModel.urlType
            cellModel.urlContent = dataModel.urlContent
            section0List.append(cellModel)
        case .beacon:
            let cellModel = MKSFBXSSlotBeaconCellModel()
            cellModel.major = dataModel.major
            cellModel.minor = dataModel.minor
            cellModel.uuid = dataModel.uuid
            section0List.append(cellModel)
        case .sensorInfo:
            let cellModel = MKSFBXSSlotSensorInfoCellModel()
            cellModel.deviceName = dataModel.deviceName
            cellModel.tagID = dataModel.tagID
            section0List.append(cellModel)
        default:
            break
        }
    }
    
    private func loadSection1Datas() {
        section1List.removeAll()
        guard dataModel.slotType != .null else { return }
        
        let cellModel = MKSFBXSSlotParamCellModel()
        cellModel.cellType = dataModel.slotType
        cellModel.interval = dataModel.advInterval
        cellModel.advDuration = dataModel.advDuration
        cellModel.standbyDuration = dataModel.standbyDuration
        cellModel.rssi = dataModel.rssi
        cellModel.txPower = dataModel.txPower
        cellModel.powerModeIsOn = dataModel.powerModeIsOn
        section1List.append(cellModel)
    }
    
    private func loadSection2Datas() {
        section2List.removeAll()
        
        let cellModel = MKSwiftNormalTextCellModel()
        cellModel.leftMsg = "Trigger"
        cellModel.leftIcon = moduleIcon(name: "bxs_swf_slotParamsTriggerIcon", in: .module)
        cellModel.showRightIcon = true
        cellModel.rightMsg = "OFF"
        
        section2List.append(cellModel)
    }
    
    // MARK: - UI
    
    private func loadSubViews() {
        defaultTitle = "SLOT\(slotIndex + 1)"
        rightButton.setImage(moduleIcon(name: "bxs_swf_slotSaveIcon", in: .module), for: .normal)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    private lazy var tableView: MKSwiftBaseTableView = {
        let tableView = MKSwiftBaseTableView(frame: .zero, style: .plain)
        tableView.backgroundColor = Color.rgb(242, 242, 242)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = headerView
        return tableView
    }()
    
    private lazy var headerView: MKSFBXSSlotFrameTypePickView = {
        let view = MKSFBXSSlotFrameTypePickView(frame: CGRect(x: 0, y: 20, width: Screen.width, height: 130))
        view.delegate = self
        return view
    }()
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension MKSFBXSSlotConfigController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return headerList.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return (dataModel.slotType == .tlm || dataModel.slotType == .null) ? 0 : section0List.count
        case 1:
            return (dataModel.slotType == .null ? 0 : section1List.count)
        case 2:
            if thStatus == 0 && accStatus == 0 && (hallStatus || resetByButton) {
                return 0
            }
            return section2List.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0 {
            switch dataModel.slotType {
            case .uid: return 120
            case .url: return 100
            case .beacon: return 160
            case .sensorInfo: return 120
            default: return 0
            }
        }
        
        if indexPath.section == 1 && indexPath.row == 0 {
            if dataModel.slotType == .tlm {
                return dataModel.powerModeIsOn ? 240 : 160
            }
            if [.uid, .url, .beacon, .sensorInfo].contains(dataModel.slotType) {
                return dataModel.powerModeIsOn ? 300 : 220
            }
            return 0
        }
        
        if indexPath.section == 2 && indexPath.row == 0 {
            if thStatus == 0 && accStatus == 0 && (hallStatus || resetByButton) {
                return 0
            }
            return 44
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = MKSwiftTableSectionLineHeader.dequeueHeader(with: tableView)
        headerView.headerModel = headerList[section]
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: return loadSection0Cell(indexPath.row)
        case 1: return loadSection1Cell(indexPath.row)
        case 2: return loadSection2Cell(indexPath.row)
        default: return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 && indexPath.row == 0 {
            let vc = MKSFBXSTriggerStepOneController()
            vc.slotIndex = slotIndex
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

// MARK: - Delegate Extensions

extension MKSFBXSSlotConfigController: @preconcurrency MKSFBXSSlotFrameTypePickViewDelegate {
    func bxs_swf_slotFrameTypeChanged(frameType: MKSFBXSSlotType) {
        dataModel.slotType = frameType
        loadSectionDatas()
    }
}

extension MKSFBXSSlotConfigController: @preconcurrency MKSFBXSSlotBeaconCellDelegate {
    func bxs_swf_advContent_majorChanged(major: String) {
        dataModel.major = major
    }
    func bxs_swf_advContent_minorChanged(minor: String) {
        dataModel.minor = minor
    }
    func bxs_swf_advContent_uuidChanged(uuid: String) {
        dataModel.uuid = uuid
    }
}

extension MKSFBXSSlotConfigController: @preconcurrency MKSFBXSSlotSensorInfoCellDelegate {
    func bxs_swf_advContent_tagInfo_deviceNameChanged(_ text: String) {
        dataModel.deviceName = text
    }
    
    func bxs_swf_advContent_tagInfo_tagIDChanged(_ text: String) {
        dataModel.tagID = text
    }
}

extension MKSFBXSSlotConfigController: @preconcurrency MKSFBXSSlotUIDCellDelegate {
    func bxs_swf_advContent_namespaceIDChanged(_ text: String) {
        dataModel.namespaceID = text
    }
    
    func bxs_swf_advContent_instanceIDChanged(_ text: String) {
        dataModel.instanceID = text
    }
}

extension MKSFBXSSlotConfigController: @preconcurrency MKSFBXSSlotURLCellDelegate {
    func bxs_swf_advContent_urlTypeChanged(_ urlType: Int) {
        dataModel.urlType = urlType
    }
    
    func bxs_swf_advContent_urlContentChanged(_ content: String) {
        dataModel.urlContent = content
    }
}

extension MKSFBXSSlotConfigController: @preconcurrency MKSFBXSSlotParamCellDelegate {
    func bxs_swf_slotParam_advIntervalChanged(_ interval: String) {
        dataModel.advInterval = interval
    }
    
    func bxs_swf_slotParam_advDurationChanged(_ duration: String) {
        dataModel.advDuration = duration
    }
    
    func bxs_swf_slotParam_standbyDurationChanged(_ duration: String) {
        dataModel.standbyDuration = duration
    }
    
    func bxs_swf_slotParam_rssiChanged(_ rssi: Int) {
        dataModel.rssi = rssi
    }
    
    func bxs_swf_slotParam_txPowerChanged(_ txPower: Int) {
        dataModel.txPower = txPower
    }
    
    func bxs_swf_slotParam_lowerPowerDetailPressed() {
        
        let msg = "If this function is enabled, the device will periodically sleeps for a period of time during broadcast."
        let alertView = MKSwiftAlertView()
        
        let confirmAction = MKSwiftAlertViewAction(title: "OK") {}

        alertView.addAction(confirmAction)
        alertView.showAlert(title: "Low-power mode",message: msg,notificationName: "mk_bxs_swf_needDismissAlert")
    }
    
    func bxs_swf_slotParam_lowerPowerModeChanged(_ isOn: Bool) {
        dataModel.powerModeIsOn = isOn
        loadSectionDatas()
    }
}
