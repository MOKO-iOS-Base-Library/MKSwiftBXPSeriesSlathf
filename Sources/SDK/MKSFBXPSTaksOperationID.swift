//
//  MKSwiftBXPSTaksOperationID.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/6/18.
//

import Foundation

enum MKSFBXSTaskOperationID: Int {
    case defaultTaskOperationID
    
    // MARK: - Password Related
    
    // MARK: - Custom Read
    case taskReadMacAddressOperation
    case taskReadThreeAxisDataParamsOperation
    case taskReadFirmwareOperation
    case taskReadManufacturerOperation
    case taskReadProductDateOperation
    case taskReadSoftwareOperation
    case taskReadHardwareOperation
    case taskReadDeviceModelOperation
    case taskReadConnectableOperation
    case taskReadTriggeredSlotParamsOperation
    case taskReadDeviceTypeOperation
    case taskReadSlotAdvTypeOperation
    case taskReadHallDataStoreStatusOperation
    case taskReadHallHistoryDataOperation
    case taskReadResetDeviceByButtonStatusOperation
    case taskReadHallSensorStatusOperation
    case taskReadSlotTypeOperation
    case taskReadSlotTriggerDataOperation
    case taskReadBeforeTriggerSlotDataOperation
    case taskReadTriggerSlotDataOperation
    case taskReadSlotDataOperation
    case taskReadADVChannelOperation
    case taskReadDirectionFindingStatusOperation
    case taskTagIDAutofillStatusOperation
    case taskDeviceRuntimeOperation
    case taskReadDeviceUTCTimeOperation
    case taskReadTHDataStoreStatusOperation
    case taskReadTHSamplingRateOperation
    case taskReadHTRecordTotalNumbersOperation
    case taskReadSensorTypeOperation
    case taskReadRemoteReminderBuzzerFrequencyOperation
    case taskReadTriggerLEDIndicatorStatusOperation
    case taskReadHallTriggerCountOperation
    case taskReadMotionTriggerCountOperation
    case taskReadBatteryVoltageOperation
    case taskReadBatteryPercentageOperation
    case taskReadBatteryADVModeOperation
    
    // MARK: - Temperature/Humidity
    case taskReadTemperatureHumidityDataOperation
    
    // MARK: - Password Characteristic
    case taskReadNeedPasswordOperation
    
    // MARK: - Hall Sensor Characteristic
    case taskReadMagnetStatusOperation
    
    // MARK: - Custom Protocol Configuration
    case taskConfigThreeAxisDataParamsOperation
    case taskConfigADVChannelOperation
    case taskConfigTriggeredSlotParamOperation
    case taskPowerOffOperation
    case taskFactoryResetOperation
    case taskClearHallTriggerCountOperation
    case taskConfigHallDataStoreStatusOperation
    case taskClearHallHistoryDataOperation
    case taskConfigResetDeviceByButtonStatusOperation
    case taskConfigHallSensorStatusOperation
    case taskConfigSlotTriggerParamsOperation
    case taskConfigBeforeTriggerSlotDataOperation
    case taskConfigTriggerSlotDataOperation
    case taskConfigSlotDataOperation
    case taskConfigDirectionFindingStatusOperation
    case taskConfigConnectableOperation
    case taskConfigTagIDAutofillStatusOperation
    case taskConfigDeviceTimeOperation
    case taskConfigTHDataStoreStatusOperation
    case taskConfigTHSamplingRateOperation
    case taskDeleteBXPRecordHTDatasOperation
    case taskConfigRemoteReminderLEDNotiParamsOperation
    case taskClearMotionTriggerCountOperation
    case taskConfigRemoteReminderBuzzerNotiParamsOperation
    case taskConfigRemoteReminderBuzzerFrequencyOperation
    case taskConfigTriggerLEDIndicatorStatusOperation
    case taskConfigBatteryResetOperation
    case taskConfigBatteryADVModeOperation
    
    // MARK: - Password Related
    case connectPasswordOperation
    case taskConfigConnectPasswordOperation
    case taskConfigPasswordVerificationOperation
}
