//
//  MKSFBXSDeviceInfoController.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/5.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

class MKSFBXSDeviceInfoController: MKSwiftBaseViewController {
    
    // MARK: - Life Cycle
    
    deinit {
        print("MKSFBXSDeviceInfoController deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        readDatasFromDevice()
    }
    
    //MARK: - Interface
    private func readDatasFromDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)
        let dataModel = self.dataModel
        Task {
            do {
                try await dataModel.read()
                MKSwiftHudManager.shared.hide()
                loadSectionDatas()
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                view.showCentralToast(errorMessage)
            }
        }
    }
    
    // MARK: - Data Handling
    
    private func loadSectionDatas() {
        let items = [
            ("Battery voltage", dataModel.voltage + "mV"),
            ("Battery Percentage", dataModel.batteryPercent + "%"),
            ("MAC address", dataModel.macAddress),
            ("Product model", dataModel.productMode),
            ("Software version", dataModel.software),
            ("Firmware version", dataModel.firmware),
            ("Hardware version", dataModel.hardware),
            ("Manufacture date", dataModel.manuDate),
            ("Manufacturer", dataModel.manu)
        ]
        
        dataList = items.map { item in
            let model = MKSwiftNormalTextCellModel()
            model.leftMsg = item.0
            model.rightMsg = item.1
            return model
        }
        
        tableView.reloadData()
    }
    
    // MARK: - UI Setup
    
    private func loadSubViews() {
        defaultTitle = "DEVICE"
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    //MARK: - Lazy
    private lazy var tableView: MKSwiftBaseTableView = {
        let tableView = MKSwiftBaseTableView.init(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    private lazy var dataList: [MKSwiftNormalTextCellModel] = {
        let list: [MKSwiftNormalTextCellModel] = []
        return list
    }()
    
    private lazy var dataModel: MKSFBXSDeviceInfoModel = {
        let model = MKSFBXSDeviceInfoModel()
        return model
    }()
}

// MARK: - UITableView Delegate & DataSource

extension MKSFBXSDeviceInfoController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = MKSwiftNormalTextCell.initCellWithTableView(tableView)
        cell.dataModel = dataList[indexPath.row]
        return cell
    }
}
