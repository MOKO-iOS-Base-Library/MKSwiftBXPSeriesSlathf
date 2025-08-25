//
//  MKBXPSDeviceTypeController.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/6/17.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

class MKBXPSDeviceTypeController: MKSwiftBaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
    }
    
    //Private method
    
    //MARK: - UI
    private func loadSubViews() {
        defaultTitle = "DEVICE TYPE"
        leftButton.isHidden = true
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    //MARK: - Lazy
    private lazy var tableView: MKSwiftBaseTableView = {
        let tableView = MKSwiftBaseTableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    private lazy var dataList: [MKBXPSDeviceTypeCellModel] = {
        let model1 = MKBXPSDeviceTypeCellModel()
        model1.msg = "Common Device"
        model1.contentMsg = "(BXP-S series)"
        model1.iconName = "bxs_swf_options_commonDevice"
        
        let model2 = MKBXPSDeviceTypeCellModel()
        model2.msg = "Temperature&Humidity Sensor"
        model2.contentMsg = "(M4 Sensor | M2 Sensor | L01S | L01AS| L02S)"
        model2.iconName = "bxs_swf_options_temperatureHumiditySensor"
        
        let model3 = MKBXPSDeviceTypeCellModel()
        model3.msg = "Temperature Sensor"
        model3.contentMsg = "(M4 Sensor | M2 Sensor | L01S | L01AS | L02S | S05T)"
        model3.iconName = "bxs_swf_options_temperatureSensor"
        
        return [model1,model2,model3]
    }()
}

extension MKBXPSDeviceTypeController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = MKSFBXSScanController()
        vc.scanType = BXSScanType(rawValue: indexPath.row) ?? .common
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = MKBXPSDeviceTypeCell.initCellWithTableView(tableView)
        cell.dataModel = dataList[indexPath.row]
        return cell
    }
    
    
}
