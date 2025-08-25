//
//  MKSFBXSExportHTDataCurveView.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/6.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

class MKSFBXSExportHTDataCurveView: UIView {
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Methods
    func updateTemperatureDatas(temperatureList: [String],
                              temperatureMax: CGFloat,
                              temperatureMin: CGFloat,
                              humidityList: [String],
                              humidityMax: CGFloat,
                              humidityMin: CGFloat,
                              completeBlock: (() -> Void)?) {
        guard !temperatureList.isEmpty, !humidityList.isEmpty else {
            completeBlock?()
            return
        }
        
        totalLabel.text = "Total Data Points: \(temperatureList.count)"
        
        var displayText = "\(temperatureList.count)"
        if temperatureList.count > 1000 {
            displayText = "1000"
        }
        displayLabel.text = "Window Display Points: \(displayText)"
        
        tempView.drawCurve(with: tempModel,
                          pointList: temperatureList,
                          maxValue: temperatureMax,
                          minValue: temperatureMin)
        
        humidityView.drawCurve(with: humidityModel,
                             pointList: humidityList,
                             maxValue: humidityMax,
                             minValue: humidityMin)
        
        completeBlock?()
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        
        totalLabel.snp.remakeConstraints { make in
            make.left.equalTo(10.0)
            make.right.equalTo(-10.0)
            make.top.equalTo(5.0)
            make.height.equalTo(UIFont.systemFont(ofSize: 10).lineHeight)
        }
        
        displayLabel.snp.remakeConstraints { make in
            make.left.equalTo(10.0)
            make.right.equalTo(-10.0)
            make.top.equalTo(totalLabel.snp.bottom).offset(3.0)
            make.height.equalTo(Font.MKFont(10.0).lineHeight)
        }
        
        tempView.snp.remakeConstraints { make in
            make.left.equalTo(5.0)
            make.right.equalTo(-5.0)
            make.top.equalTo(20.0)
            make.bottom.equalTo(self.snp.centerY).offset(-5.0)
        }
        
        humidityView.snp.remakeConstraints { make in
            make.left.equalTo(5.0)
            make.right.equalTo(-5.0)
            make.top.equalTo(self.snp.centerY).offset(5.0)
            make.height.equalTo(tempView.snp.height)
        }
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        addSubview(tempView)
        addSubview(humidityView)
        addSubview(totalLabel)
        addSubview(displayLabel)
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
    
    private lazy var humidityView: MKSFBXSTHCurveView = {
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
    
    private lazy var humidityModel: MKSFBXSTHCurveViewModel = {
        let model = MKSFBXSTHCurveViewModel()
        model.lineColor = .green
        model.curveViewBackgroundColor = .white
        model.lineWidth = 3.0
        model.curveTitle = "Humidity(%RH)"
        model.labelColor = Color.rgb(136, 136, 136)
        return model
    }()
}
