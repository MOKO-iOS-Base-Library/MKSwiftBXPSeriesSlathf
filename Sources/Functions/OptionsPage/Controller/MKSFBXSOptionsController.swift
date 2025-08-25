//
//  MKSFBXSOptionsController.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/19.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

class MKSFBXSOptionsController: MKSwiftBaseViewController {
    
    // MARK: - Properties
    private lazy var dataList: [MKSFBXSOptionsCellModel] = []
    
    // MARK: - Life Cycle
    deinit {
        print("MKSFBXSOptionsController销毁")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        loadSectionDatas()
    }
    
    // MARK: - Private Methods
    
    private func loadSectionDatas() {
        let cellModel1 = MKSFBXSOptionsCellModel()
        cellModel1.msg = "Common Device"
        cellModel1.noteMsg = "(BXP-S series)"
        cellModel1.iconName = "bxs_swf_options_commonDevice"
        dataList.append(cellModel1)
        
        let cellModel2 = MKSFBXSOptionsCellModel()
        cellModel2.msg = "Temperature&Humidity Sensor"
        cellModel2.noteMsg = "(M4 Sensor | M2 Sensor | L01S | L01AS| L02S)"
        cellModel2.iconName = "bxs_swf_options_temperatureHumiditySensor"
        dataList.append(cellModel2)
        
        let cellModel3 = MKSFBXSOptionsCellModel()
        cellModel3.msg = "Temperature Sensor"
        cellModel3.noteMsg = "(M4 Sensor | M2 Sensor | L01S | L01AS | L02S | S05T)"
        cellModel3.iconName = "bxs_swf_options_temperatureSensor"
        dataList.append(cellModel3)
        
        tableView.reloadData()
    }
    
    private func loadSubViews() {
        defaultTitle = "DEVICE TYPE"
        view.backgroundColor = Color.rgb(242, 242, 242)
        
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

extension MKSFBXSOptionsController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = MKSFBXSOptionsCell.initCell(with: tableView)
        cell.dataModel = dataList[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let scanVC = MKSFBXSScanController()
        
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            scanVC.scanType = .common
        case (0, 1):
            scanVC.scanType = .temperatureAndHumidity
        case (0, 2):
            scanVC.scanType = .temperature
        default:
            return
        }
        
        navigationController?.pushViewController(scanVC, animated: true)
    }
}
