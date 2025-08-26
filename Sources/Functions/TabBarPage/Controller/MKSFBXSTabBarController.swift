//
//  MKSFBXSTabBarController.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/25.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

protocol MKSFBXSTabBarControllerDelegate: AnyObject {
    /// Return to scan page, definitely need to start scanning
    /// - Parameter need: YES: Return after DFU update, need to set scan delegate. NO: No need to reset delegate
    func mk_bxs_swf_needResetScanDelegate(_ need: Bool)
}

class MKSFBXSTabBarController: UITabBarController {
    
    // MARK: - Properties
    weak var pageDelegate: MKSFBXSTabBarControllerDelegate?
    
    /// Disconnect types:
    /// 01: Connection timeout (no password verification within 1 minute after successful connection)
    /// 02: After successful password change, disconnect
    /// 03: Factory reset
    /// 04: Power off
    private var disconnectType = false
    
    /// Device is in DFU process, will disconnect to enter upgrade mode
    private var dfu = false
    
    // MARK: - Life Cycle
    deinit {
        print("MKSFBXSTabBarController销毁")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if !(navigationController?.viewControllers.contains(self) ?? false) {
            MKSwiftBXPSCentralManager.shared.disconnect()
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSubPages()
        addNotifications()
    }
    
    // MARK: - Notification Setup
    private func addNotifications() {
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(gotoScanPage),
                                             name: NSNotification.Name("mk_bxs_swf_popToRootViewControllerNotification"),
                                             object: nil)
        
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(dfuUpdateComplete),
                                             name: NSNotification.Name("mk_bxs_swf_centralDeallocNotification"),
                                             object: nil)
        
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(centralManagerStateChanged),
                                             name: NSNotification.Name("mk_bxs_swf_centralManagerStateChangedNotification"),
                                             object: nil)
        
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(disconnectTypeNotification(_:)),
                                             name: NSNotification.Name("mk_bxs_swf_deviceDisconnectTypeNotification"),
                                             object: nil)
        
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(deviceConnectStateChanged),
                                             name: NSNotification.Name("mk_bxs_swf_peripheralConnectStateChangedNotification"),
                                             object: nil)
        
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(deviceStartDFUProcess),
                                             name: NSNotification.Name("mk_bxs_swf_startDfuProcessNotification"),
                                             object: nil)
    }
    
    // MARK: - Notification Handlers
    @objc private func gotoScanPage() {
        dismissWithPushAnimation(false)
    }
    
    @objc private func dfuUpdateComplete() {
        dismissWithPushAnimation(true)
    }
    
    @objc private func disconnectTypeNotification(_ notification: Notification) {
        guard let type = notification.userInfo?["type"] as? String else { return }
        
        disconnectType = true
        
        switch type {
        case "02":
            showAlert(with: "Modify password success! Please reconnect the Device.", title: " ")
        case "03":
            showAlert(with: "Beacon is disconnected.", title: "Reset success!")
        case "04":
            gotoScanPage()
        default:
            break
        }
    }
    
    @objc private func centralManagerStateChanged() {
        guard !disconnectType, !dfu else { return }
        
        if MKSwiftBXPSCentralManager.shared.centralStatus() != .enable {
            showAlert(with: "The current system of bluetooth is not available!", title: "Dismiss")
        }
    }
    
    @objc private func deviceConnectStateChanged() {
        guard !disconnectType, !dfu else { return }
        showAlert(with: "The device is disconnected.", title: "Dismiss")
    }
    
    @objc private func deviceStartDFUProcess() {
        dfu = true
    }
    
    func dismissWithPushAnimation(_ need: Bool) {
        let transition = CATransition()
        transition.duration = 0.1
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        transition.type = .push
        transition.subtype = .fromLeft
        
        // 添加到窗口的layer
        if let window = UIApplication.shared.windows.first {
            window.layer.add(transition, forKey: kCATransition)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {[weak self] in
            self?.dismiss(animated: false) {
                self?.pageDelegate?.mk_bxs_swf_needResetScanDelegate(need)
            }
        }
    }
    
    // MARK: - Private Methods
    private func showAlert(with msg: String, title: String) {
        // Dismiss any existing alerts from setting page
        NotificationCenter.default.post(name: NSNotification.Name("mk_bxs_swf_needDismissAlert"), object: nil)
        
        // Dismiss all MKPickViews
        NotificationCenter.default.post(name: NSNotification.Name("mk_customUIModule_dismissPickView"), object: nil)
        
        let confirmAction = MKSwiftAlertViewAction(title: "OK", handler: {[weak self] in
                self?.gotoScanPage()
        })
        
        let alertView = MKSwiftAlertView()
        alertView.addAction(confirmAction)
        alertView.showAlert(title: title, message: msg, notificationName: "mk_bxs_swf_needDismissAlert")
    }
    
    private func loadSubPages() {
        // Slot Page
        let slotPage = MKSFBXSSlotController()
        slotPage.tabBarItem = UITabBarItem(
            title: "SLOT",
            image: moduleIcon(name: "bxs_swf_slotTabBarItemUnselected", in: .module),
            selectedImage: moduleIcon(name: "bxs_swf_slotTabBarItemSelected", in: .module)
        )
        let slotNav = MKSwiftBaseNavigationController(rootViewController: slotPage)
        
        // Setting Page
        let settingPage = MKSFBXSSettingController()
        settingPage.tabBarItem = UITabBarItem(
            title: "SETTING",
            image: moduleIcon(name: "bxs_swf_settingTabBarItemUnselected", in: .module),
            selectedImage: moduleIcon(name: "bxs_swf_settingTabBarItemSelected", in: .module)
        )
        let settingNav = MKSwiftBaseNavigationController(rootViewController: settingPage)
        
        // Device Page
        let devicePage = MKSFBXSDeviceInfoController()
        devicePage.tabBarItem = UITabBarItem(
            title: "DEVICE",
            image: moduleIcon(name: "bxs_swf_deviceTabBarItemUnselected", in: .module),
            selectedImage: moduleIcon(name: "bxs_swf_deviceTabBarItemSelected", in: .module)
        )
        let deviceNav = MKSwiftBaseNavigationController(rootViewController: devicePage)
        
        viewControllers = [slotNav, settingNav, deviceNav]
    }
}
