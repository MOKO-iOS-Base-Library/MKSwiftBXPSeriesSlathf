//
//  MKSFUBXSDeviceInfoView.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/11/7.
//

import SwiftUI

import MKSwiftUILibrary

extension MKSFBXSDeviceInfoModel: ObservableObject {
    
}

struct MKSFUBXSDeviceInfoView: View {
    
    @StateObject private var dataModel = MKSFBXSDeviceInfoModel()
    @State private var isLoading = false
    @State private var errorMsg: String?
    @State private var hudMsg: String = "Reading..."
    
    
    var body: some View {
        NavigationView {
            ZStack {
                //列表内容
                List {
                    ForEach(dataItems, id: \.0) {item in
                        MKSFUNormalTextCell(dataModel: createCellModel(for: item))
                            .listRowInsets(EdgeInsets())
                                                        .listRowSeparator(.hidden)
                                                        .background(Color.white)
                    }
                }
                .listStyle(PlainListStyle())
                
                
                if let errorMsg = errorMsg {
                    VStack {
                        Spacer()
                        Text(errorMsg)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(8)
                            .padding()
                            .onAppear {
                                // 3秒后自动隐藏错误提示
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    self.errorMsg = nil
                                }
                            }
                    }
                    .animation(.easeInOut, value: errorMsg)
                }
            }
            .navigationTitle("DEVICE")
            .onAppear {
                readDatasFromDevice()
            }
            .showHUD($isLoading, message: hudMsg, isPenetration: false)
        }
    }
    
    // MARK: - Interface
        
    private func readDatasFromDevice() {
        isLoading = true
        errorMsg = nil
        
        Task {
            do {
                try await dataModel.read()
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMsg = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Data Handling
        
    private var dataItems: [(String, String)] {
        [
            ("Battery voltage", dataModel.voltage + "mV"),
            ("Battery Percentage", dataModel.batteryPercent + "%"),
            ("MAC address", dataModel.macAddress),
            ("Product model", dataModel.productMode),
            ("Software version", dataModel.software),
            ("Firmware version", dataModel.firmware),
            ("Hardware version", dataModel.hardware),
            ("Manufacture date", dataModel.manuDate),
            ("Manufacturer", dataModel.manu)
        ]
    }
    
    private func createCellModel(for item: (String, String)) -> MKSFUNormalTextCellModel {
        let model = MKSFUNormalTextCellModel()
        model.leftMsg = item.0
        model.rightMsg = item.1
        model.showRightIcon = false
        model.leftMsgTextFont = .system(size: 16, weight: .medium)
        model.rightMsgTextFont = .system(size: 15)
        model.rightMsgTextColor = .gray
        return model
    }
}

#Preview {
    MKSFUBXSDeviceInfoView()
}
