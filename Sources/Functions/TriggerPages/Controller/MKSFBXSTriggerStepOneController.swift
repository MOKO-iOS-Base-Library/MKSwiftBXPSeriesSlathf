//
//  MKSFBXSTriggerStepOneController.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/24.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

class MKSFBXSTriggerStepOneController: MKSwiftBaseViewController {
    
    var slotIndex: Int = 0
    
    // MARK: - Data Sources
    
    private lazy var section0List: [MKSwiftTextSwitchCellModel] = []
    private lazy var section1List: [MKSwiftTextButtonCellModel] = []
    private lazy var section2List: [MKSwiftTextButtonCellModel] = []
    private lazy var section3List: [MKSwiftNormalSliderCellModel] = []
    private lazy var section4List: [MKSwiftNormalSliderCellModel] = []
    private lazy var section5List: [MKSwiftTextFieldCellModel] = []
    private lazy var section6List: [MKSwiftTextSwitchCellModel] = []
    private lazy var section7List: [MKSwiftTextFieldCellModel] = []
    private lazy var headerList: [MKSwiftTableSectionLineHeaderModel] = []
    
    // MARK: - Life Cycle
    
    deinit {
        print("MKSFBXSTriggerStepOneController销毁")
    }
    
    override func viewDidPopFromNavigationStack() {
        MKSFBXSTriggerParamManager.sharedDealloc()
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
        MKSFBXSTriggerParamManager.shared.slotIndex = self.slotIndex
        readDataFromDevice()
    }
    
    // MARK: - Event Methods
    
    @objc private func nextButtonPressed() {
        if nextButton.titleLabel?.text == "Done" {
            // Close trigger
            MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)
            Task {[weak self] in
                guard let self = self else { return }
                do {
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
                    let errorMessage = error.localizedDescription
                    MKSwiftHudManager.shared.hide()
                    self.view.showCentralToast(errorMessage)
                }
            }
            return
        }
        
        if MKSFBXSTriggerParamManager.shared.stepOneModel.fetchTriggerType() == 2 {
            // Motion trigger
            if MKSFBXSTriggerParamManager.shared.stepOneModel.motionEvent < 0 ||
                MKSFBXSTriggerParamManager.shared.stepOneModel.motionEvent > 1 ||
                MKSFBXSTriggerParamManager.shared.stepOneModel.motionVerificationPeriod.isEmpty ||
                Int(MKSFBXSTriggerParamManager.shared.stepOneModel.motionVerificationPeriod) ?? 0 < 1 ||
                Int(MKSFBXSTriggerParamManager.shared.stepOneModel.motionVerificationPeriod) ?? 0 > 65535 {
                view.showCentralToast("Params Error")
                return
            }
        }
        
        let vc = MKSFBXSTriggerStepTwoController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Interface Method
    
    private func readDataFromDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        Task {[weak self] in
            guard let self = self else { return }
            do {
                await MKSFBXSTriggerParamManager.shared.stepOneModel.loadTriggerTypeList()
                _ = try await MKSFBXSTriggerParamManager.shared.read()
                MKSwiftHudManager.shared.hide()
                self.loadSectionDatas()
                let nextTitle = MKSFBXSTriggerParamManager.shared.stepOneModel.trigger ? "Next" : "Done"
                self.nextButton.setTitle(nextTitle, for: .normal)
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                self.view.showCentralToast(errorMessage)
            }
        }
    }
    
    // MARK: - Private Methods
    
    @objc private func goback() {
        popToViewController(withClassName: "MKSFBXSSlotController")
    }
    
    private func loadTriggerEventList() -> [String] {
        switch MKSFBXSTriggerParamManager.shared.stepOneModel.fetchTriggerType() {
        case 0: return ["Temperature above", "Temperature below"]       //当前是温度触发
        case 1: return ["Humidity above", "Humidity below"]             //当前是湿度触发
        case 2: return ["Device start moving", "Device keep static"]    //当前是移动触发
        case 3: return ["Door open", "Door close"]                      //当前是霍尔触发
        default: return []
        }
    }
    
    private func loadTriggerEventIndex() -> Int {
        let step1Model = MKSFBXSTriggerParamManager.shared.stepOneModel
        switch step1Model.fetchTriggerType() {
        case 0: return step1Model.tempEvent         //当前是温度触发
        case 1: return step1Model.humidityEvent     //当前是湿度触发
        case 2: return step1Model.motionEvent       //当前是移动触发
        case 3: return step1Model.hallEvent         //当前是霍尔触发
        default: return 0
        }
    }
    
    // MARK: - Load Section Datas
    
    private func loadSectionDatas() {
        loadSection0Datas()
        loadSection1Datas()
        loadSection2Datas()
        loadSection3Datas()
        loadSection4Datas()
        loadSection5Datas()
        loadSection6Datas()
        loadSection7Datas()
        
        for _ in 0..<8 {
            headerList.append(MKSwiftTableSectionLineHeaderModel())
        }
        
        tableView.reloadData()
    }
    
    private func loadSection0Datas() {
        let cellModel = MKSwiftTextSwitchCellModel()
        cellModel.index = 0
        cellModel.msg = "Trigger"
        cellModel.isOn = MKSFBXSTriggerParamManager.shared.stepOneModel.trigger
        section0List.append(cellModel)
    }
    
    private func loadSection1Datas() {
        let cellModel = MKSwiftTextButtonCellModel()
        cellModel.index = 0
        cellModel.msg = "Trigger type"
        cellModel.dataList = MKSFBXSTriggerParamManager.shared.stepOneModel.fetchTriggerTypeList()
        cellModel.dataListIndex = MKSFBXSTriggerParamManager.shared.stepOneModel.triggerIndex
        cellModel.buttonLabelFont = Font.MKFont(12.0)
        section1List.append(cellModel)
    }
    
    private func loadSection2Datas() {
        let cellModel = MKSwiftTextButtonCellModel()
        cellModel.index = 1
        cellModel.msg = "Trigger event"
        cellModel.dataList = loadTriggerEventList()
        cellModel.dataListIndex = loadTriggerEventIndex()
        cellModel.buttonLabelFont = Font.MKFont(12.0)
        section2List.append(cellModel)
    }
    
    private func loadSection3Datas() {
        let cellModel = MKSwiftNormalSliderCellModel()
        cellModel.index = 0
        cellModel.msg = MKSwiftUIAdaptor.createAttributedString(strings: ["Temperature threshold", "   (-40℃~150℃)"], fonts: [Font.MKFont(13.0),Font.MKFont(12.0)], colors: [Color.defaultText,Color.rgb(223, 223, 223)])
        cellModel.sliderMinValue = -40
        cellModel.sliderMaxValue = 150
        cellModel.unit = "℃"
        cellModel.sliderValue = MKSFBXSTriggerParamManager.shared.stepOneModel.temperature
        section3List.append(cellModel)
    }
    
    private func loadSection4Datas() {
        let cellModel = MKSwiftNormalSliderCellModel()
        cellModel.index = 1
        cellModel.msg = MKSwiftUIAdaptor.createAttributedString(strings: ["Humidity threshold", "   (0%~95%)"], fonts: [Font.MKFont(13.0),Font.MKFont(12.0)], colors: [Color.defaultText,Color.rgb(223, 223, 223)])
        cellModel.sliderMinValue = 0
        cellModel.sliderMaxValue = 95
        cellModel.unit = "%"
        cellModel.sliderValue = MKSFBXSTriggerParamManager.shared.stepOneModel.humidity
        section4List.append(cellModel)
    }
    
    private func loadSection5Datas() {
        let cellModel = MKSwiftTextFieldCellModel()
        cellModel.index = 0
        cellModel.msg = "Static verify period"
        cellModel.textFieldType = .realNumberOnly
        cellModel.textPlaceholder = "1~65535"
        cellModel.unit = "s"
        cellModel.maxLength = 5
        cellModel.textFieldValue = MKSFBXSTriggerParamManager.shared.stepOneModel.motionVerificationPeriod
        cellModel.noteMsg = "*Static verify period: the parameter that determines when a stationary event occurs on the device."
        cellModel.noteMsgColor = Color.rgb(201, 90, 49)
        section5List.append(cellModel)
    }
    
    private func loadSection6Datas() {
        let cellModel = MKSwiftTextSwitchCellModel()
        cellModel.index = 1
        cellModel.msg = "Locked ADV function"
        cellModel.isOn = MKSFBXSTriggerParamManager.shared.stepOneModel.lockedAdvIsOn
        if MKSFBXSTriggerParamManager.shared.stepOneModel.lockedAdvIsOn {
            cellModel.noteMsg = "*Lock Event Occurs ADV Duration: If the device quickly returns to a state where the triggering condition is no longer met after initially satisfying the triggering condition, it can only broadcast for a short duration, or might not broadcast at all. The Locked ADV function ensures that, in such cases, the set post-trigger broadcast duration is fully executed, regardless of changes in the triggering condition.\n\n Note: If the Event Occurs Total adv duration is set to 0, the Lock post -trigger adv duration will default to a locked broadcast of 5 seconds."
        }
        cellModel.noteMsgColor = Color.rgb(201, 90, 49)
        section6List.append(cellModel)
    }
    
    private func loadSection7Datas() {
        let cellModel = MKSwiftTextFieldCellModel()
        cellModel.index = 1
        cellModel.msg = "Locked ADV duration"
        cellModel.textFieldType = .realNumberOnly
        cellModel.textPlaceholder = "1~65535"
        cellModel.unit = "s"
        cellModel.maxLength = 5
        cellModel.noteMsg = "*Lock ADV duration: If the device quickly returns to a state that does not meet the trigger conditions after initially satisfying them, it may only broadcast for a short period. The lock broadcast duration feature ensures that, in such cases, the device broadcasts for the set lock broadcast duration. This feature's parameter must be set to a value less than the post-trigger broadcast duration."
        cellModel.noteMsgColor = Color.rgb(201, 90, 49)
        section7List.append(cellModel)
    }
    
    // MARK: - Private Methods
    
    private func loadSubViews() {
        self.defaultTitle = "SLOT\(MKSFBXSTriggerParamManager.shared.slotIndex + 1)"
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    // MARK: - UI Components
    
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
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: Screen.width, height: 110))
        headerView.backgroundColor = Color.rgb(242, 242, 242)
        
        let stepLabel = UILabel(frame: CGRect(x: 15, y: 10, width: Screen.width - 30, height: 20))
        stepLabel.textAlignment = .left
        stepLabel.attributedText = MKSwiftUIAdaptor.createAttributedString(strings: ["1", "/3", ":", "Initial Setting"], fonts: [Font.MKFont(15.0),Font.MKFont(13.0),Font.MKFont(13.0),Font.MKFont(18.0)], colors: [Color.navBar,Color.rgb(137, 137, 137),Color.navBar,Color.defaultText])
        headerView.addSubview(stepLabel)
        
        let noteMsgLabel = UILabel(frame: CGRect(x: 15, y: 40, width: Screen.width - 30, height: 65))
        noteMsgLabel.textAlignment = .left
        noteMsgLabel.textColor = Color.rgb(204, 102, 72)
        noteMsgLabel.font = Font.MKFont(13.0)
        noteMsgLabel.numberOfLines = 0
        noteMsgLabel.text = "*In this step1, you can enable or disable the trigger feature, You can also configure the trigger type and define the event criteria that meet the trigger conditions (Trigger event)."
        headerView.addSubview(noteMsgLabel)
        
        return headerView
    }()
    
    private lazy var tableFooterView: UIView = {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: Screen.width, height: 80))
        footerView.backgroundColor = Color.rgb(242, 242, 242)
        
        footerView.addSubview(nextButton)
        nextButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.equalToSuperview().offset(30)
            make.right.equalToSuperview().offset(-30)
            make.height.equalTo(40)
        }
        
        return footerView
    }()
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension MKSFBXSTriggerStepOneController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 3://Temperature threshold
            let cellModel = section3List[indexPath.row]
            return cellModel.cellHeightWithContentWidth(Screen.width)
        case 4://Humidity threshold
            let cellModel = section4List[indexPath.row]
            return cellModel.cellHeightWithContentWidth(Screen.width)
        case 5://Static verify period
            let cellModel = section5List[indexPath.row]
            return cellModel.cellHeightWithContentWidth(Screen.width)
        case 6://Lock Event Occurs ADV Duration
            let cellModel = section6List[indexPath.row]
            return cellModel.cellHeightWithContentWidth(Screen.width)
        case 7://Locked ADV duration
            let cellModel = section7List[indexPath.row]
            return cellModel.cellHeightWithContentWidth(Screen.width)
        default:
            return 44
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        section == 7 ? 0 : 10
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = MKSwiftTableSectionLineHeader.dequeueHeader(with: tableView)
        headerView.headerModel = headerList[section]
        return headerView
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        headerList.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            //Trigger
            return section0List.count
        }
        
        if !MKSFBXSTriggerParamManager.shared.stepOneModel.trigger {
            //关闭触发
            return 0;
        }
        
        if section == 1 {
            //Trigger type
            return section1List.count
        }
        
        if section == 2 {
            //Trigger event
            return section2List.count
        }
        
        if section == 3 {
            //温度触发
            //Temperature threshold
            return MKSFBXSTriggerParamManager.shared.stepOneModel.fetchTriggerType() == 0 ?
                   section3List.count : 0
        }
        
        if section == 4 {
            //湿度触发
            //Humidity threshold
            return MKSFBXSTriggerParamManager.shared.stepOneModel.fetchTriggerType() == 1 ?
                   section4List.count : 0
        }
        
        if section == 5 {
            //移动触发
            //Static verify period
           return MKSFBXSTriggerParamManager.shared.stepOneModel.fetchTriggerType() == 2 ?
                  section5List.count : 0
        }
        
        if section == 6 {
            //Locked ADV function移动触发不展示
           return MKSFBXSTriggerParamManager.shared.stepOneModel.fetchTriggerType() == 2 ?
            0 : section6List.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = MKSwiftTextSwitchCell.initCellWithTableView(tableView)
            cell.dataModel = section0List[indexPath.row]
            cell.delegate = self
            return cell
        case 1:
            let cell = MKSwiftTextButtonCell.initCellWithTableView(tableView)
            cell.dataModel = section1List[indexPath.row]
            cell.delegate = self
            return cell
        case 2:
            let cell = MKSwiftTextButtonCell.initCellWithTableView(tableView)
            cell.dataModel = section2List[indexPath.row]
            cell.delegate = self
            return cell
        case 3:
            let cell = MKSwiftNormalSliderCell.initCellWithTableView(tableView)
            cell.dataModel = section3List[indexPath.row]
            cell.delegate = self
            return cell
        case 4:
            let cell = MKSwiftNormalSliderCell.initCellWithTableView(tableView)
            cell.dataModel = section4List[indexPath.row]
            cell.delegate = self
            return cell
        case 5:
            let cell = MKSwiftTextFieldCell.initCellWithTableView(tableView)
            cell.dataModel = section5List[indexPath.row]
            cell.delegate = self
            return cell
        case 6:
            let cell = MKSwiftTextSwitchCell.initCellWithTableView(tableView)
            cell.dataModel = section6List[indexPath.row]
            cell.delegate = self
            return cell
        default:
            let cell = MKSwiftTextFieldCell.initCellWithTableView(tableView)
            cell.dataModel = section7List[indexPath.row]
            cell.delegate = self
            return cell
        }
    }
}

// MARK: - MKSwiftTextSwitchCellDelegate

extension MKSFBXSTriggerStepOneController: @preconcurrency MKSwiftTextSwitchCellDelegate {
    func MKSwiftTextSwitchCellStatusChanged(isOn: Bool, index: Int) {
        if index == 0 {
            // Trigger
            MKSFBXSTriggerParamManager.shared.stepOneModel.trigger = isOn
            let cellModel = section0List[0]
            cellModel.isOn = isOn
            
            let nextTitle = MKSFBXSTriggerParamManager.shared.stepOneModel.trigger ? "Next" : "Done"
            nextButton.setTitle(nextTitle, for: .normal)
            tableView.reloadData()
            return
        }
        
        if index == 1 {
            // Locked ADV function
            MKSFBXSTriggerParamManager.shared.stepOneModel.lockedAdvIsOn = isOn
            let cellModel = section6List[0]
            cellModel.isOn = isOn
            cellModel.noteMsg = isOn ? "*Lock Event Occurs ADV Duration: If the device quickly returns to a state where the triggering condition is no longer met after initially satisfying the triggering condition, it can only broadcast for a short duration, or might not broadcast at all. The Locked ADV function ensures that, in such cases, the set post-trigger broadcast duration is fully executed, regardless of changes in the triggering condition.Note: If the Event Occurs Total adv duration is set to 0, the Lock post -trigger adv duration will default to a locked broadcast of 5 seconds." : ""
            
            tableView.reloadSections(IndexSet(integer: 6), with: .none)
            return
        }
    }
}

// MARK: - MKSwiftTextButtonCellDelegate

extension MKSFBXSTriggerStepOneController: @preconcurrency MKSwiftTextButtonCellDelegate {
    func MKSwiftTextButtonCellSelected(index: Int, dataListIndex: Int, value: String) {
        if index == 0 {
            // Trigger type
            MKSFBXSTriggerParamManager.shared.stepOneModel.triggerIndex = dataListIndex
            let cellModel1 = section1List[0]
            cellModel1.dataListIndex = dataListIndex
            
            let cellModel2 = section2List[0]
            cellModel2.dataList = loadTriggerEventList()
            cellModel2.dataListIndex = 0
            
            tableView.reloadData()
            return
        }
        
        if index == 1 {
            // Trigger event
            let cellModel = section2List[0]
            cellModel.dataListIndex = dataListIndex
            
            switch MKSFBXSTriggerParamManager.shared.stepOneModel.fetchTriggerType() {
            case 0://当前是温度触发
                MKSFBXSTriggerParamManager.shared.stepOneModel.tempEvent = dataListIndex
            case 1://当前是湿度触发
                MKSFBXSTriggerParamManager.shared.stepOneModel.humidityEvent = dataListIndex
            case 2://当前是移动触发
                MKSFBXSTriggerParamManager.shared.stepOneModel.motionEvent = dataListIndex
            case 3://当前是霍尔触发
                MKSFBXSTriggerParamManager.shared.stepOneModel.hallEvent = dataListIndex
            default:
                break
            }
            return
        }
    }
}

// MARK: - MKSwiftNormalSliderCellDelegate

extension MKSFBXSTriggerStepOneController: @preconcurrency MKSwiftNormalSliderCellDelegate {
    func mk_normalSliderValueChanged(_ value: Int, index: Int) {
        if index == 0 {
            // Temperature trigger
            MKSFBXSTriggerParamManager.shared.stepOneModel.temperature = value
            let cellModel = section3List[0]
            cellModel.sliderValue = value
            return
        }
        
        if index == 1 {
            // Humidity trigger
            MKSFBXSTriggerParamManager.shared.stepOneModel.humidity = value
            let cellModel = section4List[0]
            cellModel.sliderValue = value
            return
        }
    }
}

// MARK: - MKSwiftTextFieldCellDelegate

extension MKSFBXSTriggerStepOneController: @preconcurrency MKSwiftTextFieldCellDelegate {
    func mkDeviceTextCellValueChanged(_ index: Int, textValue: String) {
        if index == 0 {
            // Static verify period
            MKSFBXSTriggerParamManager.shared.stepOneModel.motionVerificationPeriod = textValue
            let cellModel = section5List[0]
            cellModel.textFieldValue = textValue
            return
        }
    }
}
