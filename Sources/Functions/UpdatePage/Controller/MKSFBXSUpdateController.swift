//
//  MKSFBXSUpdateController.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/25.
//

@preconcurrency import UIKit
import CoreBluetooth
import MKBaseSwiftModule

class MKSFBXSUpdateController: MKSwiftBaseViewController {
    
    private lazy var dataList: [MKSwiftNormalTextCellModel] = []
    private lazy var dfuModule = MKSFBXSDFUModule()
    private var monitorQueue: DispatchQueue?
    private var monitorSource: DispatchSourceFileSystemObject?
    
    deinit {
        print("MKSFBXSUpdateController销毁")
    }
    
    override func viewDidPopFromNavigationStack() {
        DispatchQueue.main.async {[weak self] in
            self?.cancelSource()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Disable swipe back gesture
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        loadFileList()
        startMonitoringDFUFiles()
    }
    
    private func updateComplete() {
        leftButton.isEnabled = true
        MKSwiftHudManager.shared.hide()
        MKSwiftBXPSCentralManager.sharedDealloc()
        NotificationCenter.default.post(name: Notification.Name("mk_bxs_swf_centralDeallocNotification"), object: nil)
        popToViewController(withClassName: "MKSFBXSScanController")
    }
    
    // MARK: - File Monitoring
    
    private func startMonitoringDFUFiles() {
        guard let directoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last else {
            return
        }
        
        let directoryURL = URL(fileURLWithPath: directoryPath)
        let filedes = open(directoryURL.path, O_EVTONLY)
        if filedes < 0 {
            return
        }
        
        monitorQueue = DispatchQueue(label: "ZFileMonitorQueue")
        monitorSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: filedes,
            eventMask: .write,
            queue: monitorQueue
        )
        
        monitorSource?.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                self?.loadFileList()
            }
        }
        
        monitorSource?.setCancelHandler {
            close(filedes)
        }
        
        monitorSource?.resume()
    }
    
    private func currentFileList() -> [String] {
        let fileManager = FileManager.default
        guard let document = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last else {
            return []
        }
        
        do {
            return try fileManager.contentsOfDirectory(atPath: document)
        } catch {
            print("Error reading directory: \(error)")
            return []
        }
    }
    
    private func loadFileList() {
        let list = currentFileList()
        if !list.isEmpty {
            dataList.removeAll()
            for item in list {
                let model = MKSwiftNormalTextCellModel()
                model.leftMsg = item
                dataList.append(model)
            }
            tableView.reloadData()
        }
    }
    
    private func cancelSource() {
        monitorSource?.cancel()
    }
    
    private func loadSubViews() {
        defaultTitle = "OTA"
        rightButton.isHidden = true
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    private lazy var tableView: MKSwiftBaseTableView = {
        let tableView = MKSwiftBaseTableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
}

extension MKSFBXSUpdateController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cellModel = dataList[indexPath.row]
        return cellModel.cellHeightWithContentWidth(Screen.width)
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
        
        let firmwareModel = dataList[indexPath.row]
        if firmwareModel.leftMsg.count == 0 {
            view.showCentralToast("Firmware cannot be empty!")
            return
        }
        
        NotificationCenter.default.post(name: Notification.Name("mk_bxs_swf_startDfuProcessNotification"), object: nil)
        
        guard let document = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last else {
            return
        }
        
        let filePath = document + "/" + firmwareModel.leftMsg
        leftButton.isEnabled = false
        
        MKSwiftHudManager.shared.showHUD(with: "Waiting...", in: view, isPenetration: false)
        
        Task {[weak self] in
            guard let self = self else { return }
            do {
                try await self.dfuModule.update(withFileUrl: filePath)
                MKSwiftHudManager.shared.showHUD(with: "Update firmware successfully!", in: self.view, isPenetration: false)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                    self?.updateComplete()
                }
            } catch {
                MKSwiftHudManager.shared.hide()
                let errorMessage = error.localizedDescription
                self.view.showCentralToast(errorMessage)
            }
        }
    }
}
