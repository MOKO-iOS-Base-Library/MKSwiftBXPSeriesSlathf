//
//  MKSFBXSScanPageAdopter.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/6/28.
//

import Foundation
import CoreBluetooth
import MKSwiftBeaconXCustomUI
import MKBaseSwiftModule
import UIKit

class MKSFBXSScanPageAdopter {
    
    // MARK: - Beacon Parsing
    
    static func parseBeaconDatas(_ beacon: MKSFBXSBaseBeacon) -> Any? {
        switch beacon {
        case let iBeacon as MKSFBXSiBeacon:
            let cellModel = MKSwiftBXScanBeaconCellModel()
            cellModel.rssi = "\(iBeacon.rssi)"
            cellModel.rssi1M = "\(iBeacon.rssi1M)"
            cellModel.txPower = "\(iBeacon.txPower)"
            cellModel.interval = iBeacon.interval
            cellModel.major = iBeacon.major
            cellModel.minor = iBeacon.minor
            cellModel.uuid = iBeacon.uuid.lowercased()
            return cellModel
            
        case let tlmBeacon as MKSFBXSTLMBeacon:
            let cellModel = MKSFBXSScanTLMCellModel()
            cellModel.version = tlmBeacon.version.stringValue
            cellModel.mvPerbit = tlmBeacon.mvPerbit.intValue
            cellModel.temperature = tlmBeacon.temperature.stringValue
            cellModel.advertiseCount = tlmBeacon.advertiseCount.stringValue
            cellModel.deciSecondsSinceBoot = tlmBeacon.deciSecondsSinceBoot.stringValue
            return cellModel
            
        case let uidBeacon as MKSFBXSUIDBeacon:
            let cellModel = MKSwiftBXScanUIDCellModel()
            cellModel.txPower = "\(uidBeacon.txPower)"
            cellModel.namespaceId = uidBeacon.namespaceId
            cellModel.instanceId = uidBeacon.instanceId
            return cellModel
            
        case let urlBeacon as MKSFBXSURLBeacon:
            let cellModel = MKSwiftBXScanURLCellModel()
            cellModel.txPower = "\(urlBeacon.txPower)"
            cellModel.shortUrl = urlBeacon.shortUrl
            return cellModel
            
        case let sensorBeacon as MKSFBXSSensorInfoBeacon:
            let cellModel = MKSFBXSScanSensorInfoCellModel()
            cellModel.magneticStatus = sensorBeacon.magnetStatus
            cellModel.magneticCount = sensorBeacon.hallSensorCount
            cellModel.triaxialSensor = sensorBeacon.triaxialSensor
            cellModel.motionStatus = sensorBeacon.moved
            cellModel.motionCount = sensorBeacon.movedCount
            cellModel.xData = sensorBeacon.xData
            cellModel.yData = sensorBeacon.yData
            cellModel.zData = sensorBeacon.zData
            cellModel.temperature = sensorBeacon.temperature
            cellModel.humidity = sensorBeacon.humidity
            cellModel.supportTemp = sensorBeacon.tempSensor
            cellModel.supportHumidity = sensorBeacon.humiditySensor
            return cellModel
            
        default:
            return nil
        }
    }
    
    static func parseBaseBeaconToInfoModel(_ beacon: MKSFBXSBaseBeacon) -> MKSFBXSScanInfoCellModel {
        let deviceModel = MKSFBXSScanInfoCellModel()
        
        deviceModel.identifier = beacon.peripheral!.identifier.uuidString
        deviceModel.rssi = "\(beacon.rssi)"
        deviceModel.deviceName = beacon.deviceName ?? ""
        deviceModel.displayTime = "N/A"
        deviceModel.lastScanDate = Date().timeIntervalSince1970 * 1000
        deviceModel.connectEnable = beacon.connectEnable
        deviceModel.peripheral = beacon.peripheral
        deviceModel.otaMode = (beacon.frameType == .ota)
        
        if beacon.frameType == .sensorInfo {
            if let sensorBeacon = beacon as? MKSFBXSSensorInfoBeacon {
                //如果是传感器帧
                deviceModel.battery = sensorBeacon.battery
                deviceModel.tagID = sensorBeacon.tagID
            }
        }else if beacon.frameType == .productionTest {
            if let testBeacon = beacon as? MKSFBXSProductionTestBeacon {
                //如果是产测
                deviceModel.battery = testBeacon.battery
                deviceModel.macAddress = testBeacon.macAddress
            }
        }
        
        if let parsedData = parseBeaconDatas(beacon) as? MKSwiftBXScanBaseModel {
            //如果是URL、TLM、UID、iBeacon、温湿度、三轴中的一种，直接加入到deviceModel中的数据帧数组里面
            let frameType = fetchFrameIndex(parsedData)
            
            parsedData.advertiseData = beacon.advertiseData
            parsedData.index = 0
            parsedData.frameIndex = frameType
            deviceModel.advertiseList.append(parsedData)
        }
        
        return deviceModel
    }
    
    // MARK: - Model Updating
    
    static func updateInfoCellModel(_ exsitModel: MKSFBXSScanInfoCellModel, beaconData: MKSFBXSBaseBeacon) {
        exsitModel.connectEnable = beaconData.connectEnable
        exsitModel.peripheral = beaconData.peripheral
        exsitModel.otaMode = (beaconData.frameType == .ota)
        exsitModel.rssi = "\(beaconData.rssi)"
        
        if exsitModel.lastScanDate > 0 {
            let space = Date().timeIntervalSince1970 * 1000 - exsitModel.lastScanDate
            if space > 10 {
                exsitModel.displayTime = "<->\(Int(space))ms"
                exsitModel.lastScanDate = Date().timeIntervalSince1970 * 1000
            }
        }
        
        if beaconData.frameType == .sensorInfo {
            if let sensorBeacon = beaconData as? MKSFBXSSensorInfoBeacon {
                exsitModel.battery = sensorBeacon.battery
                exsitModel.tagID = sensorBeacon.tagID
                if let deviceName = sensorBeacon.deviceName, !deviceName.isEmpty {
                    exsitModel.deviceName = deviceName
                }
            }
        } else if beaconData.frameType == .productionTest {
            if let testBeacon = beaconData as? MKSFBXSProductionTestBeacon {
                exsitModel.battery = testBeacon.battery
                exsitModel.macAddress = testBeacon.macAddress
            }
        }
        //如果是URL、TLM、UID、iBeacon的一种，
        //如果eddStone帧数组里面已经包含该类型数据，则判断是否是TLM，如果是TLM直接替换数组中的数据，如果不是，则判断广播内容是否一样，如果一样，则不处理，如果不一样，直接加入到帧数组
        guard let tempModel = parseBeaconDatas(beaconData) as? MKSwiftBXScanBaseModel else { return }
        let frameType = fetchFrameIndex(tempModel)
        tempModel.advertiseData = beaconData.advertiseData
        tempModel.frameIndex = frameType
        for (index, model) in exsitModel.advertiseList.enumerated() {
            if model.advertiseData == tempModel.advertiseData {
                //如果广播内容一样，直接舍弃数据
                return
            }
            
            if type(of: tempModel) == type(of: model),
               (model is MKSFBXSScanTLMCellModel || model is MKSFBXSScanSensorInfoCellModel) {
                //TLM、Tag需要替换
                tempModel.index = index
                exsitModel.advertiseList[index] = tempModel
                return
            }
        }
        //如果eddStone帧数组里面不包含该数据，直接添加
        exsitModel.advertiseList.append(tempModel)
        tempModel.index = exsitModel.advertiseList.count - 1
        
        exsitModel.advertiseList = exsitModel.advertiseList
            .sorted { $0.frameIndex < $1.frameIndex } // 排序
            .enumerated()
            .map { index, model in
                model.index = index // 更新 index
                return model
            }
    }
    
    // MARK: - Cell Handling
    
    @MainActor static func loadCell(with tableView: UITableView, dataModel: Any) -> UITableViewCell {
        switch dataModel {
        case let model as MKSwiftBXScanUIDCellModel:
            let cell = MKSwiftBXScanUIDCell.initCell(with: tableView)
            cell.dataModel = model
            return cell
            
        case let model as MKSwiftBXScanURLCellModel:
            let cell = MKSwiftBXScanURLCell.initCell(with: tableView)
            cell.dataModel = model
            return cell
            
        case let model as MKSFBXSScanTLMCellModel:
            let cell = MKSFBXSScanTLMCell.initCell(with: tableView)
            cell.dataModel = model
            return cell
            
        case let model as MKSwiftBXScanBeaconCellModel:
            let cell = MKSwiftBXScanBeaconCell.initCell(with: tableView)
            cell.dataModel = model
            return cell
            
        case let model as MKSFBXSScanSensorInfoCellModel:
            let cell = MKSFBXSScanSensorInfoCell.initCell(with: tableView)
            cell.dataModel = model
            return cell
            
        default:
            return UITableViewCell(style: .default, reuseIdentifier: "MKSFBXSScanPageAdopterIdenty")
        }
    }
    
    @MainActor static func loadCellHeight(with dataModel: Any) -> CGFloat {
        switch dataModel {
        case _ as MKSwiftBXScanUIDCellModel:
            return 85.0
            
        case _ as MKSwiftBXScanURLCellModel:
            return 70.0
            
        case _ as MKSFBXSScanTLMCellModel:
            return 110.0
            
        case let model as MKSwiftBXScanBeaconCellModel:
            return MKSwiftBXScanBeaconCell.getCellHeight(with: model.uuid)
            
        case let model as MKSFBXSScanSensorInfoCellModel:
            return model.fetchCellHeight()
            
        default:
            return 0
        }
    }
    
    // MARK: - Frame Index
    
    static func fetchFrameIndex(_ dataModel: Any) -> Int {
        switch dataModel {
        case _ as MKSwiftBXScanUIDCellModel:
            return 0
            
        case _ as MKSwiftBXScanURLCellModel:
            return 1
            
        case _ as MKSFBXSScanTLMCellModel:
            return 2
            
        case _ as MKSwiftBXScanBeaconCellModel:
            return 3
            
        case _ as MKSFBXSScanSensorInfoCellModel:
            return 4
            
        default:
            return 5
        }
    }
}
