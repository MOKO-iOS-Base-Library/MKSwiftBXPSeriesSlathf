//
//  MKSFBXSExcelManager.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/6.
//

import Foundation
import libxlsxwriter
import MKBaseSwiftModule

enum ExcelManagerError: LocalizedError {
    case createError
    case exportError
    
    var errorDescription: String? {
        switch self {
        case .createError:
            return "Failed to create workbook"
        case .exportError:
            return "Export Failed"
        }
    }
}

class MKSFBXSExcelManager {
    
    static func exportExcel(withTHDataList list: [[String: String]]) async throws {
        guard !list.isEmpty else {
            return
        }
        
        // 设置Excel文件名和路径
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let path = (documentPath as NSString).appendingPathComponent("Temperature&HumidityDatas.xlsx")
        
        // 创建新xlsx文件
        guard let workbook = workbook_new(path) else {
            throw ExcelManagerError.createError
        }
        
        // 创建sheet
        let worksheet = workbook_add_worksheet(workbook, nil)
        
        // 设置列宽
        worksheet_set_column(worksheet, 0, 2, 50, nil)
        
        // 添加格式
        let format = workbook_add_format(workbook)
        format_set_bold(format)
        format_set_align(format, UInt8(LXW_ALIGN_VERTICAL_CENTER.rawValue))
        
        // 写入表头
        worksheet_write_string(worksheet, 0, 0, "Date", nil)
        worksheet_write_string(worksheet, 0, 1, "Temperature", nil)
        worksheet_write_string(worksheet, 0, 2, "Humidity", nil)
        
        // 写入数据
        for (index, dict) in list.enumerated() {
            let date = dict["date"] ?? ""
            let temperature = dict["temperature"] ?? ""
            let humidity = dict["humidity"] ?? ""
            
            worksheet_write_string(worksheet, lxw_row_t(index + 1), 0, date, nil)
            worksheet_write_string(worksheet, lxw_row_t(index + 1), 1, temperature, nil)
            worksheet_write_string(worksheet, lxw_row_t(index + 1), 2, humidity, nil)
        }
        
        // 关闭并保存文件
        let errorCode = workbook_close(workbook)
        if errorCode.rawValue != LXW_NO_ERROR.rawValue {
            throw ExcelManagerError.exportError
        }
    }
}
