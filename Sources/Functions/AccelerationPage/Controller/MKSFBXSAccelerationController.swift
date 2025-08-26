//
//  MKSFBXSAccelerationController.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/5.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

class MKSFBXSAccelerationController: MKSwiftBaseViewController {
    
    deinit {
        print("MKSFBXSAccelerationController deinit")
    }
    
    override func viewDidPopFromNavigationStack() {
        NotificationCenter.default.removeObserver(self)
        DispatchQueue.main.async {
            _ = MKSwiftBXPSCentralManager.shared.notifyThreeAxisData(false)
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        readDataFromDevice()
        setupNotifications()
    }
    
    //MARK: - Super method
    override func rightButtonMethod() {
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
    
    //MARK: - Notes
    @objc private func receiveAxisDatas(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: String] else { return }
        headerView.updateDataWith(
            xData: userInfo["xData"] ?? "",
            yData: userInfo["yData"] ?? "",
            zData: userInfo["zData"] ?? ""
        )
    }
    
    private func loadSubViews() {
        defaultTitle = "3-axis accelerometer"
        view.backgroundColor = Color.rgb(242, 242, 242)
        rightButton.setImage(moduleIcon(name: "bxs_swf_slotSaveIcon", in: .module), for: .normal)
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(5)
            make.right.equalToSuperview().offset(-5)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    private func readDataFromDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        Task {[weak self] in
            guard let self = self else { return }
            do {
                try await self.dataModel.read()
                MKSwiftHudManager.shared.hide()
                self.loadSectionDatas()
                self.headerView.updateTriggerCount(self.dataModel.triggerCount)
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                self.view.showCentralToast(errorMessage)
            }
        }
    }
    
    private func loadSectionDatas() {
        let model = MKSFBXSAccelerationParamsCellModel()
        model.scale = dataModel.scale
        model.samplingRate = dataModel.samplingRate
        model.threshold = dataModel.threshold
        dataList.append(model)
        
        tableView.reloadData()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(receiveAxisDatas(_:)),
            name: NSNotification.Name("mk_bxs_swf_receiveThreeAxisDataNotification"),
            object: nil
        )
    }
    
    //MARK: - Lazy
    private lazy var tableView: MKSwiftBaseTableView = {
        let tableView = MKSwiftBaseTableView.init(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = headerView
        return tableView
    }()
    
    private lazy var headerView: MKSFBXSAccelerationHeaderView = {
        let view = MKSFBXSAccelerationHeaderView.init(frame: CGRect(x: 0, y: 0, width: Screen.width, height: 165.0))
        view.delegate = self
        return view
    }()
    
    private lazy var dataList: [MKSFBXSAccelerationParamsCellModel] = {
        let list: [MKSFBXSAccelerationParamsCellModel] = []
        return list
    }()
    
    private lazy var dataModel: MKSFBXSAccelerationModel = {
        let model = MKSFBXSAccelerationModel()
        return model
    }()
}

extension MKSFBXSAccelerationController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        160
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = MKSFBXSAccelerationParamsCell.initCell(with: tableView)
        cell.dataModel = dataList[indexPath.row]
        cell.delegate = self
        return cell
    }
}

extension MKSFBXSAccelerationController: @preconcurrency MKSFBXSAccelerationHeaderViewDelegate {
    func updateThreeAxisNotifyStatus(_ notify: Bool) {
        _ = MKSwiftBXPSCentralManager.shared.notifyThreeAxisData(notify)
    }
    
    func clearMotionTriggerCountButtonPressed() {
        MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)
        Task {[weak self] in
            guard let self = self else { return }
            do {
                _ = try await MKSFBXSInterface.clearMotionTriggerCount()
                MKSwiftHudManager.shared.hide()
                self.dataModel.triggerCount = "0"
                self.headerView.updateTriggerCount("0")
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                self.view.showCentralToast(errorMessage)
            }
        }
    }
}

extension MKSFBXSAccelerationController: @preconcurrency MKSFBXSAccelerationParamsCellDelegate {
    func accelerationParamsScaleChanged(_ scale: Int) {
        dataModel.scale = scale
        dataList[0].scale = scale
    }
    
    func accelerationParamsSamplingRateChanged(_ samplingRate: Int) {
        dataModel.samplingRate = samplingRate
        dataList[0].samplingRate = samplingRate
    }
    
    func accelerationMotionThresholdChanged(_ threshold: String) {
        dataModel.threshold = threshold
        dataList[0].threshold = threshold
    }
}
