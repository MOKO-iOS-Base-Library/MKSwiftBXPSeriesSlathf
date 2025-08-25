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
        Task {[weak self] in
            guard let self = self else { return }
            do {
                _ = try await MKSFBXSInterface.clearHallTriggerCount()
                MKSwiftHudManager.shared.hide()
                self.readDataFromDevice()
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                self.view.showCentralToast(errorMessage)
            }
        }
    }
    
    private func readDataFromDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        Task {[weak self] in
            guard let self = self else { return }
            do {
                try await self.dataModel.read()
                MKSwiftHudManager.shared.hide()
                self.headerViewModel.count = self.dataModel.count
                self.headerView.dataModel = self.headerViewModel
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                self.view.showCentralToast(errorMessage)
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
