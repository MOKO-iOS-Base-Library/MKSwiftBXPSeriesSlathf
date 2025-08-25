//
//   MKSFBXSScanInfoCellModel.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/6/27.
//

import Foundation
import CoreBluetooth
import MKSwiftBeaconXCustomUI

class MKSFBXSScanInfoCellModel {
    var advertiseList: [MKSwiftBXScanBaseModel] = []
    var rssi: String = ""
    var connectEnable: Bool = false
    var otaMode: Bool = false
    var identifier: String = ""
    var peripheral: CBPeripheral?
    var deviceName: String = ""
    var battery: String = ""
    var macAddress: String = ""
    var tagID: String = ""
    var displayTime: String = ""
    var lastScanDate: TimeInterval = 0
    
    init() {}
}
