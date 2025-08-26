//
//  MKSFBXSScanController.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/6/30.
//

import UIKit
import CoreBluetooth
import SnapKit

import MKBaseSwiftModule
import MKSwiftBeaconXCustomUI
import MKSwiftBleModule

public enum BXSScanType: Int {
    case common
    case temperatureAndHumidity
    case temperature
}

public class MKSFBXSScanController: MKSwiftBaseViewController {
    // MARK: - Properties
    
    var scanType: BXSScanType = .common
    
    private let localPasswordKey = "mk_bxs_swf_passwordKey"
    private let offsetX: CGFloat = 15.0
    private let searchButtonHeight: CGFloat = 40.0
    private let headerViewHeight: CGFloat = 90.0
    private let refreshInterval: TimeInterval = 0.5
    
    private var dataList: [ MKSFBXSScanInfoCellModel] = []
    private var asciiText: String = ""
    private var isNeedRefresh = false
    private var scanTimer: DispatchSourceTimer?
    private var observerRef: CFRunLoopObserver?
    
    private lazy var buttonModel:  MKSwiftBXScanSearchButtonModel = {
        let model =  MKSwiftBXScanSearchButtonModel()
        model.placeholder = "Edit Filter"
        model.minSearchRssi = -100
        model.searchRssi = -100
        return model
    }()
    
    // MARK: - Life Cycle
    
    deinit {
        print("MKSFBXSScanController deinit")
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if !(navigationController?.viewControllers.contains(self) ?? false) {
            NotificationCenter.default.removeObserver(self)
            
            DispatchQueue.main.async {[weak self] in
                MKSwiftBXPSCentralManager.shared.stopScan()
                MKSwiftBXPSCentralManager.removeFromCentralList()
                self?.removeObserverRef()
            }
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startRefresh()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dfuUpdateComplete),
            name: NSNotification.Name("mk_bxs_swf_centralDeallocNotification"),
            object: nil
        )
    }
    
    //MARK: - Super Methods
    @objc public override func rightButtonMethod() {
        let vc = MKSFBXSAboutController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Actions
    
    @objc private func refreshButtonPressed() {
        let centralManager = MKSwiftBleBaseCentralManager.shared.centralManager
        
        switch centralManager.state {
        case .unauthorized:
            showAuthorizationAlert()
            return
        case .poweredOff:
            showBLEDisable()
            return
        default:
            break
        }
        
        refreshButton.isSelected = !refreshButton.isSelected
        refreshIcon.layer.removeAnimation(forKey: "mk_refreshAnimationKey")
        
        if !refreshButton.isSelected {
             MKSwiftBXPSCentralManager.shared.stopScan()
            return
        }
        
        dataList.removeAll()
        tableView.reloadData()
        
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi * 2)
        rotation.duration = 2
        rotation.isCumulative = true
        rotation.repeatCount = Float.infinity
        refreshIcon.layer.add(rotation, forKey: "mk_refreshAnimationKey")
        
         MKSwiftBXPSCentralManager.shared.startScan()
    }
    
    @objc private func startScanDevice() {
        refreshButton.isSelected = false
        refreshButtonPressed()
    }
    
    @objc private func dfuUpdateComplete() {
        mk_bxs_swf_needResetScanDelegate(true)
    }
    
    // MARK: - Private Methods
    
    private func runloopObserver() {
        var timeInterval = Date().timeIntervalSince1970
        
        observerRef = CFRunLoopObserverCreateWithHandler(
            kCFAllocatorDefault,
            CFRunLoopActivity.allActivities.rawValue,
            true,
            0
        ) { [weak self] (observer, activity) in
            guard let self = self else { return }
            
            if activity == .beforeWaiting {
                let currentInterval = Date().timeIntervalSince1970
                if currentInterval - timeInterval < self.refreshInterval {
                    return
                }
                timeInterval = currentInterval
                
                if self.isNeedRefresh {
                    self.tableView.reloadData()
                    self.defaultTitle = "DEVICE(\(self.dataList.count))"
                    self.isNeedRefresh = false
                }
            }
        }
        
        if let observer = observerRef {
            CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, .commonModes)
        }
    }
    
    private func startRefresh() {
        searchButton.dataModel = buttonModel
        runloopObserver()
        MKSwiftBXPSCentralManager.shared.delegate = self
        let firstInstall = UserDefaults.standard.object(forKey: "mk_bxs_swf_firstInstall") as? NSNumber
        let afterTime: TimeInterval = firstInstall != nil ? 0.5 : 3.5
        
        if firstInstall == nil {
            UserDefaults.standard.set(false, forKey: "mk_bxs_swf_firstInstall")
        }
        
        Task { [weak self] in
            let nanoseconds = UInt64(afterTime * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            await MainActor.run {
                self?.refreshButtonPressed()
            }
        }
    }
    
    private func showAuthorizationAlert() {
        let message = "This function requires Bluetooth authorization, please enable MK Tag permission in Settings-Privacy-Bluetooth."
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showBLEDisable() {
        let message = "The current system of bluetooth is not available!"
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Data Processing
    
    private func updateData(with beacon: MKSFBXSBaseBeacon) {
        if beacon.frameType == .unknown {
            return
        }
        
        if Valid.isStringValid(buttonModel.searchMac) || Valid.isStringValid(buttonModel.searchName) {
            //如果打开了过滤，先看是否需要过滤设备名字
            //如果是设备信息帧,判断名字是否符合要求
            if beacon.rssi.intValue >= buttonModel.searchRssi {
                filterBeacon(with: beacon)
            }
            return
        }
        if buttonModel.searchRssi > buttonModel.minSearchRssi {
            //开启rssi过滤
            if beacon.rssi.intValue >= buttonModel.searchRssi {
                process(beacon: beacon)
            }
            return
        }
        process(beacon: beacon)
    }
    
    private func filterBeacon(with beacon: MKSFBXSBaseBeacon) {
        if beacon.frameType == .sensorInfo {
            //如果是设备信息帧
            guard let tempBeacon = beacon as? MKSFBXSSensorInfoBeacon else { return }
            
            let deviceNameContains = tempBeacon.deviceName?.uppercased().contains(buttonModel.searchName!.uppercased()) ?? false
            let tagIDContains = tempBeacon.tagID.uppercased().contains(buttonModel.searchMac!.uppercased())
            
            if deviceNameContains || tagIDContains {
                process(beacon: beacon)
            }
            return
        }
        //如果不是设备信息帧，则判断对应的有没有设备信息帧在当前数据源，如果没有直接舍弃，如果存在，则加入
        guard let identy = beacon.peripheral?.identifier.uuidString else { return }
        if let existingModel = dataList.first(where: { $0.identifier == identy }) {
            MKSFBXSScanPageAdopter.updateInfoCellModel(existingModel, beaconData: beacon)
            needRefreshList()
        }
    }
    
    private func process(beacon: MKSFBXSBaseBeacon) {
        //查看数据源中是否已经存在相关设备
        guard let identy = beacon.peripheral?.identifier.uuidString else { return }
        
        if let existingModel = dataList.first(where: { $0.identifier == identy }) {
            //如果是已经存在了，如果是设备信息帧和TLM帧，直接替换，如果是URL、iBeacon、UID中的一种，则判断数据内容是否和已经存在的信息一致，如果一致，不处理，如果不一致，则直接加入到MKSFBXSScanBeaconModel的dataArray里面去
            MKSFBXSScanPageAdopter.updateInfoCellModel(existingModel, beaconData: beacon)
            needRefreshList()
            return
        }
        
        //不存在，则加入到dataList里面去
        let deviceModel = MKSFBXSScanPageAdopter.parseBaseBeaconToInfoModel(beacon)
        dataList.append(deviceModel)
        needRefreshList()
    }
    
    private func needRefreshList() {
        //标记需要刷新
        isNeedRefresh = true
        //唤醒runloop
        CFRunLoopWakeUp(CFRunLoopGetMain())
    }
    
    // MARK: - Connection Methods
    
    private func connectPeripheral(_ peripheral: CBPeripheral) async {
        refreshIcon.layer.removeAnimation(forKey: "mk_refreshAnimationKey")
        MKSwiftBXPSCentralManager.shared.stopScan()
        scanTimer?.cancel()
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        
        do {
            let result = try await MKSwiftBXPSCentralManager.shared.readNeedPassword(with: peripheral)
            MKSwiftHudManager.shared.hide()
            if result == "00" {
                await startConnectPeripheral(peripheral, needPassword: false)
            }else {
                connectDeviceWithPassword(peripheral)
            }
        } catch {
            let errorMessage = error.localizedDescription
            MKSwiftHudManager.shared.hide()
            view.showCentralToast(errorMessage)
            self.connectFailed()
        }
    }
    
    private func connectDeviceWithPassword(_ peripheral: CBPeripheral) {
        let localPassword = UserDefaults.standard.string(forKey: localPasswordKey) ?? ""
        asciiText = localPassword
        
        let cancelAction = MKSwiftAlertViewAction(title: "Cancel") {
            self.refreshButton.isSelected = false
            self.refreshButtonPressed()
        }
        
        let confirmAction = MKSwiftAlertViewAction(title: "OK") {
            Task { [weak self] in
                guard let self = self else { return }
                await self.startConnectPeripheral(peripheral, needPassword: true)
            }
        }
        
        let textField = MKSwiftAlertViewTextField(textValue: localPassword,placeholder: "No more than 16 characters.",maxLength: 16) { text in
            self.asciiText = text
        }
        
        let alert = MKSwiftAlertView()
        alert.addAction(cancelAction)
        alert.addAction(confirmAction)
        alert.addTextField(textField)
        alert.showAlert(title: "Enter password",
                        message: "Please enter connection password.",
                        notificationName: "mk_bxb_needDismissAlert")
    }
    
    private func startConnectPeripheral(_ peripheral: CBPeripheral, needPassword: Bool) async {
        // 使用 weak self 避免潜在的循环引用
        await withCheckedContinuation { continuation in
            Task { @MainActor [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                do {
                    // 显示加载
                    MKSwiftHudManager.shared.showHUD(with: "Connecting...", in: self.view, isPenetration: false)
                    // 连接设备
                    try await MKSFBXSConnectManager.shared.connectDevice(
                        peripheral,
                        password: needPassword ? self.asciiText : nil
                    )
                    // 保存密码
                    if needPassword && !self.asciiText.isEmpty {
                        UserDefaults.standard.set(self.asciiText, forKey: self.localPasswordKey)
                    }
                    // 成功处理
                    MKSwiftHudManager.shared.hide()
                    self.pushTabBarPage()
                } catch {
                    // 错误处理
                    MKSwiftHudManager.shared.hide()
                    let errorMessage = error.localizedDescription
                    self.view.showCentralToast(errorMessage)
                    self.connectFailed()
                }
                
                continuation.resume()
            }
        }
    }
    
    @objc private func pushTabBarPage() {
        let vc = MKSFBXSTabBarController()
        vc.modalPresentationStyle = .fullScreen
        vc.pageDelegate = self
        
        // 创建自定义的 push 动画
        let transition = CATransition()
        transition.duration = 0.1
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        transition.type = .push
        transition.subtype = .fromRight
        
        // 添加动画到窗口的layer
        if let window = UIApplication.shared.windows.first {
            window.layer.add(transition, forKey: kCATransition)
        }
        
        present(vc, animated: false)
    }
    
    private func connectFailed() {
        refreshButton.isSelected = false
        refreshButtonPressed()
    }
    
    private func removeObserverRef() {
        if let observer = observerRef {
            CFRunLoopRemoveObserver(CFRunLoopGetCurrent(), observer, .commonModes)
        }
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = Color.rgb(237, 243, 250)
        
        rightButton.setImage(moduleIcon(name: "bxs_swf_scanRightAboutIcon", in: .module), for: .normal)
        
        defaultTitle = "DEVICE(0)"
        
        let topView = UIView()
        topView.backgroundColor = Color.rgb(237, 243, 250)
        view.addSubview(topView)
        
        topView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.height.equalTo(searchButtonHeight + 30)
        }
        
        refreshButton.addSubview(refreshIcon)
        topView.addSubview(refreshButton)
        
        refreshIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(22)
        }
        
        refreshButton.snp.makeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(40)
            make.top.equalTo(15)
            make.height.equalTo(40)
        }
        
        topView.addSubview(searchButton)
        searchButton.snp.makeConstraints { make in
            make.left.equalTo(15)
            make.right.equalTo(refreshButton.snp.left).offset(-10)
            make.top.equalTo(15)
            make.height.equalTo(searchButtonHeight)
        }
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.top.equalTo(topView.snp.bottom)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-5)
        }
    }
    
    // MARK: - UI Components
    
    private lazy var tableView: MKSwiftBaseTableView = {
        let tableView = MKSwiftBaseTableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    private lazy var refreshIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = moduleIcon(name: "bxs_swf_scan_refreshIcon", in: .module)
        return imageView
    }()
    
    private lazy var searchButton:  MKSwiftBXScanSearchButton = {
        let button =  MKSwiftBXScanSearchButton()
        button.delegate = self
        return button
    }()
    
    private lazy var refreshButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(refreshButtonPressed), for: .touchUpInside)
        return button
    }()
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension MKSFBXSScanController: UITableViewDataSource, UITableViewDelegate {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return dataList.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataList[section].advertiseList.count + 1
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            //第一个row固定为设备信息帧
            let cell = MKSFBXSScanDeviceInfoCell.initCell(with: tableView)
            cell.dataModel = dataList[indexPath.section]
            cell.delegate = self
            return cell
        }
        
        let model = dataList[indexPath.section]
        return MKSFBXSScanPageAdopter.loadCell(with: tableView, dataModel: model.advertiseList[indexPath.row - 1])
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return headerViewHeight
        }
        
        let model = dataList[indexPath.section]
        return MKSFBXSScanPageAdopter.loadCellHeight(with: model.advertiseList[indexPath.row - 1])
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0 : 5
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section != 0 else { return nil }
        
        let headerView = MKSwiftTableSectionLineHeader.dequeueHeader(with: tableView)
        
        let sectionData = MKSwiftTableSectionLineHeaderModel()
        sectionData.contentColor = Color.rgb(237, 243, 250)
        headerView.headerModel = sectionData
        return headerView
    }
}

// MARK: -  MKSFBXSCentralManagerScanDelegate

extension MKSFBXSScanController:  @preconcurrency MKSFBXSCentralManagerScanDelegate {
    //MARK: - MKSFBXSCentralManagerScanDelegate
    
    public func mk_bxs_swf_receiveBeacon(_ beaconList: [MKSFBXSBaseBeacon]) {
        switch scanType {
        case .common:
            beaconList.forEach { updateData(with: $0) }
        case .temperatureAndHumidity:
            beaconList.forEach {
                if let tempBeacon = $0 as? MKSFBXSSensorInfoBeacon, tempBeacon.tempSensor, tempBeacon.humiditySensor {
                    updateData(with: $0)
                } else if $0 is MKSFBXSOTABeacon {
                    updateData(with: $0)
                }
            }
        case .temperature:
            beaconList.forEach {
                if let tempBeacon = $0 as? MKSFBXSSensorInfoBeacon, tempBeacon.tempSensor, !tempBeacon.humiditySensor {
                    updateData(with: $0)
                } else if $0 is MKSFBXSOTABeacon {
                    updateData(with: $0)
                }
            }
        }
    }
    
    public func mk_bxs_swf_startScan() {
        
    }
    
    public func mk_bxs_swf_stopScan() {
        //如果是左上角在动画，则停止动画
        if refreshButton.isSelected {
            refreshIcon.layer.removeAnimation(forKey: "mk_refreshAnimationKey")
            refreshButton.isSelected = false
        }
    }
}

// MARK: -  MKSwiftBXScanSearchButtonDelegate

extension MKSFBXSScanController:  @preconcurrency MKSwiftBXScanSearchButtonDelegate {
    public func mk_bx_scanSearchButtonMethod() {
        MKSFBXSScanFilterView.showSearchName(buttonModel.searchName ?? "", tagID: buttonModel.searchMac ?? "", rssi: buttonModel.searchRssi) { [weak self] name, tagID, rssi in
            self?.buttonModel.searchRssi = rssi
            self?.buttonModel.searchName = name
            self?.buttonModel.searchMac = tagID
            self?.searchButton.dataModel = self?.buttonModel
            
            self?.refreshButton.isSelected = false
            self?.refreshButtonPressed()
        }
    }
    
    public func mk_bx_scanSearchButtonClearMethod() {
        buttonModel.searchRssi = -100
        buttonModel.searchMac = ""
        buttonModel.searchName = ""
        refreshButton.isSelected = false
        refreshButtonPressed()
    }
}

//MARK: - MKSFBXSTabBarControllerDelegate
extension MKSFBXSScanController: @preconcurrency MKSFBXSTabBarControllerDelegate {
    func mk_bxs_swf_needResetScanDelegate(_ need: Bool) {
        if need {
             MKSwiftBXPSCentralManager.shared.delegate = self
        }
        perform(
            #selector(startScanDevice),
            with: nil,
            afterDelay: need ? 1.0 : 0.1
        )
    }
}

// MARK: - MKSFBXSScanDeviceInfoCellDelegate

extension MKSFBXSScanController: @preconcurrency MKSFBXSScanDeviceInfoCellDelegate {
    func mk_bxs_swf_connectPeripheral(_ dataModel: MKSFBXSScanInfoCellModel) {
        MKSwiftHudManager.shared.showHUD(with: "Connecting...", in: view, isPenetration: false)
        Task {[weak self] in
            guard let self = self else { return }
            do {
                if (dataModel.otaMode) {
                    //当前设备处于OTA模式
                    _ = try await MKSwiftBXPSCentralManager.shared.connectPeripheral(dataModel.peripheral!,dfu: true)
                    MKSwiftHudManager.shared.hide()
                    let vc = MKSFBXSUpdateController()
                    self.navigationController?.pushViewController(vc, animated: true)
                    return
                }
                await self.connectPeripheral(dataModel.peripheral!)
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                self.view.showCentralToast(errorMessage)
                self.connectFailed()
            }
        }
    }
}
