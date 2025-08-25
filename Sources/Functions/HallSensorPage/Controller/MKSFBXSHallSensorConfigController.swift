//
//  MKSFBXSHallSensorConfigController.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/19.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

class MKSFBXSHallSensorConfigController: MKSwiftBaseViewController {
    
    // MARK: - Life Cycle
    deinit {
        print("MKSFBXSHallSensorConfigController销毁")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        readDataFromDevice()
    }
    
    //MARK: - Private Method
    private func clearTriggerCount() {
        MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)
        Task {
            do {
                _ = try await MKSFBXSInterface.clearHallTriggerCount()
                MKSwiftHudManager.shared.hide()
                readDataFromDevice()
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                view.showCentralToast(errorMessage)
            }
        }
    }
    
    private func readDataFromDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        Task {
            do {
                try await dataModel.read()
                MKSwiftHudManager.shared.hide()
                headerViewModel.count = dataModel.count
                headerView.dataModel = headerViewModel
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                view.showCentralToast(errorMessage)
            }
        }
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        defaultTitle = "Hall sensor"
        view.backgroundColor = Color.rgb(242, 242, 242)
        
        view.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.height.equalTo(60)
        }
    }
    
    // MARK: - Properties
    private lazy var headerViewModel = MKSFBXSHallSensorHeaderViewModel()
    private lazy var headerView:MKSFBXSHallSensorHeaderView = {
        let view = MKSFBXSHallSensorHeaderView()
        view.delegate = self
        return view
    }()
    private lazy var dataModel = MKSFBXSHallSensorConfigModel()
}

extension MKSFBXSHallSensorConfigController: @preconcurrency MKSFBXSHallSensorHeaderViewDelegate {
    func bxs_swf_hallSensorHeaderView_clearPressed() {
        clearTriggerCount()
    }
}
