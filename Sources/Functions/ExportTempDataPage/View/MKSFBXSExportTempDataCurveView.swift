//
//  MKSFBXSExportTempDataCurveView.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/17.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

class MKSFBXSExportTempDataCurveView: UIView {
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        
        totalLabel.snp.remakeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.top.equalTo(5)
            make.height.equalTo(Font.MKFont(10.0).lineHeight)
        }
        
        displayLabel.snp.remakeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.top.equalTo(totalLabel.snp.bottom).offset(3)
            make.height.equalTo(Font.MKFont(10.0).lineHeight)
        }
        
        tempView.snp.remakeConstraints { make in
            make.left.equalTo(5)
            make.right.equalTo(-5)
            make.top.equalTo(20)
            make.bottom.equalTo(snp.centerY).offset(-5)
        }
    }
    
    // MARK: - Public Methods
    func updateTemperatureDatas(_ temperatureList: [String],
                               temperatureMax: CGFloat,
                               temperatureMin: CGFloat,
                               completeBlock: @escaping () -> Void) {
        guard !temperatureList.isEmpty else {
            completeBlock()
            return
        }
        
        totalLabel.text = "Total Data Points: \(temperatureList.count)"
        let displayText = temperatureList.count > 1000 ? "1000" : "\(temperatureList.count)"
        displayLabel.text = "Window Display Points: \(displayText)"
        
        tempView.drawCurve(with: tempModel,
                          pointList: temperatureList,
                          maxValue: temperatureMax,
                          minValue: temperatureMin)
        
        completeBlock()
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        addSubview(totalLabel)
        addSubview(displayLabel)
        addSubview(tempView)
    }
    
    // MARK: - UI Components
    private lazy var totalLabel: UILabel = {
        let label = UILabel()
        label.textColor = .blue
        label.textAlignment = .right
        label.font = Font.MKFont(10.0)
        label.text = "Total Data Points: 0"
        return label
    }()
    
    private lazy var displayLabel: UILabel = {
        let label = UILabel()
        label.textColor = .blue
        label.textAlignment = .right
        label.font = Font.MKFont(10.0)
        label.text = "Window Display Points: 0"
        return label
    }()
    
    private lazy var tempView: MKSFBXSTHCurveView = {
        return MKSFBXSTHCurveView()
    }()
    
    private lazy var tempModel: MKSFBXSTHCurveViewModel = {
        let model = MKSFBXSTHCurveViewModel()
        model.curveTitle = "Temperature(℃)"
        model.curveViewBackgroundColor = .white
        model.lineWidth = 3.0
        model.labelColor = Color.rgb(136, 136, 136)
        return model
    }()
}
