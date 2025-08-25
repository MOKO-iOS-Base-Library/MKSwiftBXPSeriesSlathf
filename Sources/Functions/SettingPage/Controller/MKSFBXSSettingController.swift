//
//  MKSFBXSSettingController.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/25.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

class MKSFBXSSettingController: MKSwiftBaseViewController {
    
    // MARK: - Data Properties
    private lazy var section0List = [MKSwiftNormalTextCellModel]()
    private lazy var section1List = [MKSwiftNormalTextCellModel]()
    private lazy var section2List = [MKSwiftNormalTextCellModel]()
    private lazy var section3List = [MKSwiftNormalTextCellModel]()
    private lazy var section4List = [MKSwiftTextButtonCellModel]()
    
    private lazy var dataModel: MKSFBXSSettingModel = {
        return MKSFBXSSettingModel()
    }()
    
    private var needPassword: Bool = false
    private var password: String = ""
    private var dfuModule = false
    private var passwordAsciiStr: String = ""
    private var confirmAsciiStr: String = ""
    
    // MARK: - Life Cycle
    deinit {
        print("MKSFBXSSettingController销毁")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(deviceStartDFUProcess),
                                             name: NSNotification.Name("mk_bxs_swf_startDfuProcessNotification"),
                                             object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if dfuModule { return }
        readDatas()
    }
    
    // MARK: - Super Method
    override func leftButtonMethod() {
        NotificationCenter.default.post(name: NSNotification.Name("mk_bxs_swf_popToRootViewControllerNotification"),
                                      object: nil)
    }
    
    // MARK: - Notification
    @objc private func deviceStartDFUProcess() {
        dfuModule = true
    }
    
    // MARK: - Data Handling
    private func readDatas() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        let dataModel = self.dataModel
        Task {
            do {
                password = await MKSFBXSConnectManager.shared.getPassword()
                needPassword = await MKSFBXSConnectManager.shared.getNeedPassword()
                try await dataModel.read()
                MKSwiftHudManager.shared.hide()
                loadSection0Datas()
                loadSection1Datas()
                loadSection2Datas()
                loadSection3Datas()
                loadSection4Datas()
                tableView.reloadData()
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                view.showCentralToast(errorMessage)
            }
        }
    }
    
    // MARK: - Section Data Loading
    private func loadSection0Datas() {
        section0List.removeAll()
        
        if dataModel.supportThreeAcc || dataModel.supportTH || !dataModel.hallStatus {
            let cellModel1 = MKSwiftNormalTextCellModel()
            cellModel1.showRightIcon = true
            cellModel1.leftMsg = "Sensor configurations"
            cellModel1.methodName = "pushSensorConfigPage"
            section0List.append(cellModel1)
        }
        
        let cellModel2 = MKSwiftNormalTextCellModel()
        cellModel2.showRightIcon = true
        cellModel2.leftMsg = "Quick switch"
        cellModel2.methodName = "pushQuickSwitchPage"
        section0List.append(cellModel2)
    }
    
    private func loadSection1Datas() {
        section1List.removeAll()
        
        if needPassword {
            let resetModel = MKSwiftNormalTextCellModel()
            resetModel.leftMsg = "Reset Beacon"
            resetModel.showRightIcon = true
            resetModel.methodName = "factoryReset"
            section1List.append(resetModel)
        }
        
        if password.count > 0, needPassword {
            let passwordModel = MKSwiftNormalTextCellModel()
            passwordModel.leftMsg = "Modify password"
            passwordModel.showRightIcon = true
            passwordModel.methodName = "configPassword"
            section1List.append(passwordModel)
        }
    }
    
    private func loadSection2Datas() {
        section2List.removeAll()
        
        let dfuModel = MKSwiftNormalTextCellModel()
        dfuModel.leftMsg = "DFU"
        dfuModel.showRightIcon = true
        dfuModel.methodName = "pushDFUPage"
        section2List.append(dfuModel)
    }
    
    private func loadSection3Datas() {
        section3List.removeAll()
        
        let dfuModel = MKSwiftNormalTextCellModel()
        dfuModel.leftMsg = "Remote reminder"
        dfuModel.showRightIcon = true
        dfuModel.methodName = "pushRemoteReminder"
        section3List.append(dfuModel)
        
        let resetBatteryModel = MKSwiftNormalTextCellModel()
        resetBatteryModel.leftMsg = "Reset Battery"
        resetBatteryModel.showRightIcon = true
        resetBatteryModel.methodName = "resetBattery"
        section3List.append(resetBatteryModel)
    }
    
    private func loadSection4Datas() {
        section4List.removeAll()
        
        let cellModel1 = MKSwiftTextButtonCellModel()
        cellModel1.index = 0
        cellModel1.msg = "Battery ADV mode"
        cellModel1.dataList = ["Voltage", "Percentage"]
        cellModel1.dataListIndex = dataModel.batteryAdvMode
        section4List.append(cellModel1)
        
        let cellModel2 = MKSwiftTextButtonCellModel()
        cellModel2.index = 1
        cellModel2.msg = "ADV Channel"
        cellModel2.dataList = ["CH37&38&39", "CH37", "CH38", "CH39"]
        cellModel2.dataListIndex = dataModel.advChannel
        section4List.append(cellModel2)
    }
    
    // MARK: - Action Methods
    @objc private func pushSensorConfigPage() {
        let vc = MKSFBXSSensorConfigController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func pushQuickSwitchPage() {
        let vc = MKSFBXSQuickSwitchController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func configPassword() {
        
        let cancelAction = MKSwiftAlertViewAction(title: "Cancel") {
            
        }
        
        let confirmAction = MKSwiftAlertViewAction(title: "OK") { [weak self] in
            self?.setPasswordToDevice()
        }
        
        let passwordField = MKSwiftAlertViewTextField(placeholder: "Enter new password",textFieldType: .normal,maxLength: 16) { [weak self] text in
            self?.passwordAsciiStr = text
        }
        
        let confirmField = MKSwiftAlertViewTextField(placeholder: "Enter new password again",textFieldType: .normal,maxLength: 16) { [weak self] text in
            self?.confirmAsciiStr = text
        }
        
        let msg = "Note:The password should not be exceed 16 characters in length."
        let alertView = MKSwiftAlertView()
        alertView.addAction(cancelAction)
        alertView.addAction(confirmAction)
        alertView.addTextField(passwordField)
        alertView.addTextField(confirmField)
        alertView.showAlert(title: "Modify password", message: msg, notificationName: "mk_bxb_needDismissAlert")
    }
    
    private func setPasswordToDevice() {
        guard !passwordAsciiStr.isEmpty,
              !confirmAsciiStr.isEmpty,
              passwordAsciiStr.count <= 16,
              confirmAsciiStr.count <= 16 else {
            view.showCentralToast("Length error.")
            return
        }
        
        guard passwordAsciiStr == confirmAsciiStr else {
            view.showCentralToast("Password not match! Please try again.")
            return
        }
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        Task {
            do {
                _ = try await MKSFBXSInterface.configConnectPassword(password: passwordAsciiStr)
                MKSwiftHudManager.shared.hide()
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                view.showCentralToast(errorMessage)
            }
        }
    }
    
    @objc private func factoryReset() {
        let cancelAction = MKSwiftAlertViewAction(title: "Cancel") {
            
        }
        
        let confirmAction = MKSwiftAlertViewAction(title: "OK") { [weak self] in
            self?.sendResetCommandToDevice()
        }
        
        let msg = "Are you sure to reset the Beacon?"
        let alertView = MKSwiftAlertView()
        alertView.addAction(cancelAction)
        alertView.addAction(confirmAction)
        alertView.showAlert(title: "Warning!", message: msg, notificationName: "mk_bxb_needDismissAlert")
    }
    
    private func sendResetCommandToDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        Task {
            do {
                _ = try await MKSFBXSInterface.factoryReset()
                MKSwiftHudManager.shared.hide()
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                view.showCentralToast(errorMessage)
            }
        }
    }
    
    @objc private func pushDFUPage() {
        let vc = MKSFBXSUpdateController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func pushRemoteReminder() {
        let vc = MKSFBXSRemoteReminderController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func resetBattery() {
        let cancelAction = MKSwiftAlertViewAction(title: "Cancel") {
            
        }
        
        let confirmAction = MKSwiftAlertViewAction(title: "OK") { [weak self] in
            self?.sendResetBatteryCommandToDevice()
        }
        
        let msg = "*Please ensure you have replaced the new battery for this beacon before reset the Battery"
        let alertView = MKSwiftAlertView()
        alertView.addAction(cancelAction)
        alertView.addAction(confirmAction)
        alertView.showAlert(title: "Warning!", message: msg, notificationName: "mk_bxb_needDismissAlert")
    }
    
    private func sendResetBatteryCommandToDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        Task {
            do {
                _ = try await MKSFBXSInterface.batteryReset()
                MKSwiftHudManager.shared.hide()
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                view.showCentralToast(errorMessage)
            }
        }
    }
    
    private func configBatteryAdvMode(_ mode: Int) {
        
        let tempMode: MKSFBXSBatteryADVMode = (mode == 0) ? .voltage : .percentage
        
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        Task {
            do {
                _ = try await MKSFBXSInterface.configBatteryADVMode(mode: tempMode)
                MKSwiftHudManager.shared.hide()
                section4List[0].dataListIndex = mode
                dataModel.batteryAdvMode = mode
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                view.showCentralToast(errorMessage)
            }
        }
    }
    
    private func configAdvChannel(_ channel: Int) {
        let channelValue: MKSFBXSAdvChannel
        switch channel {
        case 1: channelValue = .ch37
        case 2: channelValue = .ch38
        case 3: channelValue = .ch39
        default: channelValue = .all
        }
        
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        Task {
            do {
                _ = try await MKSFBXSInterface.configADVChannel(channel: channelValue)
                MKSwiftHudManager.shared.hide()
                section4List[1].dataListIndex = channel
                dataModel.advChannel = channel
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                view.showCentralToast(errorMessage)
                tableView.mk_reloadRow(1, inSection: 4, with: .none)
            }
        }
    }
    
    // MARK: - UI
    private func loadSubViews() {
        defaultTitle = "SETTING"
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-49)
        }
    }
    
    // MARK: - UI Properties
    private lazy var tableView: MKSwiftBaseTableView = {
        let table = MKSwiftBaseTableView(frame: .zero, style: .plain)
        table.delegate = self
        table.dataSource = self
        return table
    }()
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension MKSFBXSSettingController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = MKSwiftNormalTextCell.initCellWithTableView(tableView)
            cell.dataModel = section0List[indexPath.row]
            return cell
        case 1:
            let cell = MKSwiftNormalTextCell.initCellWithTableView(tableView)
            cell.dataModel = section1List[indexPath.row]
            return cell
        case 2:
            let cell = MKSwiftNormalTextCell.initCellWithTableView(tableView)
            cell.dataModel = section2List[indexPath.row]
            return cell
        case 3:
            let cell = MKSwiftNormalTextCell.initCellWithTableView(tableView)
            cell.dataModel = section3List[indexPath.row]
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 4 { return }
        
        var cellModel: MKSwiftNormalTextCellModel?
        switch indexPath.section {
        case 0: cellModel = section0List[indexPath.row]
        case 1: cellModel = section1List[indexPath.row]
        case 2: cellModel = section2List[indexPath.row]
        case 3: cellModel = section3List[indexPath.row]
        default: break
        }
        
        if let methodName = cellModel?.methodName, !methodName.isEmpty, responds(to: Selector(methodName)) {
            perform(Selector(methodName))
        }
    }
}

// MARK: - MKSwiftTextButtonCellDelegate
extension MKSFBXSSettingController: @preconcurrency MKSwiftTextButtonCellDelegate {
    func MKSwiftTextButtonCellSelected(index: Int, dataListIndex: Int, value: String) {
        if index == 0 {
            // Battery ADV mode
            configBatteryAdvMode(dataListIndex)
            return
        }
        if index == 1 {
            // ADV Channel
            configAdvChannel(dataListIndex)
            return
        }
    }
}
