//
//  MKSFBXSSensorConfigController.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/21.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

class MKSFBXSSensorConfigController: MKSwiftBaseViewController {
    
    // MARK: - Data
    private lazy var dataList: [MKSwiftNormalTextCellModel] = []
    
    // MARK: - Life Cycle
    deinit {
        print("MKSFBXSSensorConfigController销毁")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSectionDatas()
//        readDatasFromDevice()
    }
    
    // MARK: - Data Loading
    private func loadSectionDatas() {
        Task {
            do {
                let manager = MKSFBXSConnectManager.shared
                
                let thStatus = await manager.getThStatus()
                let accStatus = await manager.getAccStatus()
                let hallStatus = await manager.getHallStatus()
                let resetByButton = await manager.getResetByButton()
                
                if accStatus > 0 {
                    let cellModel1 = MKSwiftNormalTextCellModel()
                    cellModel1.leftMsg = "3-axis accelerometer"
                    cellModel1.showRightIcon = true
                    cellModel1.methodName = "pushAxisSensor"
                    dataList.append(cellModel1)
                }
                
                if !hallStatus && !resetByButton {
                    let cellModel2 = MKSwiftNormalTextCellModel()
                    cellModel2.leftMsg = "Hall sensor"
                    cellModel2.showRightIcon = true
                    cellModel2.methodName = "pushHallSensor"
                    dataList.append(cellModel2)
                }
                
                if thStatus == 1 || thStatus == 2 || thStatus == 4 {
                    let cellModel3 = MKSwiftNormalTextCellModel()
                    cellModel3.leftMsg = "Temperature & Humidity"
                    cellModel3.showRightIcon = true
                    cellModel3.methodName = "pushTHSensor"
                    dataList.append(cellModel3)
                }
                
                if thStatus == 3 {
                    let cellModel4 = MKSwiftNormalTextCellModel()
                    cellModel4.leftMsg = "Temperature"
                    cellModel4.showRightIcon = true
                    cellModel4.methodName = "pushTemperatureSensor"
                    dataList.append(cellModel4)
                }
                
                tableView.reloadData()
            }
        }
    }
    
//    private func readDatasFromDevice() {
//        MKHudManager.shared.showHUD(title: "Reading...", inView: view, isPenetration: false)
//
//        dataModel.readData {
//            MKHudManager.shared.hide()
//            self.loadSectionDatas()
//        } failedBlock: { error in
//            MKHudManager.shared.hide()
//            self.view.showCentralToast(error.userInfo["errorInfo"] as? String ?? "")
//        }
//    }
    
    // MARK: - Navigation Methods
    @objc private func pushHallSensor() {
        let vc = MKSFBXSHallSensorConfigController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func pushAxisSensor() {
        let vc = MKSFBXSAccelerationController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func pushTHSensor() {
        let vc = MKSFBXSTHSensorController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func pushTemperatureSensor() {
        let vc = MKSFBXSTempSensorController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        defaultTitle = "Sensor configurations"
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
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension MKSFBXSSensorConfigController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = MKSwiftNormalTextCell.initCellWithTableView(tableView)
        cell.dataModel = dataList[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cellModel = dataList[indexPath.row]
        if cellModel.methodName.count > 0 && responds(to: Selector(cellModel.methodName)) {
            perform(Selector(cellModel.methodName))
        }
    }
}
