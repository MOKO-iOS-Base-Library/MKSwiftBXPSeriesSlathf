//
//  MKSFBXSTriggerStepTwoController.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/24.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

class MKSFBXSTriggerStepTwoController: MKSwiftBaseViewController {
    
    var slotIndex: Int = 0
    
    // MARK: - Data Sources
    private lazy var section0List: [MKSwiftTextButtonCellModel] = []
    private lazy var section1List: [Any] = []
    private lazy var section2List: [MKSFBXSTriggerSlotParamCellModel] = []
    private lazy var headerList: [MKSwiftTableSectionLineHeaderModel] = []
    
    // MARK: - Constants
    private let mk_triggerOpenHeight: CGFloat = 280.0
    private let mk_triggerCloseHeight: CGFloat = 50.0
    
    // MARK: - Life Cycle
    deinit {
        print("MKSFBXSTriggerStepTwoController销毁")
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
    
    // MARK: - Private Methods
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
        
        let cellModel = MKSwiftTextButtonCellModel()
        cellModel.index = 0
        cellModel.msg = "Frame type"
        cellModel.dataList = ["TLM", "UID", "URL", "iBeacon", "Sensor info"]
        cellModel.dataListIndex = MKSFBXSTriggerParamManager.shared.stepTwoModel.slotType.rawValue
        section0List.append(cellModel)
    }
    
    private func loadSection1Datas() {
        section1List.removeAll()
        
        let slotType = MKSFBXSTriggerParamManager.shared.stepTwoModel.slotType
        switch slotType {
        case .uid:
            let cellModel = MKSFBXSSlotUIDCellModel()
            cellModel.namespaceID = MKSFBXSTriggerParamManager.shared.stepTwoModel.namespaceID
            cellModel.instanceID = MKSFBXSTriggerParamManager.shared.stepTwoModel.instanceID
            section1List.append(cellModel)
            
        case .url:
            let cellModel = MKSFBXSSlotURLCellModel()
            cellModel.urlType = MKSFBXSTriggerParamManager.shared.stepTwoModel.urlType
            cellModel.urlContent = MKSFBXSTriggerParamManager.shared.stepTwoModel.urlContent
            section1List.append(cellModel)
            
        case .beacon:
            let cellModel = MKSFBXSSlotBeaconCellModel()
            cellModel.major = MKSFBXSTriggerParamManager.shared.stepTwoModel.major
            cellModel.minor = MKSFBXSTriggerParamManager.shared.stepTwoModel.minor
            cellModel.uuid = MKSFBXSTriggerParamManager.shared.stepTwoModel.uuid
            section1List.append(cellModel)
            
        case .sensorInfo:
            let cellModel = MKSFBXSSlotSensorInfoCellModel()
            cellModel.deviceName = MKSFBXSTriggerParamManager.shared.stepTwoModel.deviceName
            cellModel.tagID = MKSFBXSTriggerParamManager.shared.stepTwoModel.tagID
            section1List.append(cellModel)
            
        default:
            break
        }
    }
    
    private func loadSection2Datas() {
        section2List.removeAll()
        
        guard MKSFBXSTriggerParamManager.shared.stepTwoModel.slotType != .null else { return }
        
        let cellModel = MKSFBXSTriggerSlotParamCellModel()
        cellModel.cellType = MKSFBXSTriggerParamManager.shared.stepTwoModel.slotType
        cellModel.interval = MKSFBXSTriggerParamManager.shared.stepTwoModel.advInterval
        cellModel.advDuration = MKSFBXSTriggerParamManager.shared.stepTwoModel.advDuration
        
        if MKSFBXSTriggerParamManager.shared.stepOneModel.trigger,
           MKSFBXSTriggerParamManager.shared.stepOneModel.fetchTriggerType() == 2,
           MKSFBXSTriggerParamManager.shared.stepOneModel.motionEvent == 0 {
            //第一步移动触发，并且是Device start moving触发方式
            cellModel.needChangeAdvDurationRange = true
            cellModel.advDurationMaxValue = Int(MKSFBXSTriggerParamManager.shared.stepOneModel.motionVerificationPeriod) ?? 0
        } else {
            cellModel.needChangeAdvDurationRange = false
            cellModel.advDurationMaxValue = 0
        }
        
        cellModel.rssi = MKSFBXSTriggerParamManager.shared.stepTwoModel.rssi
        cellModel.txPower = MKSFBXSTriggerParamManager.shared.stepTwoModel.txPower
        section2List.append(cellModel)
    }
    
    private func fetchSlotType(_ index: Int) -> MKSFBXSSlotType {
        switch index {
        case 0: return .tlm
        case 1: return .uid
        case 2: return .url
        case 3: return .beacon
        default: return .sensorInfo
        }
    }
    
    private func loadSection0Cell(_ row: Int) -> MKSwiftTextButtonCell {
        let cell = MKSwiftTextButtonCell.initCellWithTableView(tableView)
        cell.dataModel = section0List[row]
        cell.delegate = self
        return cell
    }
    
    private func loadSection1Cell(_ row: Int) -> UITableViewCell {
        let slotType = MKSFBXSTriggerParamManager.shared.stepTwoModel.slotType
        
        switch slotType {
        case .uid:
            let cell = MKSFBXSSlotUIDCell.initCell(with: tableView)
            cell.dataModel = section1List[row] as? MKSFBXSSlotUIDCellModel
            cell.delegate = self
            return cell
            
        case .url:
            let cell = MKSFBXSSlotURLCell.initCell(with: tableView)
            cell.dataModel = section1List[row] as? MKSFBXSSlotURLCellModel
            cell.delegate = self
            return cell
            
        case .beacon:
            let cell = MKSFBXSSlotBeaconCell.initCell(with: tableView)
            cell.dataModel = section1List[row] as? MKSFBXSSlotBeaconCellModel
            cell.delegate = self
            return cell
            
        case .sensorInfo:
            let cell = MKSFBXSSlotSensorInfoCell.initCell(with: tableView)
            cell.dataModel = section1List[row] as? MKSFBXSSlotSensorInfoCellModel
            cell.delegate = self
            return cell
            
        default:
            return UITableViewCell(style: .default, reuseIdentifier: "MKSFBXSTriggerStepTwoControllerCell")
        }
    }
    
    private func loadSection2Cell(_ row: Int) -> UITableViewCell {
        guard MKSFBXSTriggerParamManager.shared.stepTwoModel.slotType != .null else {
            return UITableViewCell(style: .default, reuseIdentifier: "MKSFBXSTriggerStepTwoControllerCell")
        }
        
        let cell = MKSFBXSTriggerSlotParamCell.initCell(with: tableView)
        cell.dataModel = section2List[row]
        cell.delegate = self
        return cell
    }
    
    @objc private func goback() {
        popToViewController(withClassName: "MKSFBXSSlotController")
    }
    
    // MARK: - Event Methods
    @objc private func nextButtonPressed() {
        guard MKSFBXSTriggerParamManager.shared.stepTwoModel.validParams() else {
            view.showCentralToast("Params Error")
            return
        }
        
        if MKSFBXSTriggerParamManager.shared.stepOneModel.trigger,
           MKSFBXSTriggerParamManager.shared.stepOneModel.fetchTriggerType() == 2,
           MKSFBXSTriggerParamManager.shared.stepOneModel.motionEvent == 0,
           let advDuration = Int(MKSFBXSTriggerParamManager.shared.stepTwoModel.advDuration),
           let verificationPeriod = Int(MKSFBXSTriggerParamManager.shared.stepOneModel.motionVerificationPeriod),
           advDuration > verificationPeriod {
            view.showCentralToast("Params Error")
            return
        }
        
        MKSFBXSTriggerParamManager.shared.stepThreeModel.slotType = MKSFBXSTriggerParamManager.shared.stepTwoModel.slotType
        
        let vc = MKSFBXSTriggerStepThreeController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Interface
    func saveDataToDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)
        //第一个页面读取全部数据，包含了第二个和第三个页面的数据
        Task {[weak self] in
            guard let self = self else { return }
            do {
                _ = try await MKSFBXSTriggerParamManager.shared.config()
                MKSwiftHudManager.shared.hide()
                self.view.showCentralToast("Success")
                perform(#selector(self.goback), with: nil, afterDelay: 0.5)
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                self.view.showCentralToast(errorMessage)
            }
        }
    }
    //MARK: - UI Components
    private func loadSubViews() {
        self.defaultTitle = "SLOT\(MKSFBXSTriggerParamManager.shared.slotIndex + 1)"
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    // MARK: - Lazy
    
    private lazy var tableView: MKSwiftBaseTableView = {
        let tableView = MKSwiftBaseTableView(frame: .zero, style: .plain)
        tableView.backgroundColor = Color.rgb(242, 242, 242)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = tableHeaderView
        tableView.tableFooterView = tableFooterView
        return tableView
    }()
    
    private lazy var nextButton: UIButton = {
        return MKSwiftUIAdaptor.createRoundedButton(title: "Next",
                                                    target: self,
                                                    action: #selector(nextButtonPressed))
    }()
    
    private lazy var tableHeaderView: UIView = {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: Screen.width, height: 90.0))
        headerView.backgroundColor = Color.rgb(242, 242, 242)
        
        let stepLabel = UILabel(frame: CGRect(x: 15, y: 10, width: Screen.width - 30, height: 20))
        stepLabel.textAlignment = .left
        stepLabel.attributedText = MKSwiftUIAdaptor.createAttributedString(strings: ["2", "/3", ":", "Event occurs setting"], fonts: [Font.MKFont(15.0),Font.MKFont(13.0),Font.MKFont(13.0),Font.MKFont(18.0)], colors: [Color.navBar,Color.rgb(137, 137, 137),Color.navBar,Color.defaultText])
        headerView.addSubview(stepLabel)
        
        let noteMsgLabel = UILabel(frame: CGRect(x: 15, y: 40, width: Screen.width - 30, height: 45))
        noteMsgLabel.textAlignment = .left
        noteMsgLabel.textColor = Color.rgb(204, 102, 72)
        noteMsgLabel.font = Font.MKFont(13.0)
        noteMsgLabel.numberOfLines = 0
        noteMsgLabel.text = "*In this step, you can configure the advertising parameters of trigger event occurs."
        headerView.addSubview(noteMsgLabel)
        
        return headerView
    }()
    
    private lazy var tableFooterView: UIView = {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: Screen.width, height: 80))
        footerView.backgroundColor = Color.rgb(242, 242, 242)
        
        let btnWidth = (Screen.width - 90) / 2
                
        let backBtn = MKSwiftUIAdaptor.createRoundedButton(title: "Back",target: self,action: #selector(leftButtonMethod))
        backBtn.frame = CGRect(x: 30, y: 20, width: btnWidth, height: 40)
        footerView.addSubview(backBtn)
        
        nextButton.frame = CGRect(x: 60 + btnWidth, y: 20, width: btnWidth, height: 40)
        footerView.addSubview(nextButton)
        
        return footerView
    }()
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension MKSFBXSTriggerStepTwoController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return headerList.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            //Frame type
            return section0List.count
        }
        
        let slotType = MKSFBXSTriggerParamManager.shared.stepTwoModel.slotType
        
        if section == 1 {
            return (slotType == .tlm || slotType == .null) ? 0 : section1List.count
        }
        
        if section == 2 {
            return (slotType == .null) ? 0 : section2List.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let slotType = MKSFBXSTriggerParamManager.shared.stepTwoModel.slotType
        
        if indexPath.section == 1 && indexPath.row == 0 {
            switch slotType {
            case .uid: return 120
            case .url: return 100
            case .beacon: return 160
            case .sensorInfo: return 120
            default: return 0
            }
        }
        
        if indexPath.section == 2 && indexPath.row == 0 {
            switch slotType {
            case .tlm: return 200
            case .uid, .url, .beacon, .sensorInfo: return 260
            default: return 0
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
        case 0: return loadSection0Cell(indexPath.row)
        case 1: return loadSection1Cell(indexPath.row)
        case 2: return loadSection2Cell(indexPath.row)
        default: return UITableViewCell()
        }
    }
}

// MARK: - MKSwiftTextButtonCellDelegate
extension MKSFBXSTriggerStepTwoController: @preconcurrency MKSwiftTextButtonCellDelegate {
    func MKSwiftTextButtonCellSelected(index: Int, dataListIndex: Int, value: String) {
        if index == 0 {
            //Frame type
            MKSFBXSTriggerParamManager.shared.stepTwoModel.slotType = fetchSlotType(dataListIndex)
            loadSectionDatas()
            return
        }
    }
}

// MARK: - MKSFBXSSlotBeaconCellDelegate
extension MKSFBXSTriggerStepTwoController: @preconcurrency MKSFBXSSlotBeaconCellDelegate {
    func bxs_swf_advContent_majorChanged(major: String) {
        MKSFBXSTriggerParamManager.shared.stepTwoModel.major = major
    }
    
    func bxs_swf_advContent_minorChanged(minor: String) {
        MKSFBXSTriggerParamManager.shared.stepTwoModel.minor = minor
    }
    
    func bxs_swf_advContent_uuidChanged(uuid: String) {
        MKSFBXSTriggerParamManager.shared.stepTwoModel.uuid = uuid
    }
}

// MARK: - MKSFBXSSlotSensorInfoCellDelegate
extension MKSFBXSTriggerStepTwoController: @preconcurrency MKSFBXSSlotSensorInfoCellDelegate {
    func bxs_swf_advContent_tagInfo_deviceNameChanged(_ text: String) {
        MKSFBXSTriggerParamManager.shared.stepTwoModel.deviceName = text
    }
    
    func bxs_swf_advContent_tagInfo_tagIDChanged(_ text: String) {
        MKSFBXSTriggerParamManager.shared.stepTwoModel.tagID = text
    }
}

// MARK: - MKSFBXSSlotUIDCellDelegate
extension MKSFBXSTriggerStepTwoController: @preconcurrency MKSFBXSSlotUIDCellDelegate {
    func bxs_swf_advContent_namespaceIDChanged(_ text: String) {
        MKSFBXSTriggerParamManager.shared.stepTwoModel.namespaceID = text
    }
    
    func bxs_swf_advContent_instanceIDChanged(_ text: String) {
        MKSFBXSTriggerParamManager.shared.stepTwoModel.instanceID = text
    }
}

// MARK: - MKSFBXSSlotURLCellDelegate
extension MKSFBXSTriggerStepTwoController: @preconcurrency MKSFBXSSlotURLCellDelegate {
    func bxs_swf_advContent_urlTypeChanged(_ urlType: Int) {
        MKSFBXSTriggerParamManager.shared.stepTwoModel.urlType = urlType
    }
    
    func bxs_swf_advContent_urlContentChanged(_ content: String) {
        MKSFBXSTriggerParamManager.shared.stepTwoModel.urlContent = content
    }
}

// MARK: - MKSFBXSTriggerSlotParamCellDelegate
extension MKSFBXSTriggerStepTwoController: @preconcurrency MKSFBXSTriggerSlotParamCellDelegate {
    func bxs_swf_triggerSlotParam_advIntervalChanged(_ interval: String) {
        MKSFBXSTriggerParamManager.shared.stepTwoModel.advInterval = interval
    }
    
    func bxs_swf_triggerSlotParam_advDurationChanged(_ duration: String) {
        MKSFBXSTriggerParamManager.shared.stepTwoModel.advDuration = duration
    }
    
    func bxs_swf_triggerSlotParam_rssiChanged(_ rssi: Int) {
        MKSFBXSTriggerParamManager.shared.stepTwoModel.rssi = rssi
    }
    
    func bxs_swf_triggerSlotParam_txPowerChanged(_ txPower: Int) {
        MKSFBXSTriggerParamManager.shared.stepTwoModel.txPower = txPower
    }
}
