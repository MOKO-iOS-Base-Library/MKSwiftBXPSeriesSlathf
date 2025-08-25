//
//  MKSFBXSTriggerStepThreeController.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/25.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

class MKSFBXSTriggerStepThreeController: MKSwiftBaseViewController {
    
    // MARK: - Properties
    
    var slotIndex: Int = 0
    
    private lazy var section0List: [MKSwiftTextSwitchCellModel] = []
    private lazy var section1List: [MKSwiftNormalTextCellModel] = []
    private lazy var section2List: [Any] = []
    private lazy var section3List: [MKSFBXSSlotParamCellModel] = []
    private lazy var headerList: [MKSwiftTableSectionLineHeaderModel] = []
    
    // MARK: - Life Cycle
    
    deinit {
        print("MKSFBXSTriggerStepThreeController销毁")
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
        loadSectionDatas()
    }
    
    // MARK: - Event Methods
    
    @objc private func doneButtonPressed() {
        let manager = MKSFBXSTriggerParamManager.shared
        let stepOneModel = manager.stepOneModel
        let stepThreeModel = manager.stepThreeModel
        
        if stepOneModel.trigger,
           stepOneModel.fetchTriggerType() == 2,
           stepOneModel.motionEvent == 1 {
            //第一步移动触发，并且是Device remains stationary触发方式
            stepThreeModel.advDuration = stepOneModel.motionVerificationPeriod
        }
        
        if stepThreeModel.trigger && !stepThreeModel.validParams() {
            view.showCentralToast("Params Error")
            return
        }
        
        if !stepThreeModel.powerModeIsOn {
            stepThreeModel.standbyDuration = "0"
            stepThreeModel.advDuration = "1"
        }
        
        let confirmAction = MKSwiftAlertViewAction(title: "OK") { [weak self] in
            self?.saveDataToDevice()
        }
        
        let msg = manager.fetchStepThreeAlert()
        let alertView = MKSwiftAlertView()
        alertView.addAction(confirmAction)
        alertView.showAlert(title: "",message: msg,notificationName: "mk_bxs_swf_needDismissAlert")
    }
    
    private func saveDataToDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)
        Task {[weak self] in
            guard let self = self else { return }
            do {
                //第一个页面读取全部数据，包含了第二个和第三个页面的数据
                _ = try await MKSFBXSTriggerParamManager.shared.config()
                MKSwiftHudManager.shared.hide()
                self.view.showCentralToast("Success")
                Task { [weak self] in
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    await MainActor.run {
                        self?.goback()
                    }
                }
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                self.view.showCentralToast(errorMessage)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchFrameTypeMsg() -> String {
        switch MKSFBXSTriggerParamManager.shared.stepThreeModel.slotType {
        case .tlm: return "TLM"
        case .uid: return "UID"
        case .url: return "URL"
        case .beacon: return "iBeacon"
        default: return "Sensor info"
        }
    }
    
    @objc private func goback() {
        popToViewController(withClassName: "MKSFBXSSlotController")
    }
    
    private func loadSection0Cell(row: Int) -> UITableViewCell {
        let cell = MKSwiftTextSwitchCell.initCellWithTableView(tableView)
        cell.dataModel = section0List[row]
        cell.delegate = self
        return cell
    }
    
    private func loadSection1Cell(row: Int) -> UITableViewCell {
        let cell = MKSwiftNormalTextCell.initCellWithTableView(tableView)
        cell.dataModel = section1List[row]
        return cell
    }
    
    private func loadSection2Cell(row: Int) -> UITableViewCell {
        
        switch MKSFBXSTriggerParamManager.shared.stepThreeModel.slotType {
        case .uid:
            let cell = MKSFBXSSlotUIDCell.initCell(with: tableView)
            cell.dataModel = section2List[row] as? MKSFBXSSlotUIDCellModel
            cell.delegate = self
            return cell
            
        case .url:
            let cell = MKSFBXSSlotURLCell.initCell(with: tableView)
            cell.dataModel = section2List[row] as? MKSFBXSSlotURLCellModel
            cell.delegate = self
            return cell
            
        case .beacon:
            let cell = MKSFBXSSlotBeaconCell.initCell(with: tableView)
            cell.dataModel = section2List[row] as? MKSFBXSSlotBeaconCellModel
            cell.delegate = self
            return cell
            
        case .sensorInfo:
            let cell = MKSFBXSSlotSensorInfoCell.initCell(with: tableView)
            cell.dataModel = section2List[row] as? MKSFBXSSlotSensorInfoCellModel
            cell.delegate = self
            return cell
            
        default:
            return UITableViewCell(style: .default, reuseIdentifier: "MKSFBXSTriggerStepThreeControllerCell")
        }
    }
    
    private func loadSection3Cell(row: Int) -> UITableViewCell {
        if MKSFBXSTriggerParamManager.shared.stepThreeModel.slotType != .null {
            let cell = MKSFBXSSlotParamCell.initCell(with: tableView)
            cell.dataModel = section3List[row]
            cell.delegate = self
            return cell
        }
        return UITableViewCell(style: .default, reuseIdentifier: "MKSFBXSTriggerStepThreeControllerCell")
    }
    
    //MARK: - Load Sections
    private func loadSectionDatas() {
        loadSection0Datas()
        loadSection1Datas()
        loadSection2Datas()
        loadSection3Datas()
        
        headerList.removeAll()
        
        for _ in 0..<4 {
            let headerModel = MKSwiftTableSectionLineHeaderModel()
            headerList.append(headerModel)
        }
        
        tableView.reloadData()
    }
    
    private func loadSection0Datas() {
        section0List.removeAll()
        
        let cellModel = MKSwiftTextSwitchCellModel()
        cellModel.index = 0
        cellModel.msg = "Advertising before trigger event occurs"
        cellModel.isOn = MKSFBXSTriggerParamManager.shared.stepThreeModel.trigger
        section0List.append(cellModel)
    }
    
    private func loadSection1Datas() {
        section1List.removeAll()
        
        let cellModel = MKSwiftNormalTextCellModel()
        cellModel.leftMsg = "Frame type"
        cellModel.rightMsg = fetchFrameTypeMsg()
        section1List.append(cellModel)
    }
    
    private func loadSection2Datas() {
        section2List.removeAll()
        
        let model = MKSFBXSTriggerParamManager.shared.stepThreeModel
        
        switch model.slotType {
        case .uid:
            let cellModel = MKSFBXSSlotUIDCellModel()
            cellModel.namespaceID = model.namespaceID
            cellModel.instanceID = model.instanceID
            section2List.append(cellModel)
            
        case .url:
            let cellModel = MKSFBXSSlotURLCellModel()
            cellModel.urlType = model.urlType
            cellModel.urlContent = model.urlContent
            section2List.append(cellModel)
            
        case .beacon:
            let cellModel = MKSFBXSSlotBeaconCellModel()
            cellModel.major = model.major
            cellModel.minor = model.minor
            cellModel.uuid = model.uuid
            section2List.append(cellModel)
            
        case .sensorInfo:
            let cellModel = MKSFBXSSlotSensorInfoCellModel()
            cellModel.deviceName = model.deviceName
            cellModel.tagID = model.tagID
            section2List.append(cellModel)
            
        default:
            break
        }
    }
    
    private func loadSection3Datas() {
        section3List.removeAll()
        
        if MKSFBXSTriggerParamManager.shared.stepThreeModel.slotType == .null {
            return
        }
        
        let model = MKSFBXSTriggerParamManager.shared.stepThreeModel
        let cellModel = MKSFBXSSlotParamCellModel()
        cellModel.cellType = model.slotType
        cellModel.interval = model.advInterval
        cellModel.advDuration = model.advDuration
        cellModel.standbyDuration = model.standbyDuration
        cellModel.rssi = model.rssi
        cellModel.txPower = model.txPower
        cellModel.powerModeIsOn = model.powerModeIsOn
        
        if MKSFBXSTriggerParamManager.shared.stepOneModel.trigger,
           MKSFBXSTriggerParamManager.shared.stepOneModel.fetchTriggerType() == 2,
           MKSFBXSTriggerParamManager.shared.stepOneModel.motionEvent == 1 {
            //第一步移动触发，并且是Device remains stationary触发方式
            cellModel.powerModeButtonEnabled = false
        } else {
            cellModel.powerModeButtonEnabled = true
        }
        
        section3List.append(cellModel)
    }
    
    //MARK: - UI
    private func loadSubViews() {
        self.defaultTitle = "SLOT\(MKSFBXSTriggerParamManager.shared.slotIndex + 1)"
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    //MARK: - Lazy
    private lazy var tableView: MKSwiftBaseTableView = {
        let view = MKSwiftBaseTableView(frame: .zero, style: .plain)
        view.backgroundColor = Color.rgb(242, 242, 242)
        view.delegate = self
        view.dataSource = self
        view.tableHeaderView = tableHeaderView
        view.tableFooterView = tableFooterView
        return view
    }()
    
    private lazy var nextButton: UIButton = {
        return MKSwiftUIAdaptor.createRoundedButton(title: "Done",
                                                    target: self,
                                                    action: #selector(doneButtonPressed))
    }()
    
    private lazy var tableHeaderView: UIView = {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: Screen.width, height: 100.0))
        headerView.backgroundColor = Color.rgb(242, 242, 242)
        
        let stepLabel = UILabel(frame: CGRect(x: 15, y: 10, width: Screen.width - 30, height: 20))
        stepLabel.textAlignment = .left
        stepLabel.attributedText = MKSwiftUIAdaptor.createAttributedString(strings: ["3", "/3", ":", "Before event occurs setting"], fonts: [Font.MKFont(15.0),Font.MKFont(13.0),Font.MKFont(13.0),Font.MKFont(18.0)], colors: [Color.navBar,Color.rgb(137, 137, 137),Color.navBar,Color.defaultText])
        headerView.addSubview(stepLabel)
        
        let noteMsgLabel = UILabel(frame: CGRect(x: 15, y: 40, width: Screen.width - 30, height: 60.0))
        noteMsgLabel.textAlignment = .left
        noteMsgLabel.textColor = Color.rgb(204, 102, 72)
        noteMsgLabel.font = Font.MKFont(13.0)
        noteMsgLabel.numberOfLines = 0
        noteMsgLabel.text = "*In this step, you can configure whether to enable pre-trigger broadcasting and related advertising parameters."
        headerView.addSubview(noteMsgLabel)
        
        return headerView
    }()
    
    private lazy var tableFooterView: UIView = {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: Screen.width, height: 80))
        footerView.backgroundColor = Color.rgb(242, 242, 242)
        
        let btnWidth = (Screen.width - 90) / 2
                
        let backBtn = MKSwiftUIAdaptor.createRoundedButton(title: "Back",
                                                           target: self,
                                                           action: #selector(leftButtonMethod))
        backBtn.frame = CGRect(x: 30, y: 20, width: btnWidth, height: 40)
        footerView.addSubview(backBtn)
        
        nextButton.frame = CGRect(x: 60 + btnWidth, y: 20, width: btnWidth, height: 40)
        footerView.addSubview(nextButton)
        
        return footerView
    }()
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension MKSFBXSTriggerStepThreeController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return headerList.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            //Advertising before trigger event occurs
            return section0List.count
        }
                
        let model = MKSFBXSTriggerParamManager.shared.stepThreeModel
        
        if !model.trigger {
            return 0
        }
        
        if section == 1 {
            //Frame type
            return section1List.count
        }
        
        if section == 2 {
            return (model.slotType == .tlm || model.slotType == .null) ? 0 : section2List.count
        }
        
        if section == 3 {
            return model.slotType == .null ? 0 : section3List.count
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let model = MKSFBXSTriggerParamManager.shared.stepThreeModel
        
        if indexPath.section == 2 && indexPath.row == 0 {
            switch model.slotType {
            case .uid: return 120
            case .url: return 100
            case .beacon: return 160
            case .sensorInfo: return 120
            default: return 0
            }
        }
        
        if indexPath.section == 3 && indexPath.row == 0 {
            switch model.slotType {
            case .tlm:
                return model.powerModeIsOn ? 240 : 160
            case .uid, .url, .beacon, .sensorInfo:
                return model.powerModeIsOn ? 300 : 220
            default:
                return 0
            }
        }
        
        return 44
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
        case 0: return loadSection0Cell(row: indexPath.row)
        case 1: return loadSection1Cell(row: indexPath.row)
        case 2: return loadSection2Cell(row: indexPath.row)
        default: return loadSection3Cell(row: indexPath.row)
        }
    }
}

// MARK: - MKSwiftTextSwitchCellDelegate

extension MKSFBXSTriggerStepThreeController: @preconcurrency MKSwiftTextSwitchCellDelegate {
    func MKSwiftTextSwitchCellStatusChanged(isOn: Bool, index: Int) {
        if index == 0 {
            //Advertising before trigger event occurs
            section0List[0].isOn = isOn
            MKSFBXSTriggerParamManager.shared.stepThreeModel.trigger = isOn
            tableView.reloadData()
            return
        }
    }
}

// MARK: - MKSFBXSSlotBeaconCellDelegate

extension MKSFBXSTriggerStepThreeController: @preconcurrency MKSFBXSSlotBeaconCellDelegate {
    func bxs_swf_advContent_majorChanged(major: String) {
        MKSFBXSTriggerParamManager.shared.stepThreeModel.major = major
    }
    
    func bxs_swf_advContent_minorChanged(minor: String) {
        MKSFBXSTriggerParamManager.shared.stepThreeModel.minor = minor
    }
    
    func bxs_swf_advContent_uuidChanged(uuid: String) {
        MKSFBXSTriggerParamManager.shared.stepThreeModel.uuid = uuid
    }
}

// MARK: - MKSFBXSSlotSensorInfoCellDelegate

extension MKSFBXSTriggerStepThreeController: @preconcurrency MKSFBXSSlotSensorInfoCellDelegate {
    func bxs_swf_advContent_tagInfo_deviceNameChanged(_ text: String) {
        MKSFBXSTriggerParamManager.shared.stepThreeModel.deviceName = text
    }
    
    func bxs_swf_advContent_tagInfo_tagIDChanged(_ text: String) {
        MKSFBXSTriggerParamManager.shared.stepThreeModel.tagID = text
    }
}

// MARK: - MKSFBXSSlotUIDCellDelegate

extension MKSFBXSTriggerStepThreeController: @preconcurrency MKSFBXSSlotUIDCellDelegate {
    func bxs_swf_advContent_namespaceIDChanged(_ text: String) {
        MKSFBXSTriggerParamManager.shared.stepThreeModel.namespaceID = text
    }
    
    func bxs_swf_advContent_instanceIDChanged(_ text: String) {
        MKSFBXSTriggerParamManager.shared.stepThreeModel.instanceID = text
    }
}

// MARK: - MKSFBXSSlotURLCellDelegate

extension MKSFBXSTriggerStepThreeController: @preconcurrency MKSFBXSSlotURLCellDelegate {
    func bxs_swf_advContent_urlTypeChanged(_ urlType: Int) {
        MKSFBXSTriggerParamManager.shared.stepThreeModel.urlType = urlType
    }
    
    func bxs_swf_advContent_urlContentChanged(_ content: String) {
        MKSFBXSTriggerParamManager.shared.stepThreeModel.urlContent = content
    }
}

// MARK: - MKSFBXSSlotParamCellDelegate

extension MKSFBXSTriggerStepThreeController: @preconcurrency MKSFBXSSlotParamCellDelegate {
    func bxs_swf_slotParam_advIntervalChanged(_ interval: String) {
        MKSFBXSTriggerParamManager.shared.stepThreeModel.advInterval = interval
    }
    
    func bxs_swf_slotParam_advDurationChanged(_ duration: String) {
        MKSFBXSTriggerParamManager.shared.stepThreeModel.advDuration = duration
    }
    
    func bxs_swf_slotParam_standbyDurationChanged(_ duration: String) {
        MKSFBXSTriggerParamManager.shared.stepThreeModel.standbyDuration = duration
    }
    
    func bxs_swf_slotParam_rssiChanged(_ rssi: Int) {
        MKSFBXSTriggerParamManager.shared.stepThreeModel.rssi = rssi
    }
    
    func bxs_swf_slotParam_txPowerChanged(_ txPower: Int) {
        MKSFBXSTriggerParamManager.shared.stepThreeModel.txPower = txPower
    }
    
    func bxs_swf_slotParam_lowerPowerDetailPressed() {
        
        let confirmAction = MKSwiftAlertViewAction(title: "OK") {}
        
        let msg = "If this function is enabled, the device will periodically sleeps for a period of time during broadcast."
        let alertView = MKSwiftAlertView()
        alertView.addAction(confirmAction)
        alertView.showAlert(title: "Low-power mode",message: msg,notificationName: "mk_bxs_swf_needDismissAlert")
    }
    
    func bxs_swf_slotParam_lowerPowerModeChanged(_ isOn: Bool) {
        MKSFBXSTriggerParamManager.shared.stepThreeModel.powerModeIsOn = isOn
        loadSectionDatas()
    }
}
