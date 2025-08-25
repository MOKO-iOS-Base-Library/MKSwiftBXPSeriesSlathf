//
//  MKSFBXSSlotController.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/25.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

class MKSFBXSSlotController: MKSwiftBaseViewController {
    
    // MARK: - Data Properties
    private lazy var dataList = [MKSwiftNormalTextCellModel]()
    private lazy var dataModel = MKSFBXSSlotModel()
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        loadSectionDatas()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        readDatasFromDevice()
    }
    
    // MARK: - Super Method
    override func leftButtonMethod() {
        NotificationCenter.default.post(name: NSNotification.Name("mk_bxs_swf_popToRootViewControllerNotification"),
                                      object: nil)
    }
        
    // MARK: - Interface
    private func readDatasFromDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        let dataModel = self.dataModel
        Task {
            do {
                try await dataModel.read()
                MKSwiftHudManager.shared.hide()
                updateCellModels()
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                view.showCentralToast(errorMessage)
            }
        }
    }
    
    private func updateCellModels() {
        guard dataList.count >= 3 else { return }
        
        dataList[0].rightMsg = dataModel.slot1
        dataList[1].rightMsg = dataModel.slot2
        dataList[2].rightMsg = dataModel.slot3
        
        tableView.reloadData()
    }
    
    // MARK: - Section Data Loading
    private func loadSectionDatas() {
        let cellModel1 = MKSwiftNormalTextCellModel()
        cellModel1.leftMsg = "SLOT1"
        cellModel1.showRightIcon = true
        dataList.append(cellModel1)
        
        let cellModel2 = MKSwiftNormalTextCellModel()
        cellModel2.leftMsg = "SLOT2"
        cellModel2.showRightIcon = true
        dataList.append(cellModel2)
        
        let cellModel3 = MKSwiftNormalTextCellModel()
        cellModel3.leftMsg = "SLOT3"
        cellModel3.showRightIcon = true
        dataList.append(cellModel3)
        
        tableView.reloadData()
    }
    
    // MARK: - UI Setup
    private func loadSubViews() {
        defaultTitle = "SLOT"
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
extension MKSFBXSSlotController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataList.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = MKSwiftNormalTextCell.initCellWithTableView(tableView)
        cell.dataModel = dataList[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        Task {
            do {
                let result = try await MKSFBXSInterface.readSlotTriggerData(index: indexPath.row)
                MKSwiftHudManager.shared.hide()
                
                guard let triggerType = result.value["triggerType"] as? String else {
                    return
                }
                
                let connectManager = MKSFBXSConnectManager.shared
                let accStatus = await connectManager.getAccStatus()
                let thStatus = await connectManager.getThStatus()
                let resetByButton = await connectManager.getResetByButton()
                let hallStatus = await connectManager.getHallStatus()
                let trigger = (triggerType != "00")
                if trigger {
                    // Trigger enabled
                    
                    if accStatus == 0 &&
                       thStatus == 0 &&
                       (resetByButton || hallStatus) {
                        view.showCentralToast("Current device doesn't has sensor!")
                        return
                    }
                    
                    let vc = MKSFBXSTriggerStepOneController()
                    vc.slotIndex = indexPath.row
                    navigationController?.pushViewController(vc, animated: true)
                } else {
                    let vc = MKSFBXSSlotConfigController()
                    vc.slotIndex = indexPath.row
                    navigationController?.pushViewController(vc, animated: true)
                }
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                view.showCentralToast(errorMessage)
            }
        }
    }
}
