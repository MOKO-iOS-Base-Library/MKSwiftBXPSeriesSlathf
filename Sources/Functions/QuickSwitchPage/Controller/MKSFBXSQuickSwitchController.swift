//
//  MKSFBXSQuickSwitchController.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/19.
//
import UIKit
import SnapKit
import MKBaseSwiftModule
import MKSwiftBeaconXCustomUI

class MKSFBXSQuickSwitchController: MKSwiftBaseViewController {
    
    // MARK: - Properties
    private lazy var dataList: [MKBXQuickSwitchCellModel] = []
    private lazy var dataModel = MKSFBXSQuickSwitchModel()
    
    // MARK: - Life Cycle
    deinit {
        print("MKSFBXSQuickSwitchController销毁")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        readDataFromDevice()
    }
    
    // MARK: - Private Methods
    
    private func readDataFromDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        Task {[weak self] in
            guard let self = self else { return }
            do {
                try await self.dataModel.read()
                MKSwiftHudManager.shared.hide()
                self.loadSectionData()
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                self.view.showCentralToast(errorMessage)
            }
        }
    }
    
    private func loadSectionData() {
        let cellModel1 = MKBXQuickSwitchCellModel()
        cellModel1.index = 0
        cellModel1.titleMsg = "Connectable status"
        cellModel1.isOn = dataModel.connectable
        dataList.append(cellModel1)
        
        let cellModel2 = MKBXQuickSwitchCellModel()
        cellModel2.index = 1
        cellModel2.titleMsg = "Trigger LED indicator"
        cellModel2.isOn = dataModel.trigger
        dataList.append(cellModel2)
        
        let cellModel3 = MKBXQuickSwitchCellModel()
        cellModel3.index = 2
        cellModel3.titleMsg = "Password verification"
        cellModel3.isOn = dataModel.passwordVerification
        dataList.append(cellModel3)
        
        let cellModel4 = MKBXQuickSwitchCellModel()
        cellModel4.index = 3
        cellModel4.titleMsg = "Tag ID Autofill"
        cellModel4.isOn = dataModel.autoFill
        dataList.append(cellModel4)
        
        let cellModel5 = MKBXQuickSwitchCellModel()
        cellModel5.index = 4
        cellModel5.titleMsg = "Reset Beacon by button"
        cellModel5.isOn = dataModel.resetByButton
        dataList.append(cellModel5)
        
        let cellModel6 = MKBXQuickSwitchCellModel()
        cellModel6.index = 5
        cellModel6.titleMsg = "Turn off Beacon by button"
        cellModel6.isOn = dataModel.turnOffByButton
        dataList.append(cellModel6)
        
        collectionView.reloadData()
    }
    
    private func configConnectEnable(_ connect: Bool) {
        if connect {
            setConnectStatusToDevice(connect)
            return
        }
        let msg = "Are you sure to set the Beacon non-connectable？"
        let alertView = MKSwiftAlertView()
        
        let confirmAction = MKSwiftAlertViewAction(title: "OK") {[weak self] in
            self?.setConnectStatusToDevice(connect)
        }
        let cancelAction = MKSwiftAlertViewAction(title: "Cancel") {[weak self] in
            self?.collectionView.reloadData()
        }
        alertView.addAction(confirmAction)
        alertView.addAction(cancelAction)
        alertView.showAlert(title: "Warning!",message: msg,notificationName: "mk_bxs_swf_needDismissAlert")
    }
    
    private func setConnectStatusToDevice(_ connect: Bool) {
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        Task {[weak self] in
            guard let self = self else { return }
            do {
                let result = try await MKSFBXSInterface.configConnectable(connectable: connect)
                MKSwiftHudManager.shared.hide()
                if !result {
                    self.view.showCentralToast("Config failed")
                    self.collectionView.reloadData()
                    return
                }
                self.view.showCentralToast("Success!")
                self.dataModel.connectable = connect
                let cellModel = self.dataList[0]
                cellModel.isOn = connect
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                self.view.showCentralToast(errorMessage)
            }
        }
    }
    
    private func configTriggerLEDIndicator(_ isOn: Bool) {
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        Task {[weak self] in
            guard let self = self else { return }
            do {
                let result = try await MKSFBXSInterface.configTriggerLEDIndicatorStatus(isOn: isOn)
                MKSwiftHudManager.shared.hide()
                if !result {
                    self.view.showCentralToast("Config failed")
                    self.collectionView.reloadData()
                    return
                }
                self.view.showCentralToast("Success!")
                self.dataModel.trigger = isOn
                let cellModel = self.dataList[1]
                cellModel.isOn = isOn
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                selfview.showCentralToast(errorMessage)
            }
        }
    }
    
    private func configPasswordVerification(_ isOn: Bool) {
        if isOn {
            commandForPasswordVerification(isOn)
            return
        }
        
        let msg = "If Password verification is disabled, it will not need password to connect the Beacon."
        let alertView = MKSwiftAlertView()
        
        let confirmAction = MKSwiftAlertViewAction(title: "OK") {[weak self] in
            self?.commandForPasswordVerification(isOn)
        }
        let cancelAction = MKSwiftAlertViewAction(title: "Cancel") {[weak self] in
            self?.collectionView.reloadData()
        }
        alertView.addAction(confirmAction)
        alertView.addAction(cancelAction)
        alertView.showAlert(title: "Warning!",message: msg,notificationName: "mk_bxs_swf_needDismissAlert")
    }
    
    private func commandForPasswordVerification(_ isOn: Bool) {
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        
        Task {[weak self] in
            guard let self = self else { return }
            do {
                let result = try await MKSFBXSInterface.configPasswordVerification(isOn: isOn)
                MKSwiftHudManager.shared.hide()
                if !result {
                    self.view.showCentralToast("Config failed")
                    self.collectionView.reloadData()
                    return
                }
                self.view.showCentralToast("Success!")
                self.dataModel.passwordVerification = isOn
                let cellModel = self.dataList[2]
                cellModel.isOn = isOn
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                self.view.showCentralToast(errorMessage)
            }
        }
    }
    
    private func configTagIDAutofill(_ isOn: Bool) {
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        Task {[weak self] in
            guard let self = self else { return }
            do {
                let result = try await MKSFBXSInterface.configTagIDAutofillStatus(isOn: isOn)
                MKSwiftHudManager.shared.hide()
                if !result {
                    self.view.showCentralToast("Config failed")
                    self.collectionView.reloadData()
                    return
                }
                view.showCentralToast("Success!")
                self.dataModel.autoFill = isOn
                let cellModel = self.dataList[3]
                cellModel.isOn = isOn
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                self.view.showCentralToast(errorMessage)
            }
        }
    }
    
    private func configResetByButton(_ isOn: Bool) {
        if isOn {
            commandResetByButton(isOn)
            return
        }
        
        let msg = "If Button reset is disabled, you cannot reset the Beacon by button operation."
        let alertView = MKSwiftAlertView()
        
        let confirmAction = MKSwiftAlertViewAction(title: "OK") {[weak self] in
            self?.commandResetByButton(isOn)
        }
        let cancelAction = MKSwiftAlertViewAction(title: "Cancel") {[weak self] in
            self?.collectionView.reloadData()
        }
        alertView.addAction(confirmAction)
        alertView.addAction(cancelAction)
        alertView.showAlert(title: "Warning!",message: msg,notificationName: "mk_bxs_swf_needDismissAlert")
    }
    
    private func commandResetByButton(_ isOn: Bool) {
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        Task {[weak self] in
            guard let self = self else { return }
            do {
                let result = try await MKSFBXSInterface.configResetDeviceByButtonStatus(isOn: isOn)
                MKSwiftHudManager.shared.hide()
                if !result {
                    self.view.showCentralToast("Config failed")
                    self.collectionView.reloadData()
                    return
                }
                view.showCentralToast("Success!")
                self.dataModel.resetByButton = isOn
                let cellModel = self.dataList[4]
                cellModel.isOn = isOn
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                self.view.showCentralToast(errorMessage)
            }
        }
    }
    
    private func configTurnOffByButton(_ isOn: Bool) {
        if isOn {
            commandTurnOffByButton(isOn)
            return
        }
        
        let msg = "If this function is disabled, you cannot power off the Beacon by button."
        let alertView = MKSwiftAlertView()
        
        let confirmAction = MKSwiftAlertViewAction(title: "OK") {[weak self] in
            self?.commandTurnOffByButton(isOn)
        }
        let cancelAction = MKSwiftAlertViewAction(title: "Cancel") {[weak self] in
            self?.collectionView.reloadData()
        }
        alertView.addAction(confirmAction)
        alertView.addAction(cancelAction)
        alertView.showAlert(title: "Warning!",message: msg,notificationName: "mk_bxs_swf_needDismissAlert")
    }
    
    private func commandTurnOffByButton(_ isOn: Bool) {
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        Task {[weak self] in
            guard let self = self else { return }
            do {
                let result = try await MKSFBXSInterface.configHallSensorStatus(isOn: isOn)
                MKSwiftHudManager.shared.hide()
                if !result {
                    self.view.showCentralToast("Config failed")
                    self.collectionView.reloadData()
                    return
                }
                self.view.showCentralToast("Success!")
                self.dataModel.turnOffByButton = isOn
                let cellModel = self.dataList[5]
                cellModel.isOn = isOn
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                self.view.showCentralToast(errorMessage)
            }
        }
    }
    
    private func setupUI() {
        defaultTitle = "Quick switch"
        view.backgroundColor = Color.rgb(242, 242, 242)
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    // MARK: - UI Components
    private lazy var collectionView: UICollectionView = {
        let layout = MKBXQuickSwitchCellLayout()
        layout.sectionInset = UIEdgeInsets(top: 11, left: 11, bottom: 0, right: 11)
        layout.scrollDirection = .vertical
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = Color.rgb(246, 247, 251)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.alwaysBounceVertical = true
        collectionView.register(MKBXQuickSwitchCell.self, forCellWithReuseIdentifier: "MKBXQuickSwitchCellIdenty")
        return collectionView
    }()
}

extension MKSFBXSQuickSwitchController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MKBXQuickSwitchCellIdenty", for: indexPath) as! MKBXQuickSwitchCell
        cell.dataModel = dataList[indexPath.row]
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (UIScreen.main.bounds.width - 3 * 11) / 2
        return CGSize(width: width, height: 85)
    }
}

extension MKSFBXSQuickSwitchController: @preconcurrency MKBXQuickSwitchCellDelegate {
    func mk_swift_bx_quickSwitchStatusChanged(_ isOn: Bool, index: Int) {
        switch index {
        case 0:
            configConnectEnable(isOn)
        case 1:
            configTriggerLEDIndicator(isOn)
        case 2:
            configPasswordVerification(isOn)
        case 3:
            configTagIDAutofill(isOn)
        case 4:
            configResetByButton(isOn)
        case 5:
            configTurnOffByButton(isOn)
        default:
            break
        }
    }
}

